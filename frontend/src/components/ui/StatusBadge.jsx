import React from 'react';

const STYLES = {
  DITERIMA: 'bg-amber-50 text-amber-700 ring-1 ring-inset ring-amber-200',
  DIKERJAKAN: 'bg-blue-50 text-blue-700 ring-1 ring-inset ring-blue-200',
  MENUNGGU_PEMBAYARAN: 'bg-violet-50 text-violet-700 ring-1 ring-inset ring-violet-200',
  SELESAI: 'bg-emerald-50 text-emerald-700 ring-1 ring-inset ring-emerald-200',
  BAIK: 'bg-emerald-50 text-emerald-700 ring-1 ring-inset ring-emerald-200',
  RENDAH: 'bg-amber-50 text-amber-700 ring-1 ring-inset ring-amber-200',
  HABIS: 'bg-red-50 text-red-700 ring-1 ring-inset ring-red-200',
  AKTIF: 'bg-emerald-50 text-emerald-700 ring-1 ring-inset ring-emerald-200',
  NONAKTIF: 'bg-slate-100 text-slate-600 ring-1 ring-inset ring-slate-200',
};

const DOT = {
  DITERIMA: 'bg-amber-500', DIKERJAKAN: 'bg-blue-500', MENUNGGU_PEMBAYARAN: 'bg-violet-500', SELESAI: 'bg-emerald-500',
  BAIK: 'bg-emerald-500', RENDAH: 'bg-amber-500', HABIS: 'bg-red-500', AKTIF: 'bg-emerald-500', NONAKTIF: 'bg-slate-400',
};

// Label yang ramah dibaca untuk status transaksi service
export const SERVICE_STATUS_LABEL = {
  DITERIMA: 'Diterima',
  DIKERJAKAN: 'Dikerjakan',
  MENUNGGU_PEMBAYARAN: 'Menunggu Pembayaran',
  SELESAI: 'Selesai (Lunas)',
};

export default function StatusBadge({ status }) {
  return (
    <span className={`badge ${STYLES[status] || 'bg-slate-100 text-slate-600 ring-1 ring-inset ring-slate-200'}`}>
      <span className={`h-1.5 w-1.5 rounded-full ${DOT[status] || 'bg-slate-400'}`} aria-hidden />
      {SERVICE_STATUS_LABEL[status] || status}
    </span>
  );
}
