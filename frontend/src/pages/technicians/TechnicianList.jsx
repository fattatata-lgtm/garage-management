import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import api from '../../api/axios';
import Spinner from '../../components/ui/Spinner';
import EmptyState from '../../components/ui/EmptyState';
import StatusBadge from '../../components/ui/StatusBadge';
import PageHeader from '../../components/ui/PageHeader';
import ListCard from '../../components/ui/ListCard';
import { FaHardHat, FaPlus, FaCog, FaHashtag, FaInfoCircle, FaTools, FaUser, FaWrench, FaCalendarAlt } from 'react-icons/fa';
import { DeleteAction, EditAction, RowActions, ViewAction } from '../../components/ui/RowActions';

// Ambil inisial dari nama (maks 2 huruf)
function getInitials(name) {
  const parts = String(name || '').trim().split(/\s+/).filter(Boolean);
  if (parts.length === 0) return '?';
  if (parts.length === 1) return parts[0][0].toUpperCase();
  return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
}

// Warna avatar disamakan untuk semua teknisi
const AVATAR_COLOR = 'bg-brand-500'; // ganti sesuai tema (mis. bg-blue-500, bg-emerald-500)

function TechnicianAvatar({ name, size = 'md' }) {
  const initials = getInitials(name);
  const sizeCls = size === 'sm' ? 'h-6 w-6 text-[10px]' : 'h-8 w-8 text-xs';
  return (
    <span
      className={`inline-flex ${sizeCls} shrink-0 items-center justify-center rounded-full ${AVATAR_COLOR} font-semibold text-white ring-2 ring-white`}
      aria-hidden
    >
      {initials}
    </span>
  );
}

export default function TechnicianList() {
  const [technicians, setTechnicians] = useState([]);
  const [loading, setLoading] = useState(true);

  function load() {
    setLoading(true);
    api.get('/technicians').then(({ data }) => setTechnicians(data)).finally(() => setLoading(false));
  }
  useEffect(() => { load(); }, []);

  async function handleDelete(t) {
    if (!confirm(`Hapus teknisi ${t.name}?`)) return;
    try { await api.delete(`/technicians/${t.id}`); load(); }
    catch (err) { alert(err?.response?.data?.message || 'Gagal menghapus.'); }
  }

  // Format tanggal + jam "Terdaftar Sejak"
  function formatDateTime(dateStr) {
    if (!dateStr) return '-';
    const d = new Date(dateStr);
    if (isNaN(d.getTime())) return '-';
    const tanggal = d.toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' });
    const jam = d.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' });
    return `${tanggal}, ${jam}`;
  }

  return (
    <div className="space-y-4">
      <PageHeader icon={FaHardHat} title="Data Teknisi" subtitle="Kelola data teknisi bengkel">
        <Link to="/technicians/new" className="btn-primary"><FaPlus aria-hidden /> Tambah Teknisi</Link>
      </PageHeader>

      <ListCard title="Daftar Teknisi">
        {loading ? <Spinner /> : technicians.length === 0 ? <EmptyState /> : (
          <table className="table-base">
            <thead>
              <tr>
                <th className="col-no"><FaHashtag className="mr-1 inline text-[10px]" aria-hidden /> No</th>
                <th><FaUser className="mr-1 inline text-[10px]" aria-hidden /> Nama</th>
                <th><FaWrench className="mr-1 inline text-[10px]" aria-hidden /> Keahlian</th>
                <th><FaInfoCircle className="mr-1 inline text-[10px]" aria-hidden /> Status</th>
                <th><FaCalendarAlt className="mr-1 inline text-[10px]" aria-hidden /> Terdaftar Sejak</th>
                <th className="num"><FaTools className="mr-1 inline text-[10px]" aria-hidden /> Total Service</th>
                <th className="col-actions"><FaCog className="mr-1 inline text-[10px]" aria-hidden /> Aksi</th>
              </tr>
            </thead>
            <tbody>
              {technicians.map((t, rowNo) => (
                <tr key={t.id}>
                  <td className="col-no">{rowNo + 1}</td>
                  <td>
                    <Link to={`/technicians/${t.id}`} className="cell-link inline-flex items-center gap-2">
                      <TechnicianAvatar name={t.name} />
                      <span>{t.name}</span>
                    </Link>
                  </td>
                  <td>{t.skill || '-'}</td>
                  <td><StatusBadge status={t.status} /></td>
                  <td>{formatDateTime(t.createdAt)}</td>
                  <td className="num">{t._count?.services ?? 0}</td>
                  <td className="col-actions">
                    <RowActions>
                      <ViewAction to={`/technicians/${t.id}`} />
                      <EditAction to={`/technicians/${t.id}/edit`} />
                      <DeleteAction onClick={() => handleDelete(t)} />
                    </RowActions>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </ListCard>
    </div>
  );
}