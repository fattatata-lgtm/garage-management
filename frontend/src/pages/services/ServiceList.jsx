import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import api from '../../api/axios';
import { useAuth } from '../../context/AuthContext';
import Spinner from '../../components/ui/Spinner';
import EmptyState from '../../components/ui/EmptyState';
import StatusBadge from '../../components/ui/StatusBadge';
import PageHeader from '../../components/ui/PageHeader';
import ListCard from '../../components/ui/ListCard';
import usePagination from '../../hooks/usePagination';
import Pagination from '../../components/ui/Pagination';
import Alert from '../../components/ui/Alert';
import { FaPlus, FaSearch, FaWrench, FaCalendarAlt, FaCar, FaCog, FaFileInvoice, FaHashtag, FaInfoCircle, FaMoneyBillWave, FaUser, FaUserCog } from 'react-icons/fa';
import SearchInput from '../../components/ui/SearchInput';
import DateRangeFilter, { applyDateRange, fmtRangeDate } from '../../components/ui/DateRangeFilter';
import FilterField from '../../components/ui/FilterField';
import { RowActions, ViewAction, EditAction, DeleteAction } from '../../components/ui/RowActions';

function formatRp(n) { return `Rp${Number(n || 0).toLocaleString('id-ID')}`; }

const statusOptions = [
  ['', 'Semua Status'], ['DITERIMA', 'Diterima'], ['DIKERJAKAN', 'Dikerjakan'],
  ['MENUNGGU_PEMBAYARAN', 'Menunggu Pembayaran'], ['SELESAI', 'Selesai (Lunas)'],
];

export default function ServiceList() {
  const { user } = useAuth();
  const isOps = user.role === 'ADMIN' || user.role === 'STAFF';
  const [services, setServices] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [status, setStatus] = useState('');
  const [q, setQ] = useState('');
  const [from, setFrom] = useState('');
  const [to, setTo] = useState('');

  function load() {
    setLoading(true);
    const params = new URLSearchParams();
    if (status) params.set('status', status);
    if (q) params.set('q', q);
    applyDateRange(params, from, to);
    return api.get(`/services?${params.toString()}`).then(({ data }) => setServices(data)).finally(() => setLoading(false));
  }

  const pg = usePagination(services, 10, [q, status, from, to].join('|'));
  useEffect(() => {
    const t = setTimeout(load, q ? 350 : 0);
    return () => clearTimeout(t);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [status, q, from, to]);

  async function handleDelete(s) {
    const lunas = s.status === 'SELESAI';
    const msg = lunas
      ? `Transaksi ${s.invoiceNo} sudah LUNAS. Menghapusnya akan menghilangkan catatan pembayaran dan mengembalikan stok sparepart. Lanjutkan?`
      : `Hapus transaksi ${s.invoiceNo}? Stok sparepart yang sudah terpakai akan dikembalikan.`;
    if (!confirm(msg)) return;
    setError('');
    try { await api.delete(`/services/${s.id}`); load(); }
    catch (err) { setError(err?.response?.data?.message || 'Gagal menghapus transaksi.'); }
  }

  return (
    <div className="space-y-4">
      <PageHeader icon={FaWrench} title="Data Layanan" subtitle="Daftar layanan service kendaraan">
        <Link to="/services/new" className="btn-primary"><FaPlus aria-hidden /> Tambah Service</Link>
      </PageHeader>

      <Alert message={error} />

      <div className="filter-bar">
        <FilterField label="Pencarian" icon={FaSearch} className="w-full sm:w-80">
          <SearchInput placeholder="Cari no. invoice / plat..." value={q} onChange={setQ} />
        </FilterField>
        <FilterField label="Status" icon={FaInfoCircle} className="w-full sm:w-52">
          <select className="input" value={status} onChange={(e) => setStatus(e.target.value)}>
            {statusOptions.map(([v, l]) => <option key={v} value={v}>{l}</option>)}
          </select>
        </FilterField>
        <DateRangeFilter from={from} to={to} onChange={({ from: f, to: t }) => { setFrom(f); setTo(t); }} />
      </div>

      <ListCard
        title="Daftar Service"
        right={<span className="text-xs font-semibold text-white/80">{(from || to) ? `${fmtRangeDate(from) || 'awal'} – ${fmtRangeDate(to) || 'sekarang'} · ` : ''}{services.length} transaksi</span>}
      >
        {loading ? <Spinner /> : services.length === 0 ? <EmptyState text={(from || to) ? 'Tidak ada layanan pada periode yang dipilih.' : 'Belum ada data.'} /> : (
          <table className="table-base">
            <thead>
              <tr>
                <th className="col-no"><FaHashtag className="mr-1 inline text-[10px]" aria-hidden /> No</th>
                <th><FaFileInvoice className="mr-1 inline text-[10px]" aria-hidden /> No. Invoice</th>
                <th><FaCalendarAlt className="mr-1 inline text-[10px]" aria-hidden /> Tanggal</th>
                <th><FaCar className="mr-1 inline text-[10px]" aria-hidden /> Kendaraan</th>
                <th><FaUser className="mr-1 inline text-[10px]" aria-hidden /> Pelanggan</th>
                <th><FaUserCog className="mr-1 inline text-[10px]" aria-hidden /> Teknisi</th>
                <th><FaInfoCircle className="mr-1 inline text-[10px]" aria-hidden /> Status</th>
                <th className="num"><FaMoneyBillWave className="mr-1 inline text-[10px]" aria-hidden /> Total</th>
                <th className="col-actions"><FaCog className="mr-1 inline text-[10px]" aria-hidden /> Aksi</th>
              </tr>
            </thead>
            <tbody>
              {pg.pageItems.map((s, rowNo) => {
                const lunas = s.status === 'SELESAI';
                const canDelete = isOps && (!lunas || user.role === 'ADMIN');
                return (
                  <tr key={s.id}>
                    <td className="col-no">{pg.start + rowNo + 1}</td>
                    <td><Link to={`/services/${s.id}`} className="cell-link">{s.invoiceNo}</Link></td>
                    <td>{new Date(s.date).toLocaleDateString('id-ID')}</td>
                    <td>{s.vehicle.plateNumber}</td>
                    <td>{s.vehicle.customer.name}</td>
                    <td>{s.technician.name}</td>
                    <td><StatusBadge status={s.status} /></td>
                    <td className="num">{formatRp(s.total)}</td>
                    <td className="col-actions">
                      <RowActions>
                        <ViewAction to={`/services/${s.id}`} label="Lihat detail & riwayat transaksi" />
                        {isOps && !lunas && <EditAction to={`/services/${s.id}/edit`} label="Edit data service" />}
                        {canDelete && <DeleteAction onClick={() => handleDelete(s)} label="Hapus transaksi" />}
                      </RowActions>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        )}
        <Pagination pg={pg} />
      </ListCard>
    </div>
  );
}