import React, { useEffect, useState } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import api from '../../api/axios';
import { useAuth } from '../../context/AuthContext';
import Spinner from '../../components/ui/Spinner';
import Alert from '../../components/ui/Alert';
import CardHeader from '../../components/ui/CardHeader';
import DetailHeader from '../../components/ui/DetailHeader';
import InfoRow from '../../components/ui/InfoRow';
import { stagger, SubtotalStrip, ReceiptRow } from '../../components/ui/ReceiptParts';
import { printDocument, paperWidthMm } from '../../utils/print';
import { printInvoice } from '../../utils/invoice';
import { isRawMode, printThermal } from '../../utils/thermal';
import { buildSalesReceipt } from '../../utils/thermalReceipts';
import useSettings from '../../hooks/useSettings';
import { openWhatsApp } from '../../utils/whatsapp';
import { formatRp, fmtDateTime } from '../../utils/format';
import {
  FaArrowLeft, FaBoxes, FaCalendarAlt, FaCheckCircle, FaClock, FaCogs, FaPhone, FaPrint, FaReceipt,
  FaShoppingCart, FaTicketAlt, FaTrash, FaUser, FaWhatsapp, FaFileInvoice,
} from 'react-icons/fa';

const lbl = (Icon, text) => (
  <span className="flex items-center gap-2"><Icon className="text-brand-500" aria-hidden /> {text}</span>
);

