import React, { useEffect, useState } from 'react';
import { useParams, Link, useNavigate } from 'react-router-dom';
import api from '../../api/axios';
import Spinner from '../../components/ui/Spinner';
import usePagination from '../../hooks/usePagination';
import Pagination from '../../components/ui/Pagination';
import EmptyState from '../../components/ui/EmptyState';
import StatusBadge from '../../components/ui/StatusBadge';
import DetailHeader from '../../components/ui/DetailHeader';
import InfoRow from '../../components/ui/InfoRow';
import ListCard from '../../components/ui/ListCard';
import { ViewAction, RowActions } from '../../components/ui/RowActions';
import { FaCar, FaMotorcycle, FaArrowLeft, FaPen, FaPlus, FaHistory, FaUser, FaPalette, FaCog, FaBarcode, FaCalendarAlt, FaIdCard, FaPhone, FaEnvelope, FaMapMarkerAlt, FaWhatsapp, FaStickyNote, FaTools, FaCalendarDay, FaHashtag, FaInfoCircle, FaMoneyBillWave } from 'react-icons/fa';

function formatRp(n) { return `Rp${Number(n || 0).toLocaleString('id-ID')}`; }
function fmtDate(d) { return d ? new Date(d).toLocaleDateString('id-ID', { day: 'numeric', month: 'long', year: 'numeric' }) : '-'; }

// Peta warna umum agar badge "Warna" punya titik warna; selain itu memakai abu-abu.
const COLOR_MAP = {
  merah: '#dc2626', biru: '#2563eb', hitam: '#111827', putih: '#e5e7eb', silver: '#9ca3af',
  abu: '#6b7280', 'abu-abu': '#6b7280', hijau: '#16a34a', kuning: '#eab308', orange: '#f97316',
  oranye: '#f97316', coklat: '#92400e', cokelat: '#92400e', ungu: '#7c3aed', pink: '#ec4899', emas: '#ca8a04',
};

const lbl = (Icon, text) => (
  <span className="flex items-center gap-2"><Icon className="text-brand-500" aria-hidden /> {text}</span>
);

