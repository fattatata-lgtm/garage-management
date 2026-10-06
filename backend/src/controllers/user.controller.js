const bcrypt = require('bcryptjs');
const prisma = require('../lib/prisma');

async function list(req, res, next) {
  try {
    const users = await prisma.user.findMany({
      select: { id: true, username: true, email: true, role: true, technicianId: true, createdAt: true },
      orderBy: { createdAt: 'desc' },
    });
    res.json(users);
  } catch (err) { next(err); }
}

async function create(req, res, next) {
  try {
    const { username, email, password, role } = req.body;
    if (!username || !email || !password) {
      return res.status(400).json({ message: 'Username, email, dan password wajib diisi.' });
    }
    if (password.length < 8) {
      return res.status(400).json({ message: 'Password minimal 8 karakter.' });
    }
    const hashed = await bcrypt.hash(password, 10);
    const user = await prisma.user.create({
      data: { username, email, password: hashed, role: role || 'STAFF' },
      select: { id: true, username: true, email: true, role: true },
    });
    res.status(201).json(user);
  } catch (err) { next(err); }
}

async function update(req, res, next) {
  try {
    const id = Number(req.params.id);
    const { username, email, role, password } = req.body;
    // technicianId dikosongkan: akun user tidak lagi ditautkan ke data teknisi
    const data = { username, email, role, technicianId: null };
    if (password) {
      if (password.length < 8) return res.status(400).json({ message: 'Password minimal 8 karakter.' });
      data.password = await bcrypt.hash(password, 10);
    }
    const user = await prisma.user.update({
      where: { id },
      data,
      select: { id: true, username: true, email: true, role: true },
    });
    res.json(user);
  } catch (err) { next(err); }
}

async function resetPassword(req, res, next) {
  try {
    const id = Number(req.params.id);
    const { password } = req.body;
    if (!password || password.length < 8) {
      return res.status(400).json({ message: 'Password baru minimal 8 karakter.' });
    }
    const hashed = await bcrypt.hash(password, 10);
    await prisma.user.update({ where: { id }, data: { password: hashed } });
    res.json({ message: 'Password berhasil direset.' });
  } catch (err) { next(err); }
}

async function remove(req, res, next) {
  try {
    const id = Number(req.params.id);
    await prisma.user.delete({ where: { id } });
    res.json({ message: 'User berhasil dihapus.' });
  } catch (err) { next(err); }
}

module.exports = { list, create, update, resetPassword, remove };
