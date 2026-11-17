import React, { useEffect, useState } from 'react';
import { Link, useNavigate, useSearchParams } from 'react-router-dom';
import api from '../../api/axios';
import Spinner from '../../components/ui/Spinner';
import FormPage from '../../components/ui/FormPage';
import SparepartPicker from '../../components/ui/SparepartPicker';
import useForm, { errMsg } from '../../hooks/useForm';

import { FaBoxes } from 'react-icons/fa';
// Halaman Tambah Stok Masuk (/spareparts/stock-history/in) dan Stok Keluar (/spareparts/stock-history/out)
export default function StockMoveForm({ direction = 'MASUK' }) {
  const isIn = direction === 'MASUK';
  const [searchParams] = useSearchParams();
  const navigate = useNavigate();
  const { form, setForm, bind, reset } = useForm({ sparepartId: searchParams.get('sparepartId') || '', quantity: '', supplierId: '', note: '' });
  const [spareparts, setSpareparts] = useState([]);
  const [suppliers, setSuppliers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    Promise.all([api.get('/spareparts'), api.get('/suppliers')])
      .then(([sp, sup]) => { setSpareparts(sp.data); setSuppliers(sup.data); })
      .finally(() => setLoading(false));
  }, []);

  const selected = spareparts.find((s) => String(s.id) === String(form.sparepartId));

  // Barang masuk: otomatis pilih supplier bawaan sparepart (masih bisa diganti)
  function pickSparepart(sp) {
    setForm((f) => ({
      ...f,
      sparepartId: String(sp.id),
      supplierId: isIn && !f.supplierId && sp.supplierId ? String(sp.supplierId) : f.supplierId,
    }));
  }

  async function submit(e) {
    e.preventDefault(); setSaving(true); setError('');
    try {
      await api.post(`/spareparts/${form.sparepartId}/stock-move`, { direction, quantity: form.quantity, note: form.note, supplierId: isIn ? form.supplierId : undefined });
      navigate('/spareparts/stock-history');
    } catch (err) { setError(errMsg(err, 'Gagal mencatat pergerakan stok.')); }
    finally { setSaving(false); }
  }

  if (loading) return <Spinner />;

  return (
    <FormPage
      icon={FaBoxes}
      title={isIn ? 'Tambah Stok Masuk' : 'Tambah Stok Keluar'}
      subtitle={isIn ? 'Form untuk menambah stok sparepart' : 'Form untuk mengurangi stok sparepart'}
      cardTitle={isIn ? 'Form Stok Masuk' : 'Form Stok Keluar'}
      backTo="/spareparts/stock-history"
      error={error}
      saving={saving}
      onSubmit={submit}
      onReset={reset}
      hint={(
        <>
          <p>Gunakan halaman ini untuk mencatat {isIn ? 'barang yang masuk (mis. dari supplier)' : 'barang yang keluar di luar penjualan/service (mis. koreksi atau kerusakan)'}.</p>
          <p>Stok untuk penjualan dan service berkurang otomatis, tidak perlu dicatat di sini.</p>
          <p>
            <Link className="cell-link" to={`/spareparts/stock-history/${isIn ? 'out' : 'in'}${form.sparepartId ? `?sparepartId=${form.sparepartId}` : ''}`}>
              {isIn ? 'Pindah ke form Stok Keluar' : 'Pindah ke form Stok Masuk'} &rarr;
            </Link>
          </p>
        </>
      )}
    >
      <div>
        <label className="label">Sparepart *</label>
        <SparepartPicker options={spareparts} value={form.sparepartId} onPick={pickSparepart} />
        {selected && <p className="text-xs text-slate-400 mt-1">Stok tersedia saat ini: {selected.stock}</p>}
      </div>
      {isIn && (
        <div>
          <label className="label">Supplier</label>
          <select className="input" value={form.supplierId} onChange={bind('supplierId')}>
            <option value="">-- Tanpa Supplier --</option>
            {suppliers.map((s) => <option key={s.id} value={s.id}>{s.name}</option>)}
          </select>
        </div>
      )}
      <div><label className="label">Jumlah *</label><input type="number" min="1" className="input" required value={form.quantity} onChange={bind('quantity')} /></div>
      <div><label className="label">Keterangan</label><textarea className="input" rows={3} placeholder="Tambahkan keterangan (opsional)" value={form.note} onChange={bind('note')} /></div>
    </FormPage>
  );
}
