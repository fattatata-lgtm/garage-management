import React, { useMemo, useRef, useState } from 'react';
import { FaChevronDown } from 'react-icons/fa';
import ComboPanel from './ComboPanel';

// Dropdown "Cari Jenis Service": kolom pencarian, opsi "Manual / Lainnya" di paling atas,
// lalu daftar Jenis Layanan. Memilih jenis mengisi otomatis deskripsi & biaya di baris jasa.
export default function ServiceTypePicker({ options, value, onPick, onManual }) {
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState('');
  const boxRef = useRef(null);

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    if (!q) return options;
    return options.filter((o) => o.name.toLowerCase().includes(q) || (o.description || '').toLowerCase().includes(q));
  }, [options, query]);

  const close = () => { setOpen(false); setQuery(''); };

  return (
    <div ref={boxRef} className="relative">
      <button
        type="button"
        onClick={() => setOpen((o) => !o)}
        className="input flex w-full items-center justify-between gap-2 text-left"
      >
        <span className={`truncate ${value ? 'text-slate-800' : 'text-slate-400'}`}>{value || 'Cari...'}</span>
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
            <li>
              <button
                type="button"
                className="w-full bg-slate-100 px-3.5 py-2.5 text-left text-sm text-slate-800 hover:bg-slate-200"
                onClick={() => { onManual(query.trim()); close(); }}
              >
                Manual / Lainnya{query.trim() ? ` — "${query.trim()}"` : ''}
              </button>
            </li>
            {filtered.map((o) => (
              <li key={o.id} className="border-t border-slate-100">
                <button
                  type="button"
                  className="w-full px-3.5 py-2.5 text-left text-sm text-slate-800 hover:bg-brand-50"
                  onClick={() => { onPick(o); close(); }}
                >
                  {o.name}
                  {o.description && <span className="block text-xs text-slate-500">{o.description}</span>}
                </button>
              </li>
            ))}
            {filtered.length === 0 && (
              <li className="border-t border-slate-100 px-3.5 py-2.5 text-sm text-slate-400">
                {options.length === 0 ? 'Belum ada Jenis Layanan.' : 'Jenis service tidak ditemukan.'}
              </li>
            )}
          </ul>
        </ComboPanel>
      )}
    </div>
  );
}
