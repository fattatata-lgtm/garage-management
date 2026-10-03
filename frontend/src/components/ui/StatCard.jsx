import React from 'react';
import { Link } from 'react-router-dom';

const TONES = {
  brand: 'bg-brand-50 text-brand-600',
  green: 'bg-emerald-50 text-emerald-600',
  amber: 'bg-amber-50 text-amber-600',
  violet: 'bg-violet-50 text-violet-600',
  red: 'bg-red-50 text-red-600',
  cyan: 'bg-cyan-50 text-cyan-600',
};

// Kartu statistik: ikon berwarna + label + angka besar. Jika `to` diisi, kartu menjadi tautan.
export default function StatCard({ icon: Icon, label, value, tone = 'brand', to }) {
  const body = (
    <div className={`card flex items-center gap-4 p-4 transition ${to ? 'hover:-translate-y-0.5 hover:shadow-md' : ''}`}>
      {Icon && (
        <span className={`flex h-12 w-12 shrink-0 items-center justify-center rounded-xl text-xl ${TONES[tone] || TONES.brand}`}>
          <Icon aria-hidden />
        </span>
      )}
      <div className="min-w-0">
        <p className="truncate text-xs font-semibold uppercase tracking-wide text-slate-500">{label}</p>
        <p className="truncate text-xl font-extrabold tabular-nums text-slate-900">{value}</p>
      </div>
    </div>
  );
  return to ? <Link to={to} className="block">{body}</Link> : body;
}
