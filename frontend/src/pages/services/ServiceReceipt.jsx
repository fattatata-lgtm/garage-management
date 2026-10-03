import React from 'react';
import { FaCalendarCheck, FaCheck, FaCheckCircle, FaCogs, FaHistory, FaLightbulb, FaPrint, FaReceipt, FaStickyNote, FaTachometerAlt, FaTools, FaWhatsapp } from 'react-icons/fa';
import CardHeader from '../../components/ui/CardHeader';
import InfoRow from '../../components/ui/InfoRow';
import { stagger, SubtotalStrip, ReceiptRow } from '../../components/ui/ReceiptParts';
import { formatRp, fmtDate, fmtDateTime, jasaTotalOf, partsTotalOf } from '../../utils/format';

const lbl = (Icon, text) => (
  <span className="flex items-center gap-2"><Icon className="text-brand-500" aria-hidden /> {text}</span>
);

// Tampilan detail transaksi service yang sudah SELESAI (Lunas): hanya lihat & cetak.
export default function ServiceReceipt({ service: s, onPrint, onPrintWorkOrder, onSendWa }) {
  const jasa = jasaTotalOf(s);
  const parts = partsTotalOf(s);
  const logs = s.logs || [];
  const paidLog = [...logs].reverse().find((l) => l.status === 'SELESAI');
  const paidAt = paidLog?.createdAt || s.updatedAt;
  const hasDiscount = Number(s.discountAmount) > 0;

  return (
    <div className="space-y-4">
      {/* Banner lunas */}
      <section className="card overflow-hidden animate-fade-up" style={stagger(0)}>
        <div className="flex flex-wrap items-center justify-between gap-4 bg-gradient-to-r from-emerald-700 to-emerald-500 px-5 py-5 text-white">
          <div className="flex items-center gap-4">
            <span className="flex h-14 w-14 shrink-0 animate-pop items-center justify-center rounded-full bg-white text-2xl text-emerald-600 shadow-lg shadow-emerald-900/20" style={{ animationDelay: '250ms' }}>
              <FaCheckCircle aria-hidden />
            </span>
            <div>
              <h2 className="text-lg font-extrabold leading-tight text-white">Transaksi lunas</h2>
              <p className="text-sm text-emerald-50">Pembayaran diterima pada {fmtDateTime(paidAt)}. Service dinyatakan selesai.</p>
            </div>
          </div>
          <div className="text-right">
            <div className="text-sm font-semibold text-emerald-50">Total dibayar</div>
            <div className="text-3xl font-extrabold tabular-nums leading-tight">{formatRp(s.total)}</div>
          </div>
        </div>
      </section>

      <div className="grid items-start gap-4 lg:grid-cols-3">
        {/* Kolom kiri: rincian */}
        <div className="space-y-4 lg:col-span-2">
          <section className="card overflow-hidden animate-fade-up" style={stagger(1)}>
            <CardHeader icon={FaTools} right={<span className="badge bg-white/20 text-white">{s.details.length} jasa</span>}>Detail Service</CardHeader>
            <div className="overflow-x-auto">
              <table className="table-base">
                <thead>
                  <tr><th className="col-no">No</th><th>Jenis Service</th><th className="num">Biaya</th></tr>
                </thead>
                <tbody>
                  {s.details.length === 0 ? (
                    <tr><td colSpan={3}>Tidak ada detail service.</td></tr>
                  ) : s.details.map((d, i) => (
                    <tr key={`d${d.id}`}>
                      <td className="col-no">{i + 1}</td>
                      <td className="font-medium text-slate-800">
                        {d.name}
                        {d.description ? <span className="block text-xs text-slate-500">{d.description}</span> : null}
                      </td>
                      <td className="num font-semibold">{formatRp(d.cost)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            <SubtotalStrip label="Total Biaya Service" value={formatRp(jasa)} />
          </section>

          <section className="card overflow-hidden animate-fade-up" style={stagger(2)}>
            <CardHeader icon={FaCogs} right={<span className="badge bg-white/20 text-white">{s.spareparts.length} item</span>}>Sparepart Digunakan</CardHeader>
            <div className="overflow-x-auto">
              <table className="table-base">
                <thead>
                  <tr><th className="col-no">No</th><th>Sparepart</th><th className="num">Qty</th><th className="num">Harga Satuan</th><th className="num">Subtotal</th></tr>
                </thead>
                <tbody>
                  {s.spareparts.length === 0 ? (
                    <tr><td colSpan={5}>Tidak ada sparepart dipakai.</td></tr>
                  ) : s.spareparts.map((sp, i) => (
                    <tr key={`s${sp.id}`}>
                      <td className="col-no">{i + 1}</td>
                      <td className="font-medium text-slate-800">
                        {sp.sparepart.name}
                        {sp.sparepart.code ? <span className="block text-xs text-slate-500">{sp.sparepart.code}</span> : null}
                      </td>
                      <td className="num">{sp.qty}</td>
                      <td className="num">{formatRp(sp.price)}</td>
                      <td className="num font-semibold">{formatRp(Number(sp.price) * sp.qty)}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            <SubtotalStrip label="Total Biaya Sparepart" value={formatRp(parts)} />
          </section>

          <section className="card overflow-hidden animate-fade-up" style={stagger(3)}>
            <CardHeader icon={FaStickyNote}>Catatan &amp; Rekomendasi</CardHeader>
            <div className="p-5">
              <dl className="info-list">
                <InfoRow label={lbl(FaTachometerAlt, 'Kilometer')}>{s.km != null ? `${Number(s.km).toLocaleString('id-ID')} km` : '-'}</InfoRow>
                <InfoRow label={lbl(FaCalendarCheck, 'Service berikutnya')}>{fmtDate(s.nextServiceDate)}</InfoRow>
              </dl>
              {s.nextServiceRecommendation && (
                <div className="mt-3 flex gap-3 rounded-xl border border-brand-200 bg-brand-50 p-3.5 text-sm">
                  <FaLightbulb className="mt-0.5 shrink-0 text-brand-600" aria-hidden />
                  <div>
                    <div className="font-semibold text-brand-800">Rekomendasi servis berikutnya</div>
                    <p className="text-slate-700">{s.nextServiceRecommendation}</p>
                  </div>
                </div>
              )}
              {s.internalNote && (
                <div className="mt-3 flex gap-3 rounded-xl border border-amber-200 bg-amber-50 p-3.5 text-sm">
                  <FaStickyNote className="mt-0.5 shrink-0 text-amber-600" aria-hidden />
                  <div>
                    <div className="font-semibold text-amber-800">Catatan internal</div>
                    <p className="text-slate-700">{s.internalNote}</p>
                  </div>
                </div>
              )}
            </div>
          </section>
        </div>

        {/* Kolom kanan: struk pembayaran + aksi */}
        <div className="space-y-4 lg:sticky lg:top-4">
          <section className="card overflow-hidden animate-fade-up" style={stagger(2)}>
            <CardHeader icon={FaReceipt} tone="green">Ringkasan Pembayaran</CardHeader>
            <div className="p-5">
              <dl className="space-y-2 text-sm">
                <ReceiptRow label="Biaya service" value={formatRp(jasa)} />
                <ReceiptRow label="Biaya sparepart" value={formatRp(parts)} />
                <div className="border-t border-dashed border-slate-300 pt-2" />
                <ReceiptRow label="Subtotal" value={formatRp(s.subtotal)} />
                <ReceiptRow
                  label={s.discount ? `Diskon (${s.discount.name})` : 'Diskon'}
                  value={hasDiscount ? `-${formatRp(s.discountAmount)}` : formatRp(0)}
                  tone={hasDiscount ? 'text-emerald-600' : 'text-slate-800'}
                />
                <ReceiptRow label="Pajak" value={formatRp(s.taxAmount)} />
              </dl>

              <div className="my-4 border-t-2 border-dashed border-slate-300" />

              <div className="flex items-end justify-between gap-3">
                <span className="text-sm font-semibold text-slate-600">Total</span>
                <span className="text-2xl font-extrabold tabular-nums text-brand-700">{formatRp(s.total)}</span>
              </div>

              <dl className="mt-4 space-y-2 rounded-xl bg-slate-50 p-3.5 text-sm">
                <ReceiptRow label="Dibayar" value={formatRp(s.paid)} />
                <div className="flex items-center justify-between gap-4">
                  <dt className="text-slate-500">Kembalian</dt>
                  <dd className="text-base font-extrabold tabular-nums text-emerald-700">{formatRp(s.change)}</dd>
                </div>
              </dl>
            </div>
            <div className="no-print flex flex-col gap-2 border-t border-slate-100 bg-slate-50/60 p-4">
              <button type="button" className="btn-primary" onClick={() => onPrint('invoice')}><FaPrint aria-hidden /> Cetak Invoice</button>
              <div className="grid grid-cols-2 gap-2">
                <button type="button" className="btn-secondary" onClick={() => onPrint('thermal')}><FaPrint aria-hidden /> Struk</button>
                <button type="button" className="btn-secondary" onClick={onPrintWorkOrder}><FaPrint aria-hidden /> Work Order</button>
              </div>
              <button type="button" className="btn-secondary" onClick={onSendWa}><FaWhatsapp className="text-emerald-600" aria-hidden /> Kirim WhatsApp</button>
            </div>
          </section>

          {logs.length > 0 && (
            <section className="card overflow-hidden animate-fade-up" style={stagger(3)}>
              <CardHeader icon={FaHistory}>Riwayat Tahapan</CardHeader>
              <ol className="relative space-y-5 p-5 before:absolute before:bottom-8 before:left-8 before:top-8 before:w-px before:bg-slate-200">
                {logs.map((l, i) => {
                  const last = i === logs.length - 1;
                  return (
                    <li key={l.id} className="relative flex gap-3.5">
                      <span className={`relative z-10 mt-0.5 flex h-6 w-6 shrink-0 items-center justify-center rounded-full text-[10px] ${last ? 'bg-emerald-600 text-white shadow-md shadow-emerald-600/30' : 'bg-brand-50 text-brand-600 ring-1 ring-inset ring-brand-200'}`}>
                        <FaCheck aria-hidden />
                      </span>
                      <div className="min-w-0 flex-1">
                        <div className="text-sm font-semibold leading-snug text-slate-800">{l.title}</div>
                        {l.note && <p className="text-xs text-slate-500">{l.note}</p>}
                        <div className="mt-0.5 text-xs text-slate-400">{fmtDateTime(l.createdAt)}{l.actor ? ` oleh ${l.actor}` : ''}</div>
                      </div>
                    </li>
                  );
                })}
              </ol>
            </section>
          )}
        </div>
      </div>
    </div>
  );
}
