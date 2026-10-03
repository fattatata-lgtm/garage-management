import React, { useEffect, useMemo, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import api from '../../api/axios';
import Alert from '../../components/ui/Alert';

import { Link } from 'react-router-dom';
import { FaArrowLeft, FaCogs, FaPlus, FaSave, FaShoppingCart, FaTimes, FaTrash, FaUser, FaPhone, FaMoneyBillWave, FaTicketAlt, FaExclamationCircle } from 'react-icons/fa';
import DetailHeader from '../../components/ui/DetailHeader';
import CardHeader from '../../components/ui/CardHeader';
import SparepartPicker from '../../components/ui/SparepartPicker';
import InfoRow from '../../components/ui/InfoRow';
function formatRp(n) { return `Rp${Number(n || 0).toLocaleString('id-ID')}`; }

export default function SalesAdd() {
  const navigate = useNavigate();
  const [searchParams] = useSearchParams();

  const [invoiceNo, setInvoiceNo] = useState('');
  const [customers, setCustomers] = useState([]);
  const [spareparts, setSpareparts] = useState([]);
  const [discounts, setDiscounts] = useState([]);
  const [settings, setSettings] = useState(null);

  const [customerId, setCustomerId] = useState(searchParams.get('newFor') || '');
  const [walkInName, setWalkInName] = useState('');
  const [items, setItems] = useState([]); // { sparepartId, qty }
  const [discountId, setDiscountId] = useState('');
  const [paid, setPaid] = useState('');
  const [error, setError] = useState('');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    api.get('/sales/next-invoice').then(({ data }) => setInvoiceNo(data.invoiceNo));
    api.get('/customers').then(({ data }) => setCustomers(data));
    api.get('/spareparts').then(({ data }) => setSpareparts(data));
    api.get('/discounts?activeOnly=true').then(({ data }) => setDiscounts(data));
    api.get('/settings').then(({ data }) => setSettings(data));
  }, []);

  const totals = useMemo(() => {
    const subtotal = items.reduce((s, it) => {
      const sp = spareparts.find((p) => p.id === Number(it.sparepartId));
      return s + (sp ? Number(sp.sellPrice) * (Number(it.qty) || 0) : 0);
    }, 0);
    const discount = discounts.find((d) => d.id === Number(discountId));
    const discountAmount = discount
      ? (discount.type === 'PERCENTAGE' ? (subtotal * Number(discount.value)) / 100 : Number(discount.value))
      : 0;
    const afterDiscount = Math.max(subtotal - discountAmount, 0);
    const taxRate = settings ? Number(settings.taxSales) : 10;
    const taxAmount = (afterDiscount * taxRate) / 100;
    return { subtotal, discountAmount, taxRate, taxAmount, total: afterDiscount + taxAmount };
  }, [items, spareparts, discounts, discountId, settings]);

  function addItem() { setItems([...items, { sparepartId: '', qty: 1 }]); }
  function updateItem(i, field, value) {
    const copy = [...items]; copy[i] = { ...copy[i], [field]: value }; setItems(copy);
  }
  function removeItem(i) { setItems(items.filter((_, idx) => idx !== i)); }

  async function handleSubmit(e) {
    e.preventDefault();
    setSaving(true); setError('');
    try {
      const { data } = await api.post('/sales', {
        customerId: customerId || null,
        walkInName,
        items: items.filter((it) => it.sparepartId && it.qty),
        discountId: discountId || null,
        paid: Number(paid),
      });
      navigate(`/sales/${data.id}`);
    } catch (err) {
      setError(err?.response?.data?.message || 'Gagal menyimpan transaksi penjualan.');
    } finally { setSaving(false); }
  }

  const change = paid !== '' ? Math.max(Number(paid) - totals.total, 0) : 0;
  const selectedCustomer = customers.find((c) => String(c.id) === String(customerId));
  const pas = Math.ceil(totals.total);
  const quickPay = [...new Set([pas, Math.ceil(pas / 50000) * 50000, Math.ceil(pas / 100000) * 100000])].filter((n) => n > 0);
  const headBtn = 'btn bg-white/15 !px-3 !py-1.5 text-xs text-white hover:bg-white/25 shadow-none';
  const rpAddon = 'flex items-center rounded-l-lg border border-r-0 border-slate-300 bg-slate-100 px-3 text-sm text-slate-600';

  return (
    <form onSubmit={handleSubmit} className="space-y-4">
      <DetailHeader
        icon={FaShoppingCart}
        title="Tambah Penjualan"
        subtitle={<>No. Invoice: <span className="font-semibold text-slate-700">{invoiceNo || '...'}</span> &middot; {new Date().toLocaleDateString('id-ID')}</>}
      >
        <Link to="/sales" className="btn-secondary"><FaArrowLeft aria-hidden /> Kembali</Link>
      </DetailHeader>

      <Alert message={error} />

      {/* Pembeli */}
      <div className="card overflow-hidden animate-fade-up">
        <CardHeader icon={FaUser}>Data Pembeli</CardHeader>
        <div className="space-y-4 p-5">
          <div className="grid gap-4 sm:grid-cols-2">
            <div>
              <label className="label flex items-center gap-1.5"><FaUser className="text-[12px] text-brand-500" aria-hidden /> Pelanggan (opsional)</label>
              <select className="input" value={customerId} onChange={(e) => setCustomerId(e.target.value)}>
                <option value="">-- Pelanggan Umum (walk-in) --</option>
                {customers.map((c) => <option key={c.id} value={c.id}>{c.name} ({c.phone})</option>)}
              </select>
            </div>
            {!customerId && (
              <div>
                <label className="label flex items-center gap-1.5"><FaUser className="text-[12px] text-brand-500" aria-hidden /> Nama Pembeli (walk-in)</label>
                <input className="input" value={walkInName} onChange={(e) => setWalkInName(e.target.value)} placeholder="Pelanggan Umum" />
              </div>
            )}
          </div>
          {selectedCustomer && (
            <div className="rounded-xl border border-brand-100 bg-brand-50/40 p-4 animate-fade-in">
              <div className="flex items-center gap-3">
                <span className="flex h-11 w-11 items-center justify-center rounded-full bg-gradient-to-br from-brand-500 to-sky-500 text-lg font-bold text-white">{(selectedCustomer.name || '?').charAt(0).toUpperCase()}</span>
                <div>
                  <div className="font-bold text-slate-900">{selectedCustomer.name}</div>
                  <div className="text-xs text-slate-500">ID: #{selectedCustomer.id}</div>
                </div>
              </div>
              <dl className="info-list mt-3">
                <InfoRow label={<span className="flex items-center gap-2"><FaPhone className="text-brand-500" aria-hidden /> No. WhatsApp</span>}>{selectedCustomer.phone || '-'}</InfoRow>
              </dl>
            </div>
          )}
        </div>
      </div>

      {/* Item sparepart */}
      <div className="card animate-fade-up">
        <CardHeader
          icon={FaCogs}
          className="rounded-t-2xl"
          right={<button type="button" className={headBtn} onClick={addItem}><FaPlus aria-hidden /> Tambah Item</button>}
        >
          Item Sparepart
        </CardHeader>
        <div className="space-y-3 p-5">
          {items.map((it, i) => {
            const sp = spareparts.find((p) => p.id === Number(it.sparepartId));
            const over = sp && Number(it.qty) > sp.stock;
            const rowSubtotal = sp ? Number(sp.sellPrice) * (Number(it.qty) || 0) : 0;
            return (
              <div key={i} className="grid grid-cols-1 items-start gap-3 rounded-xl border border-slate-200 bg-slate-50/60 p-3.5 sm:grid-cols-12">
                <div className="sm:col-span-4">
                  <label className="label">Sparepart</label>
                  <SparepartPicker options={spareparts} value={it.sparepartId} onPick={(x) => updateItem(i, 'sparepartId', x.id)} />
                </div>
                <div className="sm:col-span-2">
                  <label className="label">Jumlah</label>
                  <input type="number" min="1" className={`input ${over ? '!border-red-400 !ring-red-100' : ''}`} value={it.qty} onChange={(e) => updateItem(i, 'qty', e.target.value)} />
                </div>
                <div className="sm:col-span-2">
                  <label className="label">Harga Satuan</label>
                  <div className="flex"><span className={rpAddon}>Rp</span><input readOnly className="input !rounded-l-none bg-slate-50" placeholder="Harga" value={sp ? Number(sp.sellPrice) : ''} /></div>
                </div>
                <div className="sm:col-span-3">
                  <label className="label">Subtotal</label>
                  <div className="flex"><span className={rpAddon}>Rp</span><input readOnly className="input !rounded-l-none bg-slate-50" value={rowSubtotal} /></div>
                </div>
                <div className="flex sm:col-span-1 sm:justify-center sm:pt-[1.85rem]">
                  <button type="button" className="icon-btn icon-btn-delete !h-9 !w-9" onClick={() => removeItem(i)} title="Hapus baris" aria-label="Hapus baris"><FaTrash aria-hidden /></button>
                </div>
                {over && <p className="text-xs font-semibold text-red-600 sm:col-span-12">Jumlah melebihi stok tersedia ({sp.stock}).</p>}
              </div>
            );
          })}
          {items.length === 0 && (
            <div className="flex flex-col items-center gap-1.5 rounded-xl border-2 border-dashed border-slate-200 py-8 text-center text-sm text-slate-400">
              <FaCogs className="text-2xl text-slate-300" aria-hidden />
              Belum ada item. Klik “Tambah Item” lalu cari sparepart.
            </div>
          )}
          <div className="ml-auto w-full pt-1 sm:w-3/5">
            <label className="label">Total Biaya Sparepart</label>
            <div className="flex"><span className={rpAddon}>Rp</span><input readOnly className="input !rounded-l-none bg-slate-50 font-semibold" value={Number(totals.subtotal).toLocaleString('id-ID')} /></div>
          </div>
        </div>
      </div>

      {/* Pembayaran */}
      <div className="card overflow-hidden animate-fade-up">
        <CardHeader icon={FaMoneyBillWave}>Diskon &amp; Pembayaran</CardHeader>
        <div className="grid gap-6 p-5 md:grid-cols-2">
          <div className="space-y-4">
            <div>
              <label className="label flex items-center gap-1.5"><FaTicketAlt className="text-[12px] text-brand-500" aria-hidden /> Diskon</label>
              <select className="input" value={discountId} onChange={(e) => setDiscountId(e.target.value)}>
                <option value="">-- Tidak ada diskon --</option>
                {discounts.map((d) => <option key={d.id} value={d.id}>{d.name} {d.code ? `(${d.code})` : ''}</option>)}
              </select>
            </div>
            <div>
              <label className="label flex items-center gap-1.5"><FaMoneyBillWave className="text-[12px] text-brand-500" aria-hidden /> Jumlah Dibayar *</label>
              <div className="flex">
                <span className={rpAddon}>Rp</span>
                <input type="number" min="0" className="input !rounded-l-none text-base font-semibold" required placeholder="Masukkan jumlah pembayaran" value={paid} onChange={(e) => setPaid(e.target.value)} />
              </div>
              <div className="mt-2 flex flex-wrap gap-1.5">
                {quickPay.map((n, i) => (
                  <button key={n} type="button" onClick={() => setPaid(String(n))}
                    className="rounded-full border border-slate-200 bg-white px-3 py-1 text-xs font-semibold text-slate-600 transition hover:border-brand-300 hover:bg-brand-50 hover:text-brand-700">
                    {i === 0 ? 'Uang pas' : formatRp(n)}
                  </button>
                ))}
              </div>
              {paid !== '' && (
                Number(paid) < totals.total
                  ? <div className="mt-3 rounded-xl border border-red-200 bg-red-50 px-4 py-2.5 text-sm font-semibold text-red-700">Kurang {formatRp(totals.total - Number(paid))}</div>
                  : <div className="mt-3 flex items-center justify-between rounded-xl border border-emerald-200 bg-emerald-50 px-4 py-2.5 text-sm"><span className="text-emerald-700">Kembalian</span><span className="text-lg font-extrabold tabular-nums text-emerald-700">{formatRp(change)}</span></div>
              )}
            </div>
          </div>
          <div className="summary-box h-fit">
            <div className="summary-row"><span>Subtotal</span><span>{formatRp(totals.subtotal)}</span></div>
            <div className="summary-row"><span>Diskon</span><span className="text-emerald-600">-{formatRp(totals.discountAmount)}</span></div>
            <div className="summary-row"><span>Tax Sales ({totals.taxRate}%)</span><span>{formatRp(totals.taxAmount)}</span></div>
            <div className="summary-total !text-lg"><span>Total</span><span className="text-brand-700">{formatRp(totals.total)}</span></div>
            <div className="summary-row"><span>Kembalian</span><span>{formatRp(change)}</span></div>
          </div>
        </div>
      </div>

      {/* Bar aksi melayang */}
      <div className="sticky bottom-3 z-10 flex flex-wrap items-center justify-between gap-3 rounded-2xl border border-slate-200 bg-white/90 px-4 py-3 shadow-lg backdrop-blur">
        <p className="flex items-center gap-1.5 text-xs text-slate-500">
          {items.length === 0 ? <><FaExclamationCircle aria-hidden /> Tambahkan minimal 1 item sparepart.</> : `${items.length} item · Total ${formatRp(totals.total)}`}
        </p>
        <div className="flex gap-2">
          <button type="button" className="btn-secondary" onClick={() => navigate('/sales')}><FaTimes aria-hidden /> Batal</button>
          <button type="submit" className="btn-primary" disabled={saving || items.length === 0}><FaSave aria-hidden />{saving ? 'Menyimpan...' : 'Simpan Transaksi'}</button>
        </div>
      </div>
    </form>
  );
}
