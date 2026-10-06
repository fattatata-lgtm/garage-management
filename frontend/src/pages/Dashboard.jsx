import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { FaBoxes, FaCar, FaExclamationTriangle, FaHistory, FaMoneyBillWave, FaTachometerAlt, FaUsers, FaWallet, FaWrench, FaBarcode, FaBoxOpen, FaCog, FaCogs, FaFileInvoice, FaHashtag, FaInfoCircle, FaLayerGroup, FaUser, FaUserCog } from 'react-icons/fa';
import api from '../api/axios';
import Spinner from '../components/ui/Spinner';
import EmptyState from '../components/ui/EmptyState';
import StatusBadge from '../components/ui/StatusBadge';
import PageHeader from '../components/ui/PageHeader';
import ListCard from '../components/ui/ListCard';
import StatCard from '../components/ui/StatCard';
import Alert from '../components/ui/Alert';

const PERIODS = [
  { key: 'day', label: 'Hari Ini' },
  { key: 'week', label: 'Minggu Ini' },
  { key: 'month', label: 'Bulan Ini' },
];

function formatRp(n) {
  return `Rp${Number(n || 0).toLocaleString('id-ID')}`;
}

const NO_ACCESS_MSG = 'Anda tidak memiliki akses ke halaman ini.';

