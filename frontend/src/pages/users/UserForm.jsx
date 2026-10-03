import React, { useEffect, useState } from 'react';
import { useNavigate, useParams } from 'react-router-dom';
import api from '../../api/axios';
import Spinner from '../../components/ui/Spinner';
import FormPage from '../../components/ui/FormPage';
import useForm, { errMsg } from '../../hooks/useForm';

import { FaKey } from 'react-icons/fa';
const empty = { username: '', email: '', password: '', role: 'STAFF', technicianId: '' };

// Halaman Tambah (/users/new) dan Edit (/users/:id/edit) pengguna
export default function UserForm() {
  const { id } = useParams();
  const editing = Boolean(id);
  const navigate = useNavigate();
  const { form, bind, load, reset } = useForm(empty);
  const [technicians, setTechnicians] = useState([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    const reqs = [api.get('/technicians')];
    if (editing) reqs.push(api.get('/users'));
    Promise.all(reqs)
      .then(([t, u]) => {
        setTechnicians(t.data);
        if (u) {
          const d = u.data.find((x) => String(x.id) === String(id));
          if (!d) return setError('Pengguna tidak ditemukan.');
          load({ username: d.username, email: d.email, password: '', role: d.role, technicianId: d.technicianId || '' });
        }
      })
      .catch(() => setError('Gagal memuat data.'))
      .finally(() => setLoading(false));
  }, [id, editing, load]);

  async function submit(e) {
    e.preventDefault(); setSaving(true); setError('');
    try {
      const payload = { ...form, technicianId: form.role === 'TEKNISI' && form.technicianId ? Number(form.technicianId) : null };
      if (editing) {
        if (!payload.password) delete payload.password;
        await api.put(`/users/${id}`, payload);
      } else {
        await api.post('/users', payload);
      }
      navigate('/users');
    } catch (err) { setError(errMsg(err, 'Gagal menyimpan pengguna.')); }
    finally { setSaving(false); }
  }

  if (loading) return <Spinner />;

  return (
    <FormPage
      icon={FaKey}
      title={editing ? 'Edit Pengguna' : 'Tambah Pengguna'}
      subtitle={editing ? 'Ubah data pengguna' : 'Tambah pengguna baru'}
      cardTitle={editing ? 'Form Edit Pengguna' : 'Form Tambah Pengguna'}
      backTo="/users"
      error={error}
      saving={saving}
      onSubmit={submit}
      onReset={reset}
      hint={(
        <>
          <p>Isi form untuk {editing ? 'mengubah' : 'menambahkan'} data pengguna. Field bertanda * wajib diisi.</p>
          <ul className="list-disc pl-5 space-y-1">
            <li><b>Username:</b> nama untuk login.</li>
            <li><b>Role:</b> Admin, Staff, atau Teknisi. Role Teknisi ditautkan ke data teknisi.</li>
            <li><b>Password:</b> minimal 8 karakter{editing ? '; kosongkan bila tidak diubah' : ''}.</li>
          </ul>
        </>
      )}
    >
      <div className="grid sm:grid-cols-2 gap-4">
        <div><label className="label">Username *</label><input className="input" required value={form.username} onChange={bind('username')} /></div>
        <div><label className="label">Email *</label><input type="email" className="input" required value={form.email} onChange={bind('email')} /></div>
        <div>
          <label className="label">Role *</label>
          <select className="input" value={form.role} onChange={bind('role')}>
            <option value="ADMIN">Admin</option>
            <option value="STAFF">Staff</option>
            <option value="TEKNISI">Teknisi</option>
          </select>
        </div>
        {form.role === 'TEKNISI' && (
          <div>
            <label className="label">Tautkan ke Data Teknisi</label>
            <select className="input" value={form.technicianId} onChange={bind('technicianId')}>
              <option value="">-- Pilih Teknisi --</option>
              {technicians.map((t) => <option key={t.id} value={t.id}>{t.name}</option>)}
            </select>
          </div>
        )}
        <div className="sm:col-span-2">
          <label className="label">{editing ? 'Password Baru (kosongkan jika tidak diubah)' : 'Password * (min. 8 karakter)'}</label>
          <input type="password" className="input" required={!editing} minLength={8} value={form.password} onChange={bind('password')} />
        </div>
      </div>
    </FormPage>
  );
}