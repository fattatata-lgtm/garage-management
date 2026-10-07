import React, { useEffect, useState } from 'react';
import { useParams, Link, useNavigate } from 'react-router-dom';
import api from '../../api/axios';
import Spinner from '../../components/ui/Spinner';
import usePagination from '../../hooks/usePagination';
import Pagination from '../../components/ui/Pagination';
import EmptyState from '../../components/ui/EmptyState';
import StatusBadge from '../../components/ui/StatusBadge';
import DetailHeader from '../../components/ui/DetailHeader';
import SectionTitle from '../../components/ui/SectionTitle';
import InfoRow from '../../components/ui/InfoRow';
import ListCard from '../../components/ui/ListCard';
import { ViewAction, DeleteAction, RowActions } from '../../components/ui/RowActions';
import { FaUser, FaCar, FaHistory, FaPhone, FaEnvelope, FaMapMarkerAlt, FaCalendarAlt, FaPlus, FaTools, FaShoppingCart, FaPen, FaMotorcycle, FaTag, FaCalendarDay, FaWhatsapp, FaArrowLeft, FaCog, FaHashtag, FaInfoCircle, FaMoneyBillWave } from 'react-icons/fa';

function formatRp(n) { return `Rp${Number(n || 0).toLocaleString('id-ID')}`; }
function fmtDate(d) { return d ? new Date(d).toLocaleDateString('id-ID', { day: 'numeric', month: 'short', year: 'numeric' }) : '-'; }
function fmtDateTime(d) { return d ? new Date(d).toLocaleString('id-ID', { day: 'numeric', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' }) : '-'; }

export default function CustomerDetail() {
  const { id } = useParams();
  const navigate = useNavigate();
  const [customer, setCustomer] = useState(null);
  const [loading, setLoading] = useState(true);
  const svcPg = usePagination(customer?.serviceHistory || [], 10);
  const vehPg = usePagination(customer?.vehicles || [], 10);

  useEffect(() => {
    setLoading(true);
    api.get(`/customers/${id}`)
      .then(({ data }) => setCustomer(data))
      .finally(() => setLoading(false));
  }, [id]);

  if (loading) return <Spinner />;
  if (!customer) return <p className="text-slate-500">Pelanggan tidak ditemukan.</p>;

  const initial = (customer.name || '?').charAt(0).toUpperCase();

  return (
    <div className="space-y-5">
      {/* Header halaman — konsisten dengan halaman detail lain */}
      <DetailHeader
        icon={FaUser}
        title="Detail Pelanggan"
        subtitle={customer.name}
      >
        <Link to="/customers" className="btn-secondary">
          <FaArrowLeft aria-hidden /> Kembali
        </Link>
        <Link to={`/customers/${id}/edit`} className="btn-secondary">
          <FaPen aria-hidden /> Edit
        </Link>
      </DetailHeader>

      <div className="grid gap-4 lg:grid-cols-3">
        {/* ================= Kolom Kiri: Informasi Pelanggan ================= */}
        <div className="lg:col-span-1 space-y-4">
          <div className="card overflow-hidden animate-fade-up">
            <div className="card-header">
              <FaUser aria-hidden />
              <h3>Informasi Pelanggan</h3>
            </div>

            <div className="p-5">
              {/* Avatar + nama + sejak */}
              <div className="flex flex-col items-center text-center">
                <span className="flex h-24 w-24 items-center justify-center rounded-full bg-gradient-to-br from-brand-500 to-sky-500 text-4xl font-bold text-white shadow-lg shadow-brand-500/30">
                  {initial}
                </span>
                <h3 className="mt-3 text-xl font-extrabold text-slate-900">{customer.name}</h3>
                <p className="mt-0.5 flex items-center gap-1.5 text-xs text-slate-500">
                  <FaCalendarAlt className="text-[10px]" aria-hidden />
                  Pelanggan sejak {fmtDate(customer.createdAt)}
                </p>
              </div>

              {/* Detail info — pakai InfoRow agar konsisten */}
              <dl className="info-list mt-6">
                <InfoRow label={<span className="flex items-center gap-2"><FaPhone className="text-brand-500" aria-hidden /> No. HP</span>}>
                  <div className="flex items-center justify-end gap-2">
                    <span>{customer.phone}</span>
                    <button
                      type="button"
                      onClick={() => {
                        const digits = customer.phone.replace(/[^0-9]/g, '');
                        const normalized = digits.startsWith('0') ? `62${digits.slice(1)}` : digits;
                        window.open(`https://wa.me/${normalized}`, '_blank');
                      }}
                      className="inline-flex items-center gap-1 rounded border border-brand-200 px-2 py-0.5 text-xs font-semibold text-brand-600 hover:bg-brand-50"
                    >
                      <FaWhatsapp className="text-[10px]" aria-hidden /> Hubungi
                    </button>
                  </div>
                </InfoRow>

                <InfoRow label={<span className="flex items-center gap-2"><FaEnvelope className="text-brand-500" aria-hidden /> Email</span>}>
                  {customer.email || <span className="text-slate-400">— Tidak ada</span>}
                </InfoRow>

                <InfoRow label={<span className="flex items-center gap-2"><FaMapMarkerAlt className="text-brand-500" aria-hidden /> Alamat</span>}>
                  {customer.address || <span className="text-slate-400">— Tidak ada</span>}
                </InfoRow>

                <InfoRow label={<span className="flex items-center gap-2"><FaCalendarAlt className="text-brand-500" aria-hidden /> Terdaftar</span>}>
                  {fmtDateTime(customer.createdAt)}
                </InfoRow>
              </dl>

              {/* Tombol aksi cepat */}
              <div className="mt-6 space-y-2">
                <button
                  onClick={() => navigate(`/vehicles/new?addFor=${customer.id}`)}
                  className="btn-secondary w-full"
                >
                  <FaCar aria-hidden /> Tambah Kendaraan
                </button>
                <button
                  onClick={() => navigate(`/services/new?newFor=${customer.id}`)}
                  className="btn w-full border border-emerald-300 bg-white text-emerald-700 shadow-sm hover:bg-emerald-50"
                >
                  <FaTools aria-hidden /> Buat Service
                </button>
                <button
                  onClick={() => navigate(`/sales/new?newFor=${customer.id}`)}
                  className="btn w-full border border-brand-300 bg-white text-brand-700 shadow-sm hover:bg-brand-50"
                >
                  <FaShoppingCart aria-hidden /> Buat Penjualan
                </button>
              </div>
            </div>
          </div>
        </div>

        {/* ================= Kolom Kanan: Kendaraan & Riwayat ================= */}
        <div className="lg:col-span-2 space-y-4">
          {/* Daftar Kendaraan */}
          <ListCard
            title="Daftar Kendaraan"
            icon={FaCar}
            right={
              <Link
                to={`/vehicles/new?addFor=${customer.id}`}
                className="text-xs font-semibold text-white/90 hover:text-white hover:underline"
              >
                <FaPlus className="mr-1 inline text-[10px]" aria-hidden /> Tambah Kendaraan
              </Link>
            }
          >
            {customer.vehicles.length === 0 ? (
              <EmptyState text="Pelanggan ini belum memiliki kendaraan." />
            ) : (
              <table className="table-base">
                <thead>
                  <tr>
                    <th className="col-no"><FaHashtag className="mr-1 inline text-[10px]" aria-hidden /> No</th>
                    <th><FaTag className="mr-1 inline text-[10px]" aria-hidden /> No. Polisi</th>
                    <th><FaMotorcycle className="mr-1 inline text-[10px]" aria-hidden /> Merk</th>
                    <th><FaCar className="mr-1 inline text-[10px]" aria-hidden /> Model</th>
                    <th><FaCalendarDay className="mr-1 inline text-[10px]" aria-hidden /> Tahun</th>
                    <th className="col-actions"><FaCog className="mr-1 inline text-[10px]" aria-hidden /> Aksi</th>
                  </tr>
                </thead>
                <tbody>
                  {vehPg.pageItems.map((v, rowNo) => (
                    <tr key={v.id}>
                      <td className="col-no">{vehPg.start + rowNo + 1}</td>
                      <td><Link to={`/vehicles/${v.id}`} className="cell-link">{v.plateNumber}</Link></td>
                      <td>{v.vehicleModel.brand}</td>
                      <td>{v.vehicleModel.model}</td>
                      <td>{v.vehicleModel.year}</td>
                      <td className="col-actions">
                        <RowActions>
                          <ViewAction to={`/vehicles/${v.id}`} label="Lihat detail kendaraan" />
                        </RowActions>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
            <Pagination pg={vehPg} />
          </ListCard>

          {/* Riwayat Service */}
          <ListCard title="Riwayat Service" icon={FaHistory}>
            {customer.serviceHistory.length === 0 ? (
              <EmptyState text="Belum ada riwayat service." />
            ) : (
              <table className="table-base">
                <thead>
                  <tr>
                    <th className="col-no"><FaHashtag className="mr-1 inline text-[10px]" aria-hidden /> No</th>
                    <th><FaCalendarAlt className="mr-1 inline text-[10px]" aria-hidden /> Tanggal</th>
                    <th><FaCar className="mr-1 inline text-[10px]" aria-hidden /> Kendaraan</th>
                    <th><FaTools className="mr-1 inline text-[10px]" aria-hidden /> Jenis / Jasa</th>
                    <th><FaInfoCircle className="mr-1 inline text-[10px]" aria-hidden /> Status</th>
                    <th className="num"><FaMoneyBillWave className="mr-1 inline text-[10px]" aria-hidden /> Biaya</th>
                    <th className="col-actions"><FaCog className="mr-1 inline text-[10px]" aria-hidden /> Aksi</th>
                  </tr>
                </thead>
                <tbody>
                  {svcPg.pageItems.map((s, rowNo) => {
                    const vehicleLabel = `${s.vehicle.vehicleModel?.brand || ''} ${s.vehicle.vehicleModel?.model || ''}`.trim();
                    const jenis = (s.details || []).map((d) => d.name).join(', ') || '—';
                    return (
                      <tr key={s.id}>
                        <td className="col-no">{svcPg.start + rowNo + 1}</td>
                        <td>{fmtDate(s.date)}</td>
                        <td>
                          <div className="font-semibold text-slate-800">{vehicleLabel || '—'}</div>
                          <div className="mt-0.5 flex items-center gap-1 text-xs text-slate-500">
                            <FaTag className="text-[9px]" aria-hidden /> {s.vehicle.plateNumber}
                          </div>
                        </td>
                        <td>{jenis}</td>
                        <td><StatusBadge status={s.status} /></td>
                        <td className="num font-semibold text-slate-900">{formatRp(s.total)}</td>
                        <td className="col-actions">
                          <RowActions>
                            <ViewAction to={`/services/${s.id}`} label="Lihat detail service" />
                          </RowActions>
                        </td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            )}
            <Pagination pg={svcPg} />
          </ListCard>
        </div>
      </div>
    </div>
  );
}