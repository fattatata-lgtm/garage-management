import React, { useEffect, useState } from 'react';
import { flushSync } from 'react-dom';
import { Link, Navigate, useParams } from 'react-router-dom';
import api from '../../api/axios';
import Spinner from '../../components/ui/Spinner';
import EmptyState from '../../components/ui/EmptyState';
import StatusBadge from '../../components/ui/StatusBadge';
import PageHeader from '../../components/ui/PageHeader';
import { printDocument } from '../../utils/print';
import DateRangeFilter from '../../components/ui/DateRangeFilter';
import FilterField from '../../components/ui/FilterField';
import SearchSelect from '../../components/ui/SearchSelect';
import StatCard from '../../components/ui/StatCard';
import ListCard from '../../components/ui/ListCard';
import usePagination from '../../hooks/usePagination';
import Pagination from '../../components/ui/Pagination';
import { RowActions, ViewAction } from '../../components/ui/RowActions';
import { FaBoxes, FaCoins, FaCheckCircle, FaClipboardList, FaCog, FaExchangeAlt, FaExclamationTriangle, FaHourglassHalf, FaMoneyBillWave, FaPercent, FaPrint, FaShoppingCart, FaTools, FaTimesCircle, FaCubes, FaReceipt, FaBarcode, FaCalendarAlt, FaCar, FaFileInvoice, FaHashtag, FaInfoCircle, FaLayerGroup, FaListUl, FaUser, FaUserCog, FaUsers, FaChartBar, FaCogs, FaFire, FaHandHoldingHeart, FaTrophy, FaWrench, FaFilter } from 'react-icons/fa';

function formatRp(n) { return `Rp${Number(n || 0).toLocaleString('id-ID')}`; }

const SUMMARY_ICONS = {
  'Total Item': [FaCubes, 'brand'], 'Nilai Stok': [FaCoins, 'green'], 'Stok Rendah': [FaExclamationTriangle, 'amber'], 'Stok Habis': [FaTimesCircle, 'red'],
  'Total Service': [FaClipboardList, 'brand'], 'Total Biaya': [FaMoneyBillWave, 'green'], 'Selesai': [FaCheckCircle, 'green'], 'Berjalan': [FaHourglassHalf, 'amber'],
  'Jenis Sparepart': [FaCogs, 'brand'], 'Total Qty Terjual': [FaExchangeAlt, 'cyan'], 'Total Nilai': [FaMoneyBillWave, 'green'], 'Sparepart Terlaris': [FaTrophy, 'amber'],
  'Total Pelanggan': [FaUsers, 'brand'], 'Total Transaksi': [FaReceipt, 'violet'], 'Rata-rata Transaksi': [FaChartBar, 'cyan'], 'Total Belanja': [FaMoneyBillWave, 'green'],
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
  sparepart: [FaCogs, 'Laporan Sparepart', 'Sparepart paling laris dari service & penjualan'],
  loyalty: [FaHandHoldingHeart, 'Laporan Loyalitas Pelanggan', 'Pelanggan paling sering datang & belanja'],
};

