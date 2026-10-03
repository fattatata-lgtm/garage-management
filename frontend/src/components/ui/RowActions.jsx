import React from 'react';
import { Link } from 'react-router-dom';
import { FaEye, FaPen, FaTrash } from 'react-icons/fa';

// Tombol aksi di kolom "Aksi" tabel: semuanya berupa tombol ikon dengan ukuran & warna seragam.
const TONES = {
  view: 'icon-btn-view',
  edit: 'icon-btn-edit',
  delete: 'icon-btn-delete',
  neutral: 'icon-btn-neutral',
  success: 'icon-btn-success',
};

export function RowActions({ children }) {
  return <div className="row-actions">{children}</div>;
}

export function IconAction({ to, onClick, icon: Icon, label, tone = 'neutral' }) {
  const cls = `icon-btn ${TONES[tone] || TONES.neutral}`;
  if (to) {
    return <Link to={to} className={cls} title={label} aria-label={label}><Icon aria-hidden /></Link>;
  }
  return <button type="button" onClick={onClick} className={cls} title={label} aria-label={label}><Icon aria-hidden /></button>;
}

export const ViewAction = ({ to, label = 'Lihat detail' }) => <IconAction to={to} icon={FaEye} label={label} tone="view" />;
export const EditAction = ({ to, label = 'Edit' }) => <IconAction to={to} icon={FaPen} label={label} tone="edit" />;
export const DeleteAction = ({ onClick, label = 'Hapus' }) => <IconAction onClick={onClick} icon={FaTrash} label={label} tone="delete" />;
