const prisma = require('../lib/prisma');

const clean = (v) => (v === undefined ? undefined : (String(v).trim() || null));

async function list(req, res, next) {
  try {
    const { q } = req.query;
    const suppliers = await prisma.supplier.findMany({
      where: q ? { OR: [
        { name: { contains: q, mode: 'insensitive' } },
        { contactPerson: { contains: q, mode: 'insensitive' } },
        { phone: { contains: q, mode: 'insensitive' } },
      ] } : {},
      orderBy: { name: 'asc' },
      include: { _count: { select: { spareparts: true } } },
    });
    res.json(suppliers);
  } catch (err) { next(err); }
}

async function detail(req, res, next) {
  try {
    const id = Number(req.params.id);
    const supplier = await prisma.supplier.findUnique({
      where: { id },
      include: { _count: { select: { spareparts: true } } },
    });
    if (!supplier) return res.status(404).json({ message: 'Supplier tidak ditemukan.' });
    res.json(supplier);
  } catch (err) { next(err); }
}

async function create(req, res, next) {
  try {
    const { name, contactPerson, phone, email, address, note } = req.body;
    if (!name || !String(name).trim()) return res.status(400).json({ message: 'Nama supplier wajib diisi.' });
    const supplier = await prisma.supplier.create({
      data: {
        name: String(name).trim(),
        contactPerson: clean(contactPerson),
        phone: clean(phone),
        email: clean(email),
        address: clean(address),
        note: clean(note),
      },
    });
    res.status(201).json(supplier);
  } catch (err) { next(err); }
}

async function update(req, res, next) {
  try {
    const id = Number(req.params.id);
    const { name, contactPerson, phone, email, address, note } = req.body;
    if (name !== undefined && !String(name).trim()) {
      return res.status(400).json({ message: 'Nama supplier wajib diisi.' });
    }
    const supplier = await prisma.supplier.update({
      where: { id },
      data: {
        name: name !== undefined ? String(name).trim() : undefined,
        contactPerson: clean(contactPerson),
        phone: clean(phone),
        email: clean(email),
        address: clean(address),
        note: clean(note),
      },
    });
    res.json(supplier);
  } catch (err) { next(err); }
}

// Sparepart & riwayat stok yang terkait otomatis dilepas (supplierId -> null), datanya tidak ikut terhapus.
async function remove(req, res, next) {
  try {
    const id = Number(req.params.id);
    await prisma.supplier.delete({ where: { id } });
    res.json({ message: 'Supplier berhasil dihapus.' });
  } catch (err) { next(err); }
}

module.exports = { list, detail, create, update, remove };
