import React, { useEffect, useRef, useState } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import {
  FaBars, FaBoxes, FaCar, FaCarSide, FaChartLine, FaChevronDown, FaClipboardList, FaCog, FaCogs,
  FaHardHat, FaHistory, FaKey, FaPercent, FaShoppingCart, FaSignOutAlt, FaTachometerAlt, FaTags,
  FaTimes, FaTools, FaUserCog, FaUsers, FaWrench,
} from 'react-icons/fa';
import { useAuth } from '../context/AuthContext';
import { useSettingsContext } from '../context/SettingsContext';

const OPS = ['ADMIN', 'STAFF'];

// Struktur menu (PRD 2.3).
const MENUS = [
  { label: 'Dashboard', icon: FaTachometerAlt, to: '/', roles: ['ADMIN', 'STAFF', 'TEKNISI'] },
  { label: 'Pelanggan', icon: FaUsers, to: '/customers', roles: OPS },
  {
    label: 'Sparepart', icon: FaCogs, roles: OPS,
    items: [
      { label: 'Data Sparepart', desc: 'Daftar & harga sparepart', icon: FaCogs, to: '/spareparts' },
      { label: 'Kategori', desc: 'Kelompok sparepart', icon: FaTags, to: '/spareparts/categories' },
      { label: 'Riwayat Stok', desc: 'Stok masuk & keluar', icon: FaHistory, to: '/spareparts/stock-history' },
    ],
  },
  {
    label: 'Kendaraan', icon: FaCar, roles: OPS,
    items: [
      { label: 'Data Kendaraan', desc: 'Kendaraan milik pelanggan', icon: FaCar, to: '/vehicles' },
      { label: 'Master Kendaraan', desc: 'Merk, model & tipe', icon: FaCarSide, to: '/vehicles/master' },
    ],
  },
  {
    label: 'Layanan', icon: FaWrench, roles: ['ADMIN', 'STAFF', 'TEKNISI'],
    items: [
      { label: 'Data Layanan', desc: 'Transaksi service kendaraan', icon: FaWrench, to: '/services', roles: ['ADMIN', 'STAFF', 'TEKNISI'] },
      { label: 'Jenis Layanan', desc: 'Daftar jasa service', icon: FaClipboardList, to: '/service-types', roles: OPS },
    ],
  },
  { label: 'Penjualan', icon: FaShoppingCart, to: '/sales', roles: OPS },
  { label: 'Teknisi', icon: FaHardHat, to: '/technicians', roles: OPS },
  {
    label: 'Laporan', icon: FaChartLine, roles: OPS,
    items: [
      { label: 'Laporan Layanan', desc: 'Rekap service', icon: FaTools, to: '/reports/service' },
      { label: 'Laporan Penjualan', desc: 'Rekap penjualan sparepart', icon: FaShoppingCart, to: '/reports/sales' },
      { label: 'Laporan Stok', desc: 'Nilai & status stok', icon: FaBoxes, to: '/reports/stock' },
    ],
  },
  { label: 'Users', icon: FaKey, to: '/users', roles: ['ADMIN'] },
  {
    label: 'Admin', icon: FaUserCog, roles: ['ADMIN'],
    items: [
      { label: 'Pengaturan Aplikasi', desc: 'Konfigurasi sistem', icon: FaCog, to: '/admin/settings' },
      { label: 'Diskon', desc: 'Promo & kupon', icon: FaPercent, to: '/admin/discounts' },
    ],
  },
];

function matches(pathname, to) {
  if (to === '/') return pathname === '/';
  return pathname === to || pathname.startsWith(`${to}/`);
}

function activeItemTo(items, pathname) {
  return items
    .filter((it) => matches(pathname, it.to))
    .sort((a, b) => b.to.length - a.to.length)[0]?.to;
}

function buildMenus(role) {
  return MENUS
    .filter((m) => m.roles.includes(role))
    .map((m) => {
      if (!m.items) return m;
      const items = m.items.filter((it) => (it.roles || m.roles).includes(role));
      if (items.length === 0) return null;
      if (items.length === 1) return { label: m.label, icon: m.icon, to: items[0].to };
      return { ...m, items };
    })
    .filter(Boolean);
}

