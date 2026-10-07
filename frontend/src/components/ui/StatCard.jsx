import React from 'react';
import { Link } from 'react-router-dom';

// Tiap tone: gradien ikon, bayangan ikon, dan cahaya lembut di sudut kartu.
const TONES = {
  brand: { chip: 'from-brand-400 to-brand-600 shadow-brand-600/40', glow: 'bg-brand-400/15' },
  green: { chip: 'from-emerald-400 to-emerald-600 shadow-emerald-600/35', glow: 'bg-emerald-400/15' },
  amber: { chip: 'from-amber-400 to-amber-600 shadow-amber-600/35', glow: 'bg-amber-400/20' },
  violet: { chip: 'from-violet-400 to-violet-600 shadow-violet-600/35', glow: 'bg-violet-400/15' },
  red: { chip: 'from-red-400 to-red-600 shadow-red-600/35', glow: 'bg-red-400/15' },
  cyan: { chip: 'from-cyan-400 to-cyan-600 shadow-cyan-600/35', glow: 'bg-cyan-400/15' },
};

// Kartu statistik: label kecil, angka besar, ikon gradien di kanan. Jika `to` diisi, kartu menjadi tautan.
export default function StatCard({ icon: Icon, label, value, tone = 'brand', to }) {
  const t = TONES[tone] || TONES.brand;
  const body = (
    <div className={`card group relative overflow-hidden p-5 transition duration-200 ${to ? 'hover:-translate-y-0.5 hover:shadow-lift' : ''}`}>
      <span aria-hidden className={`pointer-events-none absolute -right-10 -top-12 h-32 w-32 rounded-full blur-2xl ${t.glow}`} />
      <div className="relative flex items-start justify-between gap-3">
        <div className="min-w-0">
          <p className="truncate text-[13px] font-semibold text-slate-500">{label}</p>
          <p className="mt-2.5 truncate text-[26px] font-extrabold leading-none tracking-tight tabular-nums text-slate-900">{value}</p>
        </div>
        {Icon && (
          <span
            className={`flex h-11 w-11 shrink-0 items-center justify-center rounded-xl bg-gradient-to-br text-lg text-white shadow-lg transition-transform duration-200 ${to ? 'group-hover:scale-105' : ''} ${t.chip}`}
          >
            <Icon aria-hidden />
          </span>
        )}
      </div>
    </div>
  );
  return to ? <Link to={to} className="block rounded-2xl focus:outline-none focus-visible:ring-2 focus-visible:ring-brand-400 focus-visible:ring-offset-2">{body}</Link> : body;
}
