const prisma = require('../lib/prisma');

async function list(req, res, next) {
  try {
    const { q } = req.query;
    const where = q
      ? { OR: [
          { plateNumber: { contains: q, mode: 'insensitive' } },
          { vin: { contains: q, mode: 'insensitive' } },
          { customer: { name: { contains: q, mode: 'insensitive' } } },
        ] }
      : {};
    const vehicles = await prisma.vehicle.findMany({
      where,
      include: { customer: true, vehicleModel: true },
      orderBy: { createdAt: 'desc' },
    });
    res.json(vehicles);
  } catch (err) { next(err); }
}

async function detail(req, res, next) {
  try {
    const id = Number(req.params.id);
    const vehicle = await prisma.vehicle.findUnique({
      where: { id },
      include: {
        customer: true,
        vehicleModel: true,
        services: {
          include: { technician: true, details: true },
          orderBy: { date: 'desc' },
        },
      },
    });
    if (!vehicle) return res.status(404).json({ message: 'Kendaraan tidak ditemukan.' });
    res.json(vehicle);
  } catch (err) { next(err); }
}

async function create(req, res, next) {
  try {
    const { customerId, vehicleModelId, plateNumber, vin, engineNumber, color, purchaseYear, note } = req.body;
    if (!customerId || !vehicleModelId || !plateNumber) {
      return res.status(400).json({ message: 'Pemilik, jenis kendaraan, dan no. plat wajib diisi.' });
    }
    const vehicle = await prisma.vehicle.create({
      data: {
        customerId: Number(customerId),
        vehicleModelId: Number(vehicleModelId),
        plateNumber,
        vin,
        engineNumber,
        color,
        purchaseYear: purchaseYear ? Number(purchaseYear) : null,
        note,
      },
    });
    res.status(201).json(vehicle);
  } catch (err) { next(err); }
}

async function update(req, res, next) {
  try {
    const id = Number(req.params.id);
    const { customerId, vehicleModelId, plateNumber, vin, engineNumber, color, purchaseYear, note } = req.body;
    const vehicle = await prisma.vehicle.update({
      where: { id },
      data: {
        customerId: customerId ? Number(customerId) : undefined,
        vehicleModelId: vehicleModelId ? Number(vehicleModelId) : undefined,
        plateNumber, vin, engineNumber, color,
        purchaseYear: purchaseYear ? Number(purchaseYear) : undefined,
        note,
      },
    });
    res.json(vehicle);
  } catch (err) { next(err); }
}

async function remove(req, res, next) {
  try {
    const id = Number(req.params.id);
    await prisma.vehicle.delete({ where: { id } });
    res.json({ message: 'Kendaraan berhasil dihapus.' });
  } catch (err) { next(err); }
}

module.exports = { list, detail, create, update, remove };
