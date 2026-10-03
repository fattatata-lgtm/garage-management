import React, { useMemo, useRef, useState } from 'react';
import { FaChevronDown } from 'react-icons/fa';
import ComboPanel from './ComboPanel';
import ScanButton from './ScanButton';

const label = (sp) => `${sp.code ? `${sp.code} - ` : ''}${sp.name}`;

// Dropdown "Cari Sparepart": kolom pencarian (kode / nama) + daftar sparepart beserta stoknya.
export default function SparepartPicker({ options, value, onPick, disabled }) {
  const [open, setOpen] = useState(false);
  const [scanMsg, setScanMsg] = useState('');
  const [query, setQuery] = useState('');
  const boxRef = useRef(null);

  const selected = options.find((o) => o.id === Number(value));
  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return options;
    return options.filter((o) => label(o).toLowerCase().includes(q));
  }, [options, query]);

  const close = () => { setOpen(false); setQuery(''); };

  // Hasil scan dicocokkan dengan kode sparepart (persis, tanpa pembeda huruf besar/kecil)
  function handleScan(text) {
    const code = text.trim().toLowerCase();
    const found = options.find((o) => (o.code || '').trim().toLowerCase() === code);
    if (found) { setScanMsg(''); onPick(found); }
    else setScanMsg(`Kode "${text}" tidak ditemukan.`);
  }

  return (
    <div>
    <div className="flex items-start gap-2">
    <div ref={boxRef} className="relative min-w-0 flex-1">
      <button
        type="button"
        disabled={disabled}
        onClick={() => setOpen((o) => !o)}
        className="input flex !h-auto min-h-[2.5rem] w-full items-center justify-between gap-2 text-left"
      >
        <span className={`min-w-0 flex-1 whitespace-normal break-words leading-snug ${selected ? 'text-slate-800' : 'text-slate-400'}`}>
          {selected ? (
            <>
              {label(selected)}
              <span className={`block text-xs ${selected.stock <= 0 ? 'text-red-500' : 'text-slate-500'}`}>(Stok: {selected.stock})</span>
            </>
          ) : 'Cari Sparepart...'}
        </span>
        <FaChevronDown className={`shrink-0 text-[10px] text-slate-400 transition-transform ${open ? 'rotate-180' : ''}`} aria-hidden />
      </button>

      {open && (
        <ComboPanel anchorRef={boxRef} onClose={close}>
          <div className="shrink-0 p-2">
            <input
              autoFocus
              className="input !border-slate-800 !py-1.5 text-[13px]"
              placeholder="Ketik untuk mencari..."
              value={query}
              onChange={(e) => setQuery(e.target.value)}
            />
          </div>
          <ul className="min-h-0 flex-1 overflow-y-auto border-t border-slate-100">
            {filtered.map((o) => (
              <li key={o.id} className="border-t border-slate-100 first:border-t-0">
                <button
                  type="button"
                  className="w-full whitespace-normal break-words px-3.5 py-2.5 text-left text-sm text-slate-800 hover:bg-brand-50"
                  onClick={() => { onPick(o); close(); }}
                >
                  {label(o)}
                  <span className={`block text-xs ${o.stock <= 0 ? 'text-red-500' : 'text-slate-500'}`}>(Stok: {o.stock})</span>
                </button>
              </li>
            ))}
            {filtered.length === 0 && (
              <li className="px-3.5 py-2.5 text-sm text-slate-400">
                {options.length === 0 ? 'Belum ada sparepart.' : 'Sparepart tidak ditemukan.'}
              </li>
            )}
          </ul>
        </ComboPanel>
      )}
    </div>
    <ScanButton disabled={disabled} onScan={handleScan} title="Scan kode sparepart" />
    </div>
    {scanMsg && <p className="mt-1 break-words text-xs font-semibold text-red-600">{scanMsg}</p>}
    </div>
  );
}
