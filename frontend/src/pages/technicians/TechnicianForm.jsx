import React, { useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import api from '../../api/axios';
import Spinner from '../../components/ui/Spinner';
import FormPage from '../../components/ui/FormPage';
import useForm, { errMsg } from '../../hooks/useForm';

import { FaHardHat } from 'react-icons/fa';
const empty = { name: '', skill: '', status: 'AKTIF' };

// Halaman Tambah (/technicians/new) dan Edit (/technicians/:id/edit) teknisi
export default function TechnicianForm() {
  const { id } = useParams();
  const editing = Boolean(id);
  const navigate = useNavigate();
  const { form, bind, load, reset } = useForm(empty);
  const [loading, setLoading] = useState(editing);
  const [error, setError] = useState('');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    if (!editing) return;
    api.get(`/technicians/${id}`)
      .then(({ data }) => load({ name: data.name, skill: data.skill || '', status: data.status }))
      .catch(() => setError('Data teknisi tidak ditemukan.'))
      .finally(() => setLoading(false));
  }, [id, editing, load]);

  async function submit(e) {
    e.preventDefault(); setSaving(true); setError('');
    try {
      if (editing) await api.put(`/technicians/${id}`, form);
      else await api.post('/technicians', form);
      navigate('/technicians');
    } catch (err) { setError(errMsg(err, 'Gagal menyimpan data teknisi.')); }
    finally { setSaving(false); }
  }

  if (loading) return <Spinner />;

  return (
    <FormPage
      icon={FaHardHat}
      title={editing ? 'Edit Teknisi' : 'Tambah Teknisi'}
      subtitle={editing ? 'Ubah data teknisi' : 'Tambah data teknisi baru'}
      cardTitle={editing ? 'Form Edit Teknisi' : 'Form Tambah Teknisi'}
      backTo="/technicians"
      error={error}
      saving={saving}
      onSubmit={submit}
      onReset={reset}
      hint={(
        <>
          <p>Isi form untuk {editing ? 'mengubah' : 'menambahkan'} data teknisi. Field bertanda * wajib diisi.</p>
          <ul className="list-disc pl-5 space-y-1">
            <li><b>Nama Teknisi:</b> nama lengkap teknisi.</li>
            <li><b>Keahlian:</b> opsional, mis. Mesin, Kelistrikan, Body.</li>
            <li><b>Status:</b> teknisi berstatus tidak aktif tidak muncul di pilihan saat membuat service.</li>
          </ul>
        </>
      )}
    >
      <div><label className="label">Nama Teknisi *</label><input className="input" required value={form.name} onChange={bind('name')} /></div>
      <div><label className="label">Keahlian</label><textarea className="input" rows={3} placeholder="Contoh: Mesin, Kelistrikan, Kaki-kaki, Body, Oli" value={form.skill} onChange={bind('skill')} /></div>
      <div>
        <label className="label">Status *</label>
        <select className="input" value={form.status} onChange={bind('status')}>
          <option value="AKTIF">Aktif</option>
          <option value="NONAKTIF">Nonaktif</option>
        </select>
      </div>
    </FormPage>
  );
}
