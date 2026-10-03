import React from 'react';
import { Link } from 'react-router-dom';
import { FaArrowLeft } from 'react-icons/fa';

// Judul halaman detail: tombol kembali, ikon tebal, judul (+ badge), subjudul, dan tombol aksi di kanan.
export default function DetailHeader({ icon: Icon, title, badge, subtitle, backTo, children }) {
  return (
    <div className="flex flex-wrap items-center justify-between gap-4">
      <div className="flex items-center gap-3.5">
        {Icon && (
          <span className="icon-tile h-12 w-12 text-[22px]">
            <Icon aria-hidden />
          </span>
        )}
        <div>
          {backTo && (
            <Link to={backTo} className="mb-0.5 inline-flex items-center gap-1.5 text-xs font-semibold text-slate-500 hover:text-brand-600">
              <FaArrowLeft className="text-[10px]" aria-hidden /> Kembali
            </Link>
          )}
          <div className="flex flex-wrap items-center gap-2.5">
            <h1 className="text-2xl font-extrabold leading-tight tracking-tight text-slate-900">{title}</h1>
            {badge}
          </div>
          {subtitle && <div className="mt-0.5 text-sm text-slate-500">{subtitle}</div>}
        </div>
      </div>
      {children && <div className="no-print flex flex-wrap items-center gap-2">{children}</div>}
    </div>
  );
}
