import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import {
  FaCar, FaCheckCircle, FaFileInvoice, FaHashtag, FaHistory, FaInfoCircle, FaInbox,
  FaTachometerAlt, FaTools, FaUser, FaUserCog, FaWrench, FaCalendarAlt,
} from 'react-icons/fa';
import api from '../api/axios';
import Spinner from '../components/ui/Spinner';
import EmptyState from '../components/ui/EmptyState';
import StatusBadge from '../components/ui/StatusBadge';
import PageHeader from '../components/ui/PageHeader';
import ListCard from '../components/ui/ListCard';
import StatCard from '../components/ui/StatCard';

const PERIODS = [
  { key: 'day', label: 'Hari Ini' },
  { key: 'week', label: 'Minggu Ini' },
  { key: 'month', label: 'Bulan Ini' },
];

const fmtDate = (d) => new Date(d).toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' });

// Dashboard khusus Teknisi: hanya ringkasan layanan.
// Sengaja tanpa data stok sparepart, penjualan, maupun pendapatan.
export default function TeknisiDashboard() {
  const [period, setPeriod] = useState('day');
  const [data, setData] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    setLoading(true);
    api.get(`/dashboard/summary?period=${period}`)
      .then(({ data }) => setData(data))
      .finally(() => setLoading(false));
  }, [period]);

  if (loading || !data) return <Spinner />;

  const periodLabel = PERIODS.find((p) => p.key === period).label;
  const c = data.statusCounts;
  const cards = [
    { label: `Total Service (${periodLabel})`, value: data.totalServices, to: '/services', icon: FaWrench, tone: 'violet' },
    { label: 'Diterima', value: c.DITERIMA, icon: FaInbox, tone: 'amber' },
    { label: 'Dikerjakan', value: c.DIKERJAKAN, icon: FaTools, tone: 'brand' },
    { label: 'Menunggu Pembayaran', value: c.MENUNGGU_PEMBAYARAN, icon: FaFileInvoice, tone: 'cyan' },
    { label: 'Selesai (Lunas)', value: c.SELESAI, icon: FaCheckCircle, tone: 'green' },
  ];

  return (
    <div className="space-y-5">
      <PageHeader icon={FaTachometerAlt} title="Dashboard" subtitle="Ringkasan layanan bengkel">
        <div className="flex flex-wrap items-center gap-2">
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
        </div>
      </PageHeader>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 xl:grid-cols-3">
        {cards.map((card) => <StatCard key={card.label} {...card} />)}
      </div>

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
                <th><FaCalendarAlt className="mr-1 inline text-[10px]" aria-hidden /> Tanggal</th>
                <th><FaCar className="mr-1 inline text-[10px]" aria-hidden /> Kendaraan</th>
                <th><FaUser className="mr-1 inline text-[10px]" aria-hidden /> Pemilik</th>
                <th><FaUserCog className="mr-1 inline text-[10px]" aria-hidden /> Teknisi</th>
                <th><FaInfoCircle className="mr-1 inline text-[10px]" aria-hidden /> Status</th>
              </tr>
            </thead>
            <tbody>
              {data.recentServices.map((s, i) => (
                <tr key={s.id}>
                  <td className="col-no">{i + 1}</td>
                  <td><Link to={`/services/${s.id}`} className="cell-link">{s.invoiceNo}</Link></td>
                  <td>{fmtDate(s.date)}</td>
                  <td>{s.vehicle.plateNumber}</td>
                  <td>{s.vehicle.customer.name}</td>
                  <td>{s.technician.name}</td>
                  <td><StatusBadge status={s.status} /></td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </ListCard>
    </div>
  );
}
