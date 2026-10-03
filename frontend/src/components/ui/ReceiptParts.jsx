import React from 'react';

// Animasi masuk berurutan (satu urutan saat halaman dibuka)
export const stagger = (n) => ({ animationDelay: `${n * 80}ms` });

// Strip subtotal di bawah tabel rincian
export function SubtotalStrip({ label, value }) {
  return (
    <div className="flex items-center justify-between border-t border-slate-200 bg-slate-50 px-5 py-3 text-sm">
      <span className="font-semibold text-slate-600">{label}</span>
      <span className="font-bold tabular-nums text-slate-900">{value}</span>
    </div>
  );
}

// Baris "label ..... nilai" pada ringkasan pembayaran
export function ReceiptRow({ label, value, tone = 'text-slate-800' }) {
  return (
    <div className="flex items-start justify-between gap-4">
      <dt className="text-slate-500">{label}</dt>
      <dd className={`font-medium tabular-nums ${tone}`}>{value}</dd>
    </div>
  );
}
