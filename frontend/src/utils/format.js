// Helper format & hitung untuk transaksi service

export function formatRp(n) { return `Rp${Number(n || 0).toLocaleString('id-ID')}`; }

export function fmtDate(d) { return d ? new Date(d).toLocaleDateString('id-ID') : '-'; }

export function fmtDateTime(d) {
  if (!d) return '-';
  return new Date(d).toLocaleString('id-ID', { day: '2-digit', month: 'short', year: 'numeric', hour: '2-digit', minute: '2-digit' });
}

// Total biaya jasa & sparepart dari data transaksi tersimpan
export function jasaTotalOf(svc) { return (svc?.details || []).reduce((t, d) => t + (Number(d.cost) || 0), 0); }
export function partsTotalOf(svc) { return (svc?.spareparts || []).reduce((t, sp) => t + (Number(sp.price) || 0) * (Number(sp.qty) || 0), 0); }
