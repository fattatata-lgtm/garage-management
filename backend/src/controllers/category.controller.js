const prisma = require('../lib/prisma');

async function list(req, res, next) {
  try {
    const categories = await prisma.category.findMany({
      orderBy: { name: 'asc' },
      include: { _count: { select: { spareparts: true } } },
    });
    res.json(categories);
  } catch (err) { next(err); }
}

async function create(req, res, next) {
  try {
    const { name } = req.body;
    if (!name) return res.status(400).json({ message: 'Nama kategori wajib diisi.' });
    const category = await prisma.category.create({ data: { name } });
    res.status(201).json(category);
  } catch (err) { next(err); }
}

async function update(req, res, next) {
  try {
    const id = Number(req.params.id);
    const { name } = req.body;
    const category = await prisma.category.update({ where: { id }, data: { name } });
    res.json(category);
  } catch (err) { next(err); }
}

async function remove(req, res, next) {
  try {
    const id = Number(req.params.id);
    await prisma.category.delete({ where: { id } });
    res.json({ message: 'Kategori berhasil dihapus.' });
  } catch (err) { next(err); }
}

module.exports = { list, create, update, remove };
