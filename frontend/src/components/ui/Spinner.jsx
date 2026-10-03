import React from 'react';
import { FaCircleNotch } from 'react-icons/fa';

export default function Spinner({ label = 'Memuat data...' }) {
  return (
    <div className="flex items-center justify-center gap-2.5 py-14 text-sm font-medium text-slate-500">
      <FaCircleNotch className="animate-spin text-lg text-brand-500" aria-hidden />
      {label}
    </div>
  );
}
