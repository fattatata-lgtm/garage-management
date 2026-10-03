const prisma = require('../lib/prisma');
const { sendNetwork, sendSystem } = require('../utils/rawPrint');

const MAX_BYTES = 512 * 1024;

// POST /api/print/raw  { data: <base64 byte ESC/POS> }
// Tujuan printer SELALU diambil dari Pengaturan (bukan dari request) agar endpoint ini tidak bisa dipakai
// untuk mengirim data ke host sembarang.
async function printRaw(req, res, next) {
  try {
    const { data } = req.body || {};
    if (typeof data !== 'string' || !data) return res.status(400).json({ message: 'Data cetak kosong.' });
    const bytes = Buffer.from(data, 'base64');
    if (!bytes.length) return res.status(400).json({ message: 'Data cetak tidak valid.' });
    if (bytes.length > MAX_BYTES) return res.status(413).json({ message: 'Data cetak terlalu besar.' });

    const s = await prisma.settings.findUnique({ where: { id: 1 } });
    const mode = s?.printerConnection || 'BROWSER';

    if (mode === 'NETWORK') await sendNetwork(s.printBridgeHost?.trim(), s.printBridgePort || 9100, bytes);
    else if (mode === 'SYSTEM') await sendSystem(s.printerName?.trim(), bytes);
    else return res.status(400).json({ message: 'Mode printer saat ini tidak memakai server. Cek Admin > Pengaturan Aplikasi.' });

    res.json({ ok: true, bytes: bytes.length });
  } catch (err) {
    // pesan dari rawPrint sudah berbahasa Indonesia & aman ditampilkan ke kasir
    err.status = err.status || 502;
    next(err);
  }
}

module.exports = { printRaw };
