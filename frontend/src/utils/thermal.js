// Pengiriman byte ESC/POS ke printer thermal asli.
//   USB     : WebUSB langsung dari browser (Chrome/Edge; butuh https atau localhost)
//   SERIAL  : Web Serial (printer USB-serial / Bluetooth yang muncul sebagai port COM)
//   BLUETOOTH : Web Bluetooth (BLE) langsung dari browser, mis. Rongta RPP02N di Android / Windows / Mac
//   NETWORK : server mengirim ke IP:9100 printer LAN/WiFi
//   SYSTEM  : server mengirim RAW ke printer yang terpasang di OS server (spooler)
//   BROWSER : (bawaan) dialog cetak browser lewat driver printer
import api from '../api/axios';
import { paperWidthMm } from './print';

const LS_USB = 'thermal.usb';
const LS_SERIAL = 'thermal.serial';
const LS_BAUD = 'thermal.baud';
const LS_BLE = 'thermal.ble';
const sleep = (ms) => new Promise((r) => { setTimeout(r, ms); });

export const CONNECTIONS = [
  { value: 'BROWSER', label: 'Dialog cetak browser (lewat driver printer)' },
  { value: 'SYSTEM', label: 'Printer terpasang di komputer server (RAW)' },
  { value: 'NETWORK', label: 'Printer jaringan LAN/WiFi (IP:9100)' },
  { value: 'USB', label: 'USB langsung dari browser (WebUSB)' },
  { value: 'SERIAL', label: 'Serial / USB virtual COM / Bluetooth COM (Web Serial)' },
  { value: 'BLUETOOTH', label: 'Bluetooth BLE langsung dari browser (Web Bluetooth)' },
];

export const isRawMode = (settings) => ['USB', 'SERIAL', 'BLUETOOTH', 'NETWORK', 'SYSTEM'].includes(settings?.printerConnection);
// Jumlah karakter per baris (Font A): 58 mm = 32, 80 mm = 48
export const paperCols = (settings) => (paperWidthMm(settings) === 58 ? 32 : 48);

const readJson = (k) => { try { return JSON.parse(localStorage.getItem(k) || 'null'); } catch { return null; } };
const writeJson = (k, v) => localStorage.setItem(k, JSON.stringify(v));

export const getBaud = () => Number(localStorage.getItem(LS_BAUD)) || 9600;
export const setBaud = (n) => localStorage.setItem(LS_BAUD, String(n));
export const pairedUsb = () => readJson(LS_USB);
export const pairedSerial = () => readJson(LS_SERIAL);
export const pairedBle = () => readJson(LS_BLE);

function bytesToBase64(bytes) {
  let bin = '';
  for (let i = 0; i < bytes.length; i += 0x8000) bin += String.fromCharCode.apply(null, bytes.subarray(i, i + 0x8000));
  return btoa(bin);
}

/* ---------------- WebUSB ---------------- */
async function findUsbDevice() {
  if (!navigator.usb) throw new Error('Browser ini tidak mendukung WebUSB. Gunakan Chrome/Edge lewat localhost atau https.');
  const saved = pairedUsb();
  const devices = await navigator.usb.getDevices();
  let dev = saved && devices.find((d) => d.vendorId === saved.vendorId && d.productId === saved.productId);
  if (!dev) dev = await navigator.usb.requestDevice({ filters: [] }); // perlu klik pengguna
  writeJson(LS_USB, { vendorId: dev.vendorId, productId: dev.productId, name: dev.productName || 'Printer USB' });
  return dev;
}

async function sendUsb(bytes) {
  const dev = await findUsbDevice();
  await dev.open();
  let claimed = null;
  try {
    if (dev.configuration === null) await dev.selectConfiguration(1);
    let pick = null;
    for (const iface of dev.configuration.interfaces) {
      for (const alt of iface.alternates) {
        const ep = alt.endpoints.find((e) => e.direction === 'out' && e.type === 'bulk');
        if (ep && (!pick || alt.interfaceClass === 7)) pick = { iface, alt, ep }; // utamakan kelas Printer (7)
      }
    }
    if (!pick) throw new Error('Endpoint tulis (bulk OUT) printer tidak ditemukan.');
    try {
      await dev.claimInterface(pick.iface.interfaceNumber);
    } catch (e) {
      throw new Error('Gagal mengambil alih printer USB. Di Windows, WebUSB hanya bisa jika printer memakai driver WinUSB; '
        + 'jika printer sudah terpasang dengan driver bawaan, pakai mode "Printer terpasang di komputer server (RAW)". '
        + `(${e.message})`);
    }
    claimed = pick.iface.interfaceNumber;
    if (pick.alt.alternateSetting) await dev.selectAlternateInterface(claimed, pick.alt.alternateSetting);
    for (let o = 0; o < bytes.length; o += 4096) {
      const r = await dev.transferOut(pick.ep.endpointNumber, bytes.slice(o, o + 4096));
      if (r.status !== 'ok') throw new Error(`Pengiriman ke printer USB gagal (${r.status}).`);
    }
  } finally {
    if (claimed !== null) await dev.releaseInterface(claimed).catch(() => {});
    await dev.close().catch(() => {});
  }
}

