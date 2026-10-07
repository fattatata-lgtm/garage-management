import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import api from '../../api/axios';
import Spinner from '../../components/ui/Spinner';
import EmptyState from '../../components/ui/EmptyState';
import PageHeader from '../../components/ui/PageHeader';
import ListCard from '../../components/ui/ListCard';
import usePagination from '../../hooks/usePagination';
import Pagination from '../../components/ui/Pagination';
import { FaSearch, FaPlus, FaUsers, FaCar, FaCog, FaEnvelope, FaHashtag, FaMapMarkerAlt, FaPhone, FaUser } from 'react-icons/fa';
import { DeleteAction, EditAction, RowActions, ViewAction } from '../../components/ui/RowActions';
import SearchInput from '../../components/ui/SearchInput';
import FilterField from '../../components/ui/FilterField';

// Normalisasi nomor HP ke format internasional (62xxx) untuk link WhatsApp
function toWaNumber(phone) {
  const digits = String(phone || '').replace(/[^0-9]/g, '');
  if (!digits) return '';
  return digits.startsWith('0') ? `62${digits.slice(1)}` : digits;
}

// Ambil inisial dari nama (maks 2 huruf)
function getInitials(name) {
  const parts = String(name || '').trim().split(/\s+/).filter(Boolean);
  if (parts.length === 0) return '?';
  if (parts.length === 1) return parts[0][0].toUpperCase();
  return (parts[0][0] + parts[parts.length - 1][0]).toUpperCase();
}

// Warna avatar disamakan untuk semua pelanggan
const AVATAR_COLOR = 'bg-brand-500'; // ganti sesuai tema (mis. bg-blue-500, bg-emerald-500)

function CustomerAvatar({ name, size = 'md' }) {
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

export default function CustomerList() {
  const [customers, setCustomers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [q, setQ] = useState('');

  function load(query = '') {
    setLoading(true);
    api.get(`/customers${query ? `?q=${encodeURIComponent(query)}` : ''}`)
      .then(({ data }) => setCustomers(data))
      .finally(() => setLoading(false));
  }

  const pg = usePagination(customers, 10, q);
  useEffect(() => {
    const t = setTimeout(() => load(q), q ? 350 : 0);
    return () => clearTimeout(t);
  }, [q]);

  async function handleDelete(c) {
    if (!confirm(`Hapus pelanggan "${c.name}"?`)) return;
    try { await api.delete(`/customers/${c.id}`); load(q); }
    catch (err) { alert(err?.response?.data?.message || 'Gagal menghapus pelanggan.'); }
  }

  return (
    <div className="space-y-4">
      <PageHeader icon={FaUsers} title="Data Pelanggan" subtitle="Kelola data pelanggan bengkel">
        <Link to="/customers/new" className="btn-primary"><FaPlus aria-hidden /> Tambah Pelanggan</Link>
      </PageHeader>

      <div className="filter-bar">
        <FilterField label="Pencarian" icon={FaSearch} className="w-full sm:w-80">
          <SearchInput placeholder="Cari nama / no. HP / email..." value={q} onChange={setQ} />
        </FilterField>
      </div>

      <ListCard title="Daftar Pelanggan">
        {loading ? <Spinner /> : customers.length === 0 ? <EmptyState /> : (
          <table className="table-base">
            <thead>
              <tr>
                <th className="col-no"><FaHashtag className="mr-1 inline text-[10px]" aria-hidden /> No</th>
                <th><FaUser className="mr-1 inline text-[10px]" aria-hidden /> Nama</th>
                <th><FaPhone className="mr-1 inline text-[10px]" aria-hidden /> No. HP</th>
                <th><FaEnvelope className="mr-1 inline text-[10px]" aria-hidden /> Email</th>
                <th><FaMapMarkerAlt className="mr-1 inline text-[10px]" aria-hidden /> Alamat</th>
                <th><FaCar className="mr-1 inline text-[10px]" aria-hidden /> Kendaraan</th>
                <th className="col-actions"><FaCog className="mr-1 inline text-[10px]" aria-hidden /> Aksi</th>
              </tr>
            </thead>
            <tbody>
              {pg.pageItems.map((c, rowNo) => (
                <tr key={c.id}>
                  <td className="col-no">{pg.start + rowNo + 1}</td>
                  <td>
                    <Link to={`/customers/${c.id}`} className="cell-link inline-flex items-center gap-2">
                      <CustomerAvatar name={c.name} />
                      <span>{c.name}</span>
                    </Link>
                  </td>
                  <td>
                    {c.phone ? (
                      <a
                        href={`https://wa.me/${toWaNumber(c.phone)}`}
                        target="_blank"
                        rel="noopener noreferrer"
                        className="font-medium text-brand-600 hover:text-brand-700 hover:underline"
                        title="Hubungi via WhatsApp"
                      >
                        {c.phone}
                      </a>
                    ) : '-'}
                  </td>
                  <td>{c.email || '-'}</td>
                  <td>{c.address || '-'}</td>
                  <td>{c._count?.vehicles ?? 0} unit</td>
                  <td className="col-actions">
                    <RowActions>
                      <ViewAction to={`/customers/${c.id}`} />
                      <EditAction to={`/customers/${c.id}/edit`} />
                      <DeleteAction onClick={() => handleDelete(c)} />
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