const SOURCE_LABEL = { ALL: 'Semua (Service + Penjualan)', SERVICE: 'Service', SALES: 'Penjualan' };

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
  const [customerId, setCustomerId] = useState('');
  const [customers, setCustomers] = useState([]);
  const [source, setSource] = useState('ALL');
  const [view, setView] = useState('ALL'); // laporan layanan: ALL = semua transaksi, TOP = layanan paling laris
  const [report, setReport] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (tab === 'stock') api.get('/categories').then(({ data }) => setCategories(data));
    else if (tab === 'service' || tab === 'sales') api.get('/customers').then(({ data }) => setCustomers(data)); // untuk filter pelanggan
  }, [tab]);

  function load() {
    setLoading(true);
    const params = new URLSearchParams();
    if (tab === 'stock' && categoryId) params.set('categoryId', categoryId);
    if (tab !== 'stock') {
      if (from) params.set('from', from);
      if (to) params.set('to', `${to}T23:59:59`);
      if (customerId && (tab === 'service' || tab === 'sales')) params.set('customerId', customerId);
      if (tab === 'sparepart' || tab === 'loyalty') params.set('source', source);
    }
    api.get(`/reports/${tab}?${params.toString()}`).then(({ data }) => setReport(data)).finally(() => setLoading(false));
  }
  useEffect(() => { setReport(null); load(); }, [tab, from, to, categoryId, customerId, source]);

  // Tabel rincian ditampilkan 10 data per halaman. Saat dicetak, SEMUA baris ikut dicetak.
  const [printing, setPrinting] = useState(false);
  const tableData = tab === 'service' && view === 'TOP' ? (report?.topServices || []) : (report?.detail || []);
  const pg = usePagination(tableData, 10, `${tab}|${from}|${to}|${categoryId}|${customerId}|${source}|${view}`);
  const rows = printing ? tableData : pg.pageItems;
  const rowStart = printing ? 0 : pg.start;

  function handlePrint() {
    flushSync(() => setPrinting(true)); // render semua baris dulu sebelum disalin
    const el = document.getElementById('report-area');
    if (el) {
      const clone = el.cloneNode(true);
      clone.querySelectorAll('.col-actions, .pagination-bar').forEach((n) => n.remove());
      const cust = customers.find((c) => String(c.id) === String(customerId));
      const custLine = cust ? `<p>Pelanggan: <b>${cust.name}</b></p>` : '';
      const srcLine = (tab === 'sparepart' || tab === 'loyalty') ? `<p>Sumber: <b>${SOURCE_LABEL[source]}</b></p>` : '';
      const viewLine = tab === 'service' && view === 'TOP' ? '<p>Tampilan: <b>Layanan Paling Laris</b></p>' : '';
      printDocument(TITLES[tab][1], `<h2>${TITLES[tab][1]}</h2>${custLine}${srcLine}${viewLine}${clone.innerHTML}`);
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
          <>
            <DateRangeFilter from={from} to={to} onChange={({ from: f, to: t }) => { setFrom(f); setTo(t); }} />
            {(tab === 'sparepart' || tab === 'loyalty') && (
              <FilterField label="Sumber Data" icon={FaFilter} className="w-full sm:w-60">
                <select className="input" value={source} onChange={(e) => setSource(e.target.value)}>
                  {Object.entries(SOURCE_LABEL).map(([k, v]) => <option key={k} value={k}>{v}</option>)}
                </select>
              </FilterField>
            )}
            {tab === 'service' && (
              <FilterField label="Tampilan" icon={FaFire} className="w-full sm:w-56">
                <select className="input" value={view} onChange={(e) => setView(e.target.value)}>
                  <option value="ALL">Semua Layanan</option>
                  <option value="TOP">Layanan Paling Laris</option>
                </select>
              </FilterField>
            )}
            {(tab === 'service' || tab === 'sales') && (
              <FilterField label="Pelanggan" icon={FaUsers} className="w-full sm:w-64">
                <SearchSelect value={customerId} onChange={(e) => setCustomerId(e.target.value)} placeholder="Cari nama pelanggan...">
                  <option value="">Semua Pelanggan</option>
                  {customers.map((c) => <option key={c.id} value={c.id}>{c.name}{c.phone ? ` (${c.phone})` : ''}</option>)}
                </SearchSelect>
              </FilterField>
            )}
          </>
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
                {view === 'TOP' ? (
                  rows.length === 0 ? <EmptyState /> : (
                  <table className="table-base">
                    <thead><tr><th className="col-no"><FaHashtag className="mr-1 inline text-[10px]" aria-hidden /> No</th><th><FaWrench className="mr-1 inline text-[10px]" aria-hidden /> Layanan</th><th className="num"><FaHashtag className="mr-1 inline text-[10px]" aria-hidden /> Dipakai (kali)</th><th className="num"><FaMoneyBillWave className="mr-1 inline text-[10px]" aria-hidden /> Total Biaya Jasa</th></tr></thead>
                    <tbody>
                      {rows.map((t, rowNo) => (
                        <tr key={t.name}><td className="col-no">{rowStart + rowNo + 1}</td><td>{t.name}</td><td className="num">{t.count}</td><td className="num">{formatRp(t.revenue)}</td></tr>
                      ))}
                    </tbody>
                  </table>
                )) : (
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
                )}
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

          {tab === 'sparepart' && (() => {
            const showService = source !== 'SALES';
            const showSales = source !== 'SERVICE';
            return (
              <>
                <SummaryCards items={[
                  ['Jenis Sparepart', report.summary.jenisTerjual],
                  ['Total Qty Terjual', report.summary.totalQty],
                  ['Total Nilai', formatRp(report.summary.totalNilai)],
                  ['Sparepart Terlaris', report.summary.terlaris],
                ]} />
                <ListCard title="Rincian Data" icon={FaClipboardList}>
                  {report.detail.length === 0 ? <EmptyState /> : (
                    <table className="table-base">
                      <thead><tr>
                        <th className="col-no"><FaHashtag className="mr-1 inline text-[10px]" aria-hidden /> No</th>
                        <th><FaBarcode className="mr-1 inline text-[10px]" aria-hidden /> Kode</th>
                        <th><FaCogs className="mr-1 inline text-[10px]" aria-hidden /> Nama</th>
                        <th><FaLayerGroup className="mr-1 inline text-[10px]" aria-hidden /> Kategori</th>
                        {showService && <th className="num"><FaTools className="mr-1 inline text-[10px]" aria-hidden /> Service</th>}
                        {showSales && <th className="num"><FaShoppingCart className="mr-1 inline text-[10px]" aria-hidden /> Penjualan</th>}
                        <th className="num"><FaExchangeAlt className="mr-1 inline text-[10px]" aria-hidden /> Total Qty</th>
                        <th className="num"><FaMoneyBillWave className="mr-1 inline text-[10px]" aria-hidden /> Nilai</th>
                        <th className="num"><FaPercent className="mr-1 inline text-[10px]" aria-hidden /> Laba</th>
                      </tr></thead>
                      <tbody>
                        {rows.map((d, rowNo) => (
                          <tr key={d.id}><td className="col-no">{rowStart + rowNo + 1}</td>
                            <td>{d.code}</td><td>{d.name}</td><td>{d.category}</td>
                            {showService && <td className="num">{d.qtyService}</td>}
                            {showSales && <td className="num">{d.qtySales}</td>}
                            <td className="num">{d.qtyTotal}</td>
                            <td className="num">{formatRp(d.revenue)}</td>
                            <td className="num">{formatRp(d.profit)}</td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  )}
                  <Pagination pg={pg} />
                </ListCard>
              </>
            );
          })()}

          {tab === 'loyalty' && (() => {
            const showService = source !== 'SALES';
            const showSales = source !== 'SERVICE';
            return (
              <>
                <SummaryCards items={[
                  ['Total Pelanggan', report.summary.totalPelanggan],
                  ['Total Transaksi', report.summary.totalTransaksi],
                  ['Rata-rata Transaksi', report.summary.rataTransaksi],
                  ['Total Belanja', formatRp(report.summary.totalBelanja)],
                ]} />
                <ListCard title="Rincian Data" icon={FaClipboardList}>
                  {report.detail.length === 0 ? <EmptyState /> : (
                    <table className="table-base">
                      <thead><tr>
                        <th className="col-no"><FaHashtag className="mr-1 inline text-[10px]" aria-hidden /> No</th>
                        <th><FaUser className="mr-1 inline text-[10px]" aria-hidden /> Pelanggan</th>
                        <th><FaHashtag className="mr-1 inline text-[10px]" aria-hidden /> Telepon</th>
                        {showService && <th className="num"><FaTools className="mr-1 inline text-[10px]" aria-hidden /> Service</th>}
                        {showSales && <th className="num"><FaShoppingCart className="mr-1 inline text-[10px]" aria-hidden /> Penjualan</th>}
                        <th className="num"><FaExchangeAlt className="mr-1 inline text-[10px]" aria-hidden /> Total Transaksi</th>
                        <th className="num"><FaMoneyBillWave className="mr-1 inline text-[10px]" aria-hidden /> Total Belanja</th>
                        <th><FaCalendarAlt className="mr-1 inline text-[10px]" aria-hidden /> Terakhir</th>
                        <th><FaInfoCircle className="mr-1 inline text-[10px]" aria-hidden /> Status</th>
                      </tr></thead>
                      <tbody>
                        {rows.map((d, rowNo) => (
                          <tr key={d.customerId}><td className="col-no">{rowStart + rowNo + 1}</td>
                            <td><Link to={`/customers/${d.customerId}`} className="cell-link">{d.name}</Link></td>
                            <td>{d.phone}</td>
                            {showService && <td className="num">{d.serviceCount}</td>}
                            {showSales && <td className="num">{d.salesCount}</td>}
                            <td className="num">{d.visits}</td>
                            <td className="num">{formatRp(d.totalSpent)}</td>
                            <td>{new Date(d.lastDate).toLocaleDateString('id-ID')}</td>
                            <td><StatusBadge status={d.active ? 'AKTIF' : 'NONAKTIF'} /></td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  )}
                  <Pagination pg={pg} />
                </ListCard>
                <p className="px-1 text-xs text-slate-500">
                  Transaksi = service lunas + pembelian sparepart atas nama pelanggan terdaftar. Status Nonaktif bila terakhir datang lebih dari {report.activeDays} hari lalu.
                </p>
              </>
            );
          })()}
        </div>
      )}
    </div>
  );
}
