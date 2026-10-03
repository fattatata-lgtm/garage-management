const prisma = require('../lib/prisma');

async function list(req, res, next) {
  try {
    const items = await prisma.serviceType.findMany({ orderBy: { name: 'asc' } });
    res.json(items);
  } catch (err) { next(err); }
}

async function create(req, res, next) {
  try {
    const { name, description, estimatedCost } = req.body;
    if (!name || estimatedCost == null) return res.status(400).json({ message: 'Nama dan estimasi biaya wajib diisi.' });
    const item = await prisma.serviceType.create({ data: { name, description, estimatedCost: Number(estimatedCost) } });
    res.status(201).json(item);
  } catch (err) { next(err); }
}

async function update(req, res, next) {
  try {
    const id = Number(req.params.id);
    const { name, description, estimatedCost } = req.body;
    const item = await prisma.serviceType.update({
      where: { id },
      data: { name, description, estimatedCost: estimatedCost != null ? Number(estimatedCost) : undefined },
    });
    res.json(item);
  } catch (err) { next(err); }
}

async function remove(req, res, next) {
  try {
    const id = Number(req.params.id);
    await prisma.serviceType.delete({ where: { id } });
    res.json({ message: 'Jenis service berhasil dihapus.' });
  } catch (err) { next(err); }
}

module.exports = { list, create, update, remove };
