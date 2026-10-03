import React from 'react';

// Judul bagian di dalam kartu polos (halaman detail): ikon tebal kecil + teks.
export default function SectionTitle({ icon: Icon, children, right }) {
  return (
    <div className="mb-4 flex flex-wrap items-center justify-between gap-2">
      <h2 className="flex items-center gap-2.5 text-[15px] font-bold text-slate-900">
        {Icon && <span className="icon-tile-soft h-8 w-8 text-sm"><Icon aria-hidden /></span>}
        {children}
      </h2>
      {right}
    </div>
  );
}
