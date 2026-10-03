# Cara Menjalankan

Pastikan [instalasi](INSTALASI.md) sudah selesai dan PostgreSQL sedang berjalan.

## Mode Development

Butuh dua terminal.

**Terminal 1: backend**
```bash
cd backend
npm run dev
```
API berjalan di **http://localhost:4000/api**. Cek kesehatan: http://localhost:4000/api/health
(harus mengembalikan `{"status":"ok", ...}`).

**Terminal 2: frontend**
```bash
cd frontend
npm run dev
```
Buka **http://localhost:5173** lalu login dengan akun demo:

| Username | Password | Role |
|---|---|---|
| admin | admin123 | ADMIN |
| staff | staff123 | STAFF |
| teknisi1 | teknisi123 | TEKNISI |

## Mode Produksi di Komputer Lokal

Cocok bila aplikasi dipakai di komputer kasir bengkel (termasuk untuk printer yang terhubung langsung).

```bash
# Backend
cd backend
npm run prisma:deploy     # bila ada migrasi baru
npm start

# Frontend: build lalu sajikan
cd frontend
npm run build             # hasil di frontend/dist
npm run preview           # http://localhost:4173
```
Jika memakai `npm run preview`, ubah `CLIENT_URL` di `backend/.env` menjadi `http://localhost:4173`.

## Daftar Perintah

### Backend (`backend/`)
| Perintah | Fungsi |
|---|---|
| `npm run dev` | Jalankan dengan auto-reload (nodemon) |
| `npm start` | Jalankan mode produksi |
| `npm run prisma:deploy` | Terapkan semua migrasi ke database |
| `npm run prisma:migrate` | Buat migrasi baru saat `schema.prisma` diubah (development) |
| `npm run prisma:generate` | Generate Prisma Client |
| `npm run prisma:studio` | Buka GUI database di browser |
| `npm run seed` | Isi data awal & akun demo |

### Frontend (`frontend/`)
| Perintah | Fungsi |
|---|---|
| `npm run dev` | Server development (port 5173) |
| `npm run build` | Build produksi ke `dist/` |
| `npm run preview` | Pratinjau hasil build |

## Menghentikan Aplikasi

Tekan `Ctrl + C` di masing-masing terminal.

## Pembaruan Kode

```bash
git pull
cd backend && npm install && npm run prisma:deploy
cd ../frontend && npm install
```
Lalu jalankan ulang backend dan frontend.

## Masalah Umum

| Gejala | Solusi |
|---|---|
| Login gagal / "Network Error" | Backend belum jalan, atau `VITE_API_URL` salah. Restart `npm run dev` frontend setelah mengubah `.env`. |
| CORS error | `CLIENT_URL` di `backend/.env` harus sama dengan alamat frontend, tanpa garis miring di akhir. |
| Port 4000/5173 sudah dipakai | Ubah `PORT` di `backend/.env` (sesuaikan `VITE_API_URL`) atau `server.port` di `frontend/vite.config.js`. |
| Suara "Panggil ke Kasir" tidak keluar | Pakai Chrome/Edge, naikkan volume, dan klik halaman sekali sebelum menekan tombol. Suara bahasa Indonesia perlu terpasang di sistem operasi. |
| Scan barcode / WebUSB tidak berfungsi | Hanya jalan di `localhost` atau `https`. |