export default function Dashboard() {
  const { user } = useAuth();
  const isTeknisi = user?.role === 'TEKNISI';
  const [notif, setNotif] = useState('');
  const [period, setPeriod] = useState('day');
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(true);
    api.get(`/dashboard/summary?period=${period}`)
      .then(({ data }) => setData(data))
      .finally(() => setLoading(false));
  }, [period]);

  // Notifikasi hilang otomatis setelah 4 detik
  useEffect(() => {
    if (!notif) return undefined;
    const t = setTimeout(() => setNotif(''), 4000);
    return () => clearTimeout(t);
  }, [notif]);

  if (loading || !data) return <Spinner />;

  const cards = [
    { label: 'Total Pelanggan', value: data.totalCustomers, to: '/customers', icon: FaUsers, tone: 'brand' },
    { label: 'Total Kendaraan', value: data.totalVehicles, to: '/vehicles', icon: FaCar, tone: 'cyan' },
    { label: `Service (${PERIODS.find((p) => p.key === period).label})`, value: data.totalServices, to: '/services', icon: FaWrench, tone: 'violet' },
    { label: 'Pendapatan Service', value: formatRp(data.pendapatanService), icon: FaMoneyBillWave, tone: 'green' },
    { label: 'Pendapatan Sales', value: formatRp(data.pendapatanSales), icon: FaBoxes, tone: 'amber' },
    { label: 'Total Pendapatan', value: formatRp(data.totalPendapatan), icon: FaWallet, tone: 'green' },
  ];

  // Hitung ringkasan alert stok
  const stokHabis = data.lowStockAlerts.filter((sp) => sp.status === 'HABIS');
  const stokRendah = data.lowStockAlerts.filter((sp) => sp.status === 'RENDAH');

  return (
    <div className="space-y-5">
      <PageHeader icon={FaTachometerAlt} title="Dashboard" subtitle="Ringkasan aktivitas bengkel">
        <div className="flex gap-1 rounded-xl border border-slate-200 bg-white p-1 shadow-sm">
          {PERIODS.map((p) => (
            <button
              key={p.key}
              onClick={() => setPeriod(p.key)}
              className={`rounded-lg px-3.5 py-1.5 text-sm font-semibold transition-colors ${
                period === p.key ? 'bg-brand-600 text-white shadow-sm' : 'text-slate-600 hover:bg-slate-100'
              }`}
            >
              {p.label}
            </button>
          ))}
        </div>
      </PageHeader>

      <Alert type="error" message={notif} />

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-3">
        {cards.map((c) => (
          <StatCard
            key={c.label}
            {...c}
            to={isTeknisi && ['/customers', '/vehicles'].includes(c.to) ? undefined : c.to}
          />
        ))}
      </div>

      {/* ============ TABEL ALERT STOK MENIPIS / HABIS ============ */}
      {data.lowStockAlerts.length > 0 && (
        <ListCard
          title="Alert Stok Sparepart Menipis / Habis"
          icon={FaExclamationTriangle}
          right={
            <div className="flex items-center gap-3 text-xs font-semibold text-white/80">
              {stokHabis.length > 0 && (
                <span className="rounded-full bg-red-500 px-2.5 py-1 text-white">
                  {stokHabis.length} Habis
                </span>
              )}
              {stokRendah.length > 0 && (
                <span className="rounded-full bg-amber-500 px-2.5 py-1 text-white">
                  {stokRendah.length} Rendah
                </span>
              )}
            </div>
          }
        >
          <table className="table-base">
            <thead>
              <tr>
                <th className="col-no"><FaHashtag className="mr-1 inline text-[10px]" aria-hidden /> No</th>
                <th><FaBarcode className="mr-1 inline text-[10px]" aria-hidden /> Kode</th>
                <th><FaCogs className="mr-1 inline text-[10px]" aria-hidden /> Nama Sparepart</th>
                <th><FaLayerGroup className="mr-1 inline text-[10px]" aria-hidden /> Kategori</th>
                <th className="num"><FaBoxes className="mr-1 inline text-[10px]" aria-hidden /> Stok</th>
                <th className="num"><FaBoxOpen className="mr-1 inline text-[10px]" aria-hidden /> Min. Stok</th>
                <th className="num"><FaMoneyBillWave className="mr-1 inline text-[10px]" aria-hidden /> Harga Jual</th>
                <th><FaInfoCircle className="mr-1 inline text-[10px]" aria-hidden /> Status</th>
                <th className="col-actions"><FaCog className="mr-1 inline text-[10px]" aria-hidden /> Aksi</th>
              </tr>
            </thead>
            <tbody>
              {data.lowStockAlerts
                .sort((a, b) => {
                  // Urutkan: HABIS dulu, lalu RENDAH, lalu berdasarkan stok ascending
                  if (a.status === 'HABIS' && b.status !== 'HABIS') return -1;
                  if (a.status !== 'HABIS' && b.status === 'HABIS') return 1;
                  return a.stock - b.stock;
                })
                .map((sp, rowNo) => (
                  <tr key={sp.id}>
                    <td className="col-no">{rowNo + 1}</td>
                    <td className="font-mono text-xs text-slate-500">{sp.code}</td>
                    <td>
                      {isTeknisi ? (
                        <button type="button" className="cell-link text-left" onClick={() => setNotif(NO_ACCESS_MSG)}>
                          {sp.name}
                        </button>
                      ) : (
                        <Link to={`/spareparts/${sp.id}/edit`} className="cell-link">
                          {sp.name}
                        </Link>
                      )}
                    </td>
                    <td>{sp.category?.name || '-'}</td>
                    <td className={`num font-bold ${sp.status === 'HABIS' ? 'text-red-600' : 'text-amber-600'}`}>
                      {sp.stock}
                    </td>
                    <td className="num text-slate-500">{sp.lowStockThreshold}</td>
                    <td className="num">{formatRp(sp.sellPrice)}</td>
                    <td><StatusBadge status={sp.status} /></td>
                    <td className="col-actions">
                      {isTeknisi ? (
                        <button
                          type="button"
                          onClick={() => setNotif(NO_ACCESS_MSG)}
                          className="btn-primary !px-3 !py-1.5 !text-xs"
                        >
                          <FaBoxes aria-hidden /> Tambah Stok
                        </button>
                      ) : (
                        <Link
                          to={`/spareparts/stock-history/in?sparepartId=${sp.id}`}
                          className="btn-primary !px-3 !py-1.5 !text-xs"
                        >
                          <FaBoxes aria-hidden /> Tambah Stok
                        </Link>
                      )}
                    </td>
                  </tr>
                ))}
            </tbody>
          </table>

          {/* Footer ringkasan */}
          <div className="flex flex-wrap items-center justify-between gap-2 border-t border-slate-100 bg-slate-50/80 px-5 py-3 text-xs text-slate-500">
            <span>
              Total <b className="text-slate-700">{data.lowStockAlerts.length}</b> sparepart perlu perhatian
            </span>
            {isTeknisi ? (
              <button type="button" onClick={() => setNotif(NO_ACCESS_MSG)} className="font-semibold text-brand-600 hover:underline">
                Lihat Laporan Stok Lengkap →
              </button>
            ) : (
              <Link to="/reports/stock" className="font-semibold text-brand-600 hover:underline">
                Lihat Laporan Stok Lengkap →
              </Link>
            )}
          </div>
        </ListCard>
      )}

      <ListCard
        title="Service Terbaru"
        icon={FaHistory}
        right={<Link to="/services" className="text-xs font-semibold text-white/80 hover:text-white hover:underline">Lihat semua</Link>}
      >
        {data.recentServices.length === 0 ? <EmptyState text="Belum ada transaksi service." /> : (
          <table className="table-base">
            <thead>
              <tr>
                <th className="col-no"><FaHashtag className="mr-1 inline text-[10px]" aria-hidden /> No</th>
                <th><FaFileInvoice className="mr-1 inline text-[10px]" aria-hidden /> No. Invoice</th>
                <th><FaCar className="mr-1 inline text-[10px]" aria-hidden /> Kendaraan</th>
                <th><FaUser className="mr-1 inline text-[10px]" aria-hidden /> Pemilik</th>
                <th><FaUserCog className="mr-1 inline text-[10px]" aria-hidden /> Teknisi</th>
                <th><FaInfoCircle className="mr-1 inline text-[10px]" aria-hidden /> Status</th>
                <th className="num"><FaMoneyBillWave className="mr-1 inline text-[10px]" aria-hidden /> Total</th>
              </tr>
            </thead>
            <tbody>
              {data.recentServices.map((s, rowNo) => (
                <tr key={s.id}>
                  <td className="col-no">{rowNo + 1}</td>
                  <td><Link to={`/services/${s.id}`} className="cell-link">{s.invoiceNo}</Link></td>
                  <td>{s.vehicle.plateNumber}</td>
                  <td>{s.vehicle.customer.name}</td>
                  <td>{s.technician.name}</td>
                  <td><StatusBadge status={s.status} /></td>
                  <td className="num">{formatRp(s.total)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </ListCard>
    </div>
  );
}