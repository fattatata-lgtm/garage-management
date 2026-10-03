import React from 'react';
import { FaCalendarAlt, FaTimes } from 'react-icons/fa';
import FilterField from './FilterField';

// Format YYYY-MM-DD -> "30 Sep 2026"
export function fmtRangeDate(v) {
  if (!v) return '';
  const [y, m, d] = v.split('-').map(Number);
  return new Date(y, m - 1, d).toLocaleDateString('id-ID', { day: '2-digit', month: 'short', year: 'numeric' });
}

// Bangun query param from/to. `to` dibuat sampai akhir hari supaya transaksi di hari terakhir ikut tampil.
export function applyDateRange(params, from, to) {
  if (from) params.set('from', `${from}T00:00:00`);
  if (to) params.set('to', `${to}T23:59:59`);
}

// Filter periode: [Tanggal Mulai] [Tanggal Akhir] + tombol reset.
// Dipakai di dalam <div className="filter-bar">. Saat aktif, kolom disorot dan muncul
// baris ringkasan "Filter aktif: 01 Sep 2026 – 30 Sep 2026" di bagian bawah bar.
export default function DateRangeFilter({ from, to, onChange }) {
  const active = Boolean(from || to);
  const invalid = from && to && from > to;

  const fieldCls = (filled) =>
    `input ${filled ? '!border-brand-400 !bg-brand-50/60 font-semibold text-brand-800' : ''}`;

  return (
    <>
      <FilterField label="Tanggal Mulai" icon={FaCalendarAlt} className="w-full sm:w-44">
        <input
          type="date"
          className={fieldCls(from)}
          value={from}
          max={to || undefined}
          onChange={(e) => onChange({ from: e.target.value, to })}
        />
      </FilterField>

      <FilterField label="Tanggal Akhir" icon={FaCalendarAlt} className="w-full sm:w-44">
        <input
          type="date"
          className={fieldCls(to)}
          value={to}
          min={from || undefined}
          onChange={(e) => onChange({ from, to: e.target.value })}
        />
      </FilterField>

      {active && (
        <button
          type="button"
          className="btn-muted h-10 !px-3.5 text-xs"
          onClick={() => onChange({ from: '', to: '' })}
          title="Hapus filter tanggal"
        >
          <FaTimes aria-hidden /> Reset
        </button>
      )}

      {active && (
        <div className="filter-note">
          {invalid ? (
            <span className="inline-flex items-center gap-1.5 rounded-full bg-red-50 px-3 py-1 text-xs font-semibold text-red-700 ring-1 ring-inset ring-red-200">
              Tanggal mulai tidak boleh melewati tanggal akhir
            </span>
          ) : (
            <span className="inline-flex items-center gap-1.5 rounded-full bg-brand-50 px-3 py-1 text-xs font-semibold text-brand-700 ring-1 ring-inset ring-brand-200">
              <span className="h-1.5 w-1.5 rounded-full bg-brand-500" aria-hidden />
              Filter aktif: {from ? fmtRangeDate(from) : 'awal'} &ndash; {to ? fmtRangeDate(to) : 'sekarang'}
            </span>
          )}
        </div>
      )}
    </>
  );
}
