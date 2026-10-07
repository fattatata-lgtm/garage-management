import { useEffect, useState } from 'react';

// Pagination sisi client: potong array `items` per `perPage` data (default 10).
// `resetKey` (opsional): kembali ke halaman 1 saat nilainya berubah, mis. saat pencarian/filter diganti.
export default function usePagination(items = [], perPage = 10, resetKey = '') {
  const [page, setPage] = useState(1);
  const total = items.length;
  const pageCount = Math.max(1, Math.ceil(total / perPage));

  useEffect(() => { setPage(1); }, [resetKey]);

  // Jika data berkurang (mis. setelah dihapus), pastikan halaman aktif tetap valid.
  useEffect(() => { if (page > pageCount) setPage(pageCount); }, [page, pageCount]);

  const start = (Math.min(page, pageCount) - 1) * perPage;
  return { page, setPage, pageCount, total, perPage, start, pageItems: items.slice(start, start + perPage) };
}
