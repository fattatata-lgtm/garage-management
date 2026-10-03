const prisma = require('../lib/prisma');
const { generateInvoiceNo, calcDiscountAmount } = require('../utils/helpers');
const { buildSalesReceipt } = require('../utils/receipt');

const fullInclude = {
  customer: true,
  discount: true,
  items: { include: { sparepart: true } },
};

async function list(req, res, next) {
  try {
    const { from, to, q } = req.query;
    const where = {
      AND: [
        from ? { date: { gte: new Date(from) } } : {},
        to ? { date: { lte: new Date(to) } } : {},
        q ? { invoiceNo: { contains: q, mode: 'insensitive' } } : {},
      ],
    };
    const sales = await prisma.salesTransaction.findMany({
      where, include: fullInclude, orderBy: { date: 'desc' },
    });
    res.json(sales);
  } catch (err) { next(err); }
}

async function detail(req, res, next) {
  try {
    const id = Number(req.params.id);
    const sale = await prisma.salesTransaction.findUnique({ where: { id }, include: fullInclude });
    if (!sale) return res.status(404).json({ message: 'Transaksi penjualan tidak ditemukan.' });
    res.json(sale);
  } catch (err) { next(err); }
}

// Buat nomor invoice baru kosong (dipakai saat halaman Tambah Penjualan dibuka)
async function nextInvoice(req, res, next) {
  try {
    const invoiceNo = await generateInvoiceNo('SLS', 'salesTransaction');
    res.json({ invoiceNo, date: new Date() });
  } catch (err) { next(err); }
}

// Buat transaksi penjualan retail lengkap: item + diskon + pajak + potong stok (atomic)
async function create(req, res, next) {
  try {
    const { customerId, walkInName, items, discountId, paid } = req.body;

    if (!Array.isArray(items) || items.length < 1) {
      return res.status(400).json({ message: 'Minimal 1 item sparepart wajib ditambahkan.' });
    }

    const result = await prisma.$transaction(async (tx) => {
      let subtotal = 0;
      const preparedItems = [];

      for (const it of items) {
        const qty = Number(it.qty);
        if (!it.sparepartId || !qty || qty <= 0) {
          throw Object.assign(new Error('Item sparepart tidak valid.'), { status: 400 });
        }
        const sp = await tx.sparepart.findUnique({ where: { id: Number(it.sparepartId) } });
        if (!sp) throw Object.assign(new Error('Sparepart tidak ditemukan.'), { status: 404 });
        if (sp.stock < qty) {
          throw Object.assign(new Error(`Stok ${sp.name} tidak mencukupi (tersedia ${sp.stock}).`), { status: 400 });
        }
        const price = Number(sp.sellPrice);
        subtotal += price * qty;
        preparedItems.push({ sparepartId: sp.id, qty, price, sparepart: sp });
      }

      let discount = null;
      if (discountId) discount = await tx.discount.findUnique({ where: { id: Number(discountId) } });
      const discountAmount = calcDiscountAmount(subtotal, discount);

      const settings = await tx.settings.findUnique({ where: { id: 1 } });
      const taxRate = settings ? Number(settings.taxSales) : 10;
      const afterDiscount = Math.max(subtotal - discountAmount, 0);
      const taxAmount = (afterDiscount * taxRate) / 100;
      const total = afterDiscount + taxAmount;

      const paidNum = Number(paid);
      if (paidNum == null || isNaN(paidNum) || paidNum < total) {
        throw Object.assign(new Error('Jumlah dibayar wajib diisi dan tidak boleh kurang dari total.'), { status: 400 });
      }
      const change = paidNum - total;

      const invoiceNo = await generateInvoiceNo('SLS', 'salesTransaction');

      const sale = await tx.salesTransaction.create({
        data: {
          invoiceNo,
          customerId: customerId ? Number(customerId) : null,
          walkInName: customerId ? null : (walkInName || 'Pelanggan Umum'),
          date: new Date(),
          discountId: discountId ? Number(discountId) : null,
          subtotal, discountAmount, taxAmount, total, paid: paidNum, change,
          items: { create: preparedItems.map((p) => ({ sparepartId: p.sparepartId, qty: p.qty, price: p.price })) },
        },
        include: fullInclude,
      });

      for (const p of preparedItems) {
        await tx.sparepart.update({ where: { id: p.sparepartId }, data: { stock: { decrement: p.qty } } });
        await tx.stockHistory.create({
          data: {
            sparepartId: p.sparepartId, direction: 'KELUAR', source: 'PENJUALAN',
            quantity: p.qty, note: `Terjual pada invoice ${invoiceNo}`, refInvoice: invoiceNo,
          },
        });
      }

      return sale;
    });

    res.status(201).json(result);
  } catch (err) { next(err); }
}

async function whatsappMessage(req, res, next) {
  try {
    const id = Number(req.params.id);
    const sale = await prisma.salesTransaction.findUnique({ where: { id }, include: fullInclude });
    if (!sale) return res.status(404).json({ message: 'Transaksi tidak ditemukan.' });
    const name = sale.customer ? sale.customer.name : (sale.walkInName || 'Pelanggan');
    const text = [
      `Halo *${name}* 👋`,
      '',
      'Terima kasih telah berbelanja di bengkel kami 🙏',
      '',
      'Berikut struk Anda:',
      '',
      buildSalesReceipt(sale),
    ].join('\n');
    res.json({ phone: sale.customer ? sale.customer.phone : null, message: text });
  } catch (err) { next(err); }
}

// Hapus transaksi penjualan: stok sparepart dikembalikan & dicatat di riwayat stok.
async function remove(req, res, next) {
  try {
    const id = Number(req.params.id);
    await prisma.$transaction(async (tx) => {
      const sale = await tx.salesTransaction.findUnique({ where: { id }, include: { items: true } });
      if (!sale) throw Object.assign(new Error('Transaksi tidak ditemukan.'), { status: 404 });
      for (const it of sale.items) {
        await tx.sparepart.update({ where: { id: it.sparepartId }, data: { stock: { increment: it.qty } } });
        await tx.stockHistory.create({
          data: {
            sparepartId: it.sparepartId, direction: 'MASUK', source: 'PENJUALAN', quantity: it.qty,
            note: `Stok dikembalikan: penjualan ${sale.invoiceNo} dihapus`, refInvoice: sale.invoiceNo,
          },
        });
      }
      await tx.salesTransaction.delete({ where: { id } });
    });
    res.json({ message: 'Transaksi penjualan berhasil dihapus.' });
  } catch (err) { next(err); }
}

module.exports = { list, detail, create, nextInvoice, whatsappMessage, remove };
