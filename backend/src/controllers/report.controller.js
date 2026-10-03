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

// Laporan Layanan Service - filter tanggal mulai-akhir
async function serviceReport(req, res, next) {
  try {
    const { from, to } = req.query;
    const where = {
      AND: [
        from ? { date: { gte: new Date(from) } } : {},
        to ? { date: { lte: new Date(to) } } : {},
      ],
    };
    const services = await prisma.serviceTransaction.findMany({
      where,
      include: { vehicle: { include: { customer: true } }, technician: true },
      orderBy: { date: 'desc' },
    });

    const summary = {
      totalService: services.length,
      totalBiaya: services.reduce((s, d) => s + Number(d.total), 0),
      selesai: services.filter((s) => s.status === 'SELESAI').length,
      berjalan: services.filter((s) => s.status !== 'SELESAI').length,
    };

    res.json({ summary, detail: services });
  } catch (err) { next(err); }
}

// Laporan Penjualan - filter tanggal
async function salesReport(req, res, next) {
  try {
    const { from, to } = req.query;
    const where = {
      AND: [
        from ? { date: { gte: new Date(from) } } : {},
        to ? { date: { lte: new Date(to) } } : {},
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

module.exports = { stockReport, serviceReport, salesReport };
