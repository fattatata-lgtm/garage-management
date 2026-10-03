import React, { createContext, useCallback, useContext, useEffect, useMemo, useState } from 'react';
import api from '../api/axios';
import { useAuth } from './AuthContext';
import { assetUrl } from '../utils/assetUrl';

const SettingsContext = createContext(null);

const DEFAULT_NAME = 'Self Automotive';

// Satu sumber data Pengaturan untuk seluruh aplikasi: topbar, login, footer, judul tab,
// favicon, invoice, dan halaman Pengaturan. Setelah disimpan, semuanya ikut berubah seketika.
// Belum login -> hanya nama & logo (endpoint publik); sudah login -> pengaturan lengkap.
export function SettingsProvider({ children }) {
  const { user } = useAuth();
  const authed = Boolean(user);
  const [settings, setSettings] = useState(null);

  const refresh = useCallback(async () => {
    try {
      const { data } = await api.get(authed ? '/settings' : '/settings/public');
      setSettings(data);
    } catch { /* abaikan: aplikasi tetap jalan dengan nama bawaan */ }
  }, [authed]);

  useEffect(() => { refresh(); }, [refresh]);

  const name = settings?.businessName || DEFAULT_NAME;
  const logo = assetUrl(settings?.logoUrl);

  // Judul tab browser
  useEffect(() => { document.title = `${name} - Aplikasi Bengkel`; }, [name]);

  // Favicon mengikuti logo (kembali ke bawaan kalau logo dihapus)
  useEffect(() => {
    let link = document.querySelector('link[rel~="icon"]');
    if (!logo) { if (link) link.remove(); return; }
    if (!link) { link = document.createElement('link'); link.rel = 'icon'; document.head.appendChild(link); }
    link.href = logo;
  }, [logo]);

  const value = useMemo(() => ({ settings, setSettings, refresh, name, logo }), [settings, refresh, name, logo]);
  return <SettingsContext.Provider value={value}>{children}</SettingsContext.Provider>;
}

export function useSettingsContext() {
  const ctx = useContext(SettingsContext);
  if (!ctx) throw new Error('useSettingsContext harus dipakai di dalam SettingsProvider');
  return ctx;
}