export default function VehicleDetail() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [vehicle, setVehicle] = useState(null);
  const [loading, setLoading] = useState(true);
  const svcPg = usePagination(vehicle?.services || [], 10);

  useEffect(() => {
    setLoading(true);
    api.get(`/vehicles/${id}`).then(({ data }) => setVehicle(data)).finally(() => setLoading(false));
  }, [id]);

  if (loading) return <Spinner />;
  if (!vehicle) return <p className="text-slate-500">Kendaraan tidak ditemukan.</p>;

  const m = vehicle.vehicleModel;
  const c = vehicle.customer;
  const VehicleIcon = m.wheels === 2 ? FaMotorcycle : FaCar;
  const colorDot = vehicle.color ? COLOR_MAP[vehicle.color.trim().toLowerCase()] || '#94a3b8' : null;
  const initial = (c.name || '?').charAt(0).toUpperCase();

  function openWhatsApp() {
    const digits = (c.phone || '').replace(/[^0-9]/g, '');
    const normalized = digits.startsWith('0') ? `62${digits.slice(1)}` : digits;
    window.open(`https://wa.me/${normalized}`, '_blank');
  }

  return (
    <div className="space-y-5">
      <DetailHeader icon={FaCar} title="Detail Kendaraan" subtitle="Informasi lengkap kendaraan">
        <Link to="/vehicles" className="btn-secondary"><FaArrowLeft aria-hidden /> Kembali</Link>
        <Link to={`/vehicles/${id}/edit`} className="btn-secondary"><FaPen aria-hidden /> Edit</Link>
      </DetailHeader>

      <div className="grid gap-4 lg:grid-cols-2">
        {/* ============ Informasi Kendaraan ============ */}
        <div className="card overflow-hidden animate-fade-up">
          <div className="card-header"><VehicleIcon aria-hidden /><h3>Informasi Kendaraan</h3></div>
          <div className="p-5">
            <div className="flex flex-col items-center rounded-lg bg-slate-50 px-4 py-5 text-center">
              <VehicleIcon className="text-4xl text-slate-700" aria-hidden />
              <h3 className="mt-2 text-lg font-extrabold uppercase text-slate-900">{m.brand} {m.model}</h3>
              <span className="mt-1.5 rounded bg-slate-900 px-2 py-0.5 text-xs font-bold tracking-wide text-white">{vehicle.plateNumber}</span>
              <p className="mt-1.5 text-xs text-slate-500">{m.year} - {m.type} - {m.wheels} Roda</p>
            </div>

            <dl className="info-list mt-4">
              <InfoRow label={lbl(FaPalette, 'Warna')}>
                {vehicle.color ? (
                  <span className="badge bg-slate-100 uppercase text-slate-700">
                    <span className="inline-block h-2.5 w-2.5 rounded-sm border border-slate-300" style={{ backgroundColor: colorDot }} aria-hidden />
                    {vehicle.color}
                  </span>
                ) : '-'}
              </InfoRow>
              <InfoRow label={lbl(FaCog, 'Jumlah Roda')}><span className="badge bg-slate-500 text-white">{m.wheels} Roda</span></InfoRow>
              <InfoRow label={lbl(FaIdCard, 'Nomor Plat')}>{vehicle.plateNumber}</InfoRow>
              <InfoRow label={lbl(FaBarcode, 'Nomor Rangka (VIN)')}>{vehicle.vin || '-'}</InfoRow>
              <InfoRow label={lbl(FaCog, 'Nomor Mesin')}>{vehicle.engineNumber || '-'}</InfoRow>
              <InfoRow label={lbl(FaCalendarDay, 'Tahun Pembelian')}>{vehicle.purchaseYear || '-'}</InfoRow>
              <InfoRow label={lbl(FaCalendarAlt, 'Tanggal Pendaftaran')}>{fmtDate(vehicle.createdAt)}</InfoRow>
              <InfoRow label={lbl(FaCalendarAlt, 'Terakhir Diperbarui')}>{fmtDate(vehicle.updatedAt)}</InfoRow>
              <InfoRow label={lbl(FaStickyNote, 'Catatan')}>{vehicle.note || '-'}</InfoRow>
            </dl>
          </div>
        </div>

        {/* ============ Informasi Pemilik ============ */}
        <div className="card overflow-hidden animate-fade-up self-start">
          <div className="card-header"><FaUser aria-hidden /><h3>Informasi Pemilik</h3></div>
          <div className="p-5">
            <div className="flex items-center gap-3">
              <span className="flex h-12 w-12 items-center justify-center rounded-full bg-gradient-to-br from-brand-500 to-sky-500 text-lg font-bold text-white">{initial}</span>
              <div>
                <div className="font-semibold text-slate-900">{c.name}</div>
                <div className="text-xs text-slate-500">ID: #{c.id}</div>
              </div>
            </div>

            <dl className="info-list mt-4">
              <InfoRow label={lbl(FaPhone, 'Telepon')}>
                <div className="flex items-center justify-end gap-2">
                  <span>{c.phone}</span>
                  <button type="button" onClick={openWhatsApp}
                    className="inline-flex items-center gap-1 rounded border border-brand-200 px-2 py-0.5 text-xs font-semibold text-brand-600 hover:bg-brand-50">
                    <FaWhatsapp className="text-[10px]" aria-hidden /> Hubungi
                  </button>
                </div>
              </InfoRow>
              <InfoRow label={lbl(FaEnvelope, 'Email')}>{c.email || '-'}</InfoRow>
              <InfoRow label={lbl(FaMapMarkerAlt, 'Alamat')}>{c.address || '-'}</InfoRow>
            </dl>

            <div className="mt-4">
              <Link to={`/customers/${c.id}`} className="btn-secondary"><FaUser aria-hidden /> Lihat Profil Pelanggan</Link>
            </div>
          </div>
        </div>
      </div>

      {/* ============ Riwayat Service ============ */}
      <ListCard
        title="Riwayat Service"
        icon={FaHistory}
        right={
          <button type="button" className="text-xs font-semibold text-white/90 hover:text-white hover:underline"
            onClick={() => navigate(`/services/new?newFor=${vehicle.customerId}&vehicleId=${vehicle.id}`)}>
            <FaPlus className="mr-1 inline text-[10px]" aria-hidden /> Tambah Service
          </button>
        }
      >
        {vehicle.services.length === 0 ? (
          <EmptyState text="Belum ada riwayat service." />
        ) : (
          <table className="table-base">
            <thead>
              <tr>
                <th className="col-no"><FaHashtag className="mr-1 inline text-[10px]" aria-hidden /> No</th>
                <th><FaCalendarAlt className="mr-1 inline text-[10px]" aria-hidden /> Tanggal Service</th>
                <th><FaTools className="mr-1 inline text-[10px]" aria-hidden /> Jenis Service</th>
                <th><FaUser className="mr-1 inline text-[10px]" aria-hidden /> Teknisi</th>
                <th><FaInfoCircle className="mr-1 inline text-[10px]" aria-hidden /> Status</th>
                <th className="num"><FaMoneyBillWave className="mr-1 inline text-[10px]" aria-hidden /> Biaya</th>
                <th className="col-actions"><FaCog className="mr-1 inline text-[10px]" aria-hidden /> Aksi</th>
              </tr>
            </thead>
            <tbody>
              {svcPg.pageItems.map((s, rowNo) => (
                <tr key={s.id}>
                  <td className="col-no">{svcPg.start + rowNo + 1}</td>
                  <td>{new Date(s.date).toLocaleDateString('id-ID')}</td>
                  <td>{s.details.map((d) => d.name).join(', ') || '-'}</td>
                  <td>{s.technician?.name || '-'}</td>
                  <td><StatusBadge status={s.status} /></td>
                  <td className="num">{formatRp(s.total)}</td>
                  <td className="col-actions">
                    <RowActions><ViewAction to={`/services/${s.id}`} label="Lihat detail service" /></RowActions>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
        <Pagination pg={svcPg} />
      </ListCard>
    </div>
  );
}
