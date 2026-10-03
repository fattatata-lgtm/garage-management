import React, { useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import api from '../../api/axios';
import Spinner from '../../components/ui/Spinner';
import FormPage from '../../components/ui/FormPage';
import useForm, { errMsg } from '../../hooks/useForm';
import ScanButton from '../../components/ui/ScanButton';

import { FaCogs } from 'react-icons/fa';
const empty = { code: '', name: '', categoryId: '', buyPrice: '', sellPrice: '', stock: 0, lowStockThreshold: 5 };

// Halaman Tambah (/spareparts/new) dan Edit (/spareparts/:id/edit) sparepart
export default function SparepartForm() {
  const { id } = useParams();
  const editing = Boolean(id);
  const navigate = useNavigate();
  const { form, setForm, bind, load, reset } = useForm(empty);
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    const reqs = [api.get('/categories')];
    if (editing) reqs.push(api.get(`/spareparts/${id}`));
    Promise.all(reqs)
      .then(([c, sp]) => {
        setCategories(c.data);
        if (sp) {
          const d = sp.data;
          load({ code: d.code, name: d.name, categoryId: d.categoryId, buyPrice: d.buyPrice, sellPrice: d.sellPrice, stock: d.stock, lowStockThreshold: d.lowStockThreshold });
        }
      })
      .catch(() => setError('Gagal memuat data.'))
      .finally(() => setLoading(false));
  }, [id, editing, load]);

  async function submit(e) {
    e.preventDefault(); setSaving(true); setError('');
    try {
      if (editing) await api.put(`/spareparts/${id}`, form);
      else await api.post('/spareparts', form);
      navigate('/spareparts');
    } catch (err) { setError(errMsg(err, 'Gagal menyimpan sparepart.')); }
    finally { setSaving(false); }
  }

  if (loading) return <Spinner />;

  return (
    <FormPage
      icon={FaCogs}
      title={editing ? 'Edit Sparepart' : 'Tambah Sparepart'}
      subtitle={editing ? 'Ubah data sparepart' : 'Tambah data sparepart baru'}
      cardTitle={editing ? 'Form Edit Sparepart' : 'Form Tambah Sparepart'}
      backTo="/spareparts"
      error={error}
      saving={saving}
      onSubmit={submit}
      onReset={reset}
    >
      <div className="grid md:grid-cols-2 gap-4">
        <div>
          <label className="label">Kode Sparepart *</label>
          <div className="flex gap-2">
            <input className="input" required value={form.code} onChange={bind('code')} placeholder="Ketik atau scan barcode" />
            <ScanButton onScan={(text) => setForm((f) => ({ ...f, code: text }))} title="Scan barcode sebagai kode sparepart" />
          </div>
        </div>
        <div>
          <label className="label">Stok {editing ? '(ubah lewat menu Riwayat Stok)' : 'Awal'}</label>
          <input type="number" min="0" className="input disabled:bg-slate-100" disabled={editing} value={form.stock} onChange={bind('stock')} />
        </div>
        <div><label className="label">Nama Sparepart *</label><input className="input" required value={form.name} onChange={bind('name')} /></div>
        <div><label className="label">Harga Beli *</label><input type="number" min="0" className="input" required value={form.buyPrice} onChange={bind('buyPrice')} /></div>
        <div>
          <label className="label">Kategori *</label>
          <select className="input" required value={form.categoryId} onChange={bind('categoryId')}>
            <option value="">-- Pilih Kategori --</option>
            {categories.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
          </select>
        </div>
        <div><label className="label">Harga Jual *</label><input type="number" min="0" className="input" required value={form.sellPrice} onChange={bind('sellPrice')} /></div>
        <div><label className="label">Ambang Stok Rendah</label><input type="number" min="0" className="input" value={form.lowStockThreshold} onChange={bind('lowStockThreshold')} /></div>
      </div>
    </FormPage>
  );
}
