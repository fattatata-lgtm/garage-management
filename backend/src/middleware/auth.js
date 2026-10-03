const jwt = require('jsonwebtoken');

// Verifies the JWT access token and attaches { id, role, username } to req.user
function authenticate(req, res, next) {
  const header = req.headers.authorization || '';
  const token = header.startsWith('Bearer ') ? header.slice(7) : null;

  if (!token) {
    return res.status(401).json({ message: 'Token tidak ditemukan. Silakan login.' });
  }

  try {
    const payload = jwt.verify(token, process.env.JWT_ACCESS_SECRET);
    req.user = payload; // { id, username, role }
    next();
  } catch (err) {
    return res.status(401).json({ message: 'Token tidak valid atau sudah kedaluwarsa.' });
  }
}

// RBAC middleware - pass allowed roles, e.g. authorize('ADMIN', 'STAFF')
function authorize(...allowedRoles) {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({ message: 'Belum terautentikasi.' });
    }
    if (!allowedRoles.includes(req.user.role)) {
      return res.status(403).json({ message: 'Anda tidak memiliki akses ke fitur ini.' });
    }
    next();
  };
}

module.exports = { authenticate, authorize };