/* ---------------- Web Serial ---------------- */
async function findSerialPort() {
  if (!navigator.serial) throw new Error('Browser ini tidak mendukung Web Serial. Gunakan Chrome/Edge lewat localhost atau https.');
  const saved = pairedSerial();
  const ports = await navigator.serial.getPorts();
  let port = saved && ports.find((p) => {
    const i = p.getInfo();
    return i.usbVendorId === saved.usbVendorId && i.usbProductId === saved.usbProductId;
  });
  if (!port) port = ports[0] || await navigator.serial.requestPort(); // perlu klik pengguna
  const info = port.getInfo();
  writeJson(LS_SERIAL, { usbVendorId: info.usbVendorId, usbProductId: info.usbProductId });
  return port;
}

async function sendSerial(bytes) {
  const port = await findSerialPort();
  await port.open({ baudRate: getBaud() });
  try {
    const writer = port.writable.getWriter();
    try {
      // Potongan kecil + jeda singkat: buffer printer mobile kecil, data besar (logo) bisa hilang bila dikirim sekaligus
      for (let o = 0; o < bytes.length; o += 512) {
        await writer.write(bytes.slice(o, o + 512));
        await sleep(8);
      }
    } finally { writer.releaseLock(); }
    await sleep(400); // beri waktu byte terakhir (feed kertas) sampai ke printer sebelum port ditutup
  } finally {
    await port.close().catch(() => {});
  }
}

/* ---------------- Web Bluetooth (BLE) ---------------- */
// UUID layanan tulis yang umum dipakai printer thermal BLE (termasuk Rongta RPP02N & printer 58 mm sejenis).
const BLE_SERVICES = [
  '000018f0-0000-1000-8000-00805f9b34fb',
  'e7810a71-73ae-499d-8c15-faa9aef0c3f2',
  '49535343-fe7d-4ae5-8fa9-9fafd205e455',
  '0000ff00-0000-1000-8000-00805f9b34fb',
  '0000fff0-0000-1000-8000-00805f9b34fb',
  '0000ffe0-0000-1000-8000-00805f9b34fb',
  '0000ae30-0000-1000-8000-00805f9b34fb',
  '0000fee7-0000-1000-8000-00805f9b34fb',
  '00001101-0000-1000-8000-00805f9b34fb',
];
let bleDevice = null; // dipertahankan selama halaman terbuka agar cetak berikutnya tanpa dialog pemilihan

async function findBleDevice({ forcePick = false } = {}) {
  if (!navigator.bluetooth) throw new Error('Browser ini tidak mendukung Web Bluetooth. Gunakan Chrome/Edge (Android atau desktop) lewat localhost atau https.');
  if (forcePick) { bleDevice = null; localStorage.removeItem(LS_BLE); }
  if (bleDevice) return bleDevice;
  const saved = pairedBle();
  if (saved && navigator.bluetooth.getDevices) {
    try {
      const list = await navigator.bluetooth.getDevices();
      const d = list.find((x) => x.id === saved.id);
      if (d) { bleDevice = d; return d; }
    } catch { /* lanjut ke dialog pemilihan */ }
  }
  const dev = await navigator.bluetooth.requestDevice({ acceptAllDevices: true, optionalServices: BLE_SERVICES }); // perlu klik pengguna
  writeJson(LS_BLE, { id: dev.id, name: dev.name || 'Printer Bluetooth' });
  bleDevice = dev;
  return dev;
}

