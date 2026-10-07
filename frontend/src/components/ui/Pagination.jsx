import React from 'react';
import { FaChevronLeft, FaChevronRight } from 'react-icons/fa';

// Daftar nomor halaman dengan elipsis, mis. 1 … 4 5 6 … 12
function pageList(page, pageCount) {
  if (pageCount <= 7) return Array.from({ length: pageCount }, (_, i) => i + 1);
  const pages = new Set([1, pageCount, page - 1, page, page + 1]);
  const sorted = [...pages].filter((p) => p >= 1 && p <= pageCount).sort((a, b) => a - b);
  const out = [];
  sorted.forEach((p, i) => { if (i > 0 && p - sorted[i - 1] > 1) out.push('…'); out.push(p); });
  return out;
}

// Kontrol pagination. Tidak tampil bila data muat dalam satu halaman.
export default function Pagination({ pg }) {
  const { page, setPage, pageCount, total, perPage, start } = pg;
  if (total <= perPage) return null;
  const from = start + 1;
  const to = Math.min(start + perPage, total);
  const btn = 'flex h-9 min-w-[2.25rem] items-center justify-center rounded-[10px] border px-2.5 text-sm font-semibold transition';

  return (
    <div className="flex flex-wrap items-center justify-between gap-3 border-t border-slate-100 px-4 py-3">
      <p className="text-sm text-slate-600">Menampilkan {from}–{to} dari {total} data</p>
      <nav className="flex items-center gap-1" aria-label="Pagination">
        <button type="button" className={`${btn} border-slate-200 bg-white text-slate-600 hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-40`}
          disabled={page <= 1} onClick={() => setPage(page - 1)} aria-label="Halaman sebelumnya"><FaChevronLeft className="text-[10px]" aria-hidden /></button>
        {pageList(page, pageCount).map((p, i) => (p === '…'
          ? <span key={`e${i}`} className="px-1 text-sm text-slate-400">…</span>
          : (
            <button key={p} type="button" onClick={() => setPage(p)} aria-current={p === page ? 'page' : undefined}
              className={`${btn} ${p === page ? 'border-brand-600 bg-gradient-to-b from-brand-500 to-brand-600 text-white shadow-md shadow-brand-600/25' : 'border-slate-200 bg-white text-slate-600 hover:bg-slate-50'}`}>{p}</button>
          )))}
        <button type="button" className={`${btn} border-slate-200 bg-white text-slate-600 hover:bg-slate-50 disabled:cursor-not-allowed disabled:opacity-40`}
          disabled={page >= pageCount} onClick={() => setPage(page + 1)} aria-label="Halaman berikutnya"><FaChevronRight className="text-[10px]" aria-hidden /></button>
      </nav>
    </div>
  );
}
