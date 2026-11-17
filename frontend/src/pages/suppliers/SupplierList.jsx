import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import api from '../../api/axios';
import Spinner from '../../components/ui/Spinner';
import EmptyState from '../../components/ui/EmptyState';
import PageHeader from '../../components/ui/PageHeader';
import ListCard from '../../components/ui/ListCard';
import usePagination from '../../hooks/usePagination';
import Pagination from '../../components/ui/Pagination';
import SearchInput from '../../components/ui/SearchInput';
import FilterField from '../../components/ui/FilterField';
import { FaPlus, FaTruck, FaBoxes, FaCog, FaHashtag, FaSearch, FaUser, FaPhone, FaMapMarkerAlt, FaBuilding } from 'react-icons/fa';
import { DeleteAction, EditAction, RowActions } from '../../components/ui/RowActions';

// Data Supplier sparepart
export default function SupplierList() {
  const [suppliers, setSuppliers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [q, setQ] = useState('');

  function load() {
    setLoading(true);
    const params = new URLSearchParams();
    if (q) params.set('q', q);
    return api.get(`/suppliers?${params.toString()}`)
      .then(({ data }) => setSuppliers(data))
      .finally(() => setLoading(false));
  }

  const pg = usePagination(suppliers, 10, q);
  useEffect(() => {
    const t = setTimeout(load, q ? 350 : 0);
    return () => clearTimeout(t);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [q]);

  async function handleDelete(s) {
    const used = s._count?.spareparts || 0;
    const msg = used > 0
      ? `Hapus supplier ${s.name}? ${used} sparepart yang memakai supplier ini akan menjadi tanpa supplier.`
      : `Hapus supplier ${s.name}?`;
    if (!confirm(msg)) return;
    try { await api.delete(`/suppliers/${s.id}`); load(); }
    catch (err) { alert(err?.response?.data?.message || 'Gagal menghapus supplier.'); }
  }

  return (
    <div className="space-y-4">
      <PageHeader icon={FaTruck} title="Supplier Sparepart" subtitle="Kelola data pemasok sparepart">
        <Link to="/suppliers/new" className="btn-primary"><FaPlus aria-hidden /> Tambah Supplier</Link>
      </PageHeader>

      <div className="filter-bar">
        <FilterField label="Pencarian" icon={FaSearch} className="w-full sm:w-80">
          <SearchInput placeholder="Cari nama / kontak / telepon..." value={q} onChange={setQ} />
        </FilterField>
      </div>

      <ListCard title="Daftar Supplier">
        {loading ? <Spinner /> : suppliers.length === 0 ? <EmptyState /> : (
          <table className="table-base">
            <thead><tr>
              <th className="col-no"><FaHashtag className="mr-1 inline text-[10px]" aria-hidden /> No</th>
              <th><FaBuilding className="mr-1 inline text-[10px]" aria-hidden /> Nama Supplier</th>
              <th><FaUser className="mr-1 inline text-[10px]" aria-hidden /> Kontak Person</th>
              <th><FaPhone className="mr-1 inline text-[10px]" aria-hidden /> Telepon</th>
              <th><FaMapMarkerAlt className="mr-1 inline text-[10px]" aria-hidden /> Alamat</th>
              <th className="num"><FaBoxes className="mr-1 inline text-[10px]" aria-hidden /> Jumlah Sparepart</th>
              <th className="col-actions"><FaCog className="mr-1 inline text-[10px]" aria-hidden /> Aksi</th>
            </tr></thead>
            <tbody>
              {pg.pageItems.map((s, rowNo) => (
                <tr key={s.id}>
                  <td className="col-no">{pg.start + rowNo + 1}</td>
                  <td>{s.name}</td>
                  <td>{s.contactPerson || '-'}</td>
                  <td className="whitespace-nowrap">{s.phone || '-'}</td>
                  <td>{s.address || '-'}</td>
                  <td className="num">{s._count?.spareparts ?? 0}</td>
                  <td className="col-actions"><RowActions>
                    <EditAction to={`/suppliers/${s.id}/edit`} />
                    <DeleteAction onClick={() => handleDelete(s)} />
                  </RowActions></td>
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
