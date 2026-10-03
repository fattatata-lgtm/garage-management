import React, { useCallback, useEffect, useRef, useState } from 'react';
import { BrowserMultiFormatReader } from '@zxing/browser';
import { DecodeHintType } from '@zxing/library';
import { FaBarcode, FaSyncAlt } from 'react-icons/fa';
import Modal from './Modal';

// Android & tablet (iPad / tablet Android) => kamera belakang. Laptop / desktop => webcam (kamera depan).
export function preferredFacing() {
  const ua = navigator.userAgent || '';
  const isAndroid = /Android/i.test(ua);
  const isTablet = /iPad|Tablet|PlayBook|Silk/i.test(ua);
  const isIpadOS = /Macintosh/i.test(ua) && navigator.maxTouchPoints > 1; // iPad mode desktop
  const isPhone = /iPhone|iPod|Mobile/i.test(ua);
  return isAndroid || isTablet || isIpadOS || isPhone ? 'environment' : 'user';
}

const NATIVE_FORMATS = ['code_128', 'code_39', 'code_93', 'ean_13', 'ean_8', 'upc_a', 'upc_e', 'itf', 'codabar', 'qr_code', 'data_matrix'];

// Modal kamera untuk memindai barcode / QR. onDetected(teks) dipanggil sekali per pemindaian berhasil.
export default function BarcodeScanner({ open, onClose, onDetected, title = 'Scan Barcode' }) {
  const videoRef = useRef(null);
  const streamRef = useRef(null);
  const stopRef = useRef(() => {});
  const doneRef = useRef(false);
  const [facing, setFacing] = useState(preferredFacing);
  const [error, setError] = useState('');
  const [starting, setStarting] = useState(true);
  const [zoom, setZoom] = useState(null); // { min, max, step, value }

  const stop = useCallback(() => {
    stopRef.current();
    stopRef.current = () => {};
    streamRef.current?.getTracks().forEach((t) => t.stop());
    streamRef.current = null;
    if (videoRef.current) videoRef.current.srcObject = null;
  }, []);

  const found = useCallback((text) => {
    if (doneRef.current || !text) return;
    doneRef.current = true;
    if (navigator.vibrate) navigator.vibrate(60);
    onDetected(text);
  }, [onDetected]);

  useEffect(() => {
    if (!open) return undefined;
    let cancelled = false;
    doneRef.current = false;
    setError('');
    setStarting(true);
    setZoom(null);

    async function start() {
      if (!navigator.mediaDevices?.getUserMedia) {
        setError('Kamera tidak tersedia. Buka aplikasi lewat HTTPS (atau localhost) dan gunakan browser terbaru.');
        setStarting(false);
        return;
      }
      try {
        // Resolusi setinggi mungkin (Full HD) supaya barcode kecil tetap tajam
        const stream = await navigator.mediaDevices.getUserMedia({
          audio: false,
          video: { facingMode: { ideal: facing }, width: { ideal: 1920 }, height: { ideal: 1080 }, frameRate: { ideal: 30 } },
        });
        if (cancelled) { stream.getTracks().forEach((t) => t.stop()); return; }
        streamRef.current = stream;
        const video = videoRef.current;
        video.srcObject = stream;
        await video.play().catch(() => {});

        // Minta autofokus terus-menerus & baca kemampuan zoom (jika didukung kamera)
        const track = stream.getVideoTracks()[0];
        const caps = track.getCapabilities ? track.getCapabilities() : {};
        try {
          if (caps.focusMode?.includes('continuous')) await track.applyConstraints({ advanced: [{ focusMode: 'continuous' }] });
        } catch { /* kamera tidak mendukung */ }
        if (caps.zoom) setZoom({ min: caps.zoom.min, max: caps.zoom.max, step: caps.zoom.step || 0.1, value: caps.zoom.min });

        // Pembaca: BarcodeDetector bawaan browser (paling akurat) bila ada, jika tidak pakai ZXing
        if ('BarcodeDetector' in window) {
          let formats = NATIVE_FORMATS;
          try { formats = (await window.BarcodeDetector.getSupportedFormats()).filter((f) => NATIVE_FORMATS.includes(f)); } catch { /* pakai default */ }
          const detector = new window.BarcodeDetector({ formats });
          let busy = false;
          const timer = setInterval(async () => {
            if (busy || doneRef.current || video.readyState < 2) return;
            busy = true;
            try {
              const codes = await detector.detect(video);
              if (codes.length) found(codes[0].rawValue);
            } catch { /* abaikan frame gagal */ }
            busy = false;
          }, 120);
          stopRef.current = () => clearInterval(timer);
        } else {
          const hints = new Map();
          hints.set(DecodeHintType.TRY_HARDER, true);
          const reader = new BrowserMultiFormatReader(hints, { delayBetweenScanAttempts: 80 });
          const controls = await reader.decodeFromStream(stream, video, (result) => { if (result) found(result.getText()); });
          stopRef.current = () => { try { controls.stop(); } catch { /* abaikan */ } };
        }
        setStarting(false);
      } catch (err) {
        if (cancelled) return;
        const name = err?.name || '';
        if (name === 'NotAllowedError' || name === 'SecurityError') setError('Izin kamera ditolak. Aktifkan izin kamera di pengaturan browser lalu coba lagi.');
        else if (name === 'NotFoundError' || name === 'OverconstrainedError') setError('Kamera tidak ditemukan di perangkat ini.');
        else if (name === 'NotReadableError') setError('Kamera sedang dipakai aplikasi lain.');
        else setError('Gagal membuka kamera.');
        setStarting(false);
      }
    }
    start();
    return () => { cancelled = true; stop(); };
  }, [open, facing, found, stop]);

  function changeZoom(v) {
    setZoom((z) => ({ ...z, value: v }));
    const track = streamRef.current?.getVideoTracks()[0];
    track?.applyConstraints({ advanced: [{ zoom: v }] }).catch(() => {});
  }

  return (
    <Modal open={open} title={title} onClose={onClose}>
      <div className="space-y-3">
        <div className="relative mx-auto aspect-[4/3] max-h-[50dvh] w-full overflow-hidden rounded-xl bg-black">
          <video ref={videoRef} className={`absolute inset-0 h-full w-full object-cover ${facing === 'user' ? '-scale-x-100' : ''}`} muted playsInline autoPlay />
          {!error && !starting && (
            <div className="pointer-events-none absolute inset-0 flex items-center justify-center">
              <div className="h-1/2 w-4/5 rounded-lg border-2 border-white/80 shadow-[0_0_0_9999px_rgba(0,0,0,0.35)]" />
              <div className="absolute h-0.5 w-4/5 animate-pulse bg-red-500/80" />
            </div>
          )}
          {starting && !error && (
            <div className="absolute inset-0 flex items-center justify-center text-sm text-white/80">Membuka kamera...</div>
          )}
        </div>

        {zoom && zoom.max > zoom.min && (
          <div className="flex items-center gap-3 text-xs text-slate-500">
            <span>Zoom</span>
            <input type="range" className="flex-1" min={zoom.min} max={zoom.max} step={zoom.step} value={zoom.value} onChange={(e) => changeZoom(Number(e.target.value))} />
          </div>
        )}

        {error
          ? <p className="rounded-lg bg-red-50 px-3 py-2 text-sm text-red-600">{error}</p>
          : (
            <div className="space-y-1 text-sm text-slate-500">
              <p className="flex items-center gap-2"><FaBarcode aria-hidden /> Arahkan barcode ke dalam kotak. Kamera {facing === 'user' ? 'depan / webcam' : 'belakang'}.</p>
              <p className="text-xs text-slate-400">Jika blur: jauhkan barcode sekitar 15–30 cm dari kamera, pastikan cahaya terang, dan jangan digoyang.</p>
            </div>
          )}

        <div className="flex flex-wrap justify-end gap-2">
          <button type="button" className="btn-secondary" onClick={() => setFacing((f) => (f === 'user' ? 'environment' : 'user'))}>
            <FaSyncAlt aria-hidden /> Ganti Kamera
          </button>
          <button type="button" className="btn-muted" onClick={onClose}>Tutup</button>
        </div>
      </div>
    </Modal>
  );
}
