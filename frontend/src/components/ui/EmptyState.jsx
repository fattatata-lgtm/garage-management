import React from 'react';
import { FaInbox } from 'react-icons/fa';

export default function EmptyState({ text = 'Belum ada data.' }) {
  return (
    <div className="flex flex-col items-center gap-3.5 py-16 text-sm font-medium text-slate-500 animate-fade-in">
      <span className="relative flex h-16 w-16 items-center justify-center rounded-2xl bg-gradient-to-b from-white to-slate-50 text-2xl text-slate-300 shadow-soft ring-1 ring-slate-900/[0.06]">
        <FaInbox aria-hidden />
      </span>
      {text}
    </div>
  );
}
