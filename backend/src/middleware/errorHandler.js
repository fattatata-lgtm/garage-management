function notFound(req, res, next) {
  res.status(404).json({ message: `Route ${req.originalUrl} tidak ditemukan.` });
}

function errorHandler(err, req, res, next) {
  console.error(err);

  if (err.code === 'P2002') {
    const field = (err.meta && err.meta.target) || 'field';
    return res.status(409).json({ message: `Data dengan ${field} tersebut sudah ada (duplikat).` });
  }
  if (err.code === 'P2025') {
    return res.status(404).json({ message: 'Data tidak ditemukan.' });
  }
  if (err.code === 'P2003') {
    return res.status(409).json({ message: 'Data masih terkait dengan data lain, tidak dapat dihapus/diubah.' });
  }

  const status = err.status || 500;
  res.status(status).json({ message: err.message || 'Terjadi kesalahan pada server.' });
}

module.exports = { notFound, errorHandler };
