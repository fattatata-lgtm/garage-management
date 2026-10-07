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
import { FaPlus, FaTags, FaBarcode, FaBullseye, FaCog, FaHashtag, FaInfoCircle, FaPercent, FaTag } from 'react-icons/fa';
import { DeleteAction, EditAction, RowActions } from '../../components/ui/RowActions';

function formatRp(n) { return `Rp${Number(n || 0).toLocaleString('id-ID')}`; }

// Admin > Diskon (/admin/discounts)
export default function DiscountList() {
  const [items, setItems] = useState([]);
  const [loading, setLoading] = useState(true);

  function load() {
    setLoading(true);
    api.get('/discounts').then(({ data }) => setItems(data)).finally(() => setLoading(false));
  }
  const pg = usePagination(items, 10, '');
  useEffect(() => { load(); }, []);

  async function handleDelete(d) {
    if (!confirm(`Hapus diskon ${d.name}?`)) return;
    try { await api.delete(`/discounts/${d.id}`); load(); }
    catch (err) { alert(err?.response?.data?.message || 'Gagal menghapus (diskon mungkin sudah dipakai transaksi).'); }
  }

  return (
    <div className="space-y-4">
      <PageHeader icon={FaTags} title="Data Diskon" subtitle="Kelola data diskon dan promo">
        <Link to="/admin/discounts/new" className="btn-primary"><FaPlus aria-hidden /> Tambah Diskon</Link>
      </PageHeader>

      <ListCard title="Daftar Diskon">
        {loading ? <Spinner /> : items.length === 0 ? <EmptyState text="Belum ada diskon." /> : (
          <table className="table-base">
            <thead><tr><th className="col-no"><FaHashtag className="mr-1 inline text-[10px]" aria-hidden /> No</th><th><FaTag className="mr-1 inline text-[10px]" aria-hidden /> Nama</th><th><FaBarcode className="mr-1 inline text-[10px]" aria-hidden /> Kode</th><th><FaTag className="mr-1 inline text-[10px]" aria-hidden /> Tipe</th><th className="num"><FaPercent className="mr-1 inline text-[10px]" aria-hidden /> Nilai</th><th><FaBullseye className="mr-1 inline text-[10px]" aria-hidden /> Berlaku Untuk</th><th><FaInfoCircle className="mr-1 inline text-[10px]" aria-hidden /> Status</th><th className="col-actions"><FaCog className="mr-1 inline text-[10px]" aria-hidden /> Aksi</th></tr></thead>
            <tbody>
              {pg.pageItems.map((d, rowNo) => (
                <tr key={d.id}><td className="col-no">{pg.start + rowNo + 1}</td>
                  <td>{d.name}</td><td>{d.code || '-'}</td><td>{d.type === 'PERCENTAGE' ? 'Persentase' : 'Nominal'}</td>
                  <td className="num">{d.type === 'PERCENTAGE' ? `${Number(d.value)}%` : formatRp(d.value)}</td>
                  <td>{d.scope}</td><td><StatusBadge status={d.status} /></td>
                  <td className="col-actions"><RowActions><EditAction to={`/admin/discounts/${d.id}/edit`} />
                    <DeleteAction onClick={() => handleDelete(d)} /></RowActions></td>
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
