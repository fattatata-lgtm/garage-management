const prisma = require('../lib/prisma');
const { stockStatus } = require('../utils/helpers');

// Laporan Stok - filter kategori
async function stockReport(req, res, next) {
  try {
    const { categoryId } = req.query;
    const where = categoryId ? { categoryId: Number(categoryId) } : {};
    const spareparts = await prisma.sparepart.findMany({ where, include: { category: true }, orderBy: { name: 'asc' } });

    const detail = spareparts.map((sp) => ({
      ...sp,
      status: stockStatus(sp.stock, sp.lowStockThreshold),
      stockValue: Number(sp.buyPrice) * sp.stock,
    }));

    const summary = {
      totalItems: detail.length,
      totalStockValue: detail.reduce((s, d) => s + d.stockValue, 0),
      baik: detail.filter((d) => d.status === 'BAIK').length,
      rendah: detail.filter((d) => d.status === 'RENDAH').length,
      habis: detail.filter((d) => d.status === 'HABIS').length,
    };

    res.json({ summary, detail });
  } catch (err) { next(err); }
}

// Laporan Layanan Service - filter tanggal mulai-akhir & pelanggan
async function serviceReport(req, res, next) {
  try {
    const { from, to, customerId } = req.query;
    const where = {
      AND: [
        from ? { date: { gte: new Date(from) } } : {},
        to ? { date: { lte: new Date(to) } } : {},
        customerId ? { vehicle: { customerId: Number(customerId) } } : {},
      ],
    };
    const services = await prisma.serviceTransaction.findMany({
      where,
      include: { vehicle: { include: { customer: true } }, technician: true, details: true },
      orderBy: { date: 'desc' },
    });

    // Layanan paling laris: jumlah dipakai (kali) & total biaya jasa per nama layanan
    const svcMap = new Map();
    for (const sv of services) {
      for (const d of sv.details) {
        const name = String(d.name || '').trim();
        if (!name) continue;
        const key = name.toLowerCase();
        const row = svcMap.get(key) || { name, count: 0, revenue: 0 };
        row.count += 1;
        row.revenue += Number(d.cost);
        svcMap.set(key, row);
      }
    }
    const topServices = [...svcMap.values()]
      .sort((a, b) => b.count - a.count || b.revenue - a.revenue)
      .map((r, i) => ({ rank: i + 1, ...r }));

    const summary = {
      totalService: services.length,
      totalBiaya: services.reduce((s, d) => s + Number(d.total), 0),
      selesai: services.filter((s) => s.status === 'SELESAI').length,
      berjalan: services.filter((s) => s.status !== 'SELESAI').length,
    };

    res.json({ summary, topServices, detail: services });
  } catch (err) { next(err); }
}

// Laporan Penjualan - filter tanggal & pelanggan
async function salesReport(req, res, next) {
  try {
    const { from, to, customerId } = req.query;
    const where = {
      AND: [
        from ? { date: { gte: new Date(from) } } : {},
        to ? { date: { lte: new Date(to) } } : {},
        customerId ? { customerId: Number(customerId) } : {},
      ],
    };
    const sales = await prisma.salesTransaction.findMany({
      where,
      include: { customer: true, items: { include: { sparepart: true } } },
      orderBy: { date: 'desc' },
    });

    let totalLaba = 0;
    let totalItem = 0;
    for (const s of sales) {
      for (const it of s.items) {
        totalLaba += (Number(it.price) - Number(it.sparepart.buyPrice)) * it.qty;
        totalItem += it.qty;
      }
    }

    const summary = {
      totalPenjualan: sales.reduce((s, d) => s + Number(d.total), 0),
      totalLaba,
      jumlahTransaksi: sales.length,
      jumlahItem: totalItem,
    };

    res.json({ summary, detail: sales });
  } catch (err) { next(err); }
}

