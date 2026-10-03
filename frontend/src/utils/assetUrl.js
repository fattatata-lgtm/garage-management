// Ubah path file upload dari backend (mis. "/uploads/logo-123.png") menjadi URL penuh.
// URL penuh (http/https/data/blob) dibiarkan apa adanya.
const API = import.meta.env.VITE_API_URL || 'http://localhost:4000/api';
const ORIGIN = API.replace(/\/api\/?$/, '');

export function assetUrl(path) {
  if (!path) return '';
  if (/^(https?:|data:|blob:)/i.test(path)) return path;
  return `${ORIGIN}${path.startsWith('/') ? '' : '/'}${path}`;
}
