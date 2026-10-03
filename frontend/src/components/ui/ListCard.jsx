import React from 'react';
import { FaListUl } from 'react-icons/fa';
import CardHeader from './CardHeader';

// Kartu daftar dengan header gelap + ikon, mis. "Daftar Pelanggan". Semua tabel dibungkus komponen ini.
export default function ListCard({ title, icon = FaListUl, tone, right, children }) {
  return (
    <div className="card overflow-hidden animate-fade-up">
      {title && <CardHeader icon={icon} tone={tone} right={right}>{title}</CardHeader>}
      <div className="overflow-x-auto">{children}</div>
    </div>
  );
}
