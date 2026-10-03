import React, { useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import api from '../../api/axios';
import Spinner from '../../components/ui/Spinner';
import FormPage from '../../components/ui/FormPage';
import useForm, { errMsg } from '../../hooks/useForm';

import { FaTags } from 'react-icons/fa';
// Halaman Tambah (/spareparts/categories/new) dan Edit (/spareparts/categories/:id/edit) kategori
export default function CategoryForm() {
  const { id } = useParams();
  const editing = Boolean(id);
  const navigate = useNavigate();
  const { form, bind, load, reset } = useForm({ name: '' });
  const [loading, setLoading] = useState(editing);
  const [error, setError] = useState('');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (!editing) return;
    api.get('/categories')
      .then(({ data }) => {
        const c = data.find((x) => String(x.id) === String(id));
        if (!c) return setError('Kategori tidak ditemukan.');
        load({ name: c.name });
      })
      .finally(() => setLoading(false));
  }, [id, editing, load]);

  async function submit(e) {
    e.preventDefault(); setSaving(true); setError('');
    try {
      if (editing) await api.put(`/categories/${id}`, form);
      else await api.post('/categories', form);
      navigate('/spareparts/categories');
    } catch (err) { setError(errMsg(err, 'Gagal menyimpan kategori.')); }
    finally { setSaving(false); }
  }

  if (loading) return <Spinner />;

  return (
    <FormPage
      icon={FaTags}
      title={editing ? 'Edit Kategori' : 'Tambah Kategori'}
      subtitle={editing ? 'Ubah data kategori' : 'Tambah data kategori baru'}
      cardTitle="Form Kategori Sparepart"
      backTo="/spareparts/categories"
      error={error}
      saving={saving}
      onSubmit={submit}
      onReset={reset}
    >
      <div><label className="label">Nama Kategori *</label><input className="input" required value={form.name} onChange={bind('name')} /></div>
    </FormPage>
  );
}
