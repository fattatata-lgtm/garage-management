import React, { useEffect, useRef, useState } from 'react';
import api from '../../api/axios';
import Spinner from '../../components/ui/Spinner';
import Alert from '../../components/ui/Alert';
import PageHeader from '../../components/ui/PageHeader';
import { errMsg } from '../../hooks/useForm';

import { FaCog, FaImage, FaPlug, FaPrint, FaSave, FaSlidersH, FaTrash, FaUndo, FaUpload } from 'react-icons/fa';
import CardHeader from '../../components/ui/CardHeader';
import { useSettingsContext } from '../../context/SettingsContext';
import { assetUrl } from '../../utils/assetUrl';
import { CONNECTIONS, errorText, getBaud, pairPrinter, pairedBle, pairedSerial, pairedUsb, printRaw, setBaud } from '../../utils/thermal';
import { buildTestReceipt } from '../../utils/thermalReceipts';

const LOGO_TYPES = ['image/png', 'image/jpeg', 'image/webp', 'image/gif'];
const LOGO_MAX = 2 * 1024 * 1024; // 2 MB (sama dengan batas di server)

const CONNECTION_HINT = {
  BROWSER: 'Memakai dialog cetak browser dan driver printer di komputer ini. Tidak ada perintah potong kertas otomatis.',
  SYSTEM: 'Server mengirim perintah ESC/POS langsung ke printer yang sudah terpasang di komputer tempat backend berjalan. Cocok untuk printer USB di Windows (driver tetap terpasang).',
  NETWORK: 'Server mengirim ke printer LAN/WiFi lewat alamat IP dan port RAW (umumnya 9100).',
  USB: 'Browser langsung bicara ke printer lewat WebUSB (Chrome/Edge, localhost atau https). Di Windows butuh driver WinUSB untuk printer tersebut.',
  SERIAL: 'Browser memakai port COM lewat Web Serial (Chrome/Edge desktop): printer USB (virtual COM) atau Bluetooth yang sudah dipasangkan di Windows (Outgoing COM port). Tidak tersedia di Android.',
  BLUETOOTH: 'Browser langsung terhubung ke printer lewat Bluetooth BLE (Chrome/Edge di Android, Windows, Mac, atau ChromeOS; localhost atau https). Printer tidak perlu dipasangkan dulu di pengaturan Bluetooth OS. Pilihan yang disarankan untuk Rongta RPP02N.',
};
const PRINTER_KEYS = ['printerConnection', 'printerName', 'printBridgeHost', 'printBridgePort'];

