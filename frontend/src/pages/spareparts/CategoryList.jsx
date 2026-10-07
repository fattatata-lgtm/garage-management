import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import api from '../../api/axios';
import Spinner from '../../components/ui/Spinner';
import EmptyState from '../../components/ui/EmptyState';
import PageHeader from '../../components/ui/PageHeader';
import ListCard from '../../components/ui/ListCard';
import usePagination from '../../hooks/usePagination';
import Pagination from '../../components/ui/Pagination';
import { FaPlus, FaTags, FaBoxes, FaCog, FaHashtag, FaLayerGroup, FaCalendarPlus, FaCalendarCheck } from 'react-icons/fa';
import { DeleteAction, EditAction, RowActions } from '../../components/ui/RowActions';

// Format tanggal + jam ke format Indonesia
function formatDateTime(dateString) {
  if (!dateString) return '-';
  const date = new Date(dateString);
  const tanggal = date.toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' });
  const jam = date.toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit', hour12: false });
  return `${tanggal}, ${jam}`;
}

export default function CategoryList() {
  const [categories, setCategories] = useState([]);
  const [loading, setLoading] = useState(true);

  function load() {
    setLoading(true);
    api.get('/categories').then(({ data }) => setCategories(data)).finally(() => setLoading(false));
  }
  const pg = usePagination(categories, 10, '');
  useEffect(() => { load(); }, []);

  async function handleDelete(c) {
    if (!confirm(`Hapus kategori ${c.name}?`)) return;
    try { await api.delete(`/categories/${c.id}`); load(); }
    catch (err) { alert(err?.response?.data?.message || 'Gagal menghapus (kategori mungkin masih dipakai).'); }
  }

  return (
    <div className="space-y-4">
      <PageHeader icon={FaTags} title="Kategori Sparepart" subtitle="Kelola data kategori sparepart">
        <Link to="/spareparts/categories/new" className="btn-primary"><FaPlus aria-hidden /> Tambah Kategori</Link>
      </PageHeader>

      <ListCard title="Daftar Kategori">
        {loading ? <Spinner /> : categories.length === 0 ? <EmptyState /> : (
          <table className="table-base">
            <thead><tr><th className="col-no"><FaHashtag className="mr-1 inline text-[10px]" aria-hidden /> No</th><th><FaLayerGroup className="mr-1 inline text-[10px]" aria-hidden /> Nama Kategori</th><th className="num"><FaBoxes className="mr-1 inline text-[10px]" aria-hidden /> Jumlah Sparepart</th><th><FaCalendarPlus className="mr-1 inline text-[10px]" aria-hidden /> Dibuat pada</th><th><FaCalendarCheck className="mr-1 inline text-[10px]" aria-hidden /> Diperbarui pada</th><th className="col-actions"><FaCog className="mr-1 inline text-[10px]" aria-hidden /> Aksi</th></tr></thead>
            <tbody>
              {pg.pageItems.map((c, rowNo) => (
                <tr key={c.id}><td className="col-no">{pg.start + rowNo + 1}</td>
                  <td>{c.name}</td><td className="num">{c._count?.spareparts ?? 0}</td>
                  <td className="whitespace-nowrap">{formatDateTime(c.createdAt)}</td>
                  <td className="whitespace-nowrap">{formatDateTime(c.updatedAt)}</td>
                  <td className="col-actions"><RowActions><EditAction to={`/spareparts/categories/${c.id}/edit`} />
                    <DeleteAction onClick={() => handleDelete(c)} /></RowActions></td>
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
