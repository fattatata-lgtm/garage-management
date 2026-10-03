import { printDocument } from './print';
import { assetUrl } from './assetUrl';

const esc = (t) => String(t ?? '').replace(/[&<>"]/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;' }[c]));
// 850000 -> "850.000,00"
const money = (n) => Number(n || 0).toLocaleString('id-ID', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
// Sel uang gaya akuntansi: "Rp" rata kiri, angka rata kanan
const rp = (n) => `<div class="rp"><span>Rp</span><span>${money(n)}</span></div>`;
// "Selasa, 29 Sep 2026"
const longDate = (d) => {
  const dt = new Date(d || Date.now());
  const part = (o) => dt.toLocaleDateString('id-ID', o);
  return `${part({ weekday: 'long' })}, ${dt.getDate()} ${part({ month: 'short' })} ${dt.getFullYear()}`;
};

const CSS = `
  * { -webkit-print-color-adjust: exact; print-color-adjust: exact; }
  body { width: 100% !important; padding: 8px 14px !important; font-family: Calibri, 'Segoe UI', Arial, sans-serif; font-size: 13px; color: #000; }
  .iv-head { display: flex; align-items: center; gap: 18px; padding-bottom: 10px; border-bottom: 1px solid #7f9fd1; }
  .iv-head img { display: block; max-width: 300px; max-height: 90px; }
  .iv-biz { font-size: 22px; font-weight: 800; letter-spacing: .6px; text-transform: uppercase; }
  .iv-contact { font-size: 13px; line-height: 1.6; color: #222; }
  .iv-meta { display: flex; justify-content: space-between; gap: 24px; margin-top: 14px; }
  .iv-title { font-size: 20px; font-weight: 800; text-decoration: underline; margin-bottom: 8px; }
  .iv-dates { text-align: right; line-height: 1.5; white-space: nowrap; font-size: 13px; }
  .iv-dates b { display: block; }
  .iv-dates div + div { margin-top: 6px; }
  .iv-to { display: flex; align-items: flex-start; gap: 14px; line-height: 1.5; font-size: 14px; }
  .iv-to h4 { margin: 0; font-size: 14px; font-weight: 800; letter-spacing: .3px; }
  .iv-to .nm { font-weight: 700; }
  .iv-to .gap { margin-top: 8px; }
  .iv-tag { border: 1px solid #000; padding: 8px 4px; font-weight: 700; font-size: 12px; writing-mode: vertical-rl; transform: rotate(180deg); }
  .iv-sec { margin: 18px 0 4px; font-weight: 800; font-size: 13px; text-transform: uppercase; }
  table.iv { width: 100%; border-collapse: collapse; border: 2px solid #000; margin: 0; }
  table.iv th, table.iv td { padding: 2px 6px; font-size: 13px; vertical-align: top; }
  table.iv thead th { border: 2px solid #000; text-align: center; font-weight: 800; padding: 3px 6px; }
  table.iv tbody td { border-left: 1px solid #000; border-right: 1px solid #000; }
  table.iv tbody tr:first-child td { padding-top: 4px; }
  table.iv .c { text-align: center; }
  table.iv .l { text-align: left; }
  table.iv td.m { padding: 0 6px; }
  .rp { display: flex; justify-content: space-between; gap: 10px; white-space: nowrap; }
  table.iv tr.tot td { border-top: 2px solid #000; border-bottom: 2px solid #000; font-weight: 800; padding: 3px 6px; }
  table.iv tr.tot td.lbl { text-align: center; }
  table.iv tr.sub td { border-top: 1px solid #000; }
  .iv-note { margin-top: 18px; text-align: center; color: #333; font-size: 12px; }
  @page { size: A4; margin: 12mm; }
`;

// items: [{ name, description?, qty, uom, price }] -> tabel dengan kolom No | Deskripsi | Qty | Sat | Harga | Jumlah
function partsTable(title, items) {
  const body = items.map((it, i) => `
    <tr>
      <td class="c">${i + 1}</td><td>${esc(it.name)}</td><td class="c">${it.qty}</td><td class="c">${esc(it.uom || '')}</td>
      <td class="m">${rp(it.price)}</td><td class="m">${rp(Number(it.price) * Number(it.qty))}</td>
    </tr>`).join('');
  const total = items.reduce((t, it) => t + Number(it.price) * Number(it.qty), 0);
  return `
    <div class="iv-sec">${esc(title)}</div>
    <table class="iv"><thead><tr>
      <th style="width:6%">No</th><th>Deskripsi</th><th style="width:7%">Qty</th><th style="width:8%">Sat</th>
      <th style="width:21%">Harga</th><th style="width:21%">Jumlah</th></tr></thead>
      <tbody>${body}
        <tr class="tot"><td colspan="5" class="lbl">Jumlah Total</td><td class="m">${rp(total)}</td></tr>
      </tbody></table>`;
}

// rows: [{ name, description?, price }] -> tabel dengan kolom No | Deskripsi | Biaya
function costTable(title, rows, totalLabel = 'Jumlah') {
  const body = rows.map((r, i) => `
    <tr><td class="c">${i + 1}</td>
      <td>${esc(r.name)}${r.description ? ` <span style="color:#444">&ndash; ${esc(r.description)}</span>` : ''}</td>
      <td class="m">${rp(r.price)}</td></tr>`).join('');
  const total = rows.reduce((t, r) => t + Number(r.price), 0);
  return `
    <div class="iv-sec">${esc(title)}</div>
    <table class="iv"><thead><tr>
      <th style="width:6%">No</th><th class="l">Deskripsi</th><th style="width:30%">Biaya</th></tr></thead>
      <tbody>${body}
        <tr class="tot"><td colspan="2" class="lbl">${esc(totalLabel)}</td><td class="m">${rp(total)}</td></tr>
      </tbody></table>`;
}

// Ringkasan: rows [{ no?, label, value }], lalu baris Grand, lalu afterRows (Dibayar, Kembalian)
function summaryTable(title, rows, grandLabel, grand, afterRows = []) {
  const line = (r) => `<tr><td class="c">${r.no ?? ''}</td><td>${esc(r.label)}</td><td class="m">${rp(r.value)}</td></tr>`;
  return `
    <div class="iv-sec">${esc(title)}</div>
    <table class="iv"><thead><tr>
      <th style="width:6%">No</th><th class="l">Deskripsi</th><th style="width:30%">Biaya</th></tr></thead>
      <tbody>${rows.map(line).join('')}
        <tr class="tot"><td colspan="2" class="lbl">${esc(grandLabel)}</td><td class="m">${rp(grand)}</td></tr>
        ${afterRows.map(line).join('')}
      </tbody></table>`;
}

// Cetak invoice A4: kop (logo/nama + Telp/Alamat), blok KEPADA + TIPE KENDARAAN, tiga tabel, catatan LUNAS.
export function printInvoice({
  title = 'Invoice', settings, invoiceNo, date, billTo, toLine, tipeKendaraan,
  parts, jasa, summary, note,
}) {
  const s = settings || {};
  const contact = [
    s.phone ? `Telp: ${esc(s.phone)}` : '',
    s.address ? `Alamat: ${esc(s.address)}` : '',
  ].filter(Boolean).map((l) => `<div>${l}</div>`).join('');
  const head = s.logoUrl
    ? `<img src="${esc(assetUrl(s.logoUrl))}" alt="${esc(s.businessName || 'Logo')}" /><div class="iv-contact">${contact}</div>`
    : `<div><div class="iv-biz">${esc(s.businessName || '')}</div><div class="iv-contact">${contact}</div></div>`;

  const html = `
    <div class="iv-head">${head}</div>

    <div class="iv-meta">
      <div>
        <div class="iv-title">Invoice</div>
        <div class="iv-to">
          <span class="iv-tag">#${esc(invoiceNo)}</span>
          <div>
            <h4>KEPADA :</h4>
            <div class="nm">${esc(billTo)}</div>
            ${toLine ? `<div>${esc(toLine)}</div>` : ''}
            ${tipeKendaraan ? `<h4 class="gap">TIPE KENDARAAN :</h4><div>${esc(tipeKendaraan)}</div>` : ''}
          </div>
        </div>
      </div>
      <div class="iv-dates">
        <div><b>Tanggal Invoice:</b>${longDate(date)}</div>
        <div><b>Jatuh Tempo:</b>${longDate(date)}</div>
      </div>
    </div>

    ${parts?.items?.length ? partsTable(parts.title, parts.items) : ''}
    ${jasa?.items?.length ? costTable(jasa.title, jasa.items) : ''}
    ${summaryTable(summary.title || 'JUMLAH TOTAL BIAYA', summary.rows, 'Total Keseluruhan', summary.grand, summary.after)}

    ${note ? `<div class="iv-note">${esc(note)}</div>` : ''}`;

  printDocument(title, html, { width: 900, height: 900, css: CSS });
}
