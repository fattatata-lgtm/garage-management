import React from 'react';

// Pembungkus satu kolom filter: label kecil di atas + kontrol di bawah.
// Semua kolom di .filter-bar memakai ini supaya label & tinggi kontrol selalu sejajar.
export default function FilterField({ label, icon: Icon, className = '', children }) {
  return (
    <div className={`min-w-0 ${className}`}>
      <label className="filter-label">
        {Icon && <Icon className="text-brand-500" aria-hidden />} {label}
      </label>
      {children}
    </div>
  );
}
