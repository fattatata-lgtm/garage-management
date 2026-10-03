import React, { useEffect, useLayoutEffect, useRef, useState } from 'react';
import { createPortal } from 'react-dom';

// Panel dropdown yang dirender di luar kartu (portal) agar tidak terpotong / tertutup kartu lain.
// Otomatis memilih membuka ke bawah atau ke atas sesuai ruang layar, dan tingginya menyesuaikan.
export default function ComboPanel({ anchorRef, onClose, children }) {
  const panelRef = useRef(null);
  const [pos, setPos] = useState(null);

  useLayoutEffect(() => {
    function place() {
      const el = anchorRef.current;
      if (!el) return;
      const r = el.getBoundingClientRect();
      const below = window.innerHeight - r.bottom - 12;
      const above = r.top - 12;
      const openUp = below < 300 && above > below;
      const maxH = Math.max(180, Math.min(openUp ? above : below, 520));
      const width = Math.max(r.width, 340);
      const left = Math.max(8, Math.min(r.left, window.innerWidth - width - 8));
      setPos({
        left, width, maxH,
        ...(openUp ? { bottom: window.innerHeight - r.top + 4 } : { top: r.bottom + 4 }),
      });
    }
    function onScroll(e) { if (panelRef.current && panelRef.current.contains(e.target)) return; place(); }
    place();
    window.addEventListener('resize', place);
    window.addEventListener('scroll', onScroll, true);
    return () => { window.removeEventListener('resize', place); window.removeEventListener('scroll', onScroll, true); };
  }, [anchorRef]);

  useEffect(() => {
    function onDown(e) {
      if (panelRef.current?.contains(e.target) || anchorRef.current?.contains(e.target)) return;
      onClose();
    }
    function onKey(e) { if (e.key === 'Escape') onClose(); }
    document.addEventListener('mousedown', onDown);
    document.addEventListener('keydown', onKey);
    return () => { document.removeEventListener('mousedown', onDown); document.removeEventListener('keydown', onKey); };
  }, [anchorRef, onClose]);

  if (!pos) return null;
  return createPortal(
    <div
      ref={panelRef}
      style={{ position: 'fixed', left: pos.left, width: pos.width, top: pos.top, bottom: pos.bottom, maxHeight: pos.maxH }}
      className="z-[100] flex flex-col overflow-hidden rounded-lg border border-slate-200 bg-white shadow-xl animate-drop-in"
    >
      {children}
    </div>,
    document.body,
  );
}
