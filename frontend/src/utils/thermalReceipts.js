// Isi struk thermal dalam bentuk byte ESC/POS (dicetak ke printer asli, mis. Rongta RPP02N 58 mm).
// Dipakai di halaman Detail Layanan dan Detail Penjualan.
import { EscPos, loadRaster } from './escpos';
import { assetUrl } from './assetUrl';
import { paperCols } from './thermal';
import { fmtDate, jasaTotalOf, partsTotalOf } from './format';

const rp = (n) => `Rp${Number(n || 0).toLocaleString('id-ID')}`;
const logoCache = new Map();
const narrow = (p) => p.cols <= 32; // kertas 58 mm: label dipersingkat agar tidak membungkus ke 2 baris

// Kop: logo (bila ada & berhasil dimuat) atau nama bengkel besar, lalu alamat & telepon.
async function header(p, settings) {
  let logoPrinted = false;
  if (settings?.logoUrl) {
    try {
      const maxW = p.cols <= 32 ? 384 : 512;
      const key = `${settings.logoUrl}|${maxW}`;
      if (!logoCache.has(key)) logoCache.set(key, await loadRaster(assetUrl(settings.logoUrl), maxW));
      p.align('center').image(logoCache.get(key)).align('left');
      logoPrinted = true;
    } catch { /* logo gagal dimuat: lanjut tanpa logo */ }
  }
  if (!logoPrinted && settings?.businessName) p.big(settings.businessName);
  if (settings?.address) p.center(settings.address);
  if (settings?.phone) p.center(`Telp: ${settings.phone}`);
  p.line();
}

// Judul struk (tinggi 2x) + nomor & tanggal, rata tengah
function title(p, text, sub) {
  p.align('center').bold(true).size(1, 2).line(text).reset().align('center');
  if (sub) p.wrap(sub);
  p.align('left').divider();
}

function section(p, text) { p.bold(true).line(text).bold(false); }

function totalBlock(p, { total, paid, change }, billing) {
  p.divider();
  p.bold(true).size(1, 2).pair(billing ? 'TOTAL TAGIHAN' : 'TOTAL', rp(total)).reset();
  if (!billing) {
    p.pair('Dibayar', rp(paid));
    p.pair('Kembalian', rp(change));
  }
}

// mode: 'thermal' (struk lunas) | 'tagihan' (belum dibayar)
export async function buildServiceReceipt(svc, settings, mode = 'thermal') {
  const billing = mode === 'tagihan';
  const p = new EscPos(paperCols(settings));
  const v = svc.vehicle;
  await header(p, settings);

  title(p, billing ? 'TAGIHAN SERVICE' : 'STRUK SERVICE', `No. ${svc.invoiceNo} - ${fmtDate(svc.date)}`);
  p.wrap(`Kendaraan: ${v.plateNumber} - ${v.vehicleModel.brand} ${v.vehicleModel.model}`);
  p.wrap(`Pemilik: ${v.customer.name}`);
  p.divider();

  section(p, 'Detail Service');
  if (svc.details.length) svc.details.forEach((d, i) => p.entry(i + 1, d.name, rp(d.cost)));
  else p.line('-');
  p.divider();

  section(p, 'Sparepart Digunakan');
  if (svc.spareparts.length) {
    svc.spareparts.forEach((x, i) => p.entry(i + 1, x.sparepart.name, rp(Number(x.price) * x.qty), `${x.qty} x ${rp(x.price)}`));
  } else p.line('-');
  p.divider();

  p.pair(narrow(p) ? 'Total Jasa' : 'Total Biaya Service', rp(jasaTotalOf(svc)));
  p.pair(narrow(p) ? 'Total Sparepart' : 'Total Biaya Sparepart', rp(partsTotalOf(svc)));
  p.pair('Subtotal', rp(svc.subtotal));
  if (Number(svc.discountAmount) > 0) p.pair('Diskon', `-${rp(svc.discountAmount)}`);
  if (Number(svc.taxAmount) > 0) p.pair('Pajak', rp(svc.taxAmount));
  totalBlock(p, svc, billing);
  p.divider();
  if (billing) p.center('Mohon lakukan pembayaran di kasir.');
  else { p.center('LUNAS'); p.center('Terima kasih atas kepercayaan Anda.'); }
  return p.cut().build();
}

