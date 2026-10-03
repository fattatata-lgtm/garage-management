const prisma = require('../lib/prisma');

async function list(req, res, next) {
  try {
    const { activeOnly } = req.query;
    const where = activeOnly === 'true' ? { status: 'AKTIF' } : {};
    const discounts = await prisma.discount.findMany({ where, orderBy: { createdAt: 'desc' } });
    res.json(discounts);
  } catch (err) { next(err); }
}

async function findByCode(req, res, next) {
  try {
    const { code } = req.params;
    const discount = await prisma.discount.findUnique({ where: { code } });
    if (!discount || discount.status !== 'AKTIF') {
      return res.status(404).json({ message: 'Kode kupon tidak ditemukan atau nonaktif.' });
    }
    res.json(discount);
  } catch (err) { next(err); }
}

async function create(req, res, next) {
  try {
    const { name, code, type, value, status, scope } = req.body;
    if (!name || !type || value == null) {
      return res.status(400).json({ message: 'Nama, tipe, dan nilai diskon wajib diisi.' });
    }
    const discount = await prisma.discount.create({
      data: { name, code: code || null, type, value: Number(value), status: status || 'AKTIF', scope: scope || 'SEMUA' },
    });
    res.status(201).json(discount);
  } catch (err) { next(err); }
}

async function update(req, res, next) {
  try {
    const id = Number(req.params.id);
    const { name, code, type, value, status, scope } = req.body;
    const discount = await prisma.discount.update({
      where: { id },
      data: { name, code: code || null, type, value: value != null ? Number(value) : undefined, status, scope },
    });
    res.json(discount);
  } catch (err) { next(err); }
}

async function remove(req, res, next) {
  try {
    const id = Number(req.params.id);
    await prisma.discount.delete({ where: { id } });
    res.json({ message: 'Diskon berhasil dihapus.' });
  } catch (err) { next(err); }
}

module.exports = { list, findByCode, create, update, remove };
