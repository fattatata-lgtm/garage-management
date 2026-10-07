import React, { useEffect, useState } from 'react';
import api from '../../api/axios';
import Spinner from '../../components/ui/Spinner';
import Modal from '../../components/ui/Modal';
import Alert from '../../components/ui/Alert';
import StatusBadge from '../../components/ui/StatusBadge';
import usePagination from '../../hooks/usePagination';
import Pagination from '../../components/ui/Pagination';
import { FaAlignLeft, FaBarcode, FaBullseye, FaCog, FaHashtag, FaInfoCircle, FaMoneyBillWave, FaPercent, FaTag, FaTools, FaUser } from 'react-icons/fa';

function formatRp(n) { return `Rp${Number(n || 0).toLocaleString('id-ID')}`; }

/* ---------- Pengaturan Aplikasi ---------- */
function SettingsTab() {
  const [form, setForm] = useState(null);
  const [msg, setMsg] = useState({ type: '', text: '' });
  const [saving, setSaving] = useState(false);

  useEffect(() => { api.get('/settings').then(({ data }) => setForm(data)); }, []);
  if (!form) return <Spinner />;

  const set = (k) => (e) => setForm({ ...form, [k]: e.target.value });

  async function submit(e) {
    e.preventDefault(); setSaving(true); setMsg({ type: '', text: '' });
    try {
      await api.put('/settings', form);
      setMsg({ type: 'success', text: 'Pengaturan berhasil disimpan.' });
    } catch (err) {
      setMsg({ type: 'error', text: err?.response?.data?.message || 'Gagal menyimpan pengaturan.' });
    } finally { setSaving(false); }
  }

  return (
    <form onSubmit={submit} className="card p-5 space-y-4 max-w-2xl">
      <Alert type={msg.type || 'error'} message={msg.text} />
      <div className="grid sm:grid-cols-2 gap-4">
        <div className="sm:col-span-2"><label className="label">Nama Bengkel</label><input className="input" value={form.businessName || ''} onChange={set('businessName')} /></div>
        <div className="sm:col-span-2"><label className="label">Alamat</label><textarea className="input" rows={2} value={form.address || ''} onChange={set('address')} /></div>
        <div><label className="label">No. Telepon</label><input className="input" value={form.phone || ''} onChange={set('phone')} /></div>
        <div><label className="label">URL Logo</label><input className="input" value={form.logoUrl || ''} onChange={set('logoUrl')} /></div>
        <div><label className="label">Tax Service (%)</label><input type="number" step="0.01" className="input" value={form.taxService} onChange={set('taxService')} /></div>
        <div><label className="label">Tax Sales (%)</label><input type="number" step="0.01" className="input" value={form.taxSales} onChange={set('taxSales')} /></div>
        <div><label className="label">Tipe Printer</label><input className="input" placeholder="mis. Thermal 58mm" value={form.printerType || ''} onChange={set('printerType')} /></div>
        <div><label className="label">Print Bridge Host</label><input className="input" placeholder="localhost" value={form.printBridgeHost || ''} onChange={set('printBridgeHost')} /></div>
        <div><label className="label">Print Bridge Port</label><input type="number" className="input" value={form.printBridgePort || ''} onChange={set('printBridgePort')} /></div>
      </div>
      <div className="flex justify-end"><button type="submit" disabled={saving} className="btn-primary">{saving ? 'Menyimpan...' : 'Simpan Pengaturan'}</button></div>
    </form>
  );
}

/* ---------- Diskon ---------- */
const emptyDiscount = { name: '', code: '', type: 'PERCENTAGE', value: '', status: 'AKTIF', scope: 'SEMUA' };

