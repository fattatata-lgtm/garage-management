import React, { useMemo, useRef, useState } from 'react';
import { FaChevronDown } from 'react-icons/fa';
import ComboPanel from './ComboPanel';

// Normalisasi untuk pencarian plat: abaikan spasi, tanda hubung, dan huruf besar/kecil
// (mis. "n 1234 ab" tetap cocok dengan "N 1234 AB").
const norm = (s) => String(s || '').toLowerCase().replace(/[\s-]+/g, '');

// Dropdown "Pilih Kendaraan" dengan kolom pencarian: bisa dicari lewat No. Plat, Nama Pemilik, atau nama kendaraan (merk/model).
// value = id kendaraan terpilih (string); onPick(vehicle) dipanggil saat memilih.
export default function VehiclePicker({ options, value, onPick, required = false }) {
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState('');
  const boxRef = useRef(null);

  const selected = options.find((v) => String(v.id) === String(value));

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return options;
    const qn = norm(q);
    const tokens = q.split(/\s+/).filter(Boolean);
    return options.filter((v) => {
      if (norm(v.plateNumber).includes(qn)) return true;
      // Nama pemilik, merk, model, tahun, dan VIN: setiap kata yang diketik harus ada
      // (mis. "honda beat" atau "budi vario" cocok walau urutannya berbeda).
      const hay = [
        v.customer?.name, v.vehicleModel?.brand, v.vehicleModel?.model,
        v.vehicleModel?.year, v.vin, v.plateNumber,
      ].filter(Boolean).join(' ').toLowerCase();
      return tokens.every((t) => hay.includes(t));
    });
  }, [options, query]);

  const close = () => { setOpen(false); setQuery(''); };

  return (
    <div ref={boxRef} className="relative">
      <button
        type="button"
        onClick={() => setOpen((o) => !o)}
        className="input flex w-full items-center justify-between gap-2 text-left"
      >
        <span className={`truncate ${selected ? 'text-slate-800' : 'text-slate-400'}`}>
          {selected
            ? `${selected.plateNumber} - ${selected.customer.name} (${selected.vehicleModel.brand} ${selected.vehicleModel.model})`
            : '-- Cari No. Plat / Pemilik / Kendaraan --'}
        </span>
        <FaChevronDown className={`shrink-0 text-[10px] text-slate-400 transition-transform ${open ? 'rotate-180' : ''}`} aria-hidden />
      </button>

      {/* Input tersembunyi agar validasi "wajib diisi" browser tetap berjalan */}
      {required && (
        <input
          tabIndex={-1}
          aria-hidden
          required
          value={value || ''}
          onChange={() => {}}
          className="pointer-events-none absolute inset-x-0 bottom-0 h-0 w-full opacity-0"
        />
      )}

      {open && (
        <ComboPanel anchorRef={boxRef} onClose={close}>
          <div className="shrink-0 p-2">
            <input
              autoFocus
              className="input !border-slate-800 !py-1.5 text-[13px]"
              placeholder="Ketik no. plat, nama pemilik, atau kendaraan..."
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter') {
                  e.preventDefault();
                  if (filtered.length > 0) { onPick(filtered[0]); close(); }
                }
              }}
            />
          </div>
          <ul className="min-h-0 flex-1 overflow-y-auto border-t border-slate-100">
            {filtered.map((v) => (
              <li key={v.id} className="border-t border-slate-100 first:border-t-0">
                <button
                  type="button"
                  className={`w-full px-3.5 py-2.5 text-left text-sm text-slate-800 hover:bg-brand-50 ${String(v.id) === String(value) ? 'bg-brand-50' : ''}`}
                  onClick={() => { onPick(v); close(); }}
                >
                  <span className="font-semibold">{v.plateNumber}</span>
                  <span className="text-slate-500"> — {v.customer.name}</span>
                  <span className="block text-xs text-slate-500">{v.vehicleModel.brand} {v.vehicleModel.model}</span>
                </button>
              </li>
            ))}
            {filtered.length === 0 && (
              <li className="px-3.5 py-2.5 text-sm text-slate-400">
                {options.length === 0 ? 'Belum ada data kendaraan.' : 'Kendaraan tidak ditemukan.'}
              </li>
            )}
          </ul>
        </ComboPanel>
      )}
    </div>
  );
}
