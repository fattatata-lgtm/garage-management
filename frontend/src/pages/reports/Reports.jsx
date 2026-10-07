import React, { useEffect, useState } from 'react';
import { flushSync } from 'react-dom';
import { Link, Navigate, useParams } from 'react-router-dom';
import api from '../../api/axios';
import Spinner from '../../components/ui/Spinner';
import StatusBadge from '../../components/ui/StatusBadge';
import PageHeader from '../../components/ui/PageHeader';
import { printDocument } from '../../utils/print';
import DateRangeFilter from '../../components/ui/DateRangeFilter';
import FilterField from '../../components/ui/FilterField';
import StatCard from '../../components/ui/StatCard';
import ListCard from '../../components/ui/ListCard';
import usePagination from '../../hooks/usePagination';
import Pagination from '../../components/ui/Pagination';
import { RowActions, ViewAction } from '../../components/ui/RowActions';
import { FaBoxes, FaCoins, FaCheckCircle, FaClipboardList, FaCog, FaExchangeAlt, FaExclamationTriangle, FaHourglassHalf, FaMoneyBillWave, FaPercent, FaPrint, FaShoppingCart, FaTools, FaTimesCircle, FaCubes, FaReceipt, FaBarcode, FaCalendarAlt, FaCar, FaFileInvoice, FaHashtag, FaInfoCircle, FaLayerGroup, FaListUl, FaUser, FaUserCog } from 'react-icons/fa';

function formatRp(n) { return `Rp${Number(n || 0).toLocaleString('id-ID')}`; }

const SUMMARY_ICONS = {
  'Total Item': [FaCubes, 'brand'], 'Nilai Stok': [FaCoins, 'green'], 'Stok Rendah': [FaExclamationTriangle, 'amber'], 'Stok Habis': [FaTimesCircle, 'red'],
  'Total Service': [FaClipboardList, 'brand'], 'Total Biaya': [FaMoneyBillWave, 'green'], 'Selesai': [FaCheckCircle, 'green'], 'Berjalan': [FaHourglassHalf, 'amber'],
  'Total Penjualan': [FaMoneyBillWave, 'brand'], 'Total Laba': [FaPercent, 'green'], 'Jumlah Transaksi': [FaReceipt, 'violet'], 'Jumlah Item Terjual': [FaExchangeAlt, 'cyan'],
};

function SummaryCards({ items }) {
  return (
    <div className="grid grid-cols-2 gap-4 md:grid-cols-4">
      {items.map(([label, value]) => {
        const [icon, tone] = SUMMARY_ICONS[label] || [FaCubes, 'brand'];
        return <StatCard key={label} icon={icon} tone={tone} label={label} value={value} />;
      })}
    </div>
  );
}

const TITLES = {
  stock: [FaBoxes, 'Laporan Stok', 'Data stok sparepart'],
  service: [FaTools, 'Laporan Layanan Service', 'Rekap layanan service kendaraan'],
  sales: [FaShoppingCart, 'Laporan Penjualan', 'Rekap penjualan sparepart'],
};

// /reports/:tab -> stock | service | sales. key={tab} mereset filter saat pindah laporan.
export default function Reports() {
  const { tab } = useParams();
  if (!TITLES[tab]) return <Navigate to="/reports/stock" replace />;
  return <ReportView key={tab} tab={tab} />;
}

