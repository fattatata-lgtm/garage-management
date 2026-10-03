import React from 'react';
import { FaCheck, FaClipboardCheck, FaWrench, FaFileInvoiceDollar, FaFlagCheckered } from 'react-icons/fa';

// 4 tahap transaksi service
export const SERVICE_STEPS = [
  { key: 'DITERIMA', no: 1, label: 'Diterima', desc: 'Data awal service', icon: FaClipboardCheck },
  { key: 'DIKERJAKAN', no: 2, label: 'Dikerjakan', desc: 'Jasa & sparepart', icon: FaWrench },
  { key: 'MENUNGGU_PEMBAYARAN', no: 3, label: 'Tagihan', desc: 'Biaya & pembayaran', icon: FaFileInvoiceDollar },
  { key: 'SELESAI', no: 4, label: 'Selesai', desc: 'Lunas', icon: FaFlagCheckered },
];
const STEP_INDEX = { DITERIMA: 0, DIKERJAKAN: 1, MENUNGGU_PEMBAYARAN: 2, SELESAI: 3 };

// Stepper horizontal dengan garis penghubung antar tahap.
export default function ServiceStepper({ status = 'DITERIMA', hideNumber = false }) {
  const current = STEP_INDEX[status] ?? 0;
  const lunas = status === 'SELESAI';
  return (
    <ol className="card flex items-start px-3 py-5 sm:px-6">
      {SERVICE_STEPS.map((st, i) => {
        const done = i < current || (i === current && lunas);
        const active = i === current && !done;
        const Icon = st.icon;
        return (
          <li key={st.key} className="relative flex flex-1 flex-col items-center text-center">
            {i > 0 && (
              <span aria-hidden className={`absolute -left-1/2 top-5 h-1 w-full -translate-y-1/2 rounded-full transition-colors ${i <= current ? 'bg-emerald-500' : 'bg-slate-200'}`} />
            )}
            <span className={`relative z-10 flex h-10 w-10 items-center justify-center rounded-full text-sm transition-all ${
              done ? 'bg-emerald-600 text-white shadow-md shadow-emerald-600/30'
                : active ? 'bg-brand-600 text-white shadow-md shadow-brand-600/30 ring-4 ring-brand-100'
                  : 'bg-slate-100 text-slate-400 ring-1 ring-inset ring-slate-200'
            }`}>
              {done ? <FaCheck aria-hidden /> : <Icon aria-hidden />}
            </span>
            {!hideNumber && <span className={`mt-2 text-[10px] font-bold uppercase tracking-wider ${done ? 'text-emerald-600' : active ? 'text-brand-600' : 'text-slate-400'}`}>Tahap {st.no}</span>}
            <span className={`${hideNumber ? 'mt-2' : ''} text-sm font-bold leading-tight ${done || active ? 'text-slate-800' : 'text-slate-400'}`}>{st.label}</span>
            <span className="mt-0.5 hidden text-xs text-slate-500 sm:block">{st.desc}</span>
          </li>
        );
      })}
    </ol>
  );
}
