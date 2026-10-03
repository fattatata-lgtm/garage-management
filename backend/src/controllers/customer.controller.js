const prisma = require('../lib/prisma');

async function list(req, res, next) {
  try {
    const { q } = req.query;
    const where = q
      ? { OR: [
          { name: { contains: q, mode: 'insensitive' } },
          { phone: { contains: q, mode: 'insensitive' } },
          { email: { contains: q, mode: 'insensitive' } },
        ] }
      : {};
    const customers = await prisma.customer.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      include: { _count: { select: { vehicles: true } } },
    });
    res.json(customers);
  } catch (err) { next(err); }
}

async function detail(req, res, next) {
  try {
    const id = Number(req.params.id);
    const customer = await prisma.customer.findUnique({
      where: { id },
      include: {
        vehicles: { include: { vehicleModel: true } },
      },
    });
    if (!customer) return res.status(404).json({ message: 'Pelanggan tidak ditemukan.' });

    // Riwayat service dari semua kendaraan milik pelanggan
    const vehicleIds = customer.vehicles.map((v) => v.id);
    const serviceHistory = vehicleIds.length
      ? await prisma.serviceTransaction.findMany({
          where: { vehicleId: { in: vehicleIds } },
          include: { vehicle: true, technician: true },
          orderBy: { date: 'desc' },
        })
      : [];

    res.json({ ...customer, serviceHistory });
  } catch (err) { next(err); }
}

async function create(req, res, next) {
  try {
    const { name, phone, email, address } = req.body;
    if (!name || !phone) return res.status(400).json({ message: 'Nama dan No. HP wajib diisi.' });
    if (email && !/^\S+@\S+\.\S+$/.test(email)) {
      return res.status(400).json({ message: 'Format email tidak valid.' });
    }
    if (!/^[0-9+\-\s]{8,20}$/.test(phone)) {
      return res.status(400).json({ message: 'Format No. HP tidak valid.' });
    }
    const customer = await prisma.customer.create({ data: { name, phone, email, address } });
    res.status(201).json(customer);
  } catch (err) { next(err); }
}

async function update(req, res, next) {
  try {
    const id = Number(req.params.id);
    const { name, phone, email, address } = req.body;
    const customer = await prisma.customer.update({
      where: { id },
      data: { name, phone, email, address },
    });
    res.json(customer);
  } catch (err) { next(err); }
}

async function remove(req, res, next) {
  try {
    const id = Number(req.params.id);
    await prisma.customer.delete({ where: { id } });
    res.json({ message: 'Pelanggan berhasil dihapus.' });
  } catch (err) { next(err); }
}

module.exports = { list, detail, create, update, remove };
