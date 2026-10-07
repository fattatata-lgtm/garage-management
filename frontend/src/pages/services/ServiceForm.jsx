import React, { useEffect, useState } from 'react';
import { useNavigate, useParams, useSearchParams } from 'react-router-dom';
import api from '../../api/axios';
import Spinner from '../../components/ui/Spinner';
import FormPage from '../../components/ui/FormPage';
import InfoRow from '../../components/ui/InfoRow';
import VehiclePicker from '../../components/ui/VehiclePicker';
import useForm, { errMsg } from '../../hooks/useForm';
import { FaWrench, FaCar, FaMotorcycle, FaUserCog, FaCalendarAlt, FaCommentDots, FaUser, FaPhone, FaPalette, FaPlus } from 'react-icons/fa';

const today = () => new Date().toISOString().slice(0, 10);
const QUICK_COMPLAINTS = ['Servis rutin', 'Ganti oli', 'Rem berbunyi', 'Mesin brebet', 'Aki lemah', 'Ganti ban'];

const Label = ({ icon: Icon, children }) => (
  <label className="label flex items-center gap-1.5"><Icon className="text-[12px] text-brand-500" aria-hidden /> {children}</label>
);

// Halaman Tambah Service (/services/new) dan Edit Service (/services/:id/edit).
// Tambah bisa dengan ?vehicleId=<id> agar kendaraan terpilih otomatis.
export default function ServiceForm() {
  const { id } = useParams();
  const isEdit = Boolean(id);
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const { form, bind, reset, load } = useForm({
    vehicleId: searchParams.get('vehicleId') || '', technicianId: '', date: today(), complaint: '',
  });
  const [vehicles, setVehicles] = useState([]);
  const [technicians, setTechnicians] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    const requests = [api.get('/vehicles'), api.get('/technicians?activeOnly=true')];
    if (isEdit) requests.push(api.get(`/services/${id}`));
    Promise.all(requests)
      .then(([v, t, s]) => {
        let techs = t.data;
        if (s) {
          const svc = s.data;
          // Teknisi yang sudah tidak aktif tetap ditampilkan agar data lama tidak hilang
          if (!techs.some((x) => x.id === svc.technicianId)) techs = [...techs, svc.technician];
          load({
            vehicleId: String(svc.vehicleId), technicianId: String(svc.technicianId),
            date: svc.date.slice(0, 10), complaint: svc.complaint || '',
          });
        }
        setVehicles(v.data); setTechnicians(techs);
      })
      .catch((err) => setError(errMsg(err, 'Gagal memuat data.')))
      .finally(() => setLoading(false));
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [id]);

  // ?newFor=<customerId> tanpa vehicleId: bila pelanggan hanya punya 1 kendaraan, pilih otomatis
  useEffect(() => {
    if (isEdit) return;
    const newFor = searchParams.get('newFor');
    if (!newFor || form.vehicleId || vehicles.length === 0) return;
    const owned = vehicles.filter((v) => String(v.customerId ?? v.customer?.id) === String(newFor));
    if (owned.length === 1) bind('vehicleId')({ target: { value: String(owned[0].id) } });
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [vehicles]);

  async function submit(e) {
    e.preventDefault(); setSaving(true); setError('');
    try {
      if (isEdit) {
        await api.put(`/services/${id}`, form);
        navigate(`/services/${id}`);
      } else {
        const { data } = await api.post('/services', form);
        navigate(`/services/${data.id}`);
      }
    } catch (err) { setError(errMsg(err, isEdit ? 'Gagal menyimpan perubahan service.' : 'Gagal membuat transaksi service.')); }
    finally { setSaving(false); }
  }

  function addComplaint(text) {
    const base = form.complaint.replace(/[\s,.]+$/, '');
    bind('complaint')({ target: { value: base ? `${base}, ${text.toLowerCase()}` : text } });
  }

  if (loading) return <Spinner />;

  const selected = vehicles.find((v) => String(v.id) === String(form.vehicleId));
  const VIcon = selected?.vehicleModel.wheels === 2 ? FaMotorcycle : FaCar;

  return (
    <div className="space-y-4">
      <FormPage
        icon={FaWrench}
        title={isEdit ? 'Edit Service' : 'Tambah Service'}
        subtitle={isEdit ? 'Ubah data awal service (kendaraan, teknisi, tanggal, keluhan)' : 'Catat kendaraan yang masuk bengkel'}
        cardTitle={isEdit ? 'Form Edit Service' : 'Form Tambah Service'}
        backTo={isEdit ? `/services/${id}` : '/services'}
        error={error}
        saving={saving}
        onSubmit={submit}
        onReset={reset}
        submitLabel={isEdit ? 'Simpan Perubahan' : 'Simpan & Lanjut'}
        hint={(
          <>
            {isEdit ? (
              <p>Halaman ini hanya mengubah data awal service. Detail jasa, sparepart, dan pembayaran diubah dari halaman detail service.</p>
            ) : (
              <p>Detail jasa, sparepart, dan pembayaran diisi di halaman detail service setelah disimpan.</p>
            )}
            <p>Nama pemilik dan No. WhatsApp terisi otomatis dari data pelanggan pada kendaraan yang dipilih.</p>
          </>
        )}
      >
        <div>
          <Label icon={FaCar}>Kendaraan *</Label>
          <VehiclePicker
            required
            options={vehicles}
            value={form.vehicleId}
            onPick={(v) => bind('vehicleId')({ target: { value: String(v.id) } })}
          />
        </div>

        {selected && (
          <div className="rounded-xl border border-brand-100 bg-brand-50/40 p-4 animate-fade-in">
            <div className="flex items-center gap-3">
              <span className="icon-tile h-11 w-11 text-lg"><VIcon aria-hidden /></span>
              <div>
                <div className="font-bold text-slate-900">
                  {selected.vehicleModel.brand} {selected.vehicleModel.model}{' '}
                  <span className="font-normal text-slate-500">({selected.vehicleModel.year})</span>
                </div>
                <span className="mt-0.5 inline-block rounded bg-slate-900 px-2 py-0.5 text-[11px] font-bold tracking-wide text-white">{selected.plateNumber}</span>
              </div>
            </div>
            <dl className="info-list mt-3">
              <InfoRow label={<span className="flex items-center gap-2"><FaUser className="text-brand-500" aria-hidden /> Nama Pemilik</span>}>{selected.customer.name}</InfoRow>
              <InfoRow label={<span className="flex items-center gap-2"><FaPhone className="text-brand-500" aria-hidden /> No. WhatsApp</span>}>{selected.customer.phone || '-'}</InfoRow>
              <InfoRow label={<span className="flex items-center gap-2"><FaPalette className="text-brand-500" aria-hidden /> Warna</span>}>{selected.color || '-'}</InfoRow>
            </dl>
          </div>
        )}

        <div className="grid gap-4 sm:grid-cols-2">
          <div>
            <Label icon={FaUserCog}>Teknisi *</Label>
            <select className="input" required value={form.technicianId} onChange={bind('technicianId')}>
              <option value="">-- Pilih Teknisi --</option>
              {technicians.map((t) => <option key={t.id} value={t.id}>{t.name}</option>)}
            </select>
          </div>
          <div>
            <Label icon={FaCalendarAlt}>Tanggal Service *</Label>
            <input type="date" className="input" required value={form.date} onChange={bind('date')} />
          </div>
        </div>

        <div>
          <Label icon={FaCommentDots}>Keluhan *</Label>
          <textarea className="input" rows={4} required placeholder="Keluhan pelanggan tentang kendaraan" value={form.complaint} onChange={bind('complaint')} />
          <div className="mt-2 flex flex-wrap items-center gap-1.5">
            <span className="text-xs text-slate-400">Cepat isi:</span>
            {QUICK_COMPLAINTS.map((c) => (
              <button key={c} type="button" onClick={() => addComplaint(c)}
                className="inline-flex items-center gap-1 rounded-full border border-slate-200 bg-white px-2.5 py-1 text-xs font-medium text-slate-600 transition hover:border-brand-300 hover:bg-brand-50 hover:text-brand-700">
                <FaPlus className="text-[8px]" aria-hidden /> {c}
              </button>
            ))}
          </div>
        </div>
      </FormPage>
    </div>
  );
}
