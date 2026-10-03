import React, { useEffect, useState } from 'react';
import { useNavigate, useParams, useSearchParams } from 'react-router-dom';
import api from '../../api/axios';
import Spinner from '../../components/ui/Spinner';
import FormPage from '../../components/ui/FormPage';
import useForm, { errMsg } from '../../hooks/useForm';

import { FaCar, FaInfoCircle } from 'react-icons/fa';
const empty = { customerId: '', vehicleModelId: '', plateNumber: '', vin: '', engineNumber: '', color: '', purchaseYear: '', note: '' };

// Halaman Tambah (/vehicles/new, bisa dengan ?addFor=<customerId>) dan Edit (/vehicles/:id/edit)
export default function VehicleForm() {
  const { id } = useParams();
  const editing = Boolean(id);
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const { form, setForm, bind, load, reset } = useForm({ ...empty, customerId: searchParams.get('addFor') || '' });
  const [customers, setCustomers] = useState([]);
  const [models, setModels] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    const reqs = [api.get('/customers'), api.get('/vehicle-models')];
    if (editing) reqs.push(api.get(`/vehicles/${id}`));
    Promise.all(reqs)
      .then(([c, m, v]) => {
        setCustomers(c.data); setModels(m.data);
        if (v) {
          const d = v.data;
          load({
            customerId: d.customerId, vehicleModelId: d.vehicleModelId, plateNumber: d.plateNumber,
            vin: d.vin || '', engineNumber: d.engineNumber || '', color: d.color || '',
            purchaseYear: d.purchaseYear || '', note: d.note || '',
          });
        }
      })
      .catch(() => setError('Gagal memuat data.'))
      .finally(() => setLoading(false));
  }, [id, editing, load]);

  async function submit(e) {
    e.preventDefault(); setSaving(true); setError('');
    try {
      if (editing) await api.put(`/vehicles/${id}`, form);
      else await api.post('/vehicles', form);
      navigate('/vehicles');
    } catch (err) { setError(errMsg(err, 'Gagal menyimpan data kendaraan.')); }
    finally { setSaving(false); }
  }

  if (loading) return <Spinner />;

  return (
    <FormPage
      icon={FaCar}
      title={editing ? 'Edit Kendaraan' : 'Tambah Kendaraan'}
      subtitle={editing ? 'Ubah data kendaraan pelanggan' : 'Tambahkan data kendaraan baru'}
      cardTitle={editing ? 'Form Edit Kendaraan' : 'Form Tambah Kendaraan'}
      backTo="/vehicles"
      error={error}
      saving={saving}
      onSubmit={submit}
      onReset={reset}
    >
      <div className="grid md:grid-cols-2 gap-6">
        <div className="space-y-4">
          <h3 className="flex items-center gap-2 font-semibold text-slate-800"><FaCar className="text-brand-500" aria-hidden /> Informasi Kendaraan</h3>
          <div>
            <label className="label">Pemilik Kendaraan *</label>
            <select className="input" required value={form.customerId} onChange={bind('customerId')}>
              <option value="">-- Pilih Pelanggan --</option>
              {customers.map((c) => <option key={c.id} value={c.id}>{c.name} ({c.phone})</option>)}
            </select>
          </div>
          <div>
            <label className="label">Jenis Kendaraan *</label>
            <select className="input" required value={form.vehicleModelId} onChange={bind('vehicleModelId')}>
              <option value="">-- Pilih Jenis (merk, model, tahun) --</option>
              {models.map((m) => <option key={m.id} value={m.id}>{m.brand} {m.model} ({m.year})</option>)}
            </select>
          </div>
          <div>
            <label className="label">Nomor Plat *</label>
            <input className="input" required value={form.plateNumber} onChange={(e) => setForm({ ...form, plateNumber: e.target.value.toUpperCase() })} />
          </div>
          <div><label className="label">Warna</label><input className="input" value={form.color} onChange={bind('color')} /></div>
        </div>

        <div className="space-y-4">
          <h3 className="flex items-center gap-2 font-semibold text-slate-800"><FaInfoCircle className="text-brand-500" aria-hidden /> Informasi Tambahan</h3>
          <div><label className="label">Nomor Rangka (VIN)</label><input className="input" value={form.vin} onChange={bind('vin')} /></div>
          <div><label className="label">Nomor Mesin</label><input className="input" value={form.engineNumber} onChange={bind('engineNumber')} /></div>
          <div><label className="label">Tahun Pembelian</label><input type="number" className="input" value={form.purchaseYear} onChange={bind('purchaseYear')} /></div>
          <div><label className="label">Catatan</label><textarea className="input" rows={3} value={form.note} onChange={bind('note')} /></div>
        </div>
      </div>
    </FormPage>
  );
}
