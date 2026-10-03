import React from 'react';
import { FaCheckCircle, FaExclamationCircle, FaExclamationTriangle } from 'react-icons/fa';

const STYLES = {
  error: { box: 'bg-red-50 text-red-800 border-red-200', Icon: FaExclamationCircle },
  success: { box: 'bg-emerald-50 text-emerald-800 border-emerald-200', Icon: FaCheckCircle },
  warning: { box: 'bg-amber-50 text-amber-800 border-amber-200', Icon: FaExclamationTriangle },
};

export default function Alert({ type = 'error', message }) {
  if (!message) return null;
  const { box, Icon } = STYLES[type] || STYLES.error;
  return (
    <div role="alert" className={`mb-4 flex items-start gap-2.5 rounded-xl border px-4 py-3 text-sm font-medium animate-slide-down ${box}`}>
      <Icon className="mt-0.5 shrink-0" aria-hidden />
      <span>{message}</span>
    </div>
  );
}
