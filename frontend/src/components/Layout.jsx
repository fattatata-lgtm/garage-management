import React from 'react';
import { Outlet, useLocation } from 'react-router-dom';
import Navbar from './Navbar';
import { useSettingsContext } from '../context/SettingsContext';

export default function Layout() {
  const { pathname } = useLocation();
  const { name } = useSettingsContext();
  return (
    <div className="flex min-h-screen flex-col">
      <Navbar />
      {/* key = pathname supaya animasi masuk diputar ulang tiap pindah halaman */}
      <main key={pathname} className="page-enter mx-auto w-full max-w-[1400px] 2xl:max-w-[1680px] flex-1 px-4 py-6">
        <Outlet />
      </main>
      <footer className="no-print mx-auto flex w-full max-w-[1400px] 2xl:max-w-[1680px] items-center justify-between px-4 py-4 text-xs text-slate-500">
        <span>&copy; {new Date().getFullYear()} {name}</span>
        <span>Versi 1.2</span>
      </footer>
    </div>
  );
}
