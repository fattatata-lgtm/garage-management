const prisma = require('../lib/prisma');
const { stockStatus } = require('../utils/helpers');

function withStatus(sp) {
  return { ...sp, status: stockStatus(sp.stock, sp.lowStockThreshold) };
}

async function list(req, res, next) {
  try {
    const { q, categoryId } = req.query;
    const where = {
      AND: [
        q ? { OR: [
              { name: { contains: q, mode: 'insensitive' } },
              { code: { contains: q, mode: 'insensitive' } },
            ] } : {},
        categoryId ? { categoryId: Number(categoryId) } : {},
      ],
    };
    const spareparts = await prisma.sparepart.findMany({
      where,
      include: { category: true },
      orderBy: { name: 'asc' },
    });
    res.json(spareparts.map(withStatus));
  } catch (err) { next(err); }
}

async function detail(req, res, next) {
  try {
    const id = Number(req.params.id);
    const sparepart = await prisma.sparepart.findUnique({
      where: { id },
      include: {
        category: true,
        stockHistory: { orderBy: { createdAt: 'desc' }, take: 100 },
      },
    });
    if (!sparepart) return res.status(404).json({ message: 'Sparepart tidak ditemukan.' });
    res.json(withStatus(sparepart));
  } catch (err) { next(err); }
}

async function create(req, res, next) {
  try {
    const { code, name, categoryId, buyPrice, sellPrice, stock, lowStockThreshold } = req.body;
    if (!code || !name || !categoryId || buyPrice == null || sellPrice == null) {
      return res.status(400).json({ message: 'Kode, nama, kategori, harga beli, dan harga jual wajib diisi.' });
    }
    const sparepart = await prisma.sparepart.create({
      data: {
        code, name,
        categoryId: Number(categoryId),
        buyPrice: Number(buyPrice),
        sellPrice: Number(sellPrice),
        stock: stock ? Number(stock) : 0,
        lowStockThreshold: lowStockThreshold ? Number(lowStockThreshold) : 5,
      },
    });
    res.status(201).json(sparepart);
  } catch (err) { next(err); }
}

async function update(req, res, next) {
  try {
    const id = Number(req.params.id);
    const { code, name, categoryId, buyPrice, sellPrice, lowStockThreshold } = req.body;
    const sparepart = await prisma.sparepart.update({
      where: { id },
      data: {
        code, name,
        categoryId: categoryId ? Number(categoryId) : undefined,
        buyPrice: buyPrice != null ? Number(buyPrice) : undefined,
        sellPrice: sellPrice != null ? Number(sellPrice) : undefined,
        lowStockThreshold: lowStockThreshold != null ? Number(lowStockThreshold) : undefined,
      },
    });
    res.json(sparepart);
  } catch (err) { next(err); }
}

async function remove(req, res, next) {
  try {
    const id = Number(req.params.id);
    await prisma.sparepart.delete({ where: { id } });
    res.json({ message: 'Sparepart berhasil dihapus.' });
  } catch (err) { next(err); }
}

// Stok Masuk / Stok Keluar manual, tercatat di StockHistory
async function stockMove(req, res, next) {
  try {
    const id = Number(req.params.id);
    const { direction, quantity, note } = req.body; // direction: MASUK | KELUAR
    const qty = Number(quantity);

    if (!['MASUK', 'KELUAR'].includes(direction) || !qty || qty <= 0) {
      return res.status(400).json({ message: 'Arah stok dan jumlah (>0) wajib diisi dengan benar.' });
    }

    const result = await prisma.$transaction(async (tx) => {
      const sparepart = await tx.sparepart.findUnique({ where: { id } });
      if (!sparepart) throw Object.assign(new Error('Sparepart tidak ditemukan.'), { status: 404 });

      if (direction === 'KELUAR' && sparepart.stock < qty) {
        throw Object.assign(new Error('Stok tidak mencukupi untuk dikurangi.'), { status: 400 });
      }

      const newStock = direction === 'MASUK' ? sparepart.stock + qty : sparepart.stock - qty;

      const updated = await tx.sparepart.update({ where: { id }, data: { stock: newStock } });
      await tx.stockHistory.create({
        data: { sparepartId: id, direction, source: 'MANUAL', quantity: qty, note },
      });
      return updated;
    });

    res.json(withStatus(result));
  } catch (err) { next(err); }
}

async function history(req, res, next) {
  try {
    const { sparepartId, from, to } = req.query;
    const where = {
      AND: [
        sparepartId ? { sparepartId: Number(sparepartId) } : {},
        from ? { createdAt: { gte: new Date(from) } } : {},
        to ? { createdAt: { lte: new Date(to) } } : {},
      ],
    };
    const history = await prisma.stockHistory.findMany({
      where,
      include: { sparepart: true },
      orderBy: { createdAt: 'desc' },
      take: 500,
    });
    res.json(history);
  } catch (err) { next(err); }
}

module.exports = { list, detail, create, update, remove, stockMove, history };
