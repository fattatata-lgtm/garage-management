import React, { useEffect, useState } from 'react';
import { Outlet, useLocation } from 'react-router-dom';
import { FaArrowUp, FaTools } from 'react-icons/fa';
import Navbar from './Navbar';
import { useSettingsContext } from '../context/SettingsContext';

// Status koneksi browser: titik hijau berdenyut saat online, merah saat offline.
function ConnectionStatus() {
  const [online, setOnline] = useState(() => (typeof navigator === 'undefined' ? true : navigator.onLine));

  useEffect(() => {
    const on = () => setOnline(true);
    const off = () => setOnline(false);
    window.addEventListener('online', on);
    window.addEventListener('offline', off);
    return () => {
      window.removeEventListener('online', on);
      window.removeEventListener('offline', off);
    };
  }, []);

  return (
    <span
      role="status"
      className={`inline-flex items-center gap-2 rounded-full border px-3 py-1.5 text-xs font-semibold ${
        online
          ? 'border-emerald-200/80 bg-emerald-50 text-emerald-700'
          : 'border-red-200/80 bg-red-50 text-red-700'
      }`}
    >
      <span className="relative flex h-2 w-2" aria-hidden>
        {online && <span className="absolute inline-flex h-full w-full animate-ping rounded-full bg-emerald-400 opacity-70" />}
        <span className={`relative inline-flex h-2 w-2 rounded-full ${online ? 'bg-emerald-500' : 'bg-red-500'}`} />
      </span>
      {online ? 'Terhubung' : 'Tidak ada koneksi'}
    </span>
  );
}

function Footer() {
  const { name, logo } = useSettingsContext();

  return (
    <footer className="no-print mt-6">
      <div className="mx-auto w-full max-w-[1400px] px-4 2xl:max-w-[1680px]">
        {/* Garis pemisah yang memudar di kedua ujung */}
        <div aria-hidden className="h-px w-full bg-gradient-to-r from-transparent via-slate-300 to-transparent" />

        <div className="flex flex-col items-center justify-between gap-4 py-6 sm:flex-row">
          <div className="flex items-center gap-3">
            {logo ? (
              <span className="flex h-9 items-center rounded-xl bg-white px-1.5 shadow-soft ring-1 ring-slate-900/[0.06]">
                <img src={logo} alt="" className="h-6 w-auto max-w-[96px] object-contain" />
              </span>
            ) : (
              <span
                className="flex h-9 w-9 items-center justify-center rounded-xl text-sm text-white"
                style={{
                  backgroundImage: 'linear-gradient(145deg, #5b8cf7 0%, #3a6df0 45%, #2045ad 100%)',
                  boxShadow: 'inset 0 1px 0 rgba(255,255,255,.35), 0 8px 16px -8px rgba(39,87,214,.6)',
                }}
              >
                <FaTools aria-hidden />
              </span>
            )}
            <div className="leading-tight">
              <p className="text-[13.5px] font-bold text-slate-800">{name}</p>
              <p className="mt-0.5 text-xs text-slate-500">&copy; {new Date().getFullYear()} Seluruh hak cipta dilindungi.</p>
            </div>
          </div>

          <div className="flex items-center gap-2.5">
            <ConnectionStatus />
            <button
              type="button"
              onClick={() => window.scrollTo({ top: 0, behavior: 'smooth' })}
              className="group inline-flex h-8 items-center gap-2 rounded-full border border-slate-200 bg-white px-3.5 text-xs font-semibold text-slate-600 shadow-sm transition-all hover:border-brand-300 hover:text-brand-600 focus:outline-none focus-visible:ring-2 focus-visible:ring-brand-400"
            >
              <FaArrowUp className="text-[10px] transition-transform group-hover:-translate-y-0.5" aria-hidden />
              Ke atas
            </button>
          </div>
        </div>
      </div>
    </footer>
  );
}

export default function Layout() {
  const { pathname } = useLocation();
  return (
    <div className="flex min-h-screen flex-col">
      <Navbar />
      {/* key = pathname supaya animasi masuk diputar ulang tiap pindah halaman */}
      <main key={pathname} className="page-enter mx-auto w-full max-w-[1400px] 2xl:max-w-[1680px] flex-1 px-4 py-6">
        <Outlet />
      </main>
      <Footer />
    </div>
  );
}
