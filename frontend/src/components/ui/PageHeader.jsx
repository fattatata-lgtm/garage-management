import React from 'react';

// Judul halaman: ikon tebal dalam ubin berwarna + judul + subjudul, tombol aksi di kanan.
// `icon` diisi komponen ikon, mis. icon={FaUsers}.
export default function PageHeader({ icon: Icon, title, subtitle, children }) {
  return (
    <div className="flex flex-wrap items-center justify-between gap-4">
      <div className="flex items-center gap-3.5">
        {Icon && (
          <span className="icon-tile h-12 w-12 text-[22px]">
            <Icon aria-hidden />
          </span>
        )}
        <div>
          <h1 className="text-2xl font-extrabold leading-tight tracking-tight text-slate-900">{title}</h1>
          {subtitle && <p className="mt-0.5 text-sm text-slate-500">{subtitle}</p>}
        </div>
      </div>
      {children && <div className="flex flex-wrap items-center gap-2">{children}</div>}
    </div>
  );
}
