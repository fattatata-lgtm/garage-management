import React, { useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import api from '../../api/axios';
import Spinner from '../../components/ui/Spinner';
import FormPage from '../../components/ui/FormPage';
import useForm, { errMsg } from '../../hooks/useForm';

import { FaTags } from 'react-icons/fa';
const empty = { name: '', code: '', type: 'PERCENTAGE', value: '', status: 'AKTIF', scope: 'SEMUA' };

// Halaman Tambah (/admin/discounts/new) dan Edit (/admin/discounts/:id/edit) diskon
export default function DiscountForm() {
  const { id } = useParams();
  const editing = Boolean(id);
  const navigate = useNavigate();
  const { form, setForm, bind, load, reset } = useForm(empty);
  const [loading, setLoading] = useState(editing);
  const [error, setError] = useState('');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (!editing) return;
    api.get('/discounts')
      .then(({ data }) => {
        const d = data.find((x) => String(x.id) === String(id));
        if (!d) return setError('Diskon tidak ditemukan.');
        load({ name: d.name, code: d.code || '', type: d.type, value: d.value, status: d.status, scope: d.scope });
      })
      .finally(() => setLoading(false));
  }, [id, editing, load]);

  async function submit(e) {
    e.preventDefault(); setSaving(true); setError('');
    try {
      if (editing) await api.put(`/discounts/${id}`, form);
      else await api.post('/discounts', form);
      navigate('/admin/discounts');
    } catch (err) { setError(errMsg(err, 'Gagal menyimpan diskon.')); }
    finally { setSaving(false); }
  }

  if (loading) return <Spinner />;

  return (
    <FormPage
      icon={FaTags}
      title={editing ? 'Edit Diskon' : 'Tambah Diskon'}
      subtitle={editing ? 'Ubah data diskon' : 'Tambah data diskon baru'}
      cardTitle={editing ? 'Form Edit Diskon' : 'Form Tambah Diskon'}
      backTo="/admin/discounts"
      error={error}
      saving={saving}
      onSubmit={submit}
      onReset={reset}
      hint={(
        <>
          <ul className="list-disc pl-5 space-y-1">
            <li><b>Nama &amp; Kode Kupon:</b> identitas promo; kode dipakai saat transaksi.</li>
            <li><b>Tipe &amp; Nilai:</b> persentase (%) atau nominal tetap (Rp).</li>
            <li><b>Berlaku Untuk:</b> Semua, hanya Service, atau hanya Sparepart.</li>
          </ul>
        </>
      )}
    >
      <div className="grid sm:grid-cols-2 gap-4">
        <div><label className="label">Nama Diskon *</label><input className="input" required value={form.name} onChange={bind('name')} /></div>
        <div><label className="label">Kode Kupon</label><input className="input" value={form.code} onChange={(e) => setForm({ ...form, code: e.target.value.toUpperCase() })} /></div>
        <div>
          <label className="label">Tipe Diskon</label>
          <select className="input" value={form.type} onChange={bind('type')}>
            <option value="PERCENTAGE">Persentase (%)</option>
            <option value="NOMINAL">Nominal (Rp)</option>
          </select>
        </div>
        <div><label className="label">Nilai Diskon *</label><input type="number" min="0" className="input" required value={form.value} onChange={bind('value')} /></div>
        <div>
          <label className="label">Berlaku Untuk</label>
          <select className="input" value={form.scope} onChange={bind('scope')}>
            <option value="SEMUA">Semua</option><option value="SERVICE">Service</option><option value="SPAREPART">Sparepart</option>
          </select>
        </div>
        <div>
          <label className="label">Status</label>
          <select className="input" value={form.status} onChange={bind('status')}>
            <option value="AKTIF">Aktif</option><option value="NONAKTIF">Nonaktif</option>
          </select>
        </div>
      </div>
    </FormPage>
  );
}