function DiscountsTab() {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [modal, setModal] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState(emptyDiscount);
  const [error, setError] = useState('');

  function load() { setLoading(true); api.get('/discounts').then(({ data }) => setItems(data)).finally(() => setLoading(false)); }
  const pg = usePagination(items, 10, '');
  useEffect(() => { load(); }, []);

  function openAdd() { setEditing(null); setForm(emptyDiscount); setError(''); setModal(true); }
  function openEdit(d) { setEditing(d); setForm({ name: d.name, code: d.code || '', type: d.type, value: d.value, status: d.status, scope: d.scope }); setError(''); setModal(true); }

  async function submit(e) {
    e.preventDefault(); setError('');
    try {
      if (editing) await api.put(`/discounts/${editing.id}`, form);
      else await api.post('/discounts', form);
      setModal(false); load();
    } catch (err) { setError(err?.response?.data?.message || 'Gagal menyimpan diskon.'); }
  }
  async function remove(d) {
    if (!confirm(`Hapus diskon ${d.name}?`)) return;
    try { await api.delete(`/discounts/${d.id}`); load(); }
    catch (err) { alert(err?.response?.data?.message || 'Gagal menghapus (diskon mungkin sudah dipakai transaksi).'); }
  }

  return (
    <div className="space-y-4">
      <div className="flex justify-end"><button className="btn-primary" onClick={openAdd}>+ Tambah Diskon</button></div>
      <div className="card overflow-x-auto">
        {loading ? <Spinner /> : (
          <table className="table-base">
            <thead><tr><th className="w-20"><FaHashtag className="mr-1 inline text-[10px]" aria-hidden /> No</th><th><FaTag className="mr-1 inline text-[10px]" aria-hidden /> Nama</th><th><FaBarcode className="mr-1 inline text-[10px]" aria-hidden /> Kode</th><th><FaTag className="mr-1 inline text-[10px]" aria-hidden /> Tipe</th><th><FaPercent className="mr-1 inline text-[10px]" aria-hidden /> Nilai</th><th><FaBullseye className="mr-1 inline text-[10px]" aria-hidden /> Berlaku Untuk</th><th><FaInfoCircle className="mr-1 inline text-[10px]" aria-hidden /> Status</th><th><FaCog className="mr-1 inline text-[10px]" aria-hidden /> Aksi</th></tr></thead>
            <tbody>
              {items.length === 0 && <tr><td colSpan={8} className="text-center text-slate-400 py-6">Belum ada diskon.</td></tr>}
              {pg.pageItems.map((d, rowNo) => (
                <tr key={d.id}><td>{pg.start + rowNo + 1}</td>
                  <td>{d.name}</td><td>{d.code || '-'}</td><td>{d.type === 'PERCENTAGE' ? 'Persentase' : 'Nominal'}</td>
                  <td>{d.type === 'PERCENTAGE' ? `${Number(d.value)}%` : formatRp(d.value)}</td>
                  <td>{d.scope}</td><td><StatusBadge status={d.status} /></td>
                  <td className="text-right space-x-2 whitespace-nowrap">
                    <button className="btn-ghost" onClick={() => openEdit(d)}>Edit</button>
                    <button className="btn-ghost text-red-600" onClick={() => remove(d)}>Hapus</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
        <Pagination pg={pg} />
      </div>

      <Modal open={modal} title={editing ? 'Edit Diskon' : 'Tambah Diskon'} onClose={() => setModal(false)}>
        <Alert message={error} />
        <form onSubmit={submit} className="space-y-4">
          <div><label className="label">Nama *</label><input className="input" required value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} /></div>
          <div><label className="label">Kode Kupon</label><input className="input" value={form.code} onChange={(e) => setForm({ ...form, code: e.target.value.toUpperCase() })} /></div>
          <div className="grid grid-cols-2 gap-4">
            <div>
              <label className="label">Tipe</label>
              <select className="input" value={form.type} onChange={(e) => setForm({ ...form, type: e.target.value })}>
                <option value="PERCENTAGE">Persentase (%)</option>
                <option value="NOMINAL">Nominal (Rp)</option>
              </select>
            </div>
            <div><label className="label">Nilai *</label><input type="number" className="input" required value={form.value} onChange={(e) => setForm({ ...form, value: e.target.value })} /></div>
            <div>
              <label className="label">Berlaku Untuk</label>
              <select className="input" value={form.scope} onChange={(e) => setForm({ ...form, scope: e.target.value })}>
                <option value="SEMUA">Semua</option><option value="SERVICE">Service</option><option value="SPAREPART">Sparepart</option>
              </select>
            </div>
            <div>
              <label className="label">Status</label>
              <select className="input" value={form.status} onChange={(e) => setForm({ ...form, status: e.target.value })}>
                <option value="AKTIF">Aktif</option><option value="NONAKTIF">Nonaktif</option>
              </select>
            </div>
          </div>
          <div className="flex justify-end gap-2 pt-2">
            <button type="button" className="btn-secondary" onClick={() => setModal(false)}>Batal</button>
            <button type="submit" className="btn-primary">Simpan</button>
          </div>
        </form>
      </Modal>
    </div>
  );
}

/* ---------- Jenis Service ---------- */
const emptyType = { name: '', description: '', estimatedCost: '' };

function ServiceTypesTab() {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);
  const [modal, setModal] = useState(false);
  const [editing, setEditing] = useState(null);
  const [form, setForm] = useState(emptyType);
  const [error, setError] = useState('');

  function load() { setLoading(true); api.get('/service-types').then(({ data }) => setItems(data)).finally(() => setLoading(false)); }
  const pg = usePagination(items, 10, '');
  useEffect(() => { load(); }, []);

  function openAdd() { setEditing(null); setForm(emptyType); setError(''); setModal(true); }
  function openEdit(t) { setEditing(t); setForm({ name: t.name, description: t.description || '', estimatedCost: t.estimatedCost }); setError(''); setModal(true); }

  async function submit(e) {
    e.preventDefault(); setError('');
    try {
      if (editing) await api.put(`/service-types/${editing.id}`, form);
      else await api.post('/service-types', form);
      setModal(false); load();
    } catch (err) { setError(err?.response?.data?.message || 'Gagal menyimpan jenis service.'); }
  }
  async function remove(t) {
    if (!confirm(`Hapus jenis service ${t.name}?`)) return;
    await api.delete(`/service-types/${t.id}`); load();
  }

  return (
    <div className="space-y-4">
      <div className="flex justify-end"><button className="btn-primary" onClick={openAdd}>+ Tambah Jenis Service</button></div>
      <div className="card overflow-x-auto">
        {loading ? <Spinner /> : (
          <table className="table-base">
            <thead><tr><th className="w-20"><FaHashtag className="mr-1 inline text-[10px]" aria-hidden /> No</th><th><FaTools className="mr-1 inline text-[10px]" aria-hidden /> Nama</th><th><FaAlignLeft className="mr-1 inline text-[10px]" aria-hidden /> Deskripsi</th><th><FaMoneyBillWave className="mr-1 inline text-[10px]" aria-hidden /> Estimasi Biaya</th><th><FaCog className="mr-1 inline text-[10px]" aria-hidden /> Aksi</th></tr></thead>
            <tbody>
              {items.length === 0 && <tr><td colSpan={5} className="text-center text-slate-400 py-6">Belum ada data.</td></tr>}
              {pg.pageItems.map((t, rowNo) => (
                <tr key={t.id}><td>{pg.start + rowNo + 1}</td>
                  <td>{t.name}</td><td>{t.description || '-'}</td><td>{formatRp(t.estimatedCost)}</td>
                  <td className="text-right space-x-2 whitespace-nowrap">
                    <button className="btn-ghost" onClick={() => openEdit(t)}>Edit</button>
                    <button className="btn-ghost text-red-600" onClick={() => remove(t)}>Hapus</button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
        <Pagination pg={pg} />
      </div>

      <Modal open={modal} title={editing ? 'Edit Jenis Service' : 'Tambah Jenis Service'} onClose={() => setModal(false)}>
        <Alert message={error} />
        <form onSubmit={submit} className="space-y-4">
          <div><label className="label">Nama *</label><input className="input" required value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} /></div>
          <div><label className="label">Deskripsi</label><textarea className="input" rows={2} value={form.description} onChange={(e) => setForm({ ...form, description: e.target.value })} /></div>
          <div><label className="label">Estimasi Biaya *</label><input type="number" className="input" required value={form.estimatedCost} onChange={(e) => setForm({ ...form, estimatedCost: e.target.value })} /></div>
          <div className="flex justify-end gap-2 pt-2">
            <button type="button" className="btn-secondary" onClick={() => setModal(false)}>Batal</button>
            <button type="submit" className="btn-primary">Simpan</button>
          </div>
        </form>
      </Modal>
    </div>
  );
}

export default function AdminPage() {
  const [tab, setTab] = useState('settings');
  const tabs = [['settings', 'Pengaturan Aplikasi'], ['discounts', 'Diskon'], ['types', 'Jenis Service']];
  return (
    <div className="space-y-4">
      <h1 className="text-xl font-semibold text-slate-800">Admin</h1>
      <div className="flex gap-1 bg-white border border-slate-200 rounded-lg p-1 w-fit flex-wrap">
        {tabs.map(([k, l]) => (
          <button key={k} onClick={() => setTab(k)} className={`px-4 py-1.5 rounded-md text-sm font-medium ${tab === k ? 'bg-brand-600 text-white' : 'text-slate-600 hover:bg-slate-100'}`}>{l}</button>
        ))}
      </div>
      {tab === 'settings' && <SettingsTab />}
      {tab === 'discounts' && <DiscountsTab />}
      {tab === 'types' && <ServiceTypesTab />}
    </div>
  );
}
