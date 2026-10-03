import React from 'react';
import { FaSearch } from 'react-icons/fa';
import ScanButton from './ScanButton';

// Kolom pencarian seragam (ikon kaca pembesar di kiri). onChange menerima string.
// scan=true menambahkan tombol scan barcode di sebelah kanan; hasil scan langsung mengisi kolom.
export default function SearchInput({ value, onChange, placeholder = 'Cari...', scan = false }) {
  return (
    <div className="flex w-full gap-2">
      <div className="relative w-full">
        <FaSearch className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-xs text-slate-400" aria-hidden />
        <input
          className="input !pl-9"
          placeholder={placeholder}
          value={value}
          onChange={(e) => onChange(e.target.value)}
        />
      </div>
      {scan && <ScanButton onScan={onChange} title="Scan barcode untuk mencari" className="!h-10" />}
    </div>
  );
}
