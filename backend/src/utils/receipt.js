// Struk teks untuk pesan WhatsApp (meniru struk thermal yang dicetak dari aplikasi).
// Dibungkus ``` agar tampil monospace di WhatsApp; lebar 32 karakter muat di layar HP.
const rp = (n) => `Rp${Number(n || 0).toLocaleString('id-ID')}`;

const RECEIPT_W = 32;
const clean = (t) => String(t ?? '').replace(/`/g, "'").replace(/\s+/g, ' ').trim();

function wrapText(text, w = RECEIPT_W) {
  const out = [];
  let line = '';
  for (let word of clean(text).split(' ')) {
    while (word.length > w) { // kata sangat panjang dipotong
      if (line) { out.push(line); line = ''; }
      out.push(word.slice(0, w));
      word = word.slice(w);
    }
    if (!line) line = word;
    else if (line.length + 1 + word.length <= w) line += ` ${word}`;
    else { out.push(line); line = word; }
  }
  if (line) out.push(line);
  return out.length ? out : [''];
}
const centerLines = (text) => wrapText(text).map((l) => ' '.repeat(Math.floor((RECEIPT_W - l.length) / 2)) + l);
// "kiri ........ kanan"; kalau tidak muat satu baris, kiri dibungkus lalu kanan di baris sendiri (rata kanan)
function pairLine(left, right) {
  const l = clean(left); const r = String(right);
  if (l.length + r.length + 1 <= RECEIPT_W) return [l + ' '.repeat(RECEIPT_W - l.length - r.length) + r];
  return [...wrapText(l), ' '.repeat(Math.max(0, RECEIPT_W - r.length)) + r];
}

function buildServiceReceipt(svc) {
  const v = svc.vehicle;
  const DIV = '-'.repeat(RECEIPT_W);
  const jasaTotal = svc.details.reduce((t, d) => t + (Number(d.cost) || 0), 0);
  const partsTotal = svc.spareparts.reduce((t, x) => t + (Number(x.price) || 0) * (Number(x.qty) || 0), 0);
  const date = new Date(svc.date).toLocaleDateString('id-ID', { timeZone: 'Asia/Jakarta' });

  const lines = [
    ...centerLines('STRUK SERVICE'),
    ...centerLines(`No. ${svc.invoiceNo} - ${date}`),
    DIV,
    ...wrapText(`Kendaraan: ${v.plateNumber} - ${v.vehicleModel.brand} ${v.vehicleModel.model}`),
    ...wrapText(`Pemilik: ${v.customer.name}`),
    DIV,
    'Detail Service',
    ...(svc.details.length ? svc.details.flatMap((d) => pairLine(d.name, rp(d.cost))) : ['-']),
    DIV,
    'Sparepart Digunakan',
    ...(svc.spareparts.length
      ? svc.spareparts.flatMap((x) => [
          ...wrapText(x.sparepart.name),
          ...pairLine(`${x.qty} x ${rp(x.price)}`, rp(Number(x.price) * x.qty)),
        ])
      : ['-']),
    DIV,
    ...pairLine('Total Biaya Service', rp(jasaTotal)),
    ...pairLine('Total Biaya Sparepart', rp(partsTotal)),
    ...pairLine('Subtotal', rp(svc.subtotal)),
    ...pairLine('Diskon', `-${rp(svc.discountAmount)}`),
    ...pairLine('Pajak', rp(svc.taxAmount)),
    DIV,
    ...pairLine('Total', rp(svc.total)),
    ...pairLine('Dibayar', rp(svc.paid)),
    ...pairLine('Kembalian', rp(svc.change)),
    DIV,
    ...centerLines('LUNAS - Terima kasih atas kepercayaan Anda.'),
  ];
  return '```\n' + lines.join('\n') + '\n```';
}

function buildSalesReceipt(sale) {
  const DIV = '-'.repeat(RECEIPT_W);
  const buyer = sale.customer ? sale.customer.name : (sale.walkInName || 'Pelanggan Umum');
  const when = new Date(sale.date).toLocaleString('id-ID', { timeZone: 'Asia/Jakarta' });

  const lines = [
    ...centerLines('STRUK PENJUALAN'),
    ...centerLines(`No. ${sale.invoiceNo}`),
    ...centerLines(when),
    ...wrapText(`Pembeli: ${buyer}`),
    DIV,
    ...sale.items.flatMap((i) => pairLine(`${i.sparepart.name} x${i.qty}`, rp(Number(i.price) * i.qty))),
    DIV,
    ...pairLine('Subtotal', rp(sale.subtotal)),
    ...pairLine('Diskon', `-${rp(sale.discountAmount)}`),
    ...pairLine('Pajak', rp(sale.taxAmount)),
    DIV,
    ...pairLine('Total', rp(sale.total)),
    ...pairLine('Dibayar', rp(sale.paid)),
    ...pairLine('Kembalian', rp(sale.change)),
    DIV,
    ...centerLines('Terima kasih telah berbelanja.'),
  ];
  return '```\n' + lines.join('\n') + '\n```';
}

module.exports = { buildServiceReceipt, buildSalesReceipt };