export async function buildSalesReceipt(sale, settings) {
  const p = new EscPos(paperCols(settings));
  const buyer = sale.customer ? sale.customer.name : (sale.walkInName || 'Pelanggan Umum');
  await header(p, settings);

  title(p, 'STRUK PENJUALAN', `No. ${sale.invoiceNo} - ${new Date(sale.date).toLocaleString('id-ID')}`);
  p.wrap(`Pembeli: ${buyer}`);
  p.divider();

  section(p, 'Detail Penjualan');
  sale.items.forEach((i, idx) => p.entry(idx + 1, i.sparepart.name, rp(Number(i.price) * i.qty), `${i.qty} x ${rp(i.price)}`));
  p.divider();

  p.pair('Subtotal', rp(sale.subtotal));
  if (Number(sale.discountAmount) > 0) p.pair('Diskon', `-${rp(sale.discountAmount)}`);
  if (Number(sale.taxAmount) > 0) p.pair('Pajak', rp(sale.taxAmount));
  totalBlock(p, sale, false);
  p.divider();
  p.center('Terima kasih telah berbelanja.');
  return p.cut().build();
}

// Bukti service diterima (saat kendaraan masuk)
export async function buildReceivedReceipt(svc, settings) {
  const p = new EscPos(paperCols(settings));
  const v = svc.vehicle;
  await header(p, settings);
  title(p, 'BUKTI SERVICE DITERIMA', `No. ${svc.invoiceNo}`);
  p.wrap(`Kendaraan: ${v.vehicleModel.brand} ${v.vehicleModel.model} (${v.vehicleModel.year})`);
  p.bold(true).wrap(`No. Plat: ${v.plateNumber}`).bold(false);
  p.wrap(`Pemilik: ${v.customer.name}`);
  if (v.customer.phone) p.wrap(`Telp: ${v.customer.phone}`);
  p.wrap(`Teknisi: ${svc.technician?.name || '-'}`);
  p.wrap(`Tanggal: ${fmtDate(svc.date)}`);
  p.wrap(`Keluhan: ${svc.complaint || '-'}`);
  p.divider();
  p.center('Simpan bukti ini untuk pengambilan kendaraan.');
  return p.cut().build();
}

// Work order untuk teknisi
export async function buildWorkOrderReceipt(svc, settings) {
  const p = new EscPos(paperCols(settings));
  const v = svc.vehicle;
  title(p, 'WORK ORDER', `No. ${svc.invoiceNo}`);
  p.wrap(`Kendaraan: ${v.plateNumber} - ${v.vehicleModel.brand} ${v.vehicleModel.model}`);
  p.wrap(`Teknisi: ${svc.technician?.name || '-'}`);
  p.wrap(`KM: ${svc.km ?? '-'}`);
  p.wrap(`Keluhan: ${svc.complaint || '-'}`);
  p.divider();

  section(p, 'Jasa Dikerjakan');
  if (svc.details.length) {
    svc.details.forEach((d, i) => { p.entry(i + 1, d.name); if (d.description) p.note(d.description); });
  } else p.line('-');
  p.divider();

  section(p, 'Sparepart Dipakai');
  if (svc.spareparts.length) svc.spareparts.forEach((x, i) => p.entry(i + 1, x.sparepart.name, `x${x.qty}`));
  else p.line('-');
  if (svc.internalNote) { p.divider(); section(p, 'Catatan Internal'); p.wrap(svc.internalNote); }
  return p.cut().build();
}

// Struk uji: penggaris lebar kolom + contoh rata kiri/kanan/tengah + teks tebal & besar.
export async function buildTestReceipt(settings) {
  const p = new EscPos(paperCols(settings));
  await header(p, settings);
  p.align('center').bold(true).line('TES CETAK PRINTER').bold(false).align('left');
  p.divider('=');
  p.line('1234567890'.repeat(5).slice(0, p.cols));
  p.line('Lebar kertas: ' + p.cols + ' karakter');
  p.pair('Rata kiri', 'rata kanan');
  p.center('Rata tengah');
  p.bold(true).line('Teks tebal').bold(false);
  p.size(2, 2).line('Besar').reset();
  p.divider();
  p.entry(1, 'Contoh nama item yang cukup panjang', rp(150000), `2 x ${rp(75000)}`);
  p.bold(true).size(1, 2).pair('TOTAL', rp(150000)).reset();
  p.divider('=');
  p.center('Printer siap digunakan.');
  return p.cut().build();
}
