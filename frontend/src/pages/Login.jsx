import React, { useState } from 'react';
import { useNavigate, useLocation } from 'react-router-dom';
import {
  FaBoxes, FaChartLine, FaCircleNotch, FaEye, FaEyeSlash, FaLock, FaSignInAlt, FaTools, FaUser, FaWrench,
} from 'react-icons/fa';
import { useAuth } from '../context/AuthContext';
import { useSettingsContext } from '../context/SettingsContext';
import Alert from '../components/ui/Alert';

// Titik-titik skala tachometer: 270 derajat, dimulai dari 135 derajat (kiri bawah).
const CX = 200;
const CY = 200;
const TICKS = Array.from({ length: 41 }, (_, i) => {
  const major = i % 5 === 0;
  const a = ((135 + (270 * i) / 40) * Math.PI) / 180;
  const r1 = 150;
  const r2 = major ? 126 : 138;
  return {
    i, major, red: i >= 34,
    x1: CX + r1 * Math.cos(a), y1: CY + r1 * Math.sin(a),
    x2: CX + r2 * Math.cos(a), y2: CY + r2 * Math.sin(a),
    lx: CX + 104 * Math.cos(a), ly: CY + 104 * Math.sin(a),
  };
});

// Busur zona merah (tick 34 sampai 40)
function polar(r, deg) {
  const a = (deg * Math.PI) / 180;
  return [CX + r * Math.cos(a), CY + r * Math.sin(a)];
}
const [RX1, RY1] = polar(160, 135 + (270 * 34) / 40);
const [RX2, RY2] = polar(160, 405);
const REDLINE = `M ${RX1.toFixed(2)} ${RY1.toFixed(2)} A 160 160 0 0 1 ${RX2.toFixed(2)} ${RY2.toFixed(2)}`;

// Tachometer: jarum menyapu penuh sekali saat halaman dibuka, lalu berhenti di putaran stasioner.
function Tachometer() {
  return (
    <svg viewBox="0 0 400 400" className="h-auto w-full" role="img" aria-label="Ilustrasi tachometer">
      <defs>
        <radialGradient id="dial" cx="50%" cy="50%" r="50%">
          <stop offset="0%" stopColor="#16233d" />
          <stop offset="100%" stopColor="#0b1220" />
        </radialGradient>
        <linearGradient id="needle" x1="0" y1="0" x2="1" y2="0">
          <stop offset="0%" stopColor="#fbbf24" />
          <stop offset="100%" stopColor="#f59e0b" />
        </linearGradient>
      </defs>

      <circle cx={CX} cy={CY} r="188" fill="url(#dial)" stroke="rgba(255,255,255,.10)" strokeWidth="1.5" />
      <circle cx={CX} cy={CY} r="178" fill="none" stroke="rgba(143,179,255,.14)" strokeWidth="1" />

      <path d={REDLINE} fill="none" stroke="#ef4444" strokeWidth="5" strokeLinecap="round" opacity=".85" />

      {TICKS.map((t) => (
        <line
          key={t.i}
          x1={t.x1} y1={t.y1} x2={t.x2} y2={t.y2}
          stroke={t.red ? '#f87171' : t.major ? 'rgba(255,255,255,.85)' : 'rgba(255,255,255,.35)'}
          strokeWidth={t.major ? 2.5 : 1.5}
          strokeLinecap="round"
        />
      ))}

      {TICKS.filter((t) => t.major).map((t) => (
        <text
          key={`l${t.i}`} x={t.lx} y={t.ly}
          textAnchor="middle" dominantBaseline="central"
          fontSize="19" fontWeight="700" fill={t.red ? '#fca5a5' : 'rgba(255,255,255,.78)'}
          style={{ fontFamily: '"Plus Jakarta Sans", sans-serif' }}
        >
          {t.i / 5}
        </text>
      ))}

      <text
        x={CX} y="272" textAnchor="middle" fontSize="12" fontWeight="600" letterSpacing="1.5"
        fill="rgba(255,255,255,.4)" style={{ fontFamily: '"Plus Jakarta Sans", sans-serif' }}
      >
        x1000 rpm
      </text>

      {/* Jarum: digambar menunjuk ke kanan, lalu diputar lewat animasi */}
      <g className="animate-gauge" style={{ transformOrigin: `${CX}px ${CY}px` }}>
        <line x1={CX - 26} y1={CY} x2={CX + 128} y2={CY} stroke="url(#needle)" strokeWidth="4" strokeLinecap="round" />
      </g>
      <circle cx={CX} cy={CY} r="15" fill="#0e1626" stroke="rgba(255,255,255,.25)" strokeWidth="2" />
      <circle cx={CX} cy={CY} r="5" fill="#fbbf24" />
    </svg>
  );
}

