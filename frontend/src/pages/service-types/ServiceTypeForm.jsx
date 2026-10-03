import React, { useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import api from '../../api/axios';
import Spinner from '../../components/ui/Spinner';
import FormPage from '../../components/ui/FormPage';
import useForm, { errMsg } from '../../hooks/useForm';

import { FaClipboardList } from 'react-icons/fa';
const empty = { name: '', description: '', estimatedCost: '' };

// Halaman Tambah (/service-types/new) dan Edit (/service-types/:id/edit) jenis layanan
export default function ServiceTypeForm() {
  const { id } = useParams();
  const editing = Boolean(id);
  const navigate = useNavigate();
  const { form, bind, load, reset } = useForm(empty);
  const [loading, setLoading] = useState(editing);
  const [error, setError] = useState('');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (!editing) return;
    api.get('/service-types')
      .then(({ data }) => {
        const t = data.find((x) => String(x.id) === String(id));
        if (!t) return setError('Jenis layanan tidak ditemukan.');
        load({ name: t.name, description: t.description || '', estimatedCost: t.estimatedCost });
      })
      .finally(() => setLoading(false));
  }, [id, editing, load]);

  async function submit(e) {
    e.preventDefault(); setSaving(true); setError('');
    try {
      if (editing) await api.put(`/service-types/${id}`, form);
      else await api.post('/service-types', form);
      navigate('/service-types');
    } catch (err) { setError(errMsg(err, 'Gagal menyimpan jenis layanan.')); }
    finally { setSaving(false); }
  }

  if (loading) return <Spinner />;

  return (
    <FormPage
      icon={FaClipboardList}
      title={editing ? 'Edit Jenis Layanan' : 'Tambah Jenis Layanan'}
      subtitle="Form data jenis layanan service"
      cardTitle="Form Jenis Layanan"
      backTo="/service-types"
      error={error}
      saving={saving}
      onSubmit={submit}
      onReset={reset}
    >
      <div className="grid md:grid-cols-2 gap-4">
        <div><label className="label">Jenis Layanan *</label><input className="input" required placeholder="Contoh: Service Ringan, Service Berat" value={form.name} onChange={bind('name')} /></div>
        <div><label className="label">Estimasi Biaya *</label><input type="number" min="0" className="input" required value={form.estimatedCost} onChange={bind('estimatedCost')} /></div>
        <div className="md:col-span-2"><label className="label">Deskripsi</label><textarea className="input" rows={3} placeholder="Keterangan mengenai jenis layanan ini" value={form.description} onChange={bind('description')} /></div>
      </div>
    </FormPage>
  );
}
