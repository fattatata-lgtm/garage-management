import React from 'react';
import { Link } from 'react-router-dom';
import { FaArrowLeft, FaInfoCircle, FaSave, FaUndo, FaCircleNotch, FaEdit } from 'react-icons/fa';
import Alert from './Alert';
import CardHeader from './CardHeader';

// Layout halaman form tambah/edit (pengganti popup):
// judul + tombol Kembali, kartu form berheader gelap, tombol Reset/Simpan,
// dan (opsional) kartu "Petunjuk" di sisi kanan.
export default function FormPage({
  icon: Icon, title, subtitle, backTo, cardTitle, hint, error, saving,
  onSubmit, onReset, submitLabel = 'Simpan', children,
}) {
  return (
    <div className="space-y-4 animate-fade-up">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div className="flex items-center gap-3.5">
          {Icon && (
            <span className="icon-tile h-12 w-12 text-[22px]">
              <Icon aria-hidden />
            </span>
          )}
          <div>
            <h1 className="text-2xl font-extrabold leading-tight tracking-tight text-slate-900">{title}</h1>
            {subtitle && <p className="mt-0.5 text-sm text-slate-500">{subtitle}</p>}
          </div>
        </div>
        <Link to={backTo} className="btn-secondary"><FaArrowLeft /> Kembali</Link>
      </div>

      <div className={hint ? 'grid items-start gap-4 lg:grid-cols-3' : ''}>
        <form onSubmit={onSubmit} className={`card overflow-hidden ${hint ? 'lg:col-span-2' : ''}`}>
          <CardHeader icon={FaEdit}>{cardTitle || title}</CardHeader>
          <div className="space-y-4 p-5">
            <Alert message={error} />
            {children}
          </div>
          <div className="flex justify-end gap-2 border-t border-slate-100 bg-slate-50/80 px-5 py-4">
            {onReset && <button type="button" className="btn-secondary" onClick={onReset}><FaUndo /> Reset</button>}
            <button type="submit" disabled={saving} className="btn-primary">
              {saving ? <FaCircleNotch className="animate-spin" /> : <FaSave />}
              {saving ? 'Menyimpan...' : submitLabel}
            </button>
          </div>
        </form>

        {hint && (
          <aside className="card overflow-hidden">
            <CardHeader icon={FaInfoCircle}>Petunjuk</CardHeader>
            <div className="space-y-2 p-5 text-sm text-slate-600">{hint}</div>
          </aside>
        )}
      </div>
    </div>
  );
}
