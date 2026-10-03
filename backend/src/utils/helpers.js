const prisma = require('../lib/prisma');

// Generate invoice number, e.g. SVC-20260927-0001 / SLS-20260927-0001
// Dihitung berdasarkan invoiceNo yang SUDAH ADA dengan awalan yang sama (bukan field "date"
// pada record, karena "date" bisa diubah user ke tanggal lain sehingga penghitungan salah).
// Retry otomatis jika terjadi tabrakan (mis. dua request nyaris bersamaan / double-submit).
async function generateInvoiceNo(prefix, model, attempt = 0) {
  const today = new Date();
  const y = today.getFullYear();
  const m = String(today.getMonth() + 1).padStart(2, '0');
  const d = String(today.getDate()).padStart(2, '0');
  const dateStr = `${y}${m}${d}`;
  const prefixStr = `${prefix}-${dateStr}-`;

  const count = await prisma[model].count({
    where: { invoiceNo: { startsWith: prefixStr } },
  });

  const seq = String(count + 1 + attempt).padStart(4, '0');
  const invoiceNo = `${prefixStr}${seq}`;

  const exists = await prisma[model].findUnique({ where: { invoiceNo } });
  if (exists && attempt < 20) {
    return generateInvoiceNo(prefix, model, attempt + 1);
  }
  return invoiceNo;
}

// Calculate discount amount given subtotal + discount record
function calcDiscountAmount(subtotal, discount) {
  if (!discount || discount.status !== 'AKTIF') return 0;
  const subtotalNum = Number(subtotal);
  if (discount.type === 'PERCENTAGE') {
    return (subtotalNum * Number(discount.value)) / 100;
  }
  return Number(discount.value);
}

// Determine stock status label from stock qty + threshold
function stockStatus(stock, threshold) {
  if (stock <= 0) return 'HABIS';
  if (stock <= threshold) return 'RENDAH';
  return 'BAIK';
}

module.exports = { generateInvoiceNo, calcDiscountAmount, stockStatus };