// Laporan Sparepart (paling laris) - filter rentang tanggal & sumber: ALL | SERVICE | SALES
async function sparepartReport(req, res, next) {
  try {
    const { from, to } = req.query;
    const source = ['SERVICE', 'SALES'].includes(req.query.source) ? req.query.source : 'ALL';
    const dateWhere = {
      AND: [
        from ? { date: { gte: new Date(from) } } : {},
        to ? { date: { lte: new Date(to) } } : {},
      ],
    };

    const map = new Map();
    const bucket = (sp) => {
      if (!map.has(sp.id)) {
        map.set(sp.id, {
          id: sp.id, code: sp.code, name: sp.name, category: sp.category?.name || '-',
          qtyService: 0, qtySales: 0, qtyTotal: 0, revenue: 0, profit: 0,
        });
      }
      return map.get(sp.id);
    };

    if (source !== 'SALES') {
      const used = await prisma.serviceSparepart.findMany({
        where: { service: dateWhere },
        include: { sparepart: { include: { category: true } } },
      });
      for (const u of used) {
        const row = bucket(u.sparepart);
        row.qtyService += u.qty;
        row.qtyTotal += u.qty;
        row.revenue += Number(u.price) * u.qty;
        row.profit += (Number(u.price) - Number(u.sparepart.buyPrice)) * u.qty;
      }
    }
    if (source !== 'SERVICE') {
      const sold = await prisma.salesItem.findMany({
        where: { sales: dateWhere },
        include: { sparepart: { include: { category: true } } },
      });
      for (const it of sold) {
        const row = bucket(it.sparepart);
        row.qtySales += it.qty;
        row.qtyTotal += it.qty;
        row.revenue += Number(it.price) * it.qty;
        row.profit += (Number(it.price) - Number(it.sparepart.buyPrice)) * it.qty;
      }
    }

    const detail = [...map.values()]
      .sort((a, b) => b.qtyTotal - a.qtyTotal || b.revenue - a.revenue)
      .map((r, i) => ({ rank: i + 1, ...r }));

    const summary = {
      jenisTerjual: detail.length,
      totalQty: detail.reduce((s, d) => s + d.qtyTotal, 0),
      totalNilai: detail.reduce((s, d) => s + d.revenue, 0),
      terlaris: detail[0] ? detail[0].name : '-',
    };

    res.json({ source, summary, detail });
  } catch (err) { next(err); }
}

// Laporan Loyalitas Pelanggan - berdasarkan transaksi dalam rentang tanggal.
// Sumber (source): ALL | SERVICE | SALES. Yang dihitung: service LUNAS (status SELESAI)
// dan penjualan sparepart atas nama pelanggan terdaftar.
const ACTIVE_DAYS = 90;

async function loyaltyReport(req, res, next) {
  try {
    const { from, to } = req.query;
    const dateWhere = {
      AND: [
        from ? { date: { gte: new Date(from) } } : {},
        to ? { date: { lte: new Date(to) } } : {},
      ],
    };

    const source = ['SERVICE', 'SALES'].includes(req.query.source) ? req.query.source : 'ALL';
    const [services, sales] = await Promise.all([
      source === 'SALES' ? [] : prisma.serviceTransaction.findMany({
        where: { AND: [dateWhere, { status: 'SELESAI' }] },
        select: { date: true, total: true, vehicle: { select: { customerId: true } } },
      }),
      source === 'SERVICE' ? [] : prisma.salesTransaction.findMany({
        where: { AND: [dateWhere, { customerId: { not: null } }] },
        select: { date: true, total: true, customerId: true },
      }),
    ]);

    const map = new Map();
    const row = (id) => {
      if (!map.has(id)) map.set(id, { customerId: id, serviceCount: 0, salesCount: 0, totalSpent: 0, firstDate: null, lastDate: null });
      return map.get(id);
    };
    const touch = (r, date) => {
      const d = new Date(date);
      if (!r.firstDate || d < r.firstDate) r.firstDate = d;
      if (!r.lastDate || d > r.lastDate) r.lastDate = d;
    };
    for (const sv of services) {
      const r = row(sv.vehicle.customerId);
      r.serviceCount += 1; r.totalSpent += Number(sv.total); touch(r, sv.date);
    }
    for (const sl of sales) {
      const r = row(sl.customerId);
      r.salesCount += 1; r.totalSpent += Number(sl.total); touch(r, sl.date);
    }

    const customers = await prisma.customer.findMany({
      where: { id: { in: [...map.keys()] } },
      select: { id: true, name: true, phone: true },
    });
    const custById = new Map(customers.map((c) => [c.id, c]));
    const now = Date.now();

    const detail = [...map.values()]
      .map((r) => {
        const c = custById.get(r.customerId) || {};
        const visits = r.serviceCount + r.salesCount;
        const daysSince = Math.floor((now - r.lastDate.getTime()) / 86400000);
        return {
          customerId: r.customerId, name: c.name || '-', phone: c.phone || '-',
          serviceCount: r.serviceCount, salesCount: r.salesCount, visits,
          totalSpent: r.totalSpent, firstDate: r.firstDate, lastDate: r.lastDate,
          daysSince, active: daysSince <= ACTIVE_DAYS,
        };
      })
      .sort((a, b) => b.visits - a.visits || b.totalSpent - a.totalSpent)
      .map((r, i) => ({ rank: i + 1, ...r }));

    const totalVisits = detail.reduce((s, d) => s + d.visits, 0);
    const summary = {
      totalPelanggan: detail.length,
      totalTransaksi: totalVisits,
      rataTransaksi: detail.length ? Math.round((totalVisits / detail.length) * 10) / 10 : 0,
      totalBelanja: detail.reduce((s, d) => s + d.totalSpent, 0),
    };

    res.json({ source, activeDays: ACTIVE_DAYS, summary, detail });
  } catch (err) { next(err); }
}

module.exports = { stockReport, serviceReport, salesReport, sparepartReport, loyaltyReport };
