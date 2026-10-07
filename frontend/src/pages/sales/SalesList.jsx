import React, { useEffect, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import api from '../../api/axios';
import Spinner from '../../components/ui/Spinner';
import EmptyState from '../../components/ui/EmptyState';
import PageHeader from '../../components/ui/PageHeader';
import ListCard from '../../components/ui/ListCard';
import usePagination from '../../hooks/usePagination';
import Pagination from '../../components/ui/Pagination';
import { useAuth } from '../../context/AuthContext';
import { RowActions, ViewAction, DeleteAction } from '../../components/ui/RowActions';
import { FaCog, FaPlus, FaSearch, FaShoppingCart, FaCalendarAlt, FaFileInvoice, FaHashtag, FaListUl, FaMoneyBillWave, FaUser } from 'react-icons/fa';
import SearchInput from '../../components/ui/SearchInput';
import DateRangeFilter, { applyDateRange, fmtRangeDate } from '../../components/ui/DateRangeFilter';
import FilterField from '../../components/ui/FilterField';

function formatRp(n) { return `Rp${Number(n || 0).toLocaleString('id-ID')}`; }

export default function SalesList() {
  const navigate = useNavigate();
  const { user } = useAuth();
  const isAdmin = user.role === 'ADMIN';
  const [sales, setSales] = useState([]);
  const [loading, setLoading] = useState(true);
  const [q, setQ] = useState('');
  const [from, setFrom] = useState('');
  const [to, setTo] = useState('');

  function load() {
    setLoading(true);
    const params = new URLSearchParams();
    if (q) params.set('q', q);
    applyDateRange(params, from, to);
    api.get(`/sales?${params.toString()}`).then(({ data }) => setSales(data)).finally(() => setLoading(false));
  }
  async function handleDelete(s) {
    if (!confirm(`Hapus transaksi penjualan ${s.invoiceNo}? Stok sparepart yang terjual akan dikembalikan.`)) return;
    try { await api.delete(`/sales/${s.id}`); load(); }
    catch (err) { alert(err?.response?.data?.message || 'Gagal menghapus transaksi.'); }
  }

  const pg = usePagination(sales, 10, [q, from, to].join('|'));
  useEffect(() => { const t = setTimeout(load, 350); return () => clearTimeout(t); }, [q, from, to]);

  return (
    <div className="space-y-4">
      <PageHeader icon={FaShoppingCart} title="Penjualan Sparepart" subtitle="Riwayat penjualan sparepart">
        <button className="btn-primary" onClick={() => navigate('/sales/new')}><FaPlus aria-hidden /> Tambah Penjualan</button>
      </PageHeader>

      <div className="filter-bar">
        <FilterField label="Pencarian" icon={FaSearch} className="w-full sm:w-80">
          <SearchInput placeholder="Cari no. invoice..." value={q} onChange={setQ} />
        </FilterField>
        <DateRangeFilter from={from} to={to} onChange={({ from: f, to: t }) => { setFrom(f); setTo(t); }} />
      </div>

      <ListCard
        title="Daftar Penjualan"
        right={<span className="text-xs font-semibold text-white/80">{(from || to) ? `${fmtRangeDate(from) || 'awal'} – ${fmtRangeDate(to) || 'sekarang'} · ` : ''}{sales.length} transaksi</span>}
      >
        {loading ? <Spinner /> : sales.length === 0 ? <EmptyState text={(from || to) ? 'Tidak ada penjualan pada periode yang dipilih.' : 'Belum ada data.'} /> : (
          <table className="table-base">
            <thead><tr><th className="col-no"><FaHashtag className="mr-1 inline text-[10px]" aria-hidden /> No</th><th><FaFileInvoice className="mr-1 inline text-[10px]" aria-hidden /> No. Invoice</th><th><FaCalendarAlt className="mr-1 inline text-[10px]" aria-hidden /> Tanggal</th><th><FaUser className="mr-1 inline text-[10px]" aria-hidden /> Pelanggan</th><th className="num"><FaListUl className="mr-1 inline text-[10px]" aria-hidden /> Item</th><th className="num"><FaMoneyBillWave className="mr-1 inline text-[10px]" aria-hidden /> Total</th><th className="col-actions"><FaCog className="mr-1 inline text-[10px]" aria-hidden /> Aksi</th></tr></thead>
            <tbody>
              {pg.pageItems.map((s, rowNo) => (
                <tr key={s.id}><td className="col-no">{pg.start + rowNo + 1}</td>
                  <td><Link to={`/sales/${s.id}`} className="cell-link">{s.invoiceNo}</Link></td>
                  <td>{new Date(s.date).toLocaleString('id-ID')}</td>
                  <td>{s.customer ? s.customer.name : (s.walkInName || 'Pelanggan Umum')}</td>
                  <td className="num">{s.items.length}</td>
                  <td className="num">{formatRp(s.total)}</td>
                  <td className="col-actions">
                    <RowActions>
                      <ViewAction to={`/sales/${s.id}`} label="Lihat detail penjualan" />
                      {isAdmin && <DeleteAction onClick={() => handleDelete(s)} label="Hapus penjualan" />}
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