const POINTS = [
  { icon: FaWrench, text: 'Transaksi service dari diterima sampai lunas' },
  { icon: FaBoxes, text: 'Stok sparepart dengan peringatan saat menipis' },
  { icon: FaChartLine, text: 'Laporan layanan, penjualan, dan stok' },
];

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

  const brandMark = logo ? (
    <span className="flex h-11 items-center rounded-xl bg-white px-2 shadow-lg shadow-black/20 ring-1 ring-white/20">
      <img src={logo} alt={brandName} className="h-8 w-auto max-w-[140px] object-contain" />
    </span>
  ) : (
    <span className="icon-tile h-11 w-11 text-lg"><FaTools aria-hidden /></span>
  );

  return (
    <div className="grid min-h-screen lg:grid-cols-[1.1fr_1fr]">
      {/* ============ Panel kiri: identitas bengkel (hanya layar lebar) ============ */}
      <aside className="relative hidden flex-col justify-between overflow-hidden bg-ink-950 p-12 text-white lg:flex">
        {/* Kisi halus + cahaya biru sebagai latar */}
        <div
          aria-hidden
          className="pointer-events-none absolute inset-0 opacity-[.35]"
          style={{
            backgroundImage:
              'linear-gradient(rgba(255,255,255,.05) 1px, transparent 1px), linear-gradient(90deg, rgba(255,255,255,.05) 1px, transparent 1px)',
            backgroundSize: '44px 44px',
            maskImage: 'radial-gradient(ellipse at 50% 45%, #000 20%, transparent 75%)',
            WebkitMaskImage: 'radial-gradient(ellipse at 50% 45%, #000 20%, transparent 75%)',
          }}
        />
        <div aria-hidden className="pointer-events-none absolute -left-32 -top-32 h-[28rem] w-[28rem] rounded-full bg-brand-500/25 blur-3xl animate-float" />
        <div aria-hidden className="pointer-events-none absolute -bottom-40 -right-24 h-[26rem] w-[26rem] rounded-full bg-brand-700/30 blur-3xl animate-float" style={{ animationDelay: '1.5s' }} />

        <div className="relative flex items-center gap-3.5">
          {brandMark}
          <span className="max-w-[320px] truncate text-lg font-extrabold tracking-tight">{brandName}</span>
        </div>

        <div className="relative mx-auto w-full max-w-[400px]">
          <Tachometer />
        </div>

        <div className="relative">
          <h2 className="max-w-md text-[34px] font-extrabold leading-[1.15] tracking-tight text-white">
            Kelola service, stok, dan penjualan dalam satu aplikasi.
          </h2>
          <ul className="mt-7 space-y-3.5">
            {POINTS.map(({ icon: Icon, text }) => (
              <li key={text} className="flex items-center gap-3 text-[14.5px] text-slate-300">
                <span className="flex h-8 w-8 shrink-0 items-center justify-center rounded-lg bg-white/[0.07] text-[13px] text-brand-300 ring-1 ring-inset ring-white/10">
                  <Icon aria-hidden />
                </span>
                {text}
              </li>
            ))}
          </ul>
        </div>
      </aside>

      {/* ============ Panel kanan: form masuk ============ */}
      <main className="relative flex items-center justify-center overflow-hidden px-5 py-10 sm:px-10">
        <div aria-hidden className="pointer-events-none absolute -right-24 -top-24 h-72 w-72 rounded-full bg-brand-400/10 blur-3xl" />

        <div className="relative w-full max-w-[400px] animate-fade-up">
          {/* Merek untuk layar kecil, karena panel kiri disembunyikan */}
          <div className="mb-8 flex items-center gap-3 lg:hidden">
            {logo ? (
              <span className="flex h-11 items-center rounded-xl bg-white px-2 shadow-soft ring-1 ring-slate-900/[0.06]">
                <img src={logo} alt={brandName} className="h-8 w-auto max-w-[140px] object-contain" />
              </span>
            ) : (
              <span className="icon-tile h-11 w-11 text-lg"><FaTools aria-hidden /></span>
            )}
            <span className="truncate text-base font-extrabold tracking-tight text-slate-900">{brandName}</span>
          </div>

          <h1 className="text-[28px] font-extrabold tracking-tight text-slate-900">Masuk</h1>
          <p className="mt-1.5 text-[14.5px] text-slate-500">Gunakan akun Anda untuk membuka aplikasi bengkel.</p>

          <div className="mt-7">
            <Alert message={error} />
          </div>

          <form onSubmit={handleSubmit} className="mt-1 space-y-5">
            <div>
              <label className="label" htmlFor="identifier">Username atau email</label>
              <div className="relative">
                <FaUser className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-sm text-slate-400" aria-hidden />
                <input
                  id="identifier"
                  className="input !h-11 !pl-10"
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
                <FaLock className="pointer-events-none absolute left-3.5 top-1/2 -translate-y-1/2 text-sm text-slate-400" aria-hidden />
                <input
                  id="password"
                  type={showPw ? 'text' : 'password'}
                  className="input !h-11 !pl-10 !pr-11"
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  placeholder="Masukkan password"
                  autoComplete="current-password"
                  required
                />
                <button
                  type="button"
                  onClick={() => setShowPw((v) => !v)}
                  className="absolute right-2 top-1/2 -translate-y-1/2 rounded-lg p-2 text-slate-400 transition hover:bg-slate-100 hover:text-slate-600 focus:outline-none focus-visible:ring-2 focus-visible:ring-brand-400"
                  aria-label={showPw ? 'Sembunyikan password' : 'Tampilkan password'}
                >
                  {showPw ? <FaEyeSlash /> : <FaEye />}
                </button>
              </div>
            </div>
            <button type="submit" disabled={loading} className="btn-primary w-full !h-11 !text-[15px]">
              {loading ? <FaCircleNotch className="animate-spin" aria-hidden /> : <FaSignInAlt aria-hidden />}
              {loading ? 'Memproses...' : 'Masuk'}
            </button>
          </form>

          <p className="mt-8 rounded-xl border border-dashed border-slate-300 bg-white/60 px-4 py-3 text-center text-xs leading-relaxed text-slate-500">
            Akun demo: admin / admin123, staff / staff123, teknisi1 / teknisi123
          </p>

          <p className="mt-8 text-center text-xs text-slate-400">&copy; {new Date().getFullYear()} {brandName}</p>
        </div>
      </main>
    </div>
  );
}
