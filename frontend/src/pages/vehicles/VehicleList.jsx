import React, { useEffect, useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import api from '../../api/axios';
import Spinner from '../../components/ui/Spinner';
import EmptyState from '../../components/ui/EmptyState';
import PageHeader from '../../components/ui/PageHeader';
import ListCard from '../../components/ui/ListCard';
import usePagination from '../../hooks/usePagination';
import Pagination from '../../components/ui/Pagination';
import { FaSearch, FaCar, FaPlus, FaCalendarDay, FaCircleNotch, FaCog, FaHashtag, FaIdCard, FaPalette, FaTimes, FaTrademark, FaUser } from 'react-icons/fa';
import { DeleteAction, EditAction, RowActions, ViewAction } from '../../components/ui/RowActions';
import SearchInput from '../../components/ui/SearchInput';
import FilterField from '../../components/ui/FilterField';

// Data Kendaraan (kendaraan milik pelanggan). Master jenis kendaraan ada di /vehicles/master.
export default function VehicleList() {
  const [vehicles, setVehicles] = useState([]);
  const [loading, setLoading] = useState(true);
  const [q, setQ] = useState('');
  const [brand, setBrand] = useState('');
  const [model, setModel] = useState('');
  const [wheels, setWheels] = useState('');
  const [masters, setMasters] = useState([]); // sumber pilihan filter merk / model / roda

  useEffect(() => { api.get('/vehicle-models').then(({ data }) => setMasters(data)).catch(() => {}); }, []);

  const brandOptions = useMemo(() => [...new Set(masters.map((m) => m.brand))].sort((a, b) => a.localeCompare(b)), [masters]);
  const modelOptions = useMemo(
    () => [...new Set(masters.filter((m) => !brand || m.brand === brand).map((m) => m.model))].sort((a, b) => a.localeCompare(b)),
    [masters, brand],
  );
  const wheelOptions = useMemo(() => [...new Set(masters.map((m) => m.wheels))].sort((a, b) => a - b), [masters]);
  const filterActive = Boolean(brand || model || wheels);

  function load() {
    setLoading(true);
    const params = new URLSearchParams();
    if (q) params.set('q', q);
    if (brand) params.set('brand', brand);
    if (model) params.set('model', model);
    if (wheels) params.set('wheels', wheels);
    const qs = params.toString();
    api.get(`/vehicles${qs ? `?${qs}` : ''}`)
      .then(({ data }) => setVehicles(data))
      .finally(() => setLoading(false));
  }

  const pg = usePagination(vehicles, 10, `${q}|${brand}|${model}|${wheels}`);
  useEffect(() => {
    const t = setTimeout(load, q ? 350 : 0);
    return () => clearTimeout(t);
  }, [q, brand, model, wheels]);

  function changeBrand(v) {
    setBrand(v);
    // Model yang dipilih dikosongkan bila bukan milik merk baru
    if (model && v && !masters.some((m) => m.brand === v && m.model === model)) setModel('');
  }

  async function handleDelete(v) {
    if (!confirm(`Hapus kendaraan ${v.plateNumber}?`)) return;
    try { await api.delete(`/vehicles/${v.id}`); load(); }
    catch (err) { alert(err?.response?.data?.message || 'Gagal menghapus.'); }
  }

  return (
    <div className="space-y-4">
      <PageHeader icon={FaCar} title="Data Kendaraan" subtitle="Kelola data kendaraan pelanggan">
        <Link to="/vehicles/new" className="btn-primary"><FaPlus aria-hidden /> Tambah Kendaraan</Link>
      </PageHeader>

      <div className="filter-bar">
        <FilterField label="Pencarian" icon={FaSearch} className="w-full sm:w-80">
          <SearchInput placeholder="Cari plat / VIN / nama pemilik..." value={q} onChange={setQ} />
        </FilterField>
        <FilterField label="Merk" icon={FaTrademark} className="w-full sm:w-44">
          <select className="input" value={brand} onChange={(e) => changeBrand(e.target.value)}>
            <option value="">Semua Merk</option>
            {brandOptions.map((b) => <option key={b} value={b}>{b}</option>)}
          </select>
        </FilterField>
        <FilterField label="Model" icon={FaCar} className="w-full sm:w-48">
          <select className="input" value={model} onChange={(e) => setModel(e.target.value)}>
            <option value="">Semua Model</option>
            {modelOptions.map((m) => <option key={m} value={m}>{m}</option>)}
          </select>
        </FilterField>
        <FilterField label="Roda" icon={FaCircleNotch} className="w-full sm:w-36">
          <select className="input" value={wheels} onChange={(e) => setWheels(e.target.value)}>
            <option value="">Semua Roda</option>
            {wheelOptions.map((w) => <option key={w} value={w}>{w} roda</option>)}
          </select>
        </FilterField>
        {filterActive && (
          <button type="button" className="btn-muted h-10 !px-3.5 text-xs" title="Hapus filter"
            onClick={() => { setBrand(''); setModel(''); setWheels(''); }}>
            <FaTimes aria-hidden /> Reset
          </button>
        )}
      </div>

      <ListCard title="Daftar Kendaraan">
        {loading ? <Spinner /> : vehicles.length === 0 ? <EmptyState /> : (
          <table className="table-base">
            <thead><tr><th className="col-no"><FaHashtag className="mr-1 inline text-[10px]" aria-hidden /> No</th><th><FaUser className="mr-1 inline text-[10px]" aria-hidden /> Pemilik</th><th><FaCar className="mr-1 inline text-[10px]" aria-hidden /> Merk &amp; Model</th><th><FaCalendarDay className="mr-1 inline text-[10px]" aria-hidden /> Tahun</th><th><FaCircleNotch className="mr-1 inline text-[10px]" aria-hidden /> Roda</th><th><FaIdCard className="mr-1 inline text-[10px]" aria-hidden /> Plat Nomor</th><th><FaPalette className="mr-1 inline text-[10px]" aria-hidden /> Warna</th><th className="col-actions"><FaCog className="mr-1 inline text-[10px]" aria-hidden /> Aksi</th></tr></thead>
            <tbody>
              {pg.pageItems.map((v, rowNo) => (
                <tr key={v.id}><td className="col-no">{pg.start + rowNo + 1}</td>
                  <td>{v.customer.name}</td>
                  <td>{v.vehicleModel.brand} {v.vehicleModel.model}</td>
                  <td>{v.vehicleModel.year}</td>
                  <td>{v.vehicleModel.wheels}</td>
                  <td><Link to={`/vehicles/${v.id}`} className="cell-link">{v.plateNumber}</Link></td>
                  <td>{v.color || '-'}</td>
                  <td className="col-actions"><RowActions><ViewAction to={`/vehicles/${v.id}`} label="Lihat detail kendaraan" />
                    <EditAction to={`/vehicles/${v.id}/edit`} />
                    <DeleteAction onClick={() => handleDelete(v)} /></RowActions></td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
        <Pagination pg={pg} />
      </ListCard>
    </div>
  );
}