export default function SalesDetail() {
  const { id } = useParams();
  const navigate = useNavigate();
  const { user } = useAuth();
  const [sale, setSale] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const settings = useSettings();

  useEffect(() => {
    api.get(`/sales/${id}`).then(({ data }) => setSale(data)).finally(() => setLoading(false));
  }, [id]);

  if (loading) return <Spinner />;
  if (!sale) return <p>Transaksi tidak ditemukan.</p>;

  const isAdmin = user.role === 'ADMIN';
  const buyer = sale.customer ? sale.customer.name : (sale.walkInName || 'Pelanggan Umum');
  const totalQty = sale.items.reduce((t, i) => t + Number(i.qty || 0), 0);
  const hasDiscount = Number(sale.discountAmount) > 0;

  async function handleWa() {
    try {
      const { data } = await api.get(`/sales/${id}/whatsapp-message`);
      openWhatsApp(data.phone, data.message);
    } catch (err) { setError(err?.response?.data?.message || 'Gagal membuka WhatsApp.'); }
  }

  async function handleDelete() {
    if (!confirm(`Hapus transaksi penjualan ${sale.invoiceNo}? Stok sparepart yang terjual akan dikembalikan.`)) return;
    setError('');
    try { await api.delete(`/sales/${id}`); navigate('/sales'); }
    catch (err) { setError(err?.response?.data?.message || 'Gagal menghapus transaksi.'); }
  }

  function handlePrint(thermal) {
    if (!thermal) {
      const sumRows = [{ label: 'Subtotal', value: sale.subtotal }];
      if (Number(sale.discountAmount) > 0) sumRows.push({ label: sale.discount ? `Diskon (${sale.discount.name})` : 'Diskon', value: -Number(sale.discountAmount) });
      if (Number(sale.taxAmount) > 0) sumRows.push({ label: 'Pajak', value: sale.taxAmount });
      printInvoice({
        title: 'Invoice Penjualan',
        settings,
        invoiceNo: sale.invoiceNo,
        date: sale.date,
        billTo: buyer,
        toLine: sale.customer?.phone || '',
        parts: { title: 'DAFTAR BARANG', items: sale.items.map((i) => ({ name: i.sparepart.name, qty: i.qty, uom: 'pcs', price: i.price })) },
        summary: {
          title: 'RINCIAN PEMBAYARAN',
          rows: sumRows,
          grand: sale.total,
          after: [{ label: 'Dibayar', value: sale.paid }, { label: 'Kembalian', value: sale.change }],
        },
        note: 'LUNAS - Terima kasih atas kepercayaan Anda.',
      });
      return;
    }
    const printHtml = () => {
      const rows = sale.items.map((i) =>
        `<tr><td>${i.sparepart.name} x${i.qty}</td><td class="right">${formatRp(Number(i.price) * i.qty)}</td></tr>`).join('');
      printDocument(thermal ? 'Struk Penjualan' : 'Invoice Penjualan', `
        <h2 class="center">${thermal ? 'STRUK PENJUALAN' : 'INVOICE PENJUALAN'}</h2>
        <p class="center muted">No. ${sale.invoiceNo} - ${new Date(sale.date).toLocaleString('id-ID')}</p>
        <p>Pembeli: ${buyer}</p>
        <div class="divider"></div>
        <table>${rows}</table>
        <div class="divider"></div>
        <table>
          <tr><td>Subtotal</td><td class="right">${formatRp(sale.subtotal)}</td></tr>
          <tr><td>Diskon</td><td class="right">-${formatRp(sale.discountAmount)}</td></tr>
          <tr><td>Pajak</td><td class="right">${formatRp(sale.taxAmount)}</td></tr>
          <tr class="total-row"><td>Total</td><td class="right">${formatRp(sale.total)}</td></tr>
          <tr><td>Dibayar</td><td class="right">${formatRp(sale.paid)}</td></tr>
          <tr><td>Kembalian</td><td class="right">${formatRp(sale.change)}</td></tr>
        </table>
        <p class="center muted">Terima kasih telah berbelanja.</p>
      `, { thermal, paperMm: paperWidthMm(settings) });
    };
    if (isRawMode(settings)) {
      printThermal({ settings, build: () => buildSalesReceipt(sale, settings), fallback: printHtml, onError: setError });
      return;
    }
    printHtml();
  }

  return (
    <div className="space-y-5">
      <DetailHeader
        icon={FaShoppingCart}
        title={sale.invoiceNo}
        badge={
          <span className="badge bg-emerald-50 text-emerald-700 ring-1 ring-inset ring-emerald-200">
            <span className="h-1.5 w-1.5 rounded-full bg-emerald-500" aria-hidden /> Lunas
          </span>
        }
        subtitle={`${new Date(sale.date).toLocaleDateString('id-ID')} · ${buyer}`}
      >
        <Link to="/sales" className="btn-secondary"><FaArrowLeft aria-hidden /> Kembali</Link>
        {isAdmin && <button type="button" className="btn-danger" onClick={handleDelete}><FaTrash aria-hidden /> Hapus</button>}
      </DetailHeader>

      <Alert message={error} />

      {/* Dua kartu informasi (sama seperti detail service) */}
      <div className="grid gap-4 md:grid-cols-2">
        <div className="card overflow-hidden animate-fade-up">
          <CardHeader icon={FaUser}>Informasi Pembeli</CardHeader>
          <div className="p-5">
            <div className="flex items-center gap-3 rounded-xl bg-slate-50 p-3.5">
              <span className="flex h-12 w-12 items-center justify-center rounded-full bg-gradient-to-br from-brand-500 to-sky-500 text-lg font-bold text-white">
                {(buyer || '?').charAt(0).toUpperCase()}
              </span>
              <div>
                <div className="font-bold text-slate-900">{buyer}</div>
                <div className="flex items-center gap-1.5 text-xs text-slate-500">
                  {sale.customer?.phone
                    ? <><FaPhone className="text-[10px]" aria-hidden /> {sale.customer.phone}</>
                    : (sale.customer ? '-' : 'Pembeli tanpa data pelanggan')}
                </div>
              </div>
            </div>
            <dl className="info-list mt-3">
              <InfoRow label={lbl(FaUser, 'Jenis pembeli')}>{sale.customer ? 'Pelanggan Terdaftar' : 'Pelanggan Umum'}</InfoRow>
              {sale.customer?.address && <InfoRow label={lbl(FaReceipt, 'Alamat')}>{sale.customer.address}</InfoRow>}
            </dl>
          </div>
        </div>

        <div className="card overflow-hidden animate-fade-up">
          <CardHeader icon={FaFileInvoice}>Informasi Penjualan</CardHeader>
          <div className="p-5">
            <div className="flex items-center gap-3 rounded-xl bg-slate-50 p-3.5">
              <span className="icon-tile h-12 w-12 text-xl"><FaReceipt aria-hidden /></span>
              <div>
                <div className="font-extrabold text-slate-900">{sale.invoiceNo}</div>
                <span className="mt-0.5 inline-block rounded bg-slate-900 px-2 py-0.5 text-[11px] font-bold tracking-wide text-white">PENJUALAN SPAREPART</span>
              </div>
            </div>
            <dl className="info-list mt-3">
              <InfoRow label={lbl(FaCalendarAlt, 'Tanggal')}>{new Date(sale.date).toLocaleDateString('id-ID')}</InfoRow>
              <InfoRow label={lbl(FaClock, 'Waktu')}>{new Date(sale.date).toLocaleTimeString('id-ID', { hour: '2-digit', minute: '2-digit' })}</InfoRow>
              <InfoRow label={lbl(FaBoxes, 'Jumlah barang')}>{sale.items.length} jenis · {totalQty} pcs</InfoRow>
              <InfoRow label={lbl(FaTicketAlt, 'Diskon')}>{sale.discount?.name || '-'}</InfoRow>
            </dl>
          </div>
        </div>
      </div>

      {/* Banner lunas (sama seperti ServiceReceipt) */}
      <section className="card overflow-hidden animate-fade-up" style={stagger(0)}>
        <div className="flex flex-wrap items-center justify-between gap-4 bg-gradient-to-r from-emerald-700 to-emerald-500 px-5 py-5 text-white">
          <div className="flex items-center gap-4">
            <span className="flex h-14 w-14 shrink-0 animate-pop items-center justify-center rounded-full bg-white text-2xl text-emerald-600 shadow-lg shadow-emerald-900/20" style={{ animationDelay: '250ms' }}>
              <FaCheckCircle aria-hidden />
            </span>
            <div>
              <h2 className="text-lg font-extrabold leading-tight text-white">Transaksi lunas</h2>
              <p className="text-sm text-emerald-50">Pembayaran diterima pada {fmtDateTime(sale.date)}.</p>
            </div>
          </div>
          <div className="text-right">
            <div className="text-sm font-semibold text-emerald-50">Total dibayar</div>
            <div className="text-3xl font-extrabold tabular-nums leading-tight">{formatRp(sale.total)}</div>
          </div>
        </div>
      </section>

      <div className="grid items-start gap-4 lg:grid-cols-3">
        {/* Kolom kiri: rincian item */}
        <div className="space-y-4 lg:col-span-2">
          <section className="card overflow-hidden animate-fade-up" style={stagger(1)}>
            <CardHeader icon={FaCogs} right={<span className="badge bg-white/20 text-white">{sale.items.length} item</span>}>Sparepart Dibeli</CardHeader>
            <div className="overflow-x-auto">
              <table className="table-base">
                <thead>
                  <tr><th className="col-no">No</th><th>Sparepart</th><th className="num">Qty</th><th className="num">Harga Satuan</th><th className="num">Subtotal</th></tr>
                </thead>
                <tbody>
                  {sale.items.map((i, n) => (
                    <tr key={i.id}>
                      <td className="col-no">{n + 1}</td>
                      <td className="font-medium text-slate-800">
                        {i.sparepart.name}
                        {i.sparepart.code ? <span className="block text-xs text-slate-500">{i.sparepart.code}</span> : null}
                      </td>
                      <td className="num">{i.qty}</td>
                      <td className="num">{formatRp(i.price)}</td>
                      <td className="num font-semibold">{formatRp(Number(i.price) * i.qty)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            <SubtotalStrip label="Total Harga Sparepart" value={formatRp(sale.subtotal)} />
          </section>
        </div>

        {/* Kolom kanan: struk pembayaran + aksi */}
        <div className="space-y-4 lg:sticky lg:top-4">
          <section className="card overflow-hidden animate-fade-up" style={stagger(2)}>
            <CardHeader icon={FaReceipt} tone="green">Ringkasan Pembayaran</CardHeader>
            <div className="p-5">
              <dl className="space-y-2 text-sm">
                <ReceiptRow label="Subtotal" value={formatRp(sale.subtotal)} />
                <ReceiptRow
                  label={sale.discount ? `Diskon (${sale.discount.name})` : 'Diskon'}
                  value={hasDiscount ? `-${formatRp(sale.discountAmount)}` : formatRp(0)}
                  tone={hasDiscount ? 'text-emerald-600' : 'text-slate-800'}
                />
                <ReceiptRow label="Pajak" value={formatRp(sale.taxAmount)} />
              </dl>

              <div className="my-4 border-t-2 border-dashed border-slate-300" />

              <div className="flex items-end justify-between gap-3">
                <span className="text-sm font-semibold text-slate-600">Total</span>
                <span className="text-2xl font-extrabold tabular-nums text-brand-700">{formatRp(sale.total)}</span>
              </div>

              <dl className="mt-4 space-y-2 rounded-xl bg-slate-50 p-3.5 text-sm">
                <ReceiptRow label="Dibayar" value={formatRp(sale.paid)} />
                <div className="flex items-center justify-between gap-4">
                  <dt className="text-slate-500">Kembalian</dt>
                  <dd className="text-base font-extrabold tabular-nums text-emerald-700">{formatRp(sale.change)}</dd>
                </div>
              </dl>
            </div>
            <div className="no-print flex flex-col gap-2 border-t border-slate-100 bg-slate-50/60 p-4">
              <button type="button" className="btn-primary" onClick={() => handlePrint(false)}><FaPrint aria-hidden /> Cetak Invoice</button>
              <button type="button" className="btn-secondary" onClick={() => handlePrint(true)}><FaPrint aria-hidden /> Struk Thermal</button>
              <button type="button" className="btn-secondary" onClick={handleWa}><FaWhatsapp className="text-emerald-600" aria-hidden /> Kirim WhatsApp</button>
            </div>
          </section>
        </div>
      </div>
    </div>
  );
}
