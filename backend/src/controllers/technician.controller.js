const prisma = require('../lib/prisma');

async function list(req, res, next) {
  try {
    const { activeOnly } = req.query;
    const where = activeOnly === 'true' ? { status: 'AKTIF' } : {};
    const technicians = await prisma.technician.findMany({
      where,
      orderBy: { name: 'asc' },
      include: { _count: { select: { services: true, schedules: true } } },
    });
    res.json(technicians);
  } catch (err) { next(err); }
}

async function detail(req, res, next) {
  try {
    const id = Number(req.params.id);
    const technician = await prisma.technician.findUnique({
      where: { id },
      include: {
        schedules: { orderBy: { date: 'desc' } },
        services: {
          include: { vehicle: { include: { customer: true, vehicleModel: true } }, details: true },
          orderBy: { date: 'desc' },
        },
      },
    });
    if (!technician) return res.status(404).json({ message: 'Teknisi tidak ditemukan.' });

    const stats = {
      totalService: technician.services.length,
      totalJadwal: technician.schedules.length,
    };
    res.json({ ...technician, stats });
  } catch (err) { next(err); }
}

async function create(req, res, next) {
  try {
    const { name, skill, status } = req.body;
    if (!name) return res.status(400).json({ message: 'Nama teknisi wajib diisi.' });
    const technician = await prisma.technician.create({ data: { name, skill, status: status || 'AKTIF' } });
    res.status(201).json(technician);
  } catch (err) { next(err); }
}

async function update(req, res, next) {
  try {
    const id = Number(req.params.id);
    const { name, skill, status } = req.body;
    const technician = await prisma.technician.update({ where: { id }, data: { name, skill, status } });
    res.json(technician);
  } catch (err) { next(err); }
}

async function remove(req, res, next) {
  try {
    const id = Number(req.params.id);
    await prisma.technician.delete({ where: { id } });
    res.json({ message: 'Teknisi berhasil dihapus.' });
  } catch (err) { next(err); }
}

async function addSchedule(req, res, next) {
  try {
    const technicianId = Number(req.params.id);
    const { date, note } = req.body;
    if (!date) return res.status(400).json({ message: 'Tanggal jadwal wajib diisi.' });
    const schedule = await prisma.technicianSchedule.create({
      data: { technicianId, date: new Date(date), note },
    });
    res.status(201).json(schedule);
  } catch (err) { next(err); }
}

async function updateSchedule(req, res, next) {
  try {
    const technicianId = Number(req.params.id);
    const id = Number(req.params.scheduleId);
    const { date, note } = req.body;
    if (!date) return res.status(400).json({ message: 'Tanggal jadwal wajib diisi.' });
    const existing = await prisma.technicianSchedule.findFirst({ where: { id, technicianId } });
    if (!existing) return res.status(404).json({ message: 'Jadwal tidak ditemukan.' });
    const schedule = await prisma.technicianSchedule.update({
      where: { id },
      data: { date: new Date(date), note },
    });
    res.json(schedule);
  } catch (err) { next(err); }
}

async function removeSchedule(req, res, next) {
  try {
    const id = Number(req.params.scheduleId);
    await prisma.technicianSchedule.delete({ where: { id } });
    res.json({ message: 'Jadwal berhasil dihapus.' });
  } catch (err) { next(err); }
}

module.exports = { list, detail, create, update, remove, addSchedule, updateSchedule, removeSchedule };