async function bleConnect(dev) {
  const server = await dev.gatt.connect();
  let services = [];
  try { services = await server.getPrimaryServices(); } catch { /* ditangani di bawah */ }
  for (const svc of services) {
    let chars = [];
    try { chars = await svc.getCharacteristics(); } catch { continue; }
    const ch = chars.find((c) => c.properties.writeWithoutResponse) || chars.find((c) => c.properties.write);
    if (ch) return ch;
  }
  throw new Error('Printer Bluetooth terhubung, tetapi karakteristik untuk menulis data tidak ditemukan. '
    + 'Pastikan memilih printer yang benar (nama RPP02N...), atau gunakan mode USB/Serial.');
}

async function sendBle(bytes) {
  let dev = await findBleDevice();
  let ch;
  try {
    ch = await bleConnect(dev);
  } catch (e) {
    // Perangkat tersimpan mungkin sudah tidak valid / printer mati -> coba pilih ulang sekali
    if (dev.gatt?.connected) dev.gatt.disconnect();
    if (/karakteristik/.test(e?.message || '')) throw e;
    dev = await findBleDevice({ forcePick: true });
    ch = await bleConnect(dev);
  }
  try {
    const noResp = ch.properties.writeWithoutResponse;
    let size = 100;
    for (let o = 0; o < bytes.length;) {
      const part = bytes.slice(o, o + size);
      try {
        if (noResp && ch.writeValueWithoutResponse) await ch.writeValueWithoutResponse(part);
        else if (ch.writeValueWithResponse) await ch.writeValueWithResponse(part);
        else await ch.writeValue(part);
      } catch (e) {
        if (size > 20) { size = 20; await sleep(60); continue; } // MTU kecil: ulangi dengan potongan 20 byte
        throw e;
      }
      o += part.length;
      await sleep(size >= 100 ? 15 : 25); // jeda agar buffer printer tidak meluap (gambar jadi acak / terpotong)
    }
    await sleep(500);
  } finally {
    if (dev.gatt?.connected) dev.gatt.disconnect(); // lepas koneksi supaya printer bisa dipakai perangkat lain
  }
}

/* ---------------- Via server ---------------- */
async function sendViaServer(bytes) {
  await api.post('/print/raw', { data: bytesToBase64(bytes) });
}

// Kirim byte ke printer sesuai mode di Pengaturan. Melempar Error berpesan Indonesia bila gagal.
export async function printRaw(bytes, settings) {
  switch (settings?.printerConnection) {
    case 'USB': return sendUsb(bytes);
    case 'SERIAL': return sendSerial(bytes);
    case 'BLUETOOTH': return sendBle(bytes);
    case 'NETWORK':
    case 'SYSTEM': return sendViaServer(bytes);
    default: throw new Error('Mode printer adalah dialog browser.');
  }
}

// Pilih/hubungkan printer USB atau Serial (hanya dari klik pengguna, mis. tombol di Pengaturan).
export async function pairPrinter(mode) {
  if (mode === 'USB') { const d = await findUsbDevice(); return d.productName || 'Printer USB'; }
  if (mode === 'SERIAL') { await findSerialPort(); return 'Port serial dipilih'; }
  if (mode === 'BLUETOOTH') { const d = await findBleDevice({ forcePick: true }); return d.name || 'Printer Bluetooth'; }
  return '';
}

// Dipanggil paling awal di dalam klik tombol Cetak: dialog pemilihan perangkat (USB/Serial/Bluetooth) hanya boleh
// muncul tak lama setelah klik pengguna, sedangkan menyusun struk (memuat logo) bisa memakan waktu.
export async function prepareConnection(settings) {
  switch (settings?.printerConnection) {
    case 'USB': await findUsbDevice(); break;
    case 'SERIAL': await findSerialPort(); break;
    case 'BLUETOOTH': await findBleDevice(); break;
    default: break;
  }
}

export const errorText = (e) => e?.response?.data?.message || e?.message || 'Gagal mencetak.';

// Pembungkus untuk halaman transaksi: bangun struk -> kirim ke printer; bila gagal tampilkan pesan lalu pakai dialog browser.
export async function printThermal({ settings, build, fallback, onError }) {
  try {
    await prepareConnection(settings);
    await printRaw(await build(), settings);
  } catch (e) {
    if (e?.name === 'NotFoundError') { onError?.('Pemilihan printer dibatalkan.'); return; }
    onError?.(`Printer thermal: ${errorText(e)}${fallback ? ' Dialihkan ke dialog cetak browser.' : ''}`);
    fallback?.();
  }
}
