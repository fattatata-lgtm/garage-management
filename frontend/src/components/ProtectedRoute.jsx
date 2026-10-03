import React from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

export default function ProtectedRoute({ children, roles }) {
  const { user } = useAuth();

  if (!user) return <Navigate to="/login" replace />;
  if (roles && !roles.includes(user.role)) {
    return (
      <div className="max-w-xl mx-auto mt-20 card p-8 text-center">
        <h2 className="text-lg font-semibold text-slate-800 mb-2">Akses Ditolak</h2>
        <p className="text-slate-500 text-sm">Anda tidak memiliki hak akses untuk membuka halaman ini.</p>
      </div>
    );
  }
  return children;
}