// Admin > Pengaturan Aplikasi (/admin/settings)
export default function SettingsPage() {
  const [form, setForm] = useState(null);
  const [saved, setSaved] = useState(null); // nilai terakhir dari server, untuk tombol Reset
  const [msg, setMsg] = useState({ type: '', text: '' });
  const [saving, setSaving] = useState(false);
  const [logoBusy, setLogoBusy] = useState(false);
  const fileRef = useRef(null);
  const [printerBusy, setPrinterBusy] = useState(false);
  const [pairedLabel, setPairedLabel] = useState('');
  const { setSettings: setGlobal } = useSettingsContext(); // agar topbar/login/invoice ikut berubah seketika

  useEffect(() => { api.get('/settings').then(({ data }) => { setForm(data); setSaved(data); }); }, []);
  if (!form) return <Spinner />;

  const set = (k) => (e) => setForm({ ...form, [k]: e.target.value });

  async function submit(e) {
    e.preventDefault(); setSaving(true); setMsg({ type: '', text: '' });
    try {
      const { data } = await api.put('/settings', form);
      setSaved({ ...form, logoUrl: data.logoUrl });
      setGlobal(data);
      setMsg({ type: 'success', text: 'Pengaturan berhasil disimpan.' });
    } catch (err) {
      setMsg({ type: 'error', text: errMsg(err, 'Gagal menyimpan pengaturan.') });
    } finally { setSaving(false); }
  }

  // Logo langsung tersimpan saat diunggah/dihapus (tidak perlu menekan Simpan Pengaturan)
  function applyLogo(data) {
    setForm((f) => ({ ...f, logoUrl: data.logoUrl }));
    setSaved((sv) => ({ ...sv, logoUrl: data.logoUrl }));
    setGlobal(data);
  }

  async function onPickLogo(e) {
    const file = e.target.files?.[0];
    e.target.value = ''; // supaya file yang sama bisa dipilih ulang
    if (!file) return;
    if (!LOGO_TYPES.includes(file.type)) return setMsg({ type: 'error', text: 'Format logo harus PNG, JPG, WEBP, atau GIF.' });
    if (file.size > LOGO_MAX) return setMsg({ type: 'error', text: 'Ukuran logo maksimal 2 MB.' });
    setLogoBusy(true); setMsg({ type: '', text: '' });
    try {
      const fd = new FormData();
      fd.append('logo', file);
      const { data } = await api.post('/settings/logo', fd);
      applyLogo(data);
      setMsg({ type: 'success', text: 'Logo berhasil diunggah.' });
    } catch (err) {
      setMsg({ type: 'error', text: errMsg(err, 'Gagal mengunggah logo.') });
    } finally { setLogoBusy(false); }
  }

  async function onRemoveLogo() {
    if (!window.confirm('Hapus logo bengkel?')) return;
    setLogoBusy(true); setMsg({ type: '', text: '' });
    try {
      const { data } = await api.delete('/settings/logo');
      applyLogo(data);
      setMsg({ type: 'success', text: 'Logo dihapus.' });
    } catch (err) {
      setMsg({ type: 'error', text: errMsg(err, 'Gagal menghapus logo.') });
    } finally { setLogoBusy(false); }
  }

  const logo = assetUrl(form.logoUrl);

  const mode = form.printerConnection || 'BROWSER';
  // Mode NETWORK/SYSTEM dikirim lewat server memakai pengaturan TERSIMPAN, jadi harus disimpan dulu sebelum tes
  const printerDirty = PRINTER_KEYS.some((k) => String(form[k] ?? '') !== String(saved[k] ?? ''));
  const pairedName = pairedLabel || (mode === 'USB' ? pairedUsb()?.name : mode === 'BLUETOOTH' ? pairedBle()?.name : mode === 'SERIAL' && pairedSerial() ? 'Port serial tersimpan' : '');

  // Preset Rongta RPP02N: kertas 58 mm (32 karakter/baris) + Bluetooth BLE
  function applyRpp02n() {
    setForm((f) => ({ ...f, printerType: 'Thermal 58mm', printerConnection: 'BLUETOOTH' }));
    setMsg({ type: 'success', text: 'Preset RPP02N diterapkan (58 mm, Bluetooth). Tekan Pilih / Hubungkan Printer, Tes Cetak, lalu Simpan Pengaturan.' });
  }

  async function onPair() {
    setPrinterBusy(true); setMsg({ type: '', text: '' });
    try {
      setPairedLabel(await pairPrinter(mode));
      setMsg({ type: 'success', text: 'Printer dipilih. Tekan Tes Cetak untuk memastikan.' });
    } catch (err) {
      if (err?.name !== 'NotFoundError') setMsg({ type: 'error', text: errorText(err) });
    } finally { setPrinterBusy(false); }
  }

  async function onTestPrint() {
    setPrinterBusy(true); setMsg({ type: '', text: '' });
    try {
      await printRaw(await buildTestReceipt(form), form);
      setMsg({ type: 'success', text: 'Perintah tes cetak terkirim ke printer.' });
    } catch (err) {
      if (err?.name !== 'NotFoundError') setMsg({ type: 'error', text: errorText(err) });
    } finally { setPrinterBusy(false); }
  }

  return (
    <div className="space-y-4">
      <PageHeader icon={FaCog} title="Pengaturan Aplikasi" subtitle="Kelola pengaturan sistem" />
      <form onSubmit={submit} className="card overflow-hidden">
        <CardHeader icon={FaSlidersH}>Konfigurasi Sistem</CardHeader>
        <div className="p-5 space-y-4">
          <Alert type={msg.type || 'error'} message={msg.text} />
          <div className="grid sm:grid-cols-2 gap-4">
            <div className="sm:col-span-2">
              <label className="label">Logo Bengkel</label>
              <div className="flex flex-wrap items-center gap-4 rounded-xl border border-slate-200 bg-slate-50/60 p-4">
                <div className="flex h-24 w-44 items-center justify-center overflow-hidden rounded-lg border border-dashed border-slate-300 bg-white p-2">
                  {logo
                    ? <img src={logo} alt="Logo bengkel" className="max-h-full max-w-full object-contain" />
                    : <span className="flex flex-col items-center gap-1 text-xs text-slate-400"><FaImage className="text-2xl" aria-hidden /> Belum ada logo</span>}
                </div>
                <div className="min-w-0 flex-1 space-y-2">
                  <div className="flex flex-wrap gap-2">
                    <button type="button" className="btn-secondary" disabled={logoBusy} onClick={() => fileRef.current?.click()}>
                      <FaUpload aria-hidden /> {logoBusy ? 'Memproses...' : logo ? 'Ganti Logo' : 'Unggah Logo'}
                    </button>
                    {logo && (
                      <button type="button" className="btn-muted" disabled={logoBusy} onClick={onRemoveLogo}>
                        <FaTrash aria-hidden /> Hapus
                      </button>
                    )}
                  </div>
                  <p className="text-xs text-slate-500">PNG, JPG, WEBP, atau GIF, maksimal 2 MB. Logo langsung tersimpan dan tampil di topbar, halaman login, dan invoice.</p>
                </div>
                <input ref={fileRef} type="file" accept="image/png,image/jpeg,image/webp,image/gif" className="hidden" onChange={onPickLogo} />
              </div>
            </div>
            <div className="sm:col-span-2"><label className="label">Nama Bengkel</label><input className="input" value={form.businessName || ''} onChange={set('businessName')} /></div>
            <div className="sm:col-span-2"><label className="label">Alamat</label><textarea className="input" rows={2} value={form.address || ''} onChange={set('address')} /></div>
            <div><label className="label">No. Telepon</label><input className="input" value={form.phone || ''} onChange={set('phone')} /></div>
            <div><label className="label">Tax Service (%)</label><input type="number" step="0.01" className="input" value={form.taxService} onChange={set('taxService')} /></div>
            <div><label className="label">Tax Sales (%)</label><input type="number" step="0.01" className="input" value={form.taxSales} onChange={set('taxSales')} /></div>
            <div>
              <label className="label">Ukuran Kertas Struk Thermal</label>
              <select className="input" value={/58/.test(form.printerType || '') ? 'Thermal 58mm' : 'Thermal 80mm'} onChange={set('printerType')}>
                <option value="Thermal 80mm">Thermal 80 mm</option>
                <option value="Thermal 58mm">Thermal 58 mm</option>
              </select>
              <p className="mt-1 text-xs text-slate-500">Dipakai saat mencetak Struk Thermal. Pilih sesuai lebar roll kertas printer.</p>
            </div>
            <div className="sm:col-span-2 space-y-4 rounded-xl border border-slate-200 bg-slate-50/60 p-4">
              <div>
                <label className="label">Cara Cetak Struk Thermal</label>
                <select className="input" value={mode} onChange={set('printerConnection')}>
                  {CONNECTIONS.map((c) => <option key={c.value} value={c.value}>{c.label}</option>)}
                </select>
                <p className="mt-1 text-xs text-slate-500">{CONNECTION_HINT[mode]}</p>
              </div>

              <div className="flex flex-wrap items-center gap-3 rounded-lg border border-dashed border-slate-300 bg-white px-3 py-2 text-xs text-slate-500">
                <button type="button" className="btn-secondary" onClick={applyRpp02n}><FaPrint aria-hidden /> Preset Rongta RPP02N</button>
                <span>Mengatur kertas 58 mm + Bluetooth. Kertas 58 mm = 32 karakter/baris; printer ini tidak punya pemotong, sobek struk manual.</span>
              </div>

              {mode === 'NETWORK' && (
                <div className="grid gap-4 sm:grid-cols-2">
                  <div><label className="label">IP Printer</label><input className="input" placeholder="mis. 192.168.1.50" value={form.printBridgeHost || ''} onChange={set('printBridgeHost')} /></div>
                  <div><label className="label">Port</label><input type="number" className="input" placeholder="9100" value={form.printBridgePort || ''} onChange={set('printBridgePort')} /></div>
                </div>
              )}

              {mode === 'SYSTEM' && (
                <div>
                  <label className="label">Nama Printer di Komputer Server</label>
                  <input className="input" placeholder="mis. POS-58" value={form.printerName || ''} onChange={set('printerName')} />
                  <p className="mt-1 text-xs text-slate-500">Persis seperti nama di Windows &gt; Printers &amp; scanners (Linux/Mac: nama antrean CUPS).</p>
                </div>
              )}

              {(mode === 'USB' || mode === 'SERIAL' || mode === 'BLUETOOTH') && (
                <div className="flex flex-wrap items-end gap-3">
                  <button type="button" className="btn-secondary" disabled={printerBusy} onClick={onPair}><FaPlug aria-hidden /> Pilih / Hubungkan Printer</button>
                  {mode === 'SERIAL' && (
                    <div>
                      <label className="label">Baud rate</label>
                      <select className="input" defaultValue={getBaud()} onChange={(e) => setBaud(e.target.value)}>
                        {[9600, 19200, 38400, 57600, 115200].map((b) => <option key={b} value={b}>{b}</option>)}
                      </select>
                    </div>
                  )}
                  <span className="text-xs text-slate-500">{pairedName ? `Terpilih: ${pairedName}` : 'Belum ada printer dipilih.'} Pilihan tersimpan di browser perangkat ini.{mode === 'BLUETOOTH' && ' Nyalakan printer lebih dulu (lampu Bluetooth berkedip); PIN pairing bawaan 1234 bila diminta.'}</span>
                </div>
              )}

              {mode !== 'BROWSER' && (
                <div className="flex flex-wrap items-center gap-3">
                  <button type="button" className="btn-primary" disabled={printerBusy || (printerDirty && (mode === 'NETWORK' || mode === 'SYSTEM'))} onClick={onTestPrint}>
                    <FaPrint aria-hidden /> {printerBusy ? 'Mengirim...' : 'Tes Cetak'}
                  </button>
                  {printerDirty && (mode === 'NETWORK' || mode === 'SYSTEM') && <span className="text-xs text-amber-600">Simpan pengaturan dulu agar server memakai alamat/nama printer yang baru.</span>}
                </div>
              )}
            </div>
          </div>
        </div>
        <div className="flex justify-end gap-2 border-t border-slate-100 bg-slate-50/80 px-5 py-4">
          <button type="button" className="btn-secondary" onClick={() => setForm(saved)}><FaUndo aria-hidden /> Reset</button>
          <button type="submit" disabled={saving} className="btn-primary"><FaSave aria-hidden />{saving ? 'Menyimpan...' : 'Simpan Pengaturan'}</button>
        </div>
      </form>
    </div>
  );
}
