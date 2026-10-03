import React, { useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import { FaCircleNotch, FaEye, FaEyeSlash, FaLock, FaSignInAlt, FaTools, FaUser } from 'react-icons/fa';
import { useAuth } from '../context/AuthContext';
import { useSettingsContext } from '../context/SettingsContext';
import Alert from '../components/ui/Alert';

export default function Login() {
  const { login, loading, error } = useAuth();
  const { name: brandName, logo } = useSettingsContext();
  const [identifier, setIdentifier] = useState('');
  const [password, setPassword] = useState('');
  const [showPw, setShowPw] = useState(false);
  const navigate = useNavigate();
  const location = useLocation();

  async function handleSubmit(e) {
    e.preventDefault();
    const ok = await login(identifier, password);
    if (ok) {
      const dest = location.state?.from || '/';
      navigate(dest, { replace: true });
    }
  }

  return (
    <div className="relative flex min-h-screen items-center justify-center overflow-hidden bg-ink-900 px-4">
      {/* Latar: cahaya lembut yang bergerak pelan */}
      <div aria-hidden className="pointer-events-none absolute -left-24 -top-24 h-96 w-96 rounded-full bg-brand-500/20 blur-3xl animate-float" />
      <div aria-hidden className="pointer-events-none absolute -bottom-32 -right-16 h-96 w-96 rounded-full bg-red-500/10 blur-3xl animate-float" style={{ animationDelay: '1.5s' }} />

      <div className="card relative w-full max-w-sm animate-scale-in p-8 shadow-2xl">
        <div className="mb-6 text-center">
          {logo ? (
            <img src={logo} alt={brandName} className="mx-auto mb-3 h-16 w-auto max-w-[220px] animate-pop object-contain" />
          ) : (
            <div className="mx-auto mb-3 flex h-14 w-14 animate-pop items-center justify-center rounded-xl bg-brand-500 text-2xl text-white shadow-lg shadow-brand-500/30">
              <FaTools aria-hidden />
            </div>
          )}
          <h1 className="text-lg font-semibold text-slate-800">{brandName} <span className="font-normal text-slate-400">v1.2</span></h1>
          <p className="text-sm text-slate-500">Masuk ke aplikasi manajemen bengkel</p>
        </div>

        <Alert message={error} />

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="label" htmlFor="identifier">Username atau Email</label>
            <div className="relative">
              <FaUser className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-sm text-slate-400" aria-hidden />
              <input
                id="identifier"
                className="input !pl-9"
                value={identifier}
                onChange={(e) => setIdentifier(e.target.value)}
                placeholder="admin"
                autoComplete="username"
                required
              />
            </div>
          </div>
          <div>
            <label className="label" htmlFor="password">Password</label>
            <div className="relative">
              <FaLock className="pointer-events-none absolute left-3 top-1/2 -translate-y-1/2 text-sm text-slate-400" aria-hidden />
              <input
                id="password"
                type={showPw ? 'text' : 'password'}
                className="input !px-9"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                placeholder="Masukkan password"
                autoComplete="current-password"
                required
              />
              <button
                type="button"
                onClick={() => setShowPw((v) => !v)}
                className="absolute right-2 top-1/2 -translate-y-1/2 rounded p-1.5 text-slate-400 transition hover:text-slate-600"
                aria-label={showPw ? 'Sembunyikan password' : 'Tampilkan password'}
              >
                {showPw ? <FaEyeSlash /> : <FaEye />}
              </button>
            </div>
          </div>
          <button type="submit" disabled={loading} className="btn-primary w-full !py-2.5">
            {loading ? <FaCircleNotch className="animate-spin" aria-hidden /> : <FaSignInAlt aria-hidden />}
            {loading ? 'Memproses...' : 'Masuk'}
          </button>
        </form>

        <p className="mt-6 text-center text-xs text-slate-400">
          Demo: admin/admin123 &middot; staff/staff123 &middot; teknisi1/teknisi123
        </p>
      </div>
    </div>
  );
}
