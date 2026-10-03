const prisma = require('../lib/prisma');

async function list(req, res, next) {
  try {
    const models = await prisma.vehicleModel.findMany({ orderBy: [{ brand: 'asc' }, { model: 'asc' }] });
    res.json(models);
  } catch (err) { next(err); }
}

async function create(req, res, next) {
  try {
    const { brand, model, year, type, wheels } = req.body;
    if (!brand || !model || !year || !type) {
      return res.status(400).json({ message: 'Merk, model, tahun, dan tipe wajib diisi.' });
    }
    const vm = await prisma.vehicleModel.create({
      data: { brand, model, year: Number(year), type, wheels: wheels ? Number(wheels) : 4 },
    });
    res.status(201).json(vm);
  } catch (err) { next(err); }
}

async function update(req, res, next) {
  try {
    const id = Number(req.params.id);
    const { brand, model, year, type, wheels } = req.body;
    const vm = await prisma.vehicleModel.update({
      where: { id },
      data: { brand, model, year: year ? Number(year) : undefined, type, wheels: wheels ? Number(wheels) : undefined },
    });
    res.json(vm);
  } catch (err) { next(err); }
}

async function remove(req, res, next) {
  try {
    const id = Number(req.params.id);
    await prisma.vehicleModel.delete({ where: { id } });
    res.json({ message: 'Data master kendaraan berhasil dihapus.' });
  } catch (err) { next(err); }
}

module.exports = { list, create, update, remove };
