import React from 'react';

// Header kartu berwarna dengan ikon dalam chip. tone: dark (default) | blue | green | cyan | amber | red
export default function CardHeader({ icon: Icon, tone = 'dark', children, className = '', right }) {
  const toneClass = tone === 'dark' ? '' : `tone-${tone}`;
  return (
    <div className={`card-header ${toneClass} ${right ? 'justify-between' : ''} ${className}`}>
      <span className="flex items-center gap-2.5">
        {Icon && <span className="card-header-icon"><Icon aria-hidden /></span>}
        {children}
      </span>
      {right}
    </div>
  );
}
