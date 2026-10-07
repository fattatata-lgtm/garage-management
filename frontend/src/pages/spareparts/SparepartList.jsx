import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import api from '../../api/axios';
import Spinner from '../../components/ui/Spinner';
import EmptyState from '../../components/ui/EmptyState';
import StatusBadge from '../../components/ui/StatusBadge';
import PageHeader from '../../components/ui/PageHeader';
import ListCard from '../../components/ui/ListCard';
import usePagination from '../../hooks/usePagination';
import Pagination from '../../components/ui/Pagination';
import { FaSearch, FaCogs, FaPlus, FaBarcode, FaBoxes, FaCog, FaHashtag, FaInfoCircle, FaLayerGroup, FaMoneyBillWave, FaUser } from 'react-icons/fa';
import { DeleteAction, EditAction, RowActions } from '../../components/ui/RowActions';
import SearchInput from '../../components/ui/SearchInput';
import FilterField from '../../components/ui/FilterField';

function formatRp(n) { return `Rp${Number(n || 0).toLocaleString('id-ID')}`; }

// Data Sparepart. Kategori: /spareparts/categories, Riwayat Stok: /spareparts/stock-history
export default function SparepartList() {
  const [spareparts, setSpareparts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [q, setQ] = useState('');

  function load(query = '') {
    setLoading(true);
    api.get(`/spareparts${query ? `?q=${encodeURIComponent(query)}` : ''}`)
      .then(({ data }) => setSpareparts(data))
      .finally(() => setLoading(false));
  }

  const pg = usePagination(spareparts, 10, q);
  useEffect(() => {
    const t = setTimeout(() => load(q), q ? 350 : 0);
    return () => clearTimeout(t);
  }, [q]);

  async function handleDelete(sp) {
    if (!confirm(`Hapus sparepart ${sp.name}?`)) return;
    try { await api.delete(`/spareparts/${sp.id}`); load(q); }
    catch (err) { alert(err?.response?.data?.message || 'Gagal menghapus.'); }
  }

  return (
    <div className="space-y-4">
      <PageHeader icon={FaCogs} title="Data Sparepart" subtitle="Kelola data sparepart">
        <Link to="/spareparts/new" className="btn-primary"><FaPlus aria-hidden /> Tambah Sparepart</Link>
      </PageHeader>

      <div className="filter-bar">
        <FilterField label="Pencarian" icon={FaSearch} className="w-full sm:w-80">
          <SearchInput scan placeholder="Cari kode / nama sparepart..." value={q} onChange={setQ} />
        </FilterField>
      </div>

      <ListCard title="Daftar Sparepart">
        {loading ? <Spinner /> : spareparts.length === 0 ? <EmptyState /> : (
          <table className="table-base">
            <thead><tr><th className="col-no"><FaHashtag className="mr-1 inline text-[10px]" aria-hidden /> No</th><th><FaBarcode className="mr-1 inline text-[10px]" aria-hidden /> Kode</th><th><FaUser className="mr-1 inline text-[10px]" aria-hidden /> Nama</th><th><FaLayerGroup className="mr-1 inline text-[10px]" aria-hidden /> Kategori</th><th className="num"><FaMoneyBillWave className="mr-1 inline text-[10px]" aria-hidden /> Harga Beli</th><th className="num"><FaMoneyBillWave className="mr-1 inline text-[10px]" aria-hidden /> Harga Jual</th><th className="num"><FaBoxes className="mr-1 inline text-[10px]" aria-hidden /> Stok</th><th><FaInfoCircle className="mr-1 inline text-[10px]" aria-hidden /> Status</th><th className="col-actions"><FaCog className="mr-1 inline text-[10px]" aria-hidden /> Aksi</th></tr></thead>
            <tbody>
              {pg.pageItems.map((sp, rowNo) => (
                <tr key={sp.id}><td className="col-no">{pg.start + rowNo + 1}</td>
                  <td>{sp.code}</td><td>{sp.name}</td><td>{sp.category.name}</td>
                  <td className="num">{formatRp(sp.buyPrice)}</td><td className="num">{formatRp(sp.sellPrice)}</td><td className="num">{sp.stock}</td>
                  <td><StatusBadge status={sp.status} /></td>
                  <td className="col-actions"><RowActions>
                    <EditAction to={`/spareparts/${sp.id}/edit`} />
                    <DeleteAction onClick={() => handleDelete(sp)} /></RowActions></td>
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