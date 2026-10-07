import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import api from '../../api/axios';
import Spinner from '../../components/ui/Spinner';
import EmptyState from '../../components/ui/EmptyState';
import PageHeader from '../../components/ui/PageHeader';
import ListCard from '../../components/ui/ListCard';
import usePagination from '../../hooks/usePagination';
import Pagination from '../../components/ui/Pagination';
import { FaClipboardList, FaPlus, FaAlignLeft, FaCog, FaHashtag, FaMoneyBillWave, FaTools } from 'react-icons/fa';
import { DeleteAction, EditAction, RowActions } from '../../components/ui/RowActions';

function formatRp(n) { return `Rp${Number(n || 0).toLocaleString('id-ID')}`; }

// Jenis Layanan (dulu "Jenis Service" di menu Admin), sekarang di dropdown Layanan
export default function ServiceTypeList() {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);

  function load() {
    setLoading(true);
    api.get('/service-types').then(({ data }) => setItems(data)).finally(() => setLoading(false));
  }
  const pg = usePagination(items, 10, '');
  useEffect(() => { load(); }, []);

  async function handleDelete(t) {
    if (!confirm(`Hapus jenis layanan ${t.name}?`)) return;
    try { await api.delete(`/service-types/${t.id}`); load(); }
    catch (err) { alert(err?.response?.data?.message || 'Gagal menghapus.'); }
  }

  return (
    <div className="space-y-4">
      <PageHeader icon={FaClipboardList} title="Jenis Layanan" subtitle="Kelola data jenis layanan service">
        <Link to="/service-types/new" className="btn-primary"><FaPlus aria-hidden /> Tambah Jenis</Link>
      </PageHeader>

      <ListCard title="Daftar Jenis Layanan">
        {loading ? <Spinner /> : items.length === 0 ? <EmptyState /> : (
          <table className="table-base">
            <thead><tr><th className="col-no"><FaHashtag className="mr-1 inline text-[10px]" aria-hidden /> No</th><th><FaTools className="mr-1 inline text-[10px]" aria-hidden /> Nama</th><th><FaAlignLeft className="mr-1 inline text-[10px]" aria-hidden /> Deskripsi</th><th className="num"><FaMoneyBillWave className="mr-1 inline text-[10px]" aria-hidden /> Estimasi Biaya</th><th className="col-actions"><FaCog className="mr-1 inline text-[10px]" aria-hidden /> Aksi</th></tr></thead>
            <tbody>
              {pg.pageItems.map((t, rowNo) => (
                <tr key={t.id}><td className="col-no">{pg.start + rowNo + 1}</td>
                  <td>{t.name}</td><td>{t.description || '-'}</td><td className="num">{formatRp(t.estimatedCost)}</td>
                  <td className="col-actions"><RowActions><EditAction to={`/service-types/${t.id}/edit`} />
                    <DeleteAction onClick={() => handleDelete(t)} /></RowActions></td>
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
