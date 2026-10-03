import React, { useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import api from '../../api/axios';
import Spinner from '../../components/ui/Spinner';
import FormPage from '../../components/ui/FormPage';
import useForm, { errMsg } from '../../hooks/useForm';

import { FaUserEdit, FaUserPlus } from 'react-icons/fa';
const empty = { name: '', phone: '', email: '', address: '' };

// Halaman Tambah (/customers/new) dan Edit (/customers/:id/edit) pelanggan
export default function CustomerForm() {
  const { id } = useParams();
  const editing = Boolean(id);
  const navigate = useNavigate();
  const { form, bind, load, reset } = useForm(empty);
  const [loading, setLoading] = useState(editing);
  const [error, setError] = useState('');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (!editing) return;
    api.get(`/customers/${id}`)
      .then(({ data }) => load({ name: data.name, phone: data.phone, email: data.email || '', address: data.address || '' }))
      .catch(() => setError('Data pelanggan tidak ditemukan.'))
      .finally(() => setLoading(false));
  }, [id, editing, load]);

  async function submit(e) {
    e.preventDefault(); setSaving(true); setError('');
    try {
      if (editing) await api.put(`/customers/${id}`, form);
      else await api.post('/customers', form);
      navigate('/customers');
    } catch (err) { setError(errMsg(err, 'Gagal menyimpan data pelanggan.')); }
    finally { setSaving(false); }
  }

  if (loading) return <Spinner />;

  return (
    <FormPage
      icon={editing ? FaUserEdit : FaUserPlus}
      title={editing ? 'Edit Pelanggan' : 'Tambah Pelanggan'}
      subtitle={editing ? 'Ubah data pelanggan' : 'Tambah data pelanggan baru'}
      cardTitle={editing ? 'Form Edit Pelanggan' : 'Form Tambah Pelanggan'}
      backTo="/customers"
      error={error}
      saving={saving}
      onSubmit={submit}
      onReset={reset}
      hint={(
        <>
          <p>Isi form untuk {editing ? 'mengubah' : 'menambahkan'} data pelanggan. Field bertanda * wajib diisi.</p>
          <ul className="list-disc pl-5 space-y-1">
            <li><b>Nama Pelanggan:</b> nama lengkap pelanggan.</li>
            <li><b>No. HP:</b> nomor aktif, dipakai untuk pesan WhatsApp.</li>
            <li><b>Email &amp; Alamat:</b> opsional.</li>
          </ul>
        </>
      )}
    >
      <div><label className="label">Nama Pelanggan *</label><input className="input" required value={form.name} onChange={bind('name')} /></div>
      <div><label className="label">No. HP *</label><input className="input" required value={form.phone} onChange={bind('phone')} /></div>
      <div><label className="label">Email</label><input type="email" className="input" value={form.email} onChange={bind('email')} /></div>
      <div><label className="label">Alamat</label><textarea className="input" rows={3} value={form.address} onChange={bind('address')} /></div>
    </FormPage>
  );
}