function ReportView({ tab }) {
  const [from, setFrom] = useState('');
  const [to, setTo] = useState('');
  const [categoryId, setCategoryId] = useState('');
  const [categories, setCategories] = useState([]);
  const [report, setReport] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => { api.get('/categories').then(({ data }) => setCategories(data)); }, []);

  function load() {
    setLoading(true);
    const params = new URLSearchParams();
    if (tab === 'stock' && categoryId) params.set('categoryId', categoryId);
    if (tab !== 'stock') {
      if (from) params.set('from', from);
      if (to) params.set('to', `${to}T23:59:59`);
    }
    api.get(`/reports/${tab}?${params.toString()}`).then(({ data }) => setReport(data)).finally(() => setLoading(false));
  }
  useEffect(() => { setReport(null); load(); }, [tab, from, to, categoryId]);

  // Tabel rincian ditampilkan 10 data per halaman. Saat dicetak, SEMUA baris ikut dicetak.
  const [printing, setPrinting] = useState(false);
  const pg = usePagination(report?.detail || [], 10, `${tab}|${from}|${to}|${categoryId}`);
  const rows = printing ? (report?.detail || []) : pg.pageItems;
  const rowStart = printing ? 0 : pg.start;

  function handlePrint() {
    flushSync(() => setPrinting(true)); // render semua baris dulu sebelum disalin
    const el = document.getElementById('report-area');
    if (el) {
      const clone = el.cloneNode(true);
      clone.querySelectorAll('.col-actions, .pagination-bar').forEach((n) => n.remove());
      printDocument(`Laporan ${tab}`, `<h2>Laporan ${tab}</h2>${clone.innerHTML}`);
    }
    setPrinting(false);
  }

  return (
    <div className="space-y-4">
      <PageHeader icon={TITLES[tab][0]} title={TITLES[tab][1]} subtitle={TITLES[tab][2]}>
        <button className="btn-secondary" onClick={handlePrint}><FaPrint aria-hidden /> Cetak / Simpan PDF</button>
      </PageHeader>

      <div className="filter-bar">
        {tab === 'stock' ? (
          <FilterField label="Kategori" icon={FaLayerGroup} className="w-full sm:w-64">
            <select className="input" value={categoryId} onChange={(e) => setCategoryId(e.target.value)}>
              <option value="">Semua Kategori</option>
              {categories.map((c) => <option key={c.id} value={c.id}>{c.name}</option>)}
            </select>
          </FilterField>
        ) : (
          <DateRangeFilter from={from} to={to} onChange={({ from: f, to: t }) => { setFrom(f); setTo(t); }} />
        )}
      </div>

      {loading || !report ? <Spinner /> : (
        <div id="report-area" className="space-y-4">
          {tab === 'stock' && (
            <>
              <SummaryCards items={[
                ['Total Item', report.summary.totalItems],
                ['Nilai Stok', formatRp(report.summary.totalStockValue)],
                ['Stok Rendah', report.summary.rendah],
                ['Stok Habis', report.summary.habis],
              ]} />
              <ListCard title="Rincian Data" icon={FaClipboardList}>
                <table className="table-base">
                  <thead><tr><th className="col-no"><FaHashtag className="mr-1 inline text-[10px]" aria-hidden /> No</th><th><FaBarcode className="mr-1 inline text-[10px]" aria-hidden /> Kode</th><th><FaUser className="mr-1 inline text-[10px]" aria-hidden /> Nama</th><th><FaLayerGroup className="mr-1 inline text-[10px]" aria-hidden /> Kategori</th><th className="num"><FaBoxes className="mr-1 inline text-[10px]" aria-hidden /> Stok</th><th className="num"><FaMoneyBillWave className="mr-1 inline text-[10px]" aria-hidden /> Harga Beli</th><th className="num"><FaCoins className="mr-1 inline text-[10px]" aria-hidden /> Nilai Stok</th><th><FaInfoCircle className="mr-1 inline text-[10px]" aria-hidden /> Status</th></tr></thead>
                  <tbody>
                    {rows.map((d, rowNo) => (
                      <tr key={d.id}><td className="col-no">{rowStart + rowNo + 1}</td><td>{d.code}</td><td>{d.name}</td><td>{d.category.name}</td><td className="num">{d.stock}</td><td className="num">{formatRp(d.buyPrice)}</td><td className="num">{formatRp(d.stockValue)}</td><td><StatusBadge status={d.status} /></td></tr>
                    ))}
                  </tbody>
                </table>
                <Pagination pg={pg} />
              </ListCard>
            </>
          )}

          {tab === 'service' && (
            <>
              <SummaryCards items={[
                ['Total Service', report.summary.totalService],
                ['Total Biaya', formatRp(report.summary.totalBiaya)],
                ['Selesai', report.summary.selesai],
                ['Berjalan', report.summary.berjalan],
              ]} />
              <ListCard title="Rincian Data" icon={FaClipboardList}>
                <table className="table-base">
                  <thead><tr><th className="col-no"><FaHashtag className="mr-1 inline text-[10px]" aria-hidden /> No</th><th><FaFileInvoice className="mr-1 inline text-[10px]" aria-hidden /> No. Invoice</th><th><FaCalendarAlt className="mr-1 inline text-[10px]" aria-hidden /> Tanggal</th><th><FaCar className="mr-1 inline text-[10px]" aria-hidden /> Kendaraan</th><th><FaUser className="mr-1 inline text-[10px]" aria-hidden /> Pemilik</th><th><FaUserCog className="mr-1 inline text-[10px]" aria-hidden /> Teknisi</th><th><FaInfoCircle className="mr-1 inline text-[10px]" aria-hidden /> Status</th><th className="num"><FaMoneyBillWave className="mr-1 inline text-[10px]" aria-hidden /> Total</th><th className="col-actions"><FaCog className="mr-1 inline text-[10px]" aria-hidden /> Aksi</th></tr></thead>
                  <tbody>
                    {rows.map((s, rowNo) => (
                      <tr key={s.id}><td className="col-no">{rowStart + rowNo + 1}</td>
                        <td><Link to={`/services/${s.id}`} className="cell-link">{s.invoiceNo}</Link></td>
                        <td>{new Date(s.date).toLocaleDateString('id-ID')}</td>
                        <td>{s.vehicle.plateNumber}</td><td>{s.vehicle.customer.name}</td><td>{s.technician.name}</td>
                        <td><StatusBadge status={s.status} /></td><td className="num">{formatRp(s.total)}</td>
                        <td className="col-actions"><RowActions><ViewAction to={`/services/${s.id}`} label="Lihat detail service" /></RowActions></td>
                      </tr>
                    ))}
                  </tbody>
                </table>
                <Pagination pg={pg} />
              </ListCard>
            </>
          )}

          {tab === 'sales' && (
            <>
              <SummaryCards items={[
                ['Total Penjualan', formatRp(report.summary.totalPenjualan)],
                ['Total Laba', formatRp(report.summary.totalLaba)],
                ['Jumlah Transaksi', report.summary.jumlahTransaksi],
                ['Jumlah Item Terjual', report.summary.jumlahItem],
              ]} />
              <ListCard title="Rincian Data" icon={FaClipboardList}>
                <table className="table-base">
                  <thead><tr><th className="col-no"><FaHashtag className="mr-1 inline text-[10px]" aria-hidden /> No</th><th><FaFileInvoice className="mr-1 inline text-[10px]" aria-hidden /> No. Invoice</th><th><FaCalendarAlt className="mr-1 inline text-[10px]" aria-hidden /> Tanggal</th><th><FaUser className="mr-1 inline text-[10px]" aria-hidden /> Pelanggan</th><th className="num"><FaListUl className="mr-1 inline text-[10px]" aria-hidden /> Item</th><th className="num"><FaMoneyBillWave className="mr-1 inline text-[10px]" aria-hidden /> Total</th><th className="col-actions"><FaCog className="mr-1 inline text-[10px]" aria-hidden /> Aksi</th></tr></thead>
                  <tbody>
                    {rows.map((s, rowNo) => (
                      <tr key={s.id}><td className="col-no">{rowStart + rowNo + 1}</td>
                        <td><Link to={`/sales/${s.id}`} className="cell-link">{s.invoiceNo}</Link></td>
                        <td>{new Date(s.date).toLocaleDateString('id-ID')}</td>
                        <td>{s.customer ? s.customer.name : (s.walkInName || 'Pelanggan Umum')}</td>
                        <td className="num">{s.items.length}</td><td className="num">{formatRp(s.total)}</td>
                        <td className="col-actions"><RowActions><ViewAction to={`/sales/${s.id}`} label="Lihat detail penjualan" /></RowActions></td>
                      </tr>
                    ))}
                  </tbody>
                </table>
                <Pagination pg={pg} />
              </ListCard>
            </>
          )}
        </div>
      )}
    </div>
  );
}
