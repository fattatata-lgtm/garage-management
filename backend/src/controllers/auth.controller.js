const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const prisma = require('../lib/prisma');

function signTokens(user) {
  const payload = { id: user.id, username: user.username, role: user.role, technicianId: user.technicianId || null };
  const accessToken = jwt.sign(payload, process.env.JWT_ACCESS_SECRET, {
    expiresIn: process.env.JWT_ACCESS_EXPIRES || '15m',
  });
  const refreshToken = jwt.sign(payload, process.env.JWT_REFRESH_SECRET, {
    expiresIn: process.env.JWT_REFRESH_EXPIRES || '7d',
  });
  return { accessToken, refreshToken };
}

async function login(req, res, next) {
  try {
    const { identifier, password } = req.body; // identifier = username or email
    if (!identifier || !password) {
      return res.status(400).json({ message: 'Username/email dan password wajib diisi.' });
    }

    const user = await prisma.user.findFirst({
      where: { OR: [{ username: identifier }, { email: identifier }] },
    });

    if (!user) {
      return res.status(401).json({ message: 'Akun tidak ditemukan.' });
    }

    const valid = await bcrypt.compare(password, user.password);
    if (!valid) {
      return res.status(401).json({ message: 'Password salah.' });
    }

    const { accessToken, refreshToken } = signTokens(user);

    res.json({
      accessToken,
      refreshToken,
      user: { id: user.id, username: user.username, email: user.email, role: user.role, technicianId: user.technicianId },
    });
  } catch (err) {
    next(err);
  }
}

async function refresh(req, res, next) {
  try {
    const { refreshToken } = req.body;
    if (!refreshToken) return res.status(400).json({ message: 'refreshToken wajib diisi.' });

    let payload;
    try {
      payload = jwt.verify(refreshToken, process.env.JWT_REFRESH_SECRET);
    } catch (e) {
      return res.status(401).json({ message: 'Refresh token tidak valid/kedaluwarsa.' });
    }

    const user = await prisma.user.findUnique({ where: { id: payload.id } });
    if (!user) return res.status(401).json({ message: 'Akun tidak valid.' });

    const tokens = signTokens(user);
    res.json(tokens);
  } catch (err) {
    next(err);
  }
}

async function me(req, res, next) {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.user.id },
      select: { id: true, username: true, email: true, role: true, createdAt: true },
    });
    res.json(user);
  } catch (err) {
    next(err);
  }
}

module.exports = { login, refresh, me };
