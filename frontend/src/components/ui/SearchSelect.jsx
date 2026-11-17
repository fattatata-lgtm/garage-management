import React, { useMemo, useRef, useState } from 'react';
import { FaChevronDown, FaCheck } from 'react-icons/fa';
import ComboPanel from './ComboPanel';

// Ambil teks dari children <option> (bisa berupa array string / elemen).
function textOf(node) {
  if (node == null || typeof node === 'boolean') return '';
  if (Array.isArray(node)) return node.map(textOf).join('');
  if (React.isValidElement(node)) return textOf(node.props.children);
  return String(node);
}

// Kumpulkan <option> dari children (mendukung Fragment, array hasil .map, dan <optgroup>).
function collect(children, out = []) {
  React.Children.forEach(children, (ch) => {
    if (!React.isValidElement(ch)) return;
    if (ch.type === React.Fragment || ch.type === 'optgroup') collect(ch.props.children, out);
    else if (ch.type === 'option') {
      const label = textOf(ch.props.children);
      out.push({ value: String(ch.props.value ?? label), label, disabled: !!ch.props.disabled });
    }
  });
  return out;
}

// Pengganti <select> dengan kolom pencarian. API sama seperti <select>:
//   <SearchSelect value={..} onChange={(e) => e.target.value} required disabled>
//     <option value="">-- Pilih --</option> ...
//   </SearchSelect>
export default function SearchSelect({
  value, defaultValue, onChange, required, disabled, name, placeholder = 'Ketik untuk mencari...', children,
}) {
  const [inner, setInner] = useState(defaultValue ?? '');
  const [open, setOpen] = useState(false);
  const [query, setQuery] = useState('');
  const boxRef = useRef(null);

  const current = String(value !== undefined ? (value ?? '') : inner);
  const all = useMemo(() => collect(children), [children]);
  const emptyOpt = all.find((o) => o.value === '');
  const selected = all.find((o) => o.value === current);

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    // Pada field wajib, opsi kosong ("-- Pilih --") hanya placeholder, bukan pilihan.
    const base = required ? all.filter((o) => o.value !== '') : all;
    if (!q) return base;
    return base.filter((o) => o.label.toLowerCase().includes(q));
  }, [all, query, required]);

  const close = () => { setOpen(false); setQuery(''); };

  function pick(o) {
    if (o.disabled) return;
    if (value === undefined) setInner(o.value);
    onChange?.({ target: { value: o.value, name } });
    close();
  }

  return (
    <div ref={boxRef} className="relative min-w-0">
      <button
        type="button"
        disabled={disabled}
        onClick={() => setOpen((o) => !o)}
        className="input flex !h-auto min-h-[2.5rem] w-full items-center justify-between gap-2 text-left"
      >
        <span className={`min-w-0 flex-1 whitespace-normal break-words leading-snug ${selected && current !== '' ? 'text-slate-800' : 'text-slate-400'}`}>
          {selected ? selected.label : (emptyOpt?.label || 'Pilih...')}
        </span>
        <FaChevronDown className={`shrink-0 text-[10px] text-slate-400 transition-transform ${open ? 'rotate-180' : ''}`} aria-hidden />
      </button>

      {/* Input tersembunyi agar atribut `required` tetap divalidasi oleh browser */}
      {required && (
        <input
          tabIndex={-1}
          aria-hidden
          required
          value={current}
          onChange={() => {}}
          className="pointer-events-none absolute inset-0 h-full w-full opacity-0"
        />
      )}

      {open && (
        <ComboPanel anchorRef={boxRef} onClose={close}>
          <div className="shrink-0 p-2">
            <input
              autoFocus
              className="input !border-slate-800 !py-1.5 text-[13px]"
              placeholder={placeholder}
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              onKeyDown={(e) => {
                if (e.key === 'Enter') { e.preventDefault(); if (filtered[0]) pick(filtered[0]); }
              }}
            />
          </div>
          <ul className="min-h-0 flex-1 overflow-y-auto border-t border-slate-100">
            {filtered.map((o) => (
              <li key={o.value} className="border-t border-slate-100 first:border-t-0">
                <button
                  type="button"
                  disabled={o.disabled}
                  className={`flex w-full items-center justify-between gap-2 whitespace-normal break-words px-3.5 py-2.5 text-left text-sm hover:bg-brand-50 disabled:opacity-40 ${o.value === current ? 'bg-brand-50 font-semibold text-slate-900' : 'text-slate-800'} ${o.value === '' ? 'text-slate-500' : ''}`}
                  onClick={() => pick(o)}
                >
                  <span>{o.label}</span>
                  {o.value === current && <FaCheck className="shrink-0 text-[10px] text-brand-600" aria-hidden />}
                </button>
              </li>
            ))}
            {filtered.length === 0 && (
              <li className="px-3.5 py-2.5 text-sm text-slate-400">
                {all.length === 0 ? 'Belum ada data.' : 'Data tidak ditemukan.'}
              </li>
            )}
          </ul>
        </ComboPanel>
      )}
    </div>
  );
}
