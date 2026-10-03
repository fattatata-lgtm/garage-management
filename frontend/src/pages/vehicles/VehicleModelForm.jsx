import React, { useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import api from '../../api/axios';
import Spinner from '../../components/ui/Spinner';
import FormPage from '../../components/ui/FormPage';
import useForm, { errMsg } from '../../hooks/useForm';

import { FaCarSide } from 'react-icons/fa';
const empty = { brand: '', model: '', year: '', type: '', wheels: 4 };

// Halaman Tambah (/vehicles/master/new) dan Edit (/vehicles/master/:id/edit) data master kendaraan
export default function VehicleModelForm() {
  const { id } = useParams();
  const editing = Boolean(id);
  const navigate = useNavigate();
  const { form, bind, load, reset } = useForm(empty);
  const [loading, setLoading] = useState(editing);
  const [error, setError] = useState('');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (!editing) return;
    api.get('/vehicle-models')
      .then(({ data }) => {
        const m = data.find((x) => String(x.id) === String(id));
        if (!m) return setError('Data master tidak ditemukan.');
        load({ brand: m.brand, model: m.model, year: m.year, type: m.type, wheels: m.wheels });
      })
      .finally(() => setLoading(false));
  }, [id, editing, load]);

  async function submit(e) {
    e.preventDefault(); setSaving(true); setError('');
    try {
      if (editing) await api.put(`/vehicle-models/${id}`, form);
      else await api.post('/vehicle-models', form);
      navigate('/vehicles/master');
    } catch (err) { setError(errMsg(err, 'Gagal menyimpan data master.')); }
    finally { setSaving(false); }
  }

  if (loading) return <Spinner />;

  return (
    <FormPage
      icon={FaCarSide}
      title={editing ? 'Edit Master Kendaraan' : 'Tambah Master Kendaraan'}
      subtitle="Data jenis kendaraan yang dipilih saat menambah kendaraan pelanggan"
      cardTitle="Form Master Kendaraan"
      backTo="/vehicles/master"
      error={error}
      saving={saving}
      onSubmit={submit}
      onReset={reset}
    >
      <div className="grid md:grid-cols-2 gap-4">
        <div><label className="label">Merk Kendaraan *</label><input className="input" required placeholder="Contoh: Toyota, Honda, Suzuki" value={form.brand} onChange={bind('brand')} /></div>
        <div><label className="label">Tahun Kendaraan *</label><input type="number" className="input" required value={form.year} onChange={bind('year')} /></div>
        <div><label className="label">Model Kendaraan *</label><input className="input" required placeholder="Contoh: Avanza, Brio, Ertiga" value={form.model} onChange={bind('model')} /></div>
        <div>
          <label className="label">Jumlah Roda</label>
          <select className="input" value={form.wheels} onChange={bind('wheels')}>
            <option value={2}>2 Roda</option>
            <option value={3}>3 Roda</option>
            <option value={4}>4 Roda</option>
            <option value={6}>6 Roda</option>
          </select>
        </div>
        <div className="md:col-span-2"><label className="label">Tipe Kendaraan *</label><input className="input" required placeholder="Contoh: MPV, SUV, Hatchback" value={form.type} onChange={bind('type')} /></div>
      </div>
    </FormPage>
  );
}
