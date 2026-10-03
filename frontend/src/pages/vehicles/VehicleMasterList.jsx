import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import api from '../../api/axios';
import Spinner from '../../components/ui/Spinner';
import EmptyState from '../../components/ui/EmptyState';
import PageHeader from '../../components/ui/PageHeader';
import ListCard from '../../components/ui/ListCard';
import { FaCarSide, FaPlus, FaCalendarDay, FaCar, FaCircleNotch, FaCog, FaHashtag, FaTag, FaTrademark } from 'react-icons/fa';
import { DeleteAction, EditAction, RowActions } from '../../components/ui/RowActions';

export default function VehicleMasterList() {
  const [models, setModels] = useState([]);
  const [loading, setLoading] = useState(true);

  function load() {
    setLoading(true);
    api.get('/vehicle-models').then(({ data }) => setModels(data)).finally(() => setLoading(false));
  }
  useEffect(() => { load(); }, []);

  async function handleDelete(m) {
    if (!confirm(`Hapus data master ${m.brand} ${m.model}?`)) return;
    try { await api.delete(`/vehicle-models/${m.id}`); load(); }
    catch (err) { alert(err?.response?.data?.message || 'Gagal menghapus.'); }
  }

  return (
    <div className="space-y-4">
      <PageHeader icon={FaCarSide} title="Data Master Kendaraan" subtitle="Kelola jenis / model kendaraan">
        <Link to="/vehicles/master/new" className="btn-primary"><FaPlus aria-hidden /> Tambah Master Kendaraan</Link>
      </PageHeader>

      <ListCard title="Daftar Master Kendaraan">
        {loading ? <Spinner /> : models.length === 0 ? <EmptyState /> : (
          <table className="table-base">
            <thead><tr><th className="col-no"><FaHashtag className="mr-1 inline text-[10px]" aria-hidden /> No</th><th><FaTrademark className="mr-1 inline text-[10px]" aria-hidden /> Merk</th><th><FaCar className="mr-1 inline text-[10px]" aria-hidden /> Model</th><th><FaCalendarDay className="mr-1 inline text-[10px]" aria-hidden /> Tahun</th><th><FaTag className="mr-1 inline text-[10px]" aria-hidden /> Tipe</th><th><FaCircleNotch className="mr-1 inline text-[10px]" aria-hidden /> Jumlah Roda</th><th className="col-actions"><FaCog className="mr-1 inline text-[10px]" aria-hidden /> Aksi</th></tr></thead>
            <tbody>
              {models.map((m, rowNo) => (
                <tr key={m.id}><td className="col-no">{rowNo + 1}</td>
                  <td>{m.brand}</td><td>{m.model}</td><td>{m.year}</td><td>{m.type}</td><td>{m.wheels}</td>
                  <td className="col-actions"><RowActions><EditAction to={`/vehicles/master/${m.id}/edit`} />
                    <DeleteAction onClick={() => handleDelete(m)} /></RowActions></td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </ListCard>
    </div>
  );
}
