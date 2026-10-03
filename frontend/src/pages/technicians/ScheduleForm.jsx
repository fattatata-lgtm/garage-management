import React, { useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import api from '../../api/axios';
import FormPage from '../../components/ui/FormPage';
import Spinner from '../../components/ui/Spinner';
import useForm, { errMsg } from '../../hooks/useForm';

import { FaCalendarAlt } from 'react-icons/fa';
// Halaman Tambah / Edit Jadwal Teknisi
// (/technicians/:id/schedules/new  dan  /technicians/:id/schedules/:scheduleId/edit)
export default function ScheduleForm() {
  const { id, scheduleId } = useParams();
  const isEdit = Boolean(scheduleId);
  const navigate = useNavigate();
  const { form, bind, reset, load } = useForm({ date: '', note: '' });
  const [error, setError] = useState('');
  const [saving, setSaving] = useState(false);
  const [loading, setLoading] = useState(isEdit);

  useEffect(() => {
    if (!isEdit) return;
    api.get(`/technicians/${id}`)
      .then(({ data }) => {
        const s = data.schedules.find((x) => x.id === Number(scheduleId));
        if (!s) { setError('Jadwal tidak ditemukan.'); return; }
        load({ date: String(s.date).slice(0, 10), note: s.note || '' });
      })
      .finally(() => setLoading(false));
  }, [id, scheduleId]);

  async function submit(e) {
    e.preventDefault(); setSaving(true); setError('');
    try {
      if (isEdit) await api.put(`/technicians/${id}/schedules/${scheduleId}`, form);
      else await api.post(`/technicians/${id}/schedules`, form);
      navigate(`/technicians/${id}`);
    } catch (err) { setError(errMsg(err, isEdit ? 'Gagal menyimpan jadwal.' : 'Gagal menambah jadwal.')); }
    finally { setSaving(false); }
  }

  if (loading) return <Spinner />;

  return (
    <FormPage
      icon={FaCalendarAlt}
      title={isEdit ? 'Edit Jadwal Teknisi' : 'Tambah Jadwal Teknisi'}
      subtitle={isEdit ? 'Ubah jadwal kerja teknisi ini' : 'Tambahkan jadwal kerja untuk teknisi ini'}
      cardTitle={isEdit ? 'Form Edit Jadwal' : 'Form Tambah Jadwal'}
      backTo={`/technicians/${id}`}
      error={error}
      saving={saving}
      onSubmit={submit}
      onReset={reset}
    >
      <div><label className="label">Tanggal *</label><input type="date" className="input" required value={form.date} onChange={bind('date')} /></div>
      <div><label className="label">Tugas / Catatan</label><textarea className="input" rows={3} value={form.note} onChange={bind('note')} /></div>
    </FormPage>
  );
}
