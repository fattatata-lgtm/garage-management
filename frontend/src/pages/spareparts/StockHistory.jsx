import React, { useEffect, useState } from 'react';
import { Link } from 'react-router-dom';
import api from '../../api/axios';
import Spinner from '../../components/ui/Spinner';
import EmptyState from '../../components/ui/EmptyState';
import PageHeader from '../../components/ui/PageHeader';
import ListCard from '../../components/ui/ListCard';
import { FaArrowDown, FaArrowUp, FaHistory, FaBarcode, FaCalendarAlt, FaCogs, FaExchangeAlt, FaHashtag, FaRandom, FaSortNumericUp, FaStickyNote } from 'react-icons/fa';

export default function StockHistory() {
  const [history, setHistory] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    api.get('/spareparts/history/all').then(({ data }) => setHistory(data)).finally(() => setLoading(false));
  }, []);

  return (
    <div className="space-y-4">
      <PageHeader icon={FaHistory} title="Riwayat Stok Sparepart" subtitle="Daftar pergerakan stok masuk dan keluar">
        <Link to="/spareparts/stock-history/in" className="btn-success"><FaArrowDown aria-hidden /> Stok Masuk</Link>
        <Link to="/spareparts/stock-history/out" className="btn-danger"><FaArrowUp aria-hidden /> Stok Keluar</Link>
      </PageHeader>

      <ListCard title="Riwayat Pergerakan Stok">
        {loading ? <Spinner /> : history.length === 0 ? <EmptyState /> : (
          <table className="table-base">
            <thead><tr><th className="col-no"><FaHashtag className="mr-1 inline text-[10px]" aria-hidden /> No</th><th><FaCalendarAlt className="mr-1 inline text-[10px]" aria-hidden /> Tanggal</th><th><FaBarcode className="mr-1 inline text-[10px]" aria-hidden /> Kode</th><th><FaCogs className="mr-1 inline text-[10px]" aria-hidden /> Sparepart</th><th><FaExchangeAlt className="mr-1 inline text-[10px]" aria-hidden /> Arah</th><th><FaRandom className="mr-1 inline text-[10px]" aria-hidden /> Sumber</th><th className="num"><FaSortNumericUp className="mr-1 inline text-[10px]" aria-hidden /> Jumlah</th><th><FaStickyNote className="mr-1 inline text-[10px]" aria-hidden /> Keterangan</th></tr></thead>
            <tbody>
              {history.map((h, rowNo) => (
                <tr key={h.id}><td className="col-no">{rowNo + 1}</td>
                  <td>{new Date(h.createdAt).toLocaleString('id-ID')}</td>
                  <td>{h.sparepart.code}</td>
                  <td>{h.sparepart.name}</td>
                  <td><span className={`badge ring-1 ring-inset ${h.direction === 'MASUK' ? 'bg-emerald-50 text-emerald-700 ring-emerald-200' : 'bg-red-50 text-red-700 ring-red-200'}`}>{h.direction === 'MASUK' ? <FaArrowDown aria-hidden /> : <FaArrowUp aria-hidden />}{h.direction}</span></td>
                  <td>{h.source}</td>
                  <td className="num">{h.quantity}</td>
                  <td>{h.note || '-'}</td>
                </tr>
              ))}
            </tbody>
          </table>
        )}
      </ListCard>
    </div>
  );
}