const ROLE_LABEL = { ADMIN: 'Administrator', STAFF: 'Staff', TEKNISI: 'Teknisi' };

// Ukuran seragam untuk semua dropdown
const DROPDOWN_WIDTH = 'min-w-[280px]';

// Gaya tautan menu — teks naik sedikit, tetap rapat
const linkBase = 'relative flex items-center gap-1.5 rounded-md px-2.5 py-1.5 text-[13px] font-medium whitespace-nowrap transition-all duration-150 focus:outline-none focus-visible:ring-2 focus-visible:ring-sky-400/60 focus-visible:ring-offset-1 focus-visible:ring-offset-ink-900';
const linkActive = 'bg-white/[0.08] text-white';
const linkIdle = 'text-slate-300/90 hover:bg-white/[0.05] hover:text-white';

// Garis pembatas vertikal tipis antar elemen navbar
function Divider({ className = '' }) {
  return (
    <span
      aria-hidden
      className={`mx-0.5 h-6 w-px shrink-0 bg-white/10 ${className}`}
    />
  );
}

export default function Navbar() {
  const { user, logout } = useAuth();
  const { name: brandName, logo } = useSettingsContext();
  const navigate = useNavigate();
  const { pathname } = useLocation();
  const [openMenu, setOpenMenu] = useState(null);
  const [mobileOpen, setMobileOpen] = useState(false);
  const [mobileGroup, setMobileGroup] = useState(null);
  const [scrolled, setScrolled] = useState(false);
  const navRef = useRef(null);

  useEffect(() => { setOpenMenu(null); setMobileOpen(false); setMobileGroup(null); }, [pathname]);

  useEffect(() => {
    function onDown(e) { if (navRef.current && !navRef.current.contains(e.target)) setOpenMenu(null); }
    function onKey(e) { if (e.key === 'Escape') { setOpenMenu(null); setMobileOpen(false); } }
    document.addEventListener('mousedown', onDown);
    document.addEventListener('keydown', onKey);
    return () => { document.removeEventListener('mousedown', onDown); document.removeEventListener('keydown', onKey); };
  }, []);

  useEffect(() => {
    const onScroll = () => setScrolled(window.scrollY > 4);
    onScroll();
    window.addEventListener('scroll', onScroll, { passive: true });
    return () => window.removeEventListener('scroll', onScroll);
  }, []);

  if (!user) return null;
  const menus = buildMenus(user.role);
  const initial = (user.username || '?').charAt(0).toUpperCase();
  const roleLabel = ROLE_LABEL[user.role] || user.role;

  function handleLogout() { logout(); navigate('/login'); }

  return (
    <header
      ref={navRef}
      className={`no-print sticky top-0 z-40 text-white backdrop-blur-xl transition-all duration-300
        bg-gradient-to-r from-ink-950/95 via-ink-900/95 to-ink-900/95
        ${scrolled ? 'shadow-2xl shadow-black/30 border-b border-white/[0.06]' : 'shadow-md shadow-black/10 border-b border-white/[0.03]'}`}
    >
      <div className="mx-auto max-w-[1400px] px-4 2xl:max-w-[1680px]">
        <div className="flex h-[72px] items-center justify-between gap-2">

          {/* Logo & nama bengkel (dari Admin > Pengaturan Aplikasi) */}
          <Link to="/" className="group flex min-w-0 shrink-0 items-center gap-2.5" title={brandName}>
            {logo ? (
              <span className="flex h-10 items-center rounded-xl bg-white px-1.5 shadow-lg shadow-black/20 ring-1 ring-white/20 transition-transform duration-300 group-hover:scale-105">
                <img src={logo} alt={brandName} className="h-8 w-auto max-w-[120px] object-contain" />
              </span>
            ) : (
              <span className="relative flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-brand-500 to-sky-500 text-[17px] text-white shadow-lg shadow-brand-500/40 transition-transform duration-300 group-hover:-rotate-6 group-hover:scale-105">
                <FaTools aria-hidden />
                <span aria-hidden className="absolute inset-0 rounded-xl ring-1 ring-inset ring-white/20" />
              </span>
            )}
            <span className="hidden min-w-0 leading-tight sm:block">
              <span className="block max-w-[200px] truncate text-[15.5px] font-extrabold uppercase tracking-tight text-white">
                {brandName}
              </span>
            </span>
          </Link>

          {/* Garis pembatas antara logo dan navigasi */}
          <Divider className="hidden min-[1340px]:block" />

          {/* Navigasi desktop — tetap rapat */}
          <nav className={`hidden flex-1 items-center gap-0 min-[1340px]:flex ${user.role === 'TEKNISI' ? 'justify-start' : 'justify-center'}`} aria-label="Menu utama">
            {menus.map((m, idx) => {
              if (!m.items) {
                const active = matches(pathname, m.to);
                return (
                  <React.Fragment key={m.label}>
                    {idx > 0 && <Divider />}
                    <Link
                      to={m.to}
                      className={`${linkBase} ${active ? linkActive : linkIdle}`}
                      aria-current={active ? 'page' : undefined}
                    >
                      <m.icon className={`text-[13px] transition-opacity ${active ? 'opacity-100 text-sky-300' : 'opacity-70'}`} aria-hidden />
                      {m.label}
                      {active && (
                        <span aria-hidden className="absolute inset-x-2 -bottom-[12px] h-[2px] rounded-full bg-gradient-to-r from-brand-400 to-sky-400" />
                      )}
                    </Link>
                  </React.Fragment>
                );
              }
              const activeTo = activeItemTo(m.items, pathname);
              const isOpen = openMenu === m.label;
              return (
                <React.Fragment key={m.label}>
                  {idx > 0 && <Divider />}
                  <div className="relative" onMouseEnter={() => setOpenMenu(m.label)} onMouseLeave={() => setOpenMenu(null)}>
                    <button
                      type="button"
                      aria-haspopup="true"
                      aria-expanded={isOpen}
                      onClick={() => setOpenMenu(isOpen ? null : m.label)}
                      className={`${linkBase} ${activeTo || isOpen ? linkActive : linkIdle}`}
                    >
                      <m.icon className={`text-[13px] transition-opacity ${activeTo ? 'opacity-100 text-sky-300' : 'opacity-70'}`} aria-hidden />
                      {m.label}
                      <FaChevronDown className={`text-[9px] opacity-60 transition-transform duration-200 ${isOpen ? 'rotate-180' : ''}`} aria-hidden />
                      {activeTo && !isOpen && (
                        <span aria-hidden className="absolute inset-x-2 -bottom-[12px] h-[2px] rounded-full bg-gradient-to-r from-brand-400 to-sky-400" />
                      )}
                    </button>

                    {isOpen && (
                      <div className={`absolute left-0 top-full pt-3 ${DROPDOWN_WIDTH}`}>
                        <div className="animate-drop-in overflow-hidden rounded-xl bg-white shadow-2xl ring-1 ring-black/5">
                          {/* header kecil dropdown */}
                          <div className="border-b border-slate-100 bg-slate-50/70 px-4 py-2">
                            <span className="text-[10.5px] font-bold uppercase tracking-wider text-slate-500">{m.label}</span>
                          </div>
                          <div className="p-1.5">
                            {m.items.map((it, i) => {
                              const on = activeTo === it.to;
                              return (
                                <React.Fragment key={it.to}>
                                  {i > 0 && <div className="mx-2 my-0.5 h-px bg-slate-100" />}
                                  <Link
                                    to={it.to}
                                    className={`group flex items-center gap-2.5 rounded-lg px-2.5 py-2 transition-colors ${on ? 'bg-brand-50' : 'hover:bg-slate-50'}`}
                                  >
                                    <span className={`flex h-8 w-8 shrink-0 items-center justify-center rounded-lg text-[13px] transition-all ${on ? 'bg-brand-500 text-white shadow-md shadow-brand-500/30' : 'bg-slate-100 text-slate-500 group-hover:bg-brand-500 group-hover:text-white group-hover:shadow-md group-hover:shadow-brand-500/30'}`}>
                                      <it.icon aria-hidden />
                                    </span>
                                    <span className="leading-tight">
                                      <span className={`block text-[13.5px] font-semibold ${on ? 'text-brand-600' : 'text-slate-800'}`}>{it.label}</span>
                                      <span className="block text-[12px] text-slate-500">{it.desc}</span>
                                    </span>
                                  </Link>
                                </React.Fragment>
                              );
                            })}
                          </div>
                        </div>
                      </div>
                    )}
                  </div>
                </React.Fragment>
              );
            })}
          </nav>

          {/* Garis pembatas antara navigasi dan menu pengguna */}
          <Divider className="hidden min-[1340px]:block" />

          {/* Menu pengguna (desktop) */}
          <div className="relative hidden shrink-0 min-[1340px]:block">
            <button
              type="button"
              aria-haspopup="true"
              aria-expanded={openMenu === 'user'}
              onClick={() => setOpenMenu(openMenu === 'user' ? null : 'user')}
              className="flex items-center gap-2 rounded-full border border-white/10 bg-white/[0.06] py-1 pl-1 pr-2.5 transition-all hover:bg-white/[0.12] hover:border-white/20 focus:outline-none focus-visible:ring-2 focus-visible:ring-sky-400"
            >
              <span className="relative flex h-8 w-8 items-center justify-center rounded-full bg-gradient-to-br from-brand-500 to-sky-500 text-[12.5px] font-bold shadow-md shadow-brand-500/30">
                {initial}
                <span aria-hidden className="absolute -bottom-0.5 -right-0.5 h-2.5 w-2.5 rounded-full border-2 border-ink-900 bg-emerald-400" />
              </span>
              <span className="hidden text-left leading-tight min-[1700px]:block">
                <span className="block text-[13px] font-semibold text-white">{user.username}</span>
                <span className="block text-[10px] font-medium uppercase tracking-wider text-slate-400">{roleLabel}</span>
              </span>
              <FaChevronDown className={`text-[9px] opacity-60 transition-transform duration-200 ${openMenu === 'user' ? 'rotate-180' : ''}`} aria-hidden />
            </button>

            {openMenu === 'user' && (
              <div className="absolute right-0 top-full w-60 pt-3">
                <div className="animate-drop-in overflow-hidden rounded-xl bg-white text-slate-800 shadow-2xl ring-1 ring-black/5">
                  <div className="flex items-center gap-3 border-b border-slate-100 bg-gradient-to-br from-slate-50 to-white px-4 py-3">
                    <span className="flex h-10 w-10 items-center justify-center rounded-full bg-gradient-to-br from-brand-500 to-sky-500 text-[13px] font-bold text-white shadow-md shadow-brand-500/30">
                      {initial}
                    </span>
                    <span className="leading-tight">
                      <span className="block text-[13.5px] font-semibold text-slate-800">{user.username}</span>
                      <span className="mt-1 inline-block rounded-full bg-brand-50 px-2 py-0.5 text-[10.5px] font-semibold uppercase tracking-wider text-brand-600">
                        {roleLabel}
                      </span>
                    </span>
                  </div>
                  <div className="p-1.5">
                    <button
                      onClick={handleLogout}
                      className="flex w-full items-center gap-3 rounded-lg px-3 py-2 text-[13.5px] font-semibold text-red-600 transition-colors hover:bg-red-50"
                    >
                      <FaSignOutAlt aria-hidden /> Keluar
                    </button>
                  </div>
                </div>
              </div>
            )}
          </div>

          {/* Tombol hamburger (mobile & tablet) */}
          <button
            className="flex h-10 w-10 items-center justify-center rounded-lg text-lg text-white transition-colors hover:bg-white/10 min-[1340px]:hidden"
            onClick={() => setMobileOpen((o) => !o)}
            aria-label="Menu"
            aria-expanded={mobileOpen}
          >
            {mobileOpen ? <FaTimes aria-hidden /> : <FaBars aria-hidden />}
          </button>
        </div>
      </div>

      {/* Menu mobile: accordion */}
      {mobileOpen && (
        <div className="animate-slide-down max-h-[80vh] overflow-y-auto border-t border-white/10 bg-ink-900 min-[1340px]:hidden">
          <div className="mx-auto max-w-[1400px] space-y-0.5 px-4 py-3 2xl:max-w-[1680px]">
            {menus.map((m, idx) => {
              if (!m.items) {
                const active = matches(pathname, m.to);
                return (
                  <React.Fragment key={m.label}>
                    {idx > 0 && <div className="mx-1 h-px bg-white/[0.06]" />}
                    <Link
                      to={m.to}
                      className={`${linkBase} !py-2.5 !text-[14.5px] ${active ? 'bg-white/10 text-white' : 'text-slate-300 hover:bg-white/5'}`}
                    >
                      <m.icon className={`w-4 ${active ? 'text-sky-300' : 'opacity-80'}`} aria-hidden />
                      {m.label}
                    </Link>
                  </React.Fragment>
                );
              }
              const activeTo = activeItemTo(m.items, pathname);
              const isOpen = mobileGroup === m.label;
              return (
                <React.Fragment key={m.label}>
                  {idx > 0 && <div className="mx-1 h-px bg-white/[0.06]" />}
                  <div>
                    <button
                      type="button"
                      onClick={() => setMobileGroup(isOpen ? null : m.label)}
                      className={`${linkBase} w-full justify-between !py-2.5 !text-[14.5px] ${activeTo ? 'bg-white/10 text-white' : 'text-slate-300 hover:bg-white/5'}`}
                    >
                      <span className="flex items-center gap-2.5">
                        <m.icon className={`w-4 ${activeTo ? 'text-sky-300' : 'opacity-80'}`} aria-hidden />
                        {m.label}
                      </span>
                      <FaChevronDown className={`text-[10px] transition-transform duration-200 ${isOpen ? 'rotate-180' : ''}`} aria-hidden />
                    </button>
                    {isOpen && (
                      <div className="ml-5 mt-1 animate-slide-down space-y-0.5 border-l border-white/10 pl-3">
                        {m.items.map((it, i) => (
                          <React.Fragment key={it.to}>
                            {i > 0 && <div className="ml-3 h-px bg-white/[0.05]" />}
                            <Link
                              to={it.to}
                              className={`flex items-center gap-2.5 rounded-lg px-3 py-2 text-[14px] ${activeTo === it.to ? 'bg-brand-500 text-white shadow-md shadow-brand-500/30' : 'text-slate-300 hover:bg-white/5'}`}
                            >
                              <it.icon className="w-4 text-xs opacity-80" aria-hidden />
                              {it.label}
                            </Link>
                          </React.Fragment>
                        ))}
                      </div>
                    )}
                  </div>
                </React.Fragment>
              );
            })}

            <div className="mt-3 flex items-center justify-between gap-3 border-t border-white/10 pt-3.5">
              <div className="flex items-center gap-3">
                <span className="relative flex h-9 w-9 items-center justify-center rounded-full bg-gradient-to-br from-brand-500 to-sky-500 text-[12.5px] font-bold">
                  {initial}
                  <span aria-hidden className="absolute -bottom-0.5 -right-0.5 h-3 w-3 rounded-full border-2 border-ink-900 bg-emerald-400" />
                </span>
                <div className="leading-tight">
                  <p className="text-[13.5px] font-semibold text-white">{user.username}</p>
                  <p className="text-[10.5px] font-medium uppercase tracking-wider text-slate-400">{roleLabel}</p>
                </div>
              </div>
              <button
                onClick={handleLogout}
                className="inline-flex items-center gap-2 rounded-lg bg-white/10 px-3.5 py-2 text-[13px] font-semibold text-white transition-colors hover:bg-red-600"
              >
                <FaSignOutAlt aria-hidden /> Keluar
              </button>
            </div>
          </div>
        </div>
      )}
    </header>
  );
}