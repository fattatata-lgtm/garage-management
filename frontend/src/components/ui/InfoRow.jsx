import React from 'react';

// Baris "label : nilai" untuk kartu informasi. Bungkus dengan <dl className="info-list">.
export default function InfoRow({ label, children }) {
  return (
    <div className="info-row">
      <dt>{label}</dt>
      <dd>{children}</dd>
    </div>
  );
}
