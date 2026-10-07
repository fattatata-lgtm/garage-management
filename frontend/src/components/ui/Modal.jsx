import React, { useEffect } from 'react';
import { createPortal } from 'react-dom';
import { FaTimes } from 'react-icons/fa';

export default function Modal({ open, title, onClose, children, wide }) {
  // Tutup dengan tombol Escape
  useEffect(() => {
    if (!open) return undefined;
    const onKey = (e) => { if (e.key === 'Escape') onClose?.(); };
    document.addEventListener('keydown', onKey);
    return () => document.removeEventListener('keydown', onKey);
  }, [open, onClose]);

  // Kunci scroll halaman di belakang overlay
  useEffect(() => {
    if (!open) return undefined;
    const prev = document.body.style.overflow;
    document.body.style.overflow = 'hidden';
    return () => { document.body.style.overflow = prev; };
  }, [open]);

  if (!open) return null;

  // Dirender lewat portal ke <body> supaya overlay benar-benar full screen:
  // elemen `fixed` di dalam parent ber-transform (mis. .page-enter) akan terkurung di parent tsb
  // dan tertimpa navbar / bar sticky.
  return createPortal(
    <div
      className="fixed inset-0 z-[1000] flex items-center justify-center bg-ink-950/60 p-3 backdrop-blur-sm no-print animate-fade-in sm:p-4"
      onMouseDown={(e) => { if (e.target === e.currentTarget) onClose?.(); }}
    >
      <div
        role="dialog"
        aria-modal="true"
        className={`card flex w-full shadow-lift ${wide ? 'max-w-2xl' : 'max-w-md'} max-h-[calc(100dvh-1.5rem)] flex-col overflow-hidden animate-scale-in sm:max-h-[calc(100dvh-2rem)]`}
      >
        <div className="card-header shrink-0 justify-between">
          <h3>{title}</h3>
          <button onClick={onClose} aria-label="Tutup" className="rounded-lg p-1.5 text-white/70 transition hover:bg-white/10 hover:text-white focus:outline-none focus-visible:ring-2 focus-visible:ring-white/50">
            <FaTimes />
          </button>
        </div>
        <div className="min-h-0 flex-1 overflow-y-auto p-4 sm:p-5">{children}</div>
      </div>
    </div>,
    document.body,
  );
}
