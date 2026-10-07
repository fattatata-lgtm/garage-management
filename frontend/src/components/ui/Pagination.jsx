import React from 'react';

// Daftar nomor halaman dengan elipsis: 1 | 2 | 3 | ... | 12
// - Jika halaman <= 7, semua nomor ditampilkan.
// - Di awal : 1 2 3 … terakhir
// - Di akhir: 1 … (terakhir-2) (terakhir-1) terakhir
// - Di tengah: 1 … (aktif-1) aktif (aktif+1) … terakhir
export function pageList(page, pageCount) {
  if (pageCount <= 7) return Array.from({ length: pageCount }, (_, i) => i + 1);
  if (page <= 3) return [1, 2, 3, '…', pageCount];
  if (page >= pageCount - 2) return [1, '…', pageCount - 2, pageCount - 1, pageCount];
  return [1, '…', page - 1, page, page + 1, '…', pageCount];
}

// Kontrol pagination: Previous | 1 | 2 | 3 | ... | Next
// Tidak tampil bila data muat dalam satu halaman (<= perPage).
export default function Pagination({ pg }) {
  const { page, setPage, pageCount, total, perPage, start } = pg;
  if (total <= perPage) return null;
  const from = start + 1;
  const to = Math.min(start + perPage, total);
  const btn = 'flex h-9 min-w-[2.25rem] items-center justify-center rounded-[10px] border px-3 text-sm font-semibold transition';
  const idle = 'border-slate-200 bg-white text-slate-600 hover:bg-slate-50';
  const off = 'disabled:cursor-not-allowed disabled:opacity-40 disabled:hover:bg-white';

  return (
    <div className="pagination-bar flex flex-wrap items-center justify-between gap-3 border-t border-slate-100 px-4 py-3">
      <p className="text-sm text-slate-600">Menampilkan {from}–{to} dari {total} data</p>
      <nav className="flex flex-wrap items-center gap-1" aria-label="Pagination">
        <button type="button" className={`${btn} ${idle} ${off}`}
          disabled={page <= 1} onClick={() => setPage(page - 1)}>Previous</button>
        {pageList(page, pageCount).map((p, i) => (p === '…'
          ? <span key={`e${i}`} className="px-1 text-sm text-slate-400" aria-hidden>...</span>
          : (
            <button key={p} type="button" onClick={() => setPage(p)} aria-current={p === page ? 'page' : undefined}
              className={`${btn} ${p === page ? 'border-brand-600 bg-gradient-to-b from-brand-500 to-brand-600 text-white shadow-md shadow-brand-600/25' : idle}`}>{p}</button>
          )))}
        <button type="button" className={`${btn} ${idle} ${off}`}
          disabled={page >= pageCount} onClick={() => setPage(page + 1)}>Next</button>
      </nav>
    </div>
  );
}
