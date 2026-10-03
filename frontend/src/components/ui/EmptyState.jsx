import React from 'react';
import { FaInbox } from 'react-icons/fa';

export default function EmptyState({ text = 'Belum ada data.' }) {
  return (
    <div className="flex flex-col items-center gap-3 py-14 text-sm font-medium text-slate-400 animate-fade-in">
      <span className="flex h-14 w-14 items-center justify-center rounded-2xl bg-slate-100 text-2xl text-slate-300">
        <FaInbox aria-hidden />
      </span>
      {text}
    </div>
  );
}
