import React, { useState } from 'react';
import { FaBarcode } from 'react-icons/fa';
import BarcodeScanner from './BarcodeScanner';

// Tombol ikon barcode + modal kamera. onScan(teks) dipanggil saat barcode terbaca, modal otomatis tertutup.
export default function ScanButton({ onScan, disabled, title = 'Scan Barcode', className = '' }) {
  const [open, setOpen] = useState(false);
  const handle = React.useCallback((text) => { setOpen(false); onScan(String(text).trim()); }, [onScan]);
  return (
    <>
      <button
        type="button"
        disabled={disabled}
        onClick={() => setOpen(true)}
        title={title}
        aria-label={title}
        className={`btn-dark !px-3 shrink-0 disabled:opacity-50 ${className}`}
      >
        <FaBarcode aria-hidden />
      </button>
      {open && <BarcodeScanner open title={title} onClose={() => setOpen(false)} onDetected={handle} />}
    </>
  );
}
