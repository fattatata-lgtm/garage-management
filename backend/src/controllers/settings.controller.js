const fs = require('fs');
const path = require('path');
const multer = require('multer');
const prisma = require('../lib/prisma');

// Folder upload yang sama dengan yang disajikan statis di app.js (/uploads)
const UPLOAD_ROOT = path.join(process.cwd(), process.env.UPLOAD_DIR || 'uploads');
const PRINTER_CONNECTIONS = ['BROWSER', 'USB', 'SERIAL', 'BLUETOOTH', 'NETWORK', 'SYSTEM'];
const MAX_LOGO_BYTES = 2 * 1024 * 1024; // 2 MB
const LOGO_TYPES = { 'image/png': '.png', 'image/jpeg': '.jpg', 'image/webp': '.webp', 'image/gif': '.gif' };

const logoUpload = multer({
  storage: multer.diskStorage({
    destination: (req, file, cb) => { fs.mkdirSync(UPLOAD_ROOT, { recursive: true }); cb(null, UPLOAD_ROOT); },
    filename: (req, file, cb) => cb(null, `logo-${Date.now()}${LOGO_TYPES[file.mimetype]}`),
  }),
  limits: { fileSize: MAX_LOGO_BYTES, files: 1 },
  fileFilter: (req, file, cb) => {
    if (LOGO_TYPES[file.mimetype]) return cb(null, true);
    const err = new Error('Format logo harus PNG, JPG, WEBP, atau GIF.');
    err.status = 400;
    return cb(err);
  },
});

// Middleware: terima 1 file di field "logo"; ubah error multer menjadi pesan 400 yang ramah
function receiveLogo(req, res, next) {
  logoUpload.single('logo')(req, res, (err) => {
    if (!err) return next();
    if (err.code === 'LIMIT_FILE_SIZE') return res.status(400).json({ message: 'Ukuran logo maksimal 2 MB.' });
    return res.status(err.status || 400).json({ message: err.message || 'Gagal mengunggah logo.' });
  });
}

// Hapus file logo lama dari disk (hanya file hasil upload kita: /uploads/logo-*)
function removeLogoFile(logoUrl) {
  if (!logoUrl || !logoUrl.startsWith('/uploads/logo-')) return;
  const file = path.join(UPLOAD_ROOT, path.basename(logoUrl));
  fs.unlink(file, () => {});
}

async function getOrCreate() {
  let settings = await prisma.settings.findUnique({ where: { id: 1 } });
  if (!settings) settings = await prisma.settings.create({ data: { id: 1 } });
  return settings;
}

async function get(req, res, next) {
  try {
    res.json(await getOrCreate());
  } catch (err) { next(err); }
}

// Publik (tanpa login): hanya nama & logo, untuk halaman Login dan judul tab
async function getPublic(req, res, next) {
  try {
    const { businessName, logoUrl } = await getOrCreate();
    res.json({ businessName, logoUrl });
  } catch (err) { next(err); }
}

async function update(req, res, next) {
  try {
    const {
      businessName, address, phone, printerType, printerConnection, printerName,
      printBridgeHost, printBridgePort, taxService, taxSales,
    } = req.body;

    if (printerConnection != null && !PRINTER_CONNECTIONS.includes(printerConnection)) {
      return res.status(400).json({ message: 'Mode koneksi printer tidak dikenal.' });
    }

    const name = typeof businessName === 'string' ? businessName.trim() : undefined;
    if (name === '') return res.status(400).json({ message: 'Nama bengkel tidak boleh kosong.' });

    // logoUrl sengaja tidak diubah di sini; logo hanya berubah lewat POST/DELETE /settings/logo
    const settings = await prisma.settings.upsert({
      where: { id: 1 },
      update: {
        businessName: name, address, phone, printerType, printerConnection, printerName,
        printBridgeHost,
        // string kosong dari form -> null (bukan 0)
        printBridgePort: printBridgePort === '' || printBridgePort === null ? null : (printBridgePort != null ? Number(printBridgePort) : undefined),
        taxService: taxService != null ? Number(taxService) : undefined,
        taxSales: taxSales != null ? Number(taxSales) : undefined,
      },
      create: {
        id: 1,
        businessName: name || 'Self Automotive',
        address, phone, printerType, printBridgeHost,
        printerConnection: printerConnection || 'BROWSER', printerName,
        printBridgePort: printBridgePort ? Number(printBridgePort) : null,
        taxService: taxService != null ? Number(taxService) : 10,
        taxSales: taxSales != null ? Number(taxSales) : 10,
      },
    });
    res.json(settings);
  } catch (err) { next(err); }
}

async function uploadLogo(req, res, next) {
  try {
    if (!req.file) return res.status(400).json({ message: 'File logo tidak ditemukan.' });
    const current = await prisma.settings.findUnique({ where: { id: 1 } });
    const logoUrl = `/uploads/${req.file.filename}`;
    const settings = await prisma.settings.upsert({
      where: { id: 1 },
      update: { logoUrl },
      create: { id: 1, logoUrl },
    });
    removeLogoFile(current?.logoUrl);
    res.json(settings);
  } catch (err) {
    if (req.file) fs.unlink(req.file.path, () => {});
    next(err);
  }
}

async function deleteLogo(req, res, next) {
  try {
    const current = await prisma.settings.findUnique({ where: { id: 1 } });
    const settings = await prisma.settings.upsert({
      where: { id: 1 },
      update: { logoUrl: null },
      create: { id: 1 },
    });
    removeLogoFile(current?.logoUrl);
    res.json(settings);
  } catch (err) { next(err); }
}

module.exports = { get, getPublic, update, receiveLogo, uploadLogo, deleteLogo };
