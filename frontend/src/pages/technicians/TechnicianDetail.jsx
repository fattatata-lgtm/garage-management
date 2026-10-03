import React, { useEffect, useState } from 'react';
import { useParams, Link } from 'react-router-dom';
import api from '../../api/axios';
import Spinner from '../../components/ui/Spinner';
import usePagination from '../../hooks/usePagination';
import Pagination from '../../components/ui/Pagination';
import EmptyState from '../../components/ui/EmptyState';
import StatusBadge from '../../components/ui/StatusBadge';
import DetailHeader from '../../components/ui/DetailHeader';
import InfoRow from '../../components/ui/InfoRow';
import ListCard from '../../components/ui/ListCard';
import { ViewAction, EditAction, DeleteAction, RowActions } from '../../components/ui/RowActions';
import {
  FaUserCog, FaArrowLeft, FaPen, FaIdCard, FaClock, FaWrench, FaCalendarAlt, FaSyncAlt, FaChartBar,
  FaPlus, FaHashtag, FaClipboardList, FaCog, FaHistory, FaCar, FaTools, FaMoneyBillWave, FaInfoCircle,
} from 'react-icons/fa';

function formatRp(n) { return `Rp${Number(n || 0).toLocaleString('id-ID')}`; }
function fmtDate(d) { return d ? new Date(d).toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' }) : '-'; }
function fmtDateTime(d) { return d ? new Date(d).toLocaleString('id-ID', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' }) : '-'; }

const lbl = (Icon, text) => (
  <span className="flex items-center gap-2"><Icon className="text-brand-500" aria-hidden /> {text}</span>
);
const th = (Icon, text) => (<><Icon className="mr-1 inline text-[10px]" aria-hidden /> {text}</>);

export default function TechnicianDetail() {
  const { id } = useParams();
  const [technician, setTechnician] = useState(null);
  const [loading, setLoading] = useState(true);
  const svcPg = usePagination(technician?.services || [], 10);

  function load() {
    setLoading(true);
    api.get(`/technicians/${id}`).then(({ data }) => setTechnician(data)).finally(() => setLoading(false));
  }
  useEffect(() => { load(); }, [id]);

  async function deleteSchedule(scheduleId) {
    if (!confirm('Hapus jadwal ini?')) return;
    try { await api.delete(`/technicians/${id}/schedules/${scheduleId}`); load(); }
    catch (err) { alert(err?.response?.data?.message || 'Gagal menghapus jadwal.'); }
  }

  if (loading) return <Spinner />;
  if (!technician) return <p className="text-slate-500">Teknisi tidak ditemukan.</p>;

  const initial = (technician.name || '?').charAt(0).toUpperCase();

  return (
    <div className="space-y-5">
      <DetailHeader icon={FaUserCog} title="Detail Teknisi" subtitle={technician.name}>
        <Link to="/technicians" className="btn-secondary"><FaArrowLeft aria-hidden /> Kembali</Link>
        <Link to={`/technicians/${id}/edit`} className="btn-secondary"><FaPen aria-hidden /> Edit</Link>
      </DetailHeader>

      <div className="grid gap-4 lg:grid-cols-3">
        {/* ================= Kolom Kiri: Informasi Teknisi ================= */}
        <div className="lg:col-span-1 space-y-4">
          <div className="card overflow-hidden animate-fade-up">
            <div className="card-header"><FaIdCard aria-hidden /><h3>Informasi Teknisi</h3></div>
            <div className="p-5">
              <div className="flex flex-col items-center text-center">
                <span className="flex h-24 w-24 items-center justify-center rounded-full bg-gradient-to-br from-brand-500 to-sky-500 text-4xl font-bold text-white shadow-lg shadow-brand-500/30">
                  {initial}
                </span>
                <h3 className="mt-3 text-xl font-extrabold text-slate-900">{technician.name}</h3>
                <p className="mt-0.5 flex items-center gap-1.5 text-xs text-slate-500">
                  <FaClock className="text-[10px]" aria-hidden /> Teknisi sejak {fmtDate(technician.createdAt)}
                </p>
                <div className="mt-3"><StatusBadge status={technician.status} /></div>
              </div>

              <dl className="info-list mt-6">
                <InfoRow label={lbl(FaWrench, 'Keahlian')}>{technician.skill || <span className="text-slate-400">— Tidak ada</span>}</InfoRow>
                <InfoRow label={lbl(FaCalendarAlt, 'Terdaftar')}>{fmtDateTime(technician.createdAt)}</InfoRow>
                <InfoRow label={lbl(FaSyncAlt, 'Terakhir Diperbarui')}>{fmtDateTime(technician.updatedAt)}</InfoRow>
              </dl>

              {/* Statistik */}
              <div className="mt-6 rounded-xl bg-slate-50 p-4">
                <div className="mb-3 flex items-center gap-2 text-sm font-semibold text-slate-700">
                  <FaChartBar className="text-brand-500" aria-hidden /> Statistik
                </div>
                <div className="grid grid-cols-2 gap-3 text-center">
                  <div>
                    <span className="mx-auto flex h-11 w-11 items-center justify-center rounded-full bg-cyan-500 text-white"><FaWrench aria-hidden /></span>
                    <div className="mt-1.5 text-xl font-extrabold text-slate-900">{technician.stats.totalService}</div>
                    <div className="text-xs text-slate-500">Total Service</div>
                  </div>
                  <div>
                    <span className="mx-auto flex h-11 w-11 items-center justify-center rounded-full bg-emerald-600 text-white"><FaCalendarAlt aria-hidden /></span>
                    <div className="mt-1.5 text-xl font-extrabold text-slate-900">{technician.stats.totalJadwal}</div>
                    <div className="text-xs text-slate-500">Jadwal</div>
                  </div>
                </div>
              </div>
            </div>
          </div>
        </div>

        {/* ================= Kolom Kanan: Jadwal & Riwayat ================= */}
        <div className="lg:col-span-2 space-y-4">
          <ListCard
            title="Jadwal Teknisi"
            icon={FaCalendarAlt}
            right={
              <Link to={`/technicians/${id}/schedules/new`} className="text-xs font-semibold text-white/90 hover:text-white hover:underline">
                <FaPlus className="mr-1 inline text-[10px]" aria-hidden /> Tambah Jadwal
              </Link>
            }
          >
            {technician.schedules.length === 0 ? (
              <EmptyState text="Belum ada jadwal." />
            ) : (
              <table className="table-base">
                <thead>
                  <tr>
                    <th className="col-no">{th(FaHashtag, 'No')}</th>
                    <th>{th(FaCalendarAlt, 'Tanggal')}</th>
                    <th>{th(FaClipboardList, 'Tugas')}</th>
                    <th className="col-actions">{th(FaCog, 'Aksi')}</th>
                  </tr>
                </thead>
                <tbody>
                  {technician.schedules.map((s, rowNo) => (
                    <tr key={s.id}>
                      <td className="col-no">{rowNo + 1}</td>
                      <td>{fmtDate(s.date)}</td>
                      <td>{s.note || '-'}</td>
                      <td className="col-actions">
                        <RowActions>
                          <EditAction to={`/technicians/${id}/schedules/${s.id}/edit`} label="Edit jadwal" />
                          <DeleteAction onClick={() => deleteSchedule(s.id)} label="Hapus jadwal" />
                        </RowActions>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            )}
          </ListCard>

          <ListCard title="Riwayat Service" icon={FaHistory}>
            {technician.services.length === 0 ? (
              <EmptyState text="Belum ada riwayat service." />
            ) : (
              <table className="table-base">
                <thead>
                  <tr>
                    <th className="col-no">{th(FaHashtag, 'No')}</th>
                    <th>{th(FaCalendarAlt, 'Tanggal')}</th>
                    <th>{th(FaCar, 'Kendaraan')}</th>
                    <th>{th(FaTools, 'Jenis Service')}</th>
                    <th>{th(FaInfoCircle, 'Status')}</th>
                    <th className="num">{th(FaMoneyBillWave, 'Biaya')}</th>
                    <th className="col-actions">{th(FaCog, 'Aksi')}</th>
                  </tr>
                </thead>
                <tbody>
                  {svcPg.pageItems.map((s, rowNo) => {
                    const vm = s.vehicle.vehicleModel;
                    return (
                      <tr key={s.id}>
                        <td className="col-no">{svcPg.start + rowNo + 1}</td>
                        <td>{fmtDate(s.date)}</td>
                        <td>
                          <div className="font-semibold text-slate-800">{s.vehicle.plateNumber}</div>
                          {vm && <div className="mt-0.5 text-xs text-slate-500">{vm.brand} {vm.model} ({vm.year})</div>}
                        </td>
                        <td>
                          {s.details.length === 0 ? '-' : (
                            <div className="flex flex-wrap gap-1">
                              {s.details.map((d) => (
                                <span key={d.id} className="badge bg-brand-600 text-white">{d.name}</span>
                              ))}
                            </div>
                          )}
                        </td>
                        <td><StatusBadge status={s.status} /></td>
                        <td className="num font-semibold text-slate-900">{formatRp(s.total)}</td>
                        <td className="col-actions">
                          <RowActions><ViewAction to={`/services/${s.id}`} label="Lihat detail service" /></RowActions>
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
