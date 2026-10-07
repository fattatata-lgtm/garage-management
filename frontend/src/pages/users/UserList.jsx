import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import api from '../../api/axios';
import Spinner from '../../components/ui/Spinner';
import EmptyState from '../../components/ui/EmptyState';
import PageHeader from '../../components/ui/PageHeader';
import ListCard from '../../components/ui/ListCard';
import usePagination from '../../hooks/usePagination';
import Pagination from '../../components/ui/Pagination';
import { FaKey, FaPlus, FaCog, FaEnvelope, FaHashtag, FaUserCircle, FaUserShield, FaCalendarAlt } from 'react-icons/fa';
import { DeleteAction, EditAction, RowActions } from '../../components/ui/RowActions';

// Ambil inisial dari username/nama (maks 2 huruf)
function getInitials(name) {
  const parts = String(name || '').trim().split(/[\s._-]+/).filter(Boolean);
  if (parts.length === 0) return '?';
  if (parts.length === 1) return parts[0][0].toUpperCase();
  return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
}

// Format tanggal + jam ke format Indonesia
function formatDateTime(dateString) {
  if (!dateString) return '-';
  const date = new Date(dateString);
  const tanggal = date.toLocaleDateString('id-ID', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
  });
  const jam = date.toLocaleTimeString('id-ID', {
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  });
  return `${tanggal}, ${jam}`;
}

// Cek apakah user adalah admin (case-insensitive)
function isAdmin(user) {
  return String(user?.role || '').toLowerCase() === 'admin';
}

// Warna avatar disamakan untuk semua user
const AVATAR_COLOR = 'bg-brand-500';

function UserAvatar({ name, size = 'md' }) {
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

export default function UserList() {
  const [users, setUsers] = useState([]);
  const [loading, setLoading] = useState(true);

  function load() {
    setLoading(true);
    api.get('/users').then(({ data }) => setUsers(data)).finally(() => setLoading(false));
  }
  const pg = usePagination(users, 10, '');
  useEffect(() => { load(); }, []);

  async function handleDelete(u) {
    if (!confirm(`Hapus user ${u.username}?`)) return;
    try { await api.delete(`/users/${u.id}`); load(); }
    catch (err) { alert(err?.response?.data?.message || 'Gagal menghapus.'); }
  }

  return (
    <div className="space-y-4">
      <PageHeader icon={FaKey} title="Manajemen Pengguna" subtitle="Kelola akun pengguna aplikasi">
        <Link to="/users/new" className="btn-primary"><FaPlus aria-hidden /> Tambah Pengguna</Link>
      </PageHeader>

      <ListCard title="Daftar Pengguna">
        {loading ? <Spinner /> : users.length === 0 ? <EmptyState /> : (
          <table className="table-base">
            <thead>
              <tr>
                <th className="col-no"><FaHashtag className="mr-1 inline text-[10px]" aria-hidden /> No</th>
                <th><FaUserCircle className="mr-1 inline text-[10px]" aria-hidden /> Username</th>
                <th><FaEnvelope className="mr-1 inline text-[10px]" aria-hidden /> Email</th>
                <th><FaUserShield className="mr-1 inline text-[10px]" aria-hidden /> Role</th>
                <th><FaCalendarAlt className="mr-1 inline text-[10px]" aria-hidden /> Terdaftar Sejak</th>
                <th className="col-actions"><FaCog className="mr-1 inline text-[10px]" aria-hidden /> Aksi</th>
              </tr>
            </thead>
            <tbody>
              {pg.pageItems.map((u, rowNo) => (
                <tr key={u.id}>
                  <td className="col-no">{pg.start + rowNo + 1}</td>
                  <td>
                    <span className="inline-flex items-center gap-2 font-medium">
                      <UserAvatar name={u.username} />
                      <span>{u.username}</span>
                    </span>
                  </td>
                  <td>{u.email}</td>
                  <td>{u.role}</td>
                  <td className="whitespace-nowrap">{formatDateTime(u.createdAt)}</td>
                  <td className="col-actions">
                    <RowActions>
                      <EditAction to={`/users/${u.id}/edit`} />
                      {!isAdmin(u) && <DeleteAction onClick={() => handleDelete(u)} />}
                    </RowActions>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
        <Pagination pg={pg} />
      </ListCard>
    </div>
  );
}