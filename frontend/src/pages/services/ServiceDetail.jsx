import React, { useEffect, useState, useMemo } from 'react';
import { useParams, useNavigate, Link } from 'react-router-dom';
import api from '../../api/axios';
import { useAuth } from '../../context/AuthContext';
import Spinner from '../../components/ui/Spinner';
import Alert from '../../components/ui/Alert';
import StatusBadge from '../../components/ui/StatusBadge';
import ServiceTypePicker from '../../components/ui/ServiceTypePicker';
import { printDocument, paperWidthMm } from '../../utils/print';
import { printInvoice } from '../../utils/invoice';
import { isRawMode, prepareConnection, printThermal } from '../../utils/thermal';
import { buildReceivedReceipt, buildServiceReceipt, buildWorkOrderReceipt } from '../../utils/thermalReceipts';
import useSettings from '../../hooks/useSettings';
import { openWhatsApp } from '../../utils/whatsapp';
import { speakCashierCall } from '../../utils/tts';
import { FaCarSide, FaCheckCircle, FaClipboardList, FaCreditCard, FaExclamationCircle, FaMoneyBillWave, FaPen, FaPlay, FaPlus, FaPrint, FaReceipt, FaSave, FaTimes, FaTrash, FaUser, FaVolumeUp, FaWhatsapp, FaWrench, FaHashtag, FaListUl, FaTools, FaCogs, FaTachometerAlt, FaStickyNote, FaTicketAlt, FaCommentDots, FaPhone, FaCalendarAlt, FaUserCog, FaPalette, FaBarcode, FaCog, FaCalendarDay, FaCar, FaMotorcycle, FaSearch, FaArrowLeft } from 'react-icons/fa';
import SparepartPicker from '../../components/ui/SparepartPicker';
import CardHeader from '../../components/ui/CardHeader';
import DetailHeader from '../../components/ui/DetailHeader';
import SectionTitle from '../../components/ui/SectionTitle';
import InfoRow from '../../components/ui/InfoRow';
import ServiceReceipt from './ServiceReceipt';
import { formatRp, fmtDate, jasaTotalOf, partsTotalOf } from '../../utils/format';

const lbl = (Icon, text) => (
  <span className="flex items-center gap-2"><Icon className="text-brand-500" aria-hidden /> {text}</span>
);
const headBtn = 'btn bg-white/15 !px-3 !py-1.5 text-xs text-white hover:bg-white/25 shadow-none';

// Bentuk data yang dikirim ke server; juga dipakai untuk mendeteksi ada-tidaknya perubahan yang belum disimpan
function buildPayload({ km, details, usedParts, discountId, nextRecommendation, nextDate, internalNote }, withDiscount) {
  const payload = {
    km: km === '' || km == null ? null : Number(km),
    details: details
      .filter((d) => !d.picking && d.name && d.cost !== '' && d.cost != null)
      .map((d) => ({ name: d.name, description: d.description || '', cost: Number(d.cost) })),
    spareparts: usedParts
      .filter((p) => p.sparepartId && p.qty)
      .map((p) => ({ sparepartId: Number(p.sparepartId), qty: Number(p.qty), price: Number(p.price) })),
    nextServiceRecommendation: nextRecommendation,
    nextServiceDate: nextDate || null,
    internalNote,
  };
  if (withDiscount) payload.discountId = discountId ? Number(discountId) : null;
  return payload;
}

export default function ServiceDetail() {
  const settings = useSettings();
  const { id } = useParams();
  const navigate = useNavigate();
  const { user } = useAuth();

  const [service, setService] = useState(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [saving, setSaving] = useState(false);

  const [spareparts, setSpareparts] = useState([]);
  const [discounts, setDiscounts] = useState([]);
  const [serviceTypes, setServiceTypes] = useState([]);
  const [taxRate, setTaxRate] = useState(10);

  // State form pengerjaan / tagihan
  const [km, setKm] = useState('');
  const [details, setDetails] = useState([]); // { name, description, cost, picking? }
  const [usedParts, setUsedParts] = useState([]); // { sparepartId, qty, price }
  const [discountId, setDiscountId] = useState('');
  const [nextRecommendation, setNextRecommendation] = useState('');
  const [nextDate, setNextDate] = useState('');
  const [internalNote, setInternalNote] = useState('');
  const [savedSig, setSavedSig] = useState('');
  const [paidInput, setPaidInput] = useState('');

  const isStaffOrAdmin = user.role === 'ADMIN' || user.role === 'STAFF';
  const status = service?.status;
  const withDiscount = status === 'MENUNGGU_PEMBAYARAN' && isStaffOrAdmin;

  function load() {
    setLoading(true);
    return api.get(`/services/${id}`).then(({ data }) => {
      const next = {
        km: data.km ?? '',
        details: data.details.map((d) => ({ name: d.name, description: d.description || '', cost: d.cost })),
        usedParts: data.spareparts.map((s) => ({ sparepartId: s.sparepartId, qty: s.qty, price: s.price })),
        discountId: data.discountId || '',
        nextRecommendation: data.nextServiceRecommendation || '',
        nextDate: data.nextServiceDate ? data.nextServiceDate.slice(0, 10) : '',
        internalNote: data.internalNote || '',
      };
      setService(data);
      setKm(next.km); setDetails(next.details); setUsedParts(next.usedParts);
      setDiscountId(next.discountId); setNextRecommendation(next.nextRecommendation);
      setNextDate(next.nextDate); setInternalNote(next.internalNote);
      setSavedSig(JSON.stringify(buildPayload(next, data.status === 'MENUNGGU_PEMBAYARAN' && isStaffOrAdmin)));
      return data;
    }).finally(() => setLoading(false));
  }

  useEffect(() => { load(); }, [id]); // eslint-disable-line react-hooks/exhaustive-deps
  useEffect(() => {
    api.get('/service-types').then(({ data }) => setServiceTypes(data)).catch(() => {});
    if (isStaffOrAdmin) {
      api.get('/spareparts').then(({ data }) => setSpareparts(data)).catch(() => {});
      api.get('/discounts?activeOnly=true').then(({ data }) => setDiscounts(data)).catch(() => {});
      api.get('/settings').then(({ data }) => setTaxRate(Number(data.taxService))).catch(() => {});
    }
  }, [isStaffOrAdmin]);

  const formState = { km, details, usedParts, discountId, nextRecommendation, nextDate, internalNote };
  const dirty = service ? JSON.stringify(buildPayload(formState, withDiscount)) !== savedSig : false;

  // Sparepart yang tidak ada di daftar (mis. akun teknisi tidak boleh melihat master sparepart) tetap tampil namanya
  const partOptions = useMemo(() => {
    const map = new Map(spareparts.map((s) => [s.id, s]));
    (service?.spareparts || []).forEach((s) => { if (!map.has(s.sparepartId)) map.set(s.sparepartId, s.sparepart); });
    return [...map.values()];
  }, [spareparts, service]);

  // Pratinjau perhitungan (server tetap menghitung ulang & memvalidasi saat disimpan)
  const preview = useMemo(() => {
    const jasaTotal = details.reduce((s, d) => s + (d.picking ? 0 : Number(d.cost) || 0), 0);
    const partsTotal = usedParts.reduce((s, p) => s + (Number(p.price) || 0) * (Number(p.qty) || 0), 0);
    const subtotal = jasaTotal + partsTotal;
    const discount = discounts.find((d) => d.id === Number(discountId));
    let discountAmount = 0;
    if (discount) {
      discountAmount = discount.type === 'PERCENTAGE' ? (subtotal * Number(discount.value)) / 100 : Number(discount.value);
    }
    const afterDiscount = Math.max(subtotal - discountAmount, 0);
    const taxAmount = (afterDiscount * taxRate) / 100;
    return { jasaTotal, partsTotal, subtotal, discountAmount, taxAmount, total: afterDiscount + taxAmount };
  }, [details, usedParts, discountId, discounts, taxRate]);

  // ---- Aksi ----
  async function handleStart() {
    setSaving(true); setError('');
    try { await api.patch(`/services/${id}/start`); await load(); }
    catch (err) { setError(err?.response?.data?.message || 'Gagal memulai pengerjaan.'); }
    finally { setSaving(false); }
  }

  async function handleDelete() {
    const msg = status === 'SELESAI'
      ? 'Transaksi ini sudah LUNAS. Menghapusnya akan menghilangkan catatan pembayaran dan mengembalikan stok sparepart. Lanjutkan?'
      : 'Hapus transaksi service ini? Stok sparepart yang sudah terpakai akan dikembalikan.';
    if (!confirm(msg)) return;
    try { await api.delete(`/services/${id}`); navigate('/services'); }
    catch (err) { setError(err?.response?.data?.message || 'Gagal menghapus.'); }
  }

  // Menyimpan pekerjaan/tagihan ke server. Mengembalikan data service terbaru.
  async function persist() {
    await api.put(`/services/${id}/work`, buildPayload(formState, withDiscount));
    return load();
  }

  async function saveWork(e) {
    e?.preventDefault();
    setSaving(true); setError('');
    try { await persist(); }
    catch (err) { setError(err?.response?.data?.message || 'Gagal menyimpan pekerjaan.'); }
    finally { setSaving(false); }
  }

  // Dikerjakan -> Tagihan: simpan (bila ada perubahan) lalu pindah ke halaman tagihan
  async function handleFinishWork() {
    setError('');
    const validDetails = details.filter((d) => !d.picking && d.name && d.cost !== '' && d.cost != null);
    if (km === '' || km == null) { setError('Kilometer kendaraan wajib diisi.'); return; }
    if (validDetails.length < 1) { setError('Tambahkan minimal 1 jasa service.'); return; }
    if (!confirm('Tandai pekerjaan selesai dikerjakan? Halaman akan berpindah ke rincian biaya & pembayaran.')) return;
    setSaving(true);
    try {
      if (dirty) await persist();
      await api.patch(`/services/${id}/finish-work`);
      await load();
    } catch (err) { setError(err?.response?.data?.message || 'Gagal menyelesaikan pengerjaan.'); }
    finally { setSaving(false); }
  }

  // Tagihan -> Selesai: konfirmasi pembayaran -> Selesai (Lunas)
  async function handlePay() {
    setError('');
    const paid = Number(paidInput);
    if (paidInput === '' || isNaN(paid)) { setError('Isi jumlah yang dibayar.'); return; }
    setSaving(true);
    try {
      let current = service;
      if (dirty) current = await persist();
      if (paid < Number(current.total)) {
        setError(`Jumlah dibayar kurang dari total tagihan (${formatRp(current.total)}).`);
        return;
      }
      await api.post(`/services/${id}/complete`, { paid });
      await load();
      window.scrollTo({ top: 0, behavior: 'smooth' });
    } catch (err) { setError(err?.response?.data?.message || 'Gagal menyelesaikan transaksi.'); }
    finally { setSaving(false); }
  }

  // Kembalikan data terbaru; simpan dulu bila ada perubahan agar cetak/WA memakai angka yang benar
  async function freshService() {
    if (status === 'MENUNGGU_PEMBAYARAN' && isStaffOrAdmin && dirty) return persist();
    return service;
  }

  async function handleSendWa() {
    setError('');
    try {
      await freshService();
      const { data } = await api.get(`/services/${id}/whatsapp-message`);
      openWhatsApp(data.phone, data.message);
    } catch (err) { setError(err?.response?.data?.message || 'Gagal menyiapkan pesan WhatsApp.'); }
  }

  function handleCallCashier() {
    speakCashierCall({
      plateNumber: service.vehicle.plateNumber,
      ownerName: service.vehicle.customer.name,
    });
  }

  function handlePrintDiterima() {
    const v = service.vehicle;
    const printHtml = () => printDocument('Bukti Service Diterima', `
      <h2 class="center">BUKTI SERVICE DITERIMA</h2>
      <p class="center muted">No. ${service.invoiceNo}</p>
      <div class="divider"></div>
      <p><b>Kendaraan:</b> ${v.vehicleModel.brand} ${v.vehicleModel.model} (${v.vehicleModel.year})</p>
      <p><b>No. Plat:</b> ${v.plateNumber}</p>
      <p><b>Pemilik:</b> ${v.customer.name} (${v.customer.phone})</p>
      <p><b>Teknisi:</b> ${service.technician.name}</p>
      <p><b>Tanggal:</b> ${fmtDate(service.date)}</p>
      <p><b>Keluhan:</b> ${service.complaint || '-'}</p>
      <div class="divider"></div>
      <p class="muted center">Simpan bukti ini untuk pengambilan kendaraan.</p>
    `);
    if (isRawMode(settings)) {
      setError('');
      printThermal({ settings, build: () => buildReceivedReceipt(service, settings), fallback: printHtml, onError: setError });
      return;
    }
    printHtml();
  }

  // mode: 'tagihan' (belum dibayar) | 'invoice' | 'thermal' (sudah lunas)
  function printBilling(svc, mode) {
    const v = svc.vehicle;
    // Tagihan di printer thermal (bila mode cetak thermal aktif): format ringkas 58/80 mm
    const thermalBill = mode === 'tagihan' && isRawMode(settings);
    if (mode !== 'thermal' && !thermalBill) {
      // Invoice & Tagihan: format invoice bengkel (kop + tabel). Struk thermal tetap format ringkas di bawah.
      const tagihan = mode === 'tagihan';
      const vm = v.vehicleModel;
      const tipeKendaraan = `${vm.brand} ${vm.model} (${vm.year})`.toUpperCase();
      const jasaItems = svc.details.map((d) => ({ name: d.name, description: d.description, price: d.cost }));
      const partItems = svc.spareparts.map((sp) => ({ name: sp.sparepart.name, qty: sp.qty, uom: 'pcs', price: sp.price }));
      const sumRows = [];
      if (partItems.length) sumRows.push({ no: sumRows.length + 1, label: 'Biaya Suku Cadang', value: partsTotalOf(svc) });
      if (jasaItems.length) sumRows.push({ no: sumRows.length + 1, label: 'Biaya Jasa Service', value: jasaTotalOf(svc) });
      if (Number(svc.discountAmount) > 0) sumRows.push({ label: svc.discount ? `Diskon (${svc.discount.name})` : 'Diskon', value: -Number(svc.discountAmount) });
      if (Number(svc.taxAmount) > 0) sumRows.push({ label: 'Pajak', value: svc.taxAmount });
      printInvoice({
        title: tagihan ? 'Tagihan Service' : 'Invoice Service',
        settings,
        invoiceNo: svc.invoiceNo,
        date: svc.date,
        billTo: v.customer.name,
        toLine: `${v.plateNumber}, ${tipeKendaraan}`,
        tipeKendaraan,
        parts: { title: 'BIAYA SUKU CADANG', items: partItems },
        jasa: { title: 'BIAYA JASA SERVICE', items: jasaItems },
        summary: {
          rows: sumRows,
          grand: svc.total,
          after: tagihan ? [] : [{ label: 'Dibayar', value: svc.paid }, { label: 'Kembalian', value: svc.change }],
        },
        note: tagihan ? '' : 'LUNAS - Terima kasih atas kepercayaan Anda.',
      });
      return;
    }
    // Struk HTML lewat dialog cetak browser (mode BROWSER, atau cadangan bila printer thermal gagal)
    const printHtml = () => {
      const thermal = mode === 'thermal' || thermalBill;
      const tagihan = mode === 'tagihan';
      const jasaRows = svc.details.map((d) => `<tr><td>${d.name}</td><td class="right">${formatRp(d.cost)}</td></tr>`).join('');
      const partRows = svc.spareparts.map((s) => `<tr><td>${s.sparepart.name}<br/>${s.qty} x ${formatRp(s.price)}</td><td class="right">${formatRp(Number(s.price) * s.qty)}</td></tr>`).join('');
      const heading = tagihan ? 'TAGIHAN SERVICE' : thermal ? 'STRUK SERVICE' : 'INVOICE SERVICE';
      printDocument(tagihan ? 'Tagihan Service' : thermal ? 'Struk Thermal' : 'Invoice Service', `
        <h2 class="center">${heading}</h2>
        <p class="center muted">No. ${svc.invoiceNo} - ${fmtDate(svc.date)}</p>
        <div class="divider"></div>
        <p>Kendaraan: ${v.plateNumber} - ${v.vehicleModel.brand} ${v.vehicleModel.model}</p>
        <p>Pemilik: ${v.customer.name}</p>
        <div class="divider"></div>
        <p><b>Detail Service</b></p>
        <table>${jasaRows || '<tr><td>-</td><td></td></tr>'}</table>
        <div class="divider"></div>
        <p><b>Sparepart Digunakan</b></p>
        <table>${partRows || '<tr><td>-</td><td></td></tr>'}</table>
        <div class="divider"></div>
        <table>
          <tr><td>Total Biaya Service</td><td class="right">${formatRp(jasaTotalOf(svc))}</td></tr>
          <tr><td>Total Biaya Sparepart</td><td class="right">${formatRp(partsTotalOf(svc))}</td></tr>
          <tr><td>Subtotal</td><td class="right">${formatRp(svc.subtotal)}</td></tr>
          <tr><td>Diskon</td><td class="right">-${formatRp(svc.discountAmount)}</td></tr>
          <tr><td>Pajak</td><td class="right">${formatRp(svc.taxAmount)}</td></tr>
          <tr class="total-row"><td>${tagihan ? 'Total Tagihan' : 'Total'}</td><td class="right">${formatRp(svc.total)}</td></tr>
          ${tagihan ? '' : `<tr><td>Dibayar</td><td class="right">${formatRp(svc.paid)}</td></tr>
          <tr><td>Kembalian</td><td class="right">${formatRp(svc.change)}</td></tr>`}
        </table>
        <div class="divider"></div>
        <p class="center muted">${tagihan ? 'Mohon lakukan pembayaran di kasir.' : 'LUNAS - Terima kasih atas kepercayaan Anda.'}</p>
      `, { thermal, paperMm: paperWidthMm(settings) });
    };
    if (isRawMode(settings)) {
      printThermal({ settings, build: () => buildServiceReceipt(svc, settings, mode === 'tagihan' ? 'tagihan' : 'thermal'), fallback: printHtml, onError: setError });
      return;
    }
    printHtml();
  }

  async function handlePrintTagihan() {
    setError('');
    try {
      if (isRawMode(settings)) await prepareConnection(settings).catch(() => {}); // dialog pilih printer harus tepat setelah klik
      printBilling(await freshService(), 'tagihan');
    }
    catch (err) { setError(err?.response?.data?.message || 'Gagal menyiapkan tagihan.'); }
  }

  function handlePrintWorkOrder() {
    const printHtml = () => handlePrintWorkOrderHtml();
    if (isRawMode(settings)) {
      setError('');
      printThermal({ settings, build: () => buildWorkOrderReceipt(service, settings), fallback: printHtml, onError: setError });
      return;
    }
    printHtml();
  }

  function handlePrintWorkOrderHtml() {
    const v = service.vehicle;
    const jasaRows = service.details.map((d) => `<tr><td>${d.name}</td><td>${d.description || '-'}</td></tr>`).join('');
    const partRows = service.spareparts.map((s) => `<tr><td>${s.sparepart.name}</td><td class="right">${s.qty}</td></tr>`).join('');
    printDocument('Work Order', `
      <h2 class="center">WORK ORDER</h2>
      <p class="center muted">No. ${service.invoiceNo}</p>
      <div class="divider"></div>
      <p><b>Kendaraan:</b> ${v.plateNumber} - ${v.vehicleModel.brand} ${v.vehicleModel.model}</p>
      <p><b>Teknisi:</b> ${service.technician.name}</p>
      <p><b>KM:</b> ${service.km ?? '-'}</p>
      <p><b>Keluhan:</b> ${service.complaint || '-'}</p>
      <div class="divider"></div>
      <p><b>Jasa Dikerjakan</b></p>
      <table>${jasaRows}</table>
      <p><b>Sparepart Dipakai</b></p>
      <table>${partRows}</table>
      ${service.internalNote ? `<div class="divider"></div><p><b>Catatan Internal:</b> ${service.internalNote}</p>` : ''}
    `);
  }

  // ---- Baris jasa / sparepart ----
  function addDetailRow() { setDetails([...details, { name: '', description: '', cost: '', picking: true }]); }
  function updateDetailRow(i, field, value) {
    const copy = [...details]; copy[i] = { ...copy[i], [field]: value }; setDetails(copy);
  }
  function pickServiceType(i, t) {
    const copy = [...details];
    copy[i] = { name: t.name, description: t.description || '', cost: t.estimatedCost, picking: false };
    setDetails(copy);
  }
  function pickManual(i, text) {
    const copy = [...details];
    copy[i] = { name: text || '', description: '', cost: '', picking: false, manual: true };
    setDetails(copy);
  }
  function removeDetailRow(i) { setDetails(details.filter((_, idx) => idx !== i)); }
  function resetDetailRow(i) {
    const copy = [...details]; copy[i] = { name: '', description: '', cost: '', picking: true }; setDetails(copy);
  }

  function addPartRow() { setUsedParts([...usedParts, { sparepartId: '', qty: 1, price: 0 }]); }
  function updatePartRow(i, field, value) {
    const copy = [...usedParts];
    copy[i] = { ...copy[i], [field]: value };
    if (field === 'sparepartId') {
      const sp = partOptions.find((s) => s.id === Number(value));
      if (sp) copy[i].price = sp.sellPrice;
    }
    setUsedParts(copy);
  }
  function removePartRow(i) { setUsedParts(usedParts.filter((_, idx) => idx !== i)); }

  if (loading && !service) return <Spinner />;
  if (!service) return <p>Transaksi tidak ditemukan.</p>;

  const v = service.vehicle;
  const lunas = status === 'SELESAI';
  const canEditData = isStaffOrAdmin && !lunas;
  const canDelete = isStaffOrAdmin && (!lunas || user.role === 'ADMIN');
  // Form pengerjaan: saat Dikerjakan (semua peran terkait) & saat Tagihan (hanya Admin/Staff)
  const showWorkForm = status === 'DIKERJAKAN' || (status === 'MENUNGGU_PEMBAYARAN' && isStaffOrAdmin);
  const isBilling = status === 'MENUNGGU_PEMBAYARAN';
  const changeAmount = paidInput !== '' ? Math.max(Number(paidInput) - preview.total, 0) : 0;
  const VIcon = v.vehicleModel.wheels === 2 ? FaMotorcycle : FaCar;
  const pas = Math.ceil(preview.total);
  const quickPay = [...new Set([pas, Math.ceil(pas / 50000) * 50000, Math.ceil(pas / 100000) * 100000])].filter((n) => n > 0);

  return (
    <div className="space-y-5">
      <DetailHeader
        icon={FaWrench}
        title={service.invoiceNo}
        badge={<StatusBadge status={service.status} />}
        subtitle={`${v.plateNumber} · ${v.customer.name}`}
      >
        <Link to="/services" className="btn-secondary"><FaArrowLeft aria-hidden /> Kembali</Link>
        {canEditData && <Link to={`/services/${id}/edit`} className="btn-secondary"><FaPen aria-hidden /> Edit Data</Link>}
        {canDelete && <button type="button" className="btn-danger" onClick={handleDelete}><FaTrash aria-hidden /> Hapus</button>}
      </DetailHeader>

      <Alert message={error} />

      <div className="grid gap-4 md:grid-cols-2">
        <div className="card overflow-hidden animate-fade-up">
          <CardHeader icon={FaCarSide}>Informasi Kendaraan</CardHeader>
          <div className="p-5">
            <div className="flex items-center gap-3 rounded-xl bg-slate-50 p-3.5">
              <span className="icon-tile h-12 w-12 text-xl"><VIcon aria-hidden /></span>
              <div>
                <div className="font-extrabold uppercase text-slate-900">{v.vehicleModel.brand} {v.vehicleModel.model}</div>
                <span className="mt-0.5 inline-block rounded bg-slate-900 px-2 py-0.5 text-[11px] font-bold tracking-wide text-white">{v.plateNumber}</span>
              </div>
            </div>
            <dl className="info-list mt-3">
              <InfoRow label={lbl(FaCalendarDay, 'Tahun')}>{v.vehicleModel.year}</InfoRow>
              <InfoRow label={lbl(FaPalette, 'Warna')}>{v.color || '-'}</InfoRow>
              <InfoRow label={lbl(FaBarcode, 'No. Rangka')}>{v.vin || '-'}</InfoRow>
              <InfoRow label={lbl(FaCog, 'No. Mesin')}>{v.engineNumber || '-'}</InfoRow>
            </dl>
          </div>
        </div>

        <div className="card overflow-hidden animate-fade-up">
          <CardHeader icon={FaUser}>Informasi Pemilik &amp; Service</CardHeader>
          <div className="p-5">
            <div className="flex items-center gap-3 rounded-xl bg-slate-50 p-3.5">
              <span className="flex h-12 w-12 items-center justify-center rounded-full bg-gradient-to-br from-brand-500 to-sky-500 text-lg font-bold text-white">{(v.customer.name || '?').charAt(0).toUpperCase()}</span>
              <div>
                <div className="font-bold text-slate-900">{v.customer.name}</div>
                <div className="flex items-center gap-1.5 text-xs text-slate-500"><FaPhone className="text-[10px]" aria-hidden /> {v.customer.phone}</div>
              </div>
            </div>
            <dl className="info-list mt-3">
              <InfoRow label={lbl(FaUserCog, 'Teknisi')}>{service.technician.name}</InfoRow>
              <InfoRow label={lbl(FaCalendarAlt, 'Tanggal')}>{fmtDate(service.date)}</InfoRow>
            </dl>
            <div className="mt-3 rounded-xl border border-amber-200 bg-amber-50 p-3.5 text-sm">
              <div className="mb-1 flex items-center gap-1.5 text-xs font-bold uppercase tracking-wide text-amber-700"><FaCommentDots aria-hidden /> Keluhan</div>
              <p className="text-slate-700">{service.complaint || '-'}</p>
            </div>
          </div>
        </div>
      </div>

      {/* TAHAP 1 - Diterima */}
      {status === 'DITERIMA' && (
        <div className="card overflow-hidden animate-fade-up">
          <CardHeader icon={FaClipboardList}>Service Diterima</CardHeader>
          <div className="space-y-4 p-5">
            <p className="text-sm text-slate-600">Kendaraan sudah tercatat masuk bengkel. Cetak bukti untuk pelanggan atau kirim kabar lewat WhatsApp, lalu mulai pengerjaan.</p>
            <div className="flex flex-wrap gap-2">
              <button className="btn-secondary" onClick={handleSendWa}><FaWhatsapp aria-hidden /> Kirim WA</button>
              <button className="btn-secondary" onClick={handlePrintDiterima}><FaPrint aria-hidden /> Cetak Service Diterima</button>
              {isStaffOrAdmin && <button className="btn-primary" disabled={saving} onClick={handleStart}><FaPlay aria-hidden /> Mulai Kerjakan</button>}
            </div>
          </div>
        </div>
      )}

      {/* Form pengerjaan (saat Tagihan ditambah rincian biaya & pembayaran) */}
      {showWorkForm && (
        <form onSubmit={saveWork} className="space-y-4">
          {/* Kilometer */}
          <div className="card animate-fade-up">
            <CardHeader
              icon={FaClipboardList}
              className="rounded-t-2xl"
              right={dirty && <span className="badge bg-amber-400/20 text-amber-100 ring-1 ring-inset ring-amber-300/40"><FaExclamationCircle aria-hidden /> Belum disimpan</span>}
            >
              {isBilling ? 'Rincian Pekerjaan' : 'Detail Pengerjaan'}
            </CardHeader>
            <div className="p-5">
              <label className="label flex items-center gap-1.5"><FaTachometerAlt className="text-[12px] text-brand-500" aria-hidden /> Kilometer Kendaraan *</label>
              <div className="relative max-w-xs">
                <input type="number" min="0" className="input !pr-12" placeholder="0" value={km} onChange={(e) => setKm(e.target.value)} required />
                <span className="pointer-events-none absolute right-3 top-1/2 -translate-y-1/2 text-xs font-semibold text-slate-400">km</span>
              </div>
            </div>
          </div>

          {/* Jasa */}
          <div className="card animate-fade-up">
            <CardHeader
              icon={FaTools}
              className="rounded-t-2xl"
              right={<button type="button" className={headBtn} onClick={addDetailRow}><FaPlus aria-hidden /> Tambah Jasa</button>}
            >
              Detail Service (Jasa) *
            </CardHeader>
            <div className="space-y-3 p-5">
              {details.map((d, i) => (
                <div key={i} className="grid grid-cols-1 items-start gap-3 rounded-xl border border-slate-200 bg-slate-50/60 p-3.5 sm:grid-cols-12">
                  <div className="sm:col-span-4">
                    <label className="label">Cari Jenis Service</label>
                    {d.manual ? (
                      <div className="flex gap-1.5">
                        <input className="input" placeholder="Nama jasa manual" value={d.name} autoFocus={!d.name} onChange={(e) => updateDetailRow(i, 'name', e.target.value)} />
                        <button type="button" className="btn-secondary !px-3" title="Cari dari Jenis Service" aria-label="Cari dari Jenis Service" onClick={() => resetDetailRow(i)}><FaSearch aria-hidden /></button>
                      </div>
                    ) : (
                      <ServiceTypePicker
                        options={serviceTypes}
                        value={d.name}
                        onPick={(t) => pickServiceType(i, t)}
                        onManual={(text) => pickManual(i, text)}
                      />
                    )}
                  </div>
                  <div className="sm:col-span-5">
                    <label className="label">Deskripsi Service</label>
                    <input className="input" placeholder="Deskripsi service" value={d.description} onChange={(e) => updateDetailRow(i, 'description', e.target.value)} />
                  </div>
                  <div className="sm:col-span-2">
                    <label className="label">Biaya <span className="text-red-500">*</span></label>
                    <div className="flex">
                      <span className="flex items-center rounded-l-lg border border-r-0 border-slate-300 bg-slate-100 px-3 text-sm text-slate-600">Rp</span>
                      <input type="number" min="0" className="input !rounded-l-none" placeholder="0" value={d.cost} onChange={(e) => updateDetailRow(i, 'cost', e.target.value)} />
                    </div>
                  </div>
                  <div className="flex sm:col-span-1 sm:justify-center sm:pt-[1.85rem]">
                    <button type="button" className="icon-btn icon-btn-delete !h-9 !w-9" aria-label="Hapus baris" title="Hapus baris" onClick={() => removeDetailRow(i)}><FaTrash aria-hidden /></button>
                  </div>
                </div>
              ))}
              {details.length === 0 && (
                <div className="flex flex-col items-center gap-1.5 rounded-xl border-2 border-dashed border-slate-200 py-8 text-center text-sm text-slate-400">
                  <FaTools className="text-2xl text-slate-300" aria-hidden />
                  Belum ada jasa. Klik “Tambah Jasa” lalu cari jenis service atau pilih Manual / Lainnya.
                </div>
              )}
              <div className="ml-auto w-full pt-1 sm:w-3/5">
                <label className="label">Total Biaya Service</label>
                <div className="flex">
                  <span className="flex items-center rounded-l-lg border border-r-0 border-slate-300 bg-slate-100 px-3 text-sm text-slate-600">Rp</span>
                  <input readOnly className="input !rounded-l-none bg-slate-50 font-semibold" value={Number(preview.jasaTotal).toLocaleString('id-ID')} />
                </div>
              </div>
            </div>
          </div>

          {/* Sparepart */}
          <div className="card animate-fade-up">
            <CardHeader
              icon={FaCogs}
              className="rounded-t-2xl"
              right={isStaffOrAdmin && <button type="button" className={headBtn} onClick={addPartRow}><FaPlus aria-hidden /> Tambah Sparepart</button>}
            >
              Sparepart Dipakai <span className="font-normal opacity-80">(opsional)</span>
            </CardHeader>
            <div className="space-y-3 p-5">
              {usedParts.map((p, i) => {
                const sp = partOptions.find((x) => x.id === Number(p.sparepartId));
                const over = sp && Number(p.qty) > sp.stock;
                const rowSubtotal = (Number(p.price) || 0) * (Number(p.qty) || 0);
                return (
                  <div key={i} className="grid grid-cols-1 items-start gap-3 rounded-xl border border-slate-200 bg-slate-50/60 p-3.5 sm:grid-cols-12">
                    <div className="sm:col-span-4">
                      <label className="label">Sparepart</label>
                      <SparepartPicker options={partOptions} value={p.sparepartId} disabled={!isStaffOrAdmin} onPick={(x) => updatePartRow(i, 'sparepartId', x.id)} />
                    </div>
                    <div className="sm:col-span-2">
                      <label className="label">Jumlah</label>
                      <input type="number" min="1" className={`input ${over ? '!border-red-400 !ring-red-100' : ''}`} value={p.qty} onChange={(e) => updatePartRow(i, 'qty', e.target.value)} />
                    </div>
                    <div className="sm:col-span-2">
                      <label className="label">Harga Satuan</label>
                      <div className="flex">
                        <span className="flex items-center rounded-l-lg border border-r-0 border-slate-300 bg-slate-100 px-3 text-sm text-slate-600">Rp</span>
                        <input type="number" min="0" className="input !rounded-l-none" placeholder="Harga" value={p.price} onChange={(e) => updatePartRow(i, 'price', e.target.value)} />
                      </div>
                    </div>
                    <div className="sm:col-span-3">
                      <label className="label">Subtotal</label>
                      <div className="flex">
                        <span className="flex items-center rounded-l-lg border border-r-0 border-slate-300 bg-slate-100 px-3 text-sm text-slate-600">Rp</span>
                        <input readOnly className="input !rounded-l-none bg-slate-50" value={rowSubtotal} />
                      </div>
                    </div>
                    <div className="flex sm:col-span-1 sm:justify-center sm:pt-[1.85rem]">
                      <button type="button" className="icon-btn icon-btn-delete !h-9 !w-9" aria-label="Hapus baris" title="Hapus baris" onClick={() => removePartRow(i)}><FaTrash aria-hidden /></button>
                    </div>
                    {over && <p className="text-xs font-semibold text-red-600 sm:col-span-12">Jumlah melebihi stok tersedia ({sp.stock}).</p>}
                  </div>
                );
              })}
              {usedParts.length === 0 && (
                <div className="flex flex-col items-center gap-1.5 rounded-xl border-2 border-dashed border-slate-200 py-8 text-center text-sm text-slate-400">
                  <FaCogs className="text-2xl text-slate-300" aria-hidden />
                  Tidak ada sparepart dipakai.
                </div>
              )}
            </div>
            <div className="ml-auto w-full px-5 pb-5 sm:w-3/5">
              <label className="label">Total Biaya Sparepart</label>
              <div className="flex">
                <span className="flex items-center rounded-l-lg border border-r-0 border-slate-300 bg-slate-100 px-3 text-sm text-slate-600">Rp</span>
                <input readOnly className="input !rounded-l-none bg-slate-50 font-semibold" value={Number(preview.partsTotal).toLocaleString('id-ID')} />
              </div>
            </div>
          </div>

          {/* Rekomendasi & catatan */}
          <div className="card overflow-hidden animate-fade-up">
            <CardHeader icon={FaStickyNote}>Rekomendasi &amp; Catatan</CardHeader>
            <div className="space-y-4 p-5">
              <div className="grid gap-4 sm:grid-cols-2">
                <div>
                  <label className="label">Rekomendasi Servis Berikutnya</label>
                  <textarea className="input" rows={2} placeholder="Mis. ganti oli 2.000 km lagi" value={nextRecommendation} onChange={(e) => setNextRecommendation(e.target.value)} />
                </div>
                <div>
                  <label className="label">Tanggal Service Berikutnya</label>
                  <input type="date" className="input" value={nextDate} onChange={(e) => setNextDate(e.target.value)} />
                </div>
              </div>
              <div>
                <label className="label">Catatan Internal <span className="font-normal text-slate-400">(tidak ditampilkan ke pelanggan)</span></label>
                <textarea className="input" rows={2} value={internalNote} onChange={(e) => setInternalNote(e.target.value)} />
              </div>
            </div>
          </div>

          {/* TAHAP 3 - Tagihan & pembayaran */}
          {isBilling && (
            <div className="card overflow-hidden animate-fade-up">
              <CardHeader icon={FaMoneyBillWave}>Tagihan &amp; Pembayaran</CardHeader>
              <div className="space-y-5 p-5">
                <div className="grid gap-6 md:grid-cols-2">
                  <div className="space-y-4">
                    <div>
                      <label className="label flex items-center gap-1.5"><FaTicketAlt className="text-[12px] text-brand-500" aria-hidden /> Kode Kupon / Diskon</label>
                      <select className="input" value={discountId} onChange={(e) => setDiscountId(e.target.value)}>
                        <option value="">-- Tidak ada diskon --</option>
                        {discounts.map((d) => <option key={d.id} value={d.id}>{d.name} {d.code ? `(${d.code})` : ''}</option>)}
                      </select>
                    </div>
                    <div>
                      <label className="label flex items-center gap-1.5"><FaMoneyBillWave className="text-[12px] text-brand-500" aria-hidden /> Jumlah Dibayar</label>
                      <div className="relative">
                        <span className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-xs font-semibold text-slate-400">Rp</span>
                        <input type="number" min="0" className="input !pl-9 text-base font-semibold" placeholder="Masukkan jumlah pembayaran" value={paidInput} onChange={(e) => setPaidInput(e.target.value)} />
                      </div>
                      <div className="mt-2 flex flex-wrap gap-1.5">
                        {quickPay.map((n, i) => (
                          <button key={n} type="button" onClick={() => setPaidInput(String(n))}
                            className="rounded-full border border-slate-200 bg-white px-3 py-1 text-xs font-semibold text-slate-600 transition hover:border-brand-300 hover:bg-brand-50 hover:text-brand-700">
                            {i === 0 ? 'Uang pas' : formatRp(n)}
                          </button>
                        ))}
                      </div>
                      {paidInput !== '' && (
                        Number(paidInput) < preview.total
                          ? <div className="mt-3 rounded-xl border border-red-200 bg-red-50 px-4 py-2.5 text-sm font-semibold text-red-700">Kurang {formatRp(preview.total - Number(paidInput))}</div>
                          : <div className="mt-3 flex items-center justify-between rounded-xl border border-emerald-200 bg-emerald-50 px-4 py-2.5 text-sm"><span className="text-emerald-700">Kembalian</span><span className="text-lg font-extrabold tabular-nums text-emerald-700">{formatRp(changeAmount)}</span></div>
                      )}
                    </div>
                  </div>

                  <div className="summary-box self-start">
                    <div className="summary-row"><span>Total Jasa</span><span>{formatRp(preview.jasaTotal)}</span></div>
                    <div className="summary-row"><span>Total Sparepart</span><span>{formatRp(preview.partsTotal)}</span></div>
                    <div className="summary-row border-t border-slate-200 pt-1.5"><span>Subtotal</span><span>{formatRp(preview.subtotal)}</span></div>
                    <div className="summary-row"><span>Diskon</span><span className="text-emerald-600">-{formatRp(preview.discountAmount)}</span></div>
                    <div className="summary-row"><span>Pajak ({taxRate}%)</span><span>{formatRp(preview.taxAmount)}</span></div>
                    <div className="summary-total !text-lg"><span>Total Tagihan</span><span className="text-brand-700">{formatRp(preview.total)}</span></div>
                  </div>
                </div>

                <div className="flex flex-wrap gap-2 border-t border-slate-100 pt-4">
                  <button type="button" className="btn-secondary" onClick={handleCallCashier}><FaVolumeUp aria-hidden /> Panggil ke Kasir</button>
                  <button type="button" className="btn-secondary" onClick={handlePrintTagihan}><FaPrint aria-hidden /> Cetak Tagihan</button>
                  <button type="button" className="btn-secondary" onClick={handleSendWa}><FaWhatsapp aria-hidden /> Kirim WA</button>
                </div>
              </div>
            </div>
          )}

          {/* Bar aksi melayang di bawah layar */}
          <div className="sticky bottom-3 z-10 flex flex-wrap items-center justify-between gap-3 rounded-2xl border border-slate-200 bg-white/90 px-4 py-3 shadow-lg backdrop-blur">
            <p className="text-xs text-slate-500">
              {isBilling
                ? 'Isi jumlah dibayar lalu konfirmasi untuk menyelesaikan transaksi.'
                : 'Setelah “Selesai Dikerjakan”, halaman berpindah ke rincian biaya dan pembayaran.'}
            </p>
            <div className="flex flex-wrap gap-2">
              <button type="submit" disabled={saving} className="btn-secondary"><FaSave aria-hidden />{saving ? 'Menyimpan...' : isBilling ? 'Simpan Perubahan' : 'Simpan Pekerjaan'}</button>
              {!isBilling && (
                <button type="button" className="btn-success" disabled={saving} onClick={handleFinishWork}>
                  <FaCheckCircle aria-hidden /> Selesai Dikerjakan
                </button>
              )}
              {isBilling && (
                <button type="button" className="btn-success" disabled={saving || paidInput === ''} onClick={handlePay}>
                  <FaCreditCard aria-hidden /> Konfirmasi Pembayaran (Lunas)
                </button>
              )}
            </div>
          </div>
        </form>
      )}

      {/* Teknisi: tagihan bukan bagiannya, cukup tampilkan status */}
      {isBilling && !isStaffOrAdmin && (
        <div className="flex items-center gap-3 rounded-2xl border border-violet-200 bg-violet-50 p-5 text-sm text-violet-800">
          <FaMoneyBillWave className="text-xl" aria-hidden />
          Pekerjaan sudah selesai dikerjakan. Pembayaran diproses oleh Admin/Staff di kasir.
        </div>
      )}

      {/* TAHAP 4 - Selesai & Lunas: halaman detail transaksi (hanya lihat & cetak) */}
      {lunas && (
        <ServiceReceipt
          service={service}
          onPrint={(mode) => printBilling(service, mode)}
          onPrintWorkOrder={handlePrintWorkOrder}
          onSendWa={handleSendWa}
        />
      )}
    </div>
  );
}