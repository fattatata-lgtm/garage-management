import React, { useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import api from '../../api/axios';
import Spinner from '../../components/ui/Spinner';
import FormPage from '../../components/ui/FormPage';
import useForm, { errMsg } from '../../hooks/useForm';
import { FaTruck } from 'react-icons/fa';

const empty = { name: '', contactPerson: '', phone: '', email: '', address: '', note: '' };

// Halaman Tambah (/suppliers/new) dan Edit (/suppliers/:id/edit) supplier
export default function SupplierForm() {
  const { id } = useParams();
  const editing = Boolean(id);
  const navigate = useNavigate();
  const { form, bind, load, reset } = useForm(empty);
  const [loading, setLoading] = useState(editing);
  const [error, setError] = useState('');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (!editing) return;
    api.get(`/suppliers/${id}`)
      .then(({ data: d }) => load({
        name: d.name || '', contactPerson: d.contactPerson || '', phone: d.phone || '',
        email: d.email || '', address: d.address || '', note: d.note || '',
      }))
      .catch(() => setError('Supplier tidak ditemukan.'))
      .finally(() => setLoading(false));
  }, [id, editing, load]);

  async function submit(e) {
    e.preventDefault(); setSaving(true); setError('');
    try {
      if (editing) await api.put(`/suppliers/${id}`, form);
      else await api.post('/suppliers', form);
      navigate('/suppliers');
    } catch (err) { setError(errMsg(err, 'Gagal menyimpan supplier.')); }
    finally { setSaving(false); }
  }

  if (loading) return <Spinner />;

  return (
    <FormPage
      icon={FaTruck}
      title={editing ? 'Edit Supplier' : 'Tambah Supplier'}
      subtitle={editing ? 'Ubah data supplier' : 'Tambah data supplier baru'}
      cardTitle="Form Supplier Sparepart"
      backTo="/suppliers"
      error={error}
      saving={saving}
      onSubmit={submit}
      onReset={reset}
    >
      <div className="grid md:grid-cols-2 gap-4">
        <div><label className="label">Nama Supplier *</label><input className="input" required value={form.name} onChange={bind('name')} /></div>
        <div><label className="label">Kontak Person</label><input className="input" value={form.contactPerson} onChange={bind('contactPerson')} /></div>
        <div><label className="label">Telepon</label><input className="input" value={form.phone} onChange={bind('phone')} placeholder="08xxxxxxxxxx" /></div>
        <div><label className="label">Email</label><input type="email" className="input" value={form.email} onChange={bind('email')} /></div>
      </div>
      <div><label className="label">Alamat</label><textarea className="input" rows={2} value={form.address} onChange={bind('address')} /></div>
      <div><label className="label">Catatan</label><textarea className="input" rows={2} placeholder="Opsional (mis. syarat pembayaran, jadwal kirim)" value={form.note} onChange={bind('note')} /></div>
    </FormPage>
  );
}
