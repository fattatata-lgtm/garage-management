# Garage Management

Aplikasi manajemen bengkel berbasis web: pelanggan, kendaraan, sparepart & stok, transaksi service (4 tahap),
penjualan sparepart, teknisi, laporan, serta cetak struk ke printer thermal.

- **Frontend**: React 18 + Vite + React Router + Tailwind CSS (navigasi top bar, berbasis role Admin/Staff/Teknisi)
- **Backend**: Node.js + Express + REST API
- **ORM**: Prisma
- **Database**: PostgreSQL (native, tanpa Docker)

```
garage-management/
├── backend/      # Express + Prisma API
├── frontend/     # React + Vite SPA
├── database/     # File database (struktur + data awal) -> garage_management.sql
└── docs/         # Panduan instalasi, menjalankan, dan deploy
```

## Dokumentasi

| Dokumen | Isi |
|---|---|
| [docs/INSTALASI.md](docs/INSTALASI.md) | Panduan instalasi (Node.js, PostgreSQL, backend, frontend, database) |
| [docs/MENJALANKAN.md](docs/MENJALANKAN.md) | Cara menjalankan aplikasi (development & mode produksi lokal) |
| [docs/DEPLOY.md](docs/DEPLOY.md) | Cara deploy ke server (VPS Ubuntu + Nginx + PM2, serta opsi Vercel/Render) |
| [database/garage_management.sql](database/garage_management.sql) | File database: struktur tabel + data awal |

## Mulai Cepat

Prasyarat: **Node.js 18+** dan **PostgreSQL 14+**. Detail lengkap ada di [docs/INSTALASI.md](docs/INSTALASI.md).

```bash
# 1. Buat database (di psql)
CREATE USER bengkel_user WITH PASSWORD 'bengkel_pass';
CREATE DATABASE bengkel_db OWNER bengkel_user;

# 2. Backend
cd backend
cp .env.example .env          # Windows PowerShell: copy .env.example .env
npm install
npm run prisma:deploy         # membuat semua tabel
npm run seed                  # data awal + akun demo
npm run dev                   # http://localhost:4000

# 3. Frontend (terminal baru)
cd frontend
cp .env.example .env
npm install
npm run dev                   # http://localhost:5173
```

Alternatif untuk langkah `prisma:deploy` + `seed`: impor file `database/garage_management.sql`
(lihat [docs/INSTALASI.md](docs/INSTALASI.md#opsi-b--impor-file-sql)).

## Akun Demo

| Username | Password | Role |
|---|---|---|
| admin | admin123 | ADMIN |
| staff | staff123 | STAFF |
| teknisi1 | teknisi123 | TEKNISI |

> Ganti password akun demo sebelum dipakai di server produksi.

## Struktur Menu & Hak Akses

Menu **Dashboard, Pelanggan, Penjualan, Teknisi, dan Users** berupa link langsung; menu lainnya
(Sparepart, Kendaraan, Layanan, Laporan, Admin) berupa dropdown. Proses tambah/edit data dibuka sebagai
halaman tersendiri (bukan popup).

| Menu | Isi | Admin | Staff | Teknisi |
|---|---|:-:|:-:|:-:|
| Dashboard | (link langsung) | ✅ | ✅ | – |
| Pelanggan | (link langsung) | ✅ | ✅ | – |
| Sparepart | Data Sparepart, Kategori, Riwayat Stok | ✅ | ✅ | – |
| Kendaraan | Data Kendaraan, Master Kendaraan | ✅ | ✅ | – |
| Layanan | Data Layanan, Jenis Layanan | ✅ | ✅ | ✅ (Data Layanan miliknya saja) |
| Penjualan | (link langsung) | ✅ | ✅ | – |
| Teknisi | (link langsung) | ✅ | ✅ | – |
| Laporan | Stok, Layanan, Penjualan | ✅ | ✅ | – |
| Users | (link langsung) | ✅ | – | – |
| Admin | Pengaturan Aplikasi, Diskon | ✅ | – | – |

Akun bertipe **Teknisi** yang ingin dibatasi hanya pada service miliknya harus ditautkan ke data master
Teknisi lewat **Users → Tautkan ke Data Teknisi**.

## Alur Transaksi Service (4 Tahap)

Status: `DITERIMA` → `DIKERJAKAN` → `MENUNGGU_PEMBAYARAN` → `SELESAI` (Lunas). Setiap perpindahan tahap tercatat
di **Riwayat Transaksi** (tabel `ServiceLog`).

1. **Diterima**: Staff/Admin membuat transaksi (kendaraan, teknisi, tanggal, keluhan). Bisa Kirim WA & Cetak Bukti Diterima.
2. **Dikerjakan**: klik "Mulai Kerjakan". Isi KM, detail jasa (pilih dari Jenis Layanan atau manual), sparepart yang
   dipakai (stok otomatis terpotong dan tercatat), serta rekomendasi service berikutnya. Klik **Selesai Dikerjakan**
   (butuh KM + minimal 1 jasa).
3. **Menunggu Pembayaran**: muncul diskon, subtotal, pajak, total, jumlah dibayar, dan kembalian. Tersedia
   **Panggil ke Kasir** (suara), **Cetak Tagihan**, dan **Kirim WA**.
4. **Selesai (Lunas)**: setelah "Konfirmasi Pembayaran". Tersedia Cetak Invoice / Struk Thermal / Work Order dan Kirim WA.

### Panggil ke Kasir

Pada tahap Menunggu Pembayaran, tombol **Panggil ke Kasir** mengucapkan (Web Speech API bawaan browser):

> "Perhatian. Atas nama *[nama pelanggan]*, dengan nomor polisi *[plat, dieja per karakter]*, sudah selesai
> pengerjaan. Silakan ke kasir untuk melakukan pembayaran."

Kalimatnya dapat diubah di `frontend/src/utils/tts.js` (fungsi `buildCashierCallText`).

## Cetak Struk ke Printer Thermal (ESC/POS)

Atur di **Admin → Pengaturan Aplikasi**: ukuran kertas (58/80 mm) dan cara cetak, lalu tekan **Tes Cetak**.

| Mode | Cara kerja | Cocok untuk |
|---|---|---|
| Dialog cetak browser | `window.print()` lewat driver | Cadangan / tanpa setup |
| Printer terpasang di komputer server (RAW) | Backend mengirim byte ke antrean printer OS | Printer USB di Windows |
| Printer jaringan (IP:9100) | Backend membuka koneksi TCP ke printer | Printer LAN/WiFi |
| USB langsung (WebUSB) | Browser bicara langsung ke printer | Chrome/Edge |
| Serial / Bluetooth COM (Web Serial) | Browser menulis ke port COM | Printer Bluetooth/USB-serial |

Catatan: mode RAW dan jaringan membutuhkan backend yang satu komputer/jaringan dengan printer, sehingga tidak
berfungsi bila backend di cloud. WebUSB/Web Serial hanya di Chrome/Edge dan hanya lewat `localhost` atau `https`.

## Catatan Teknis

- Endpoint yang mengubah stok (service, penjualan, stok masuk/keluar) dibungkus `prisma.$transaction`.
- Autentikasi JWT: access token 15 menit + refresh token 7 hari, auto-refresh lewat axios interceptor.
- "Kirim WA" membuka `wa.me` dengan pesan siap kirim (bukan WhatsApp Business API).
- Status stok: **Baik**, **Rendah** (≤ ambang per item), **Habis** (0), tampil sebagai alert di Dashboard.

## Troubleshooting Singkat

- **Error koneksi database**: pastikan PostgreSQL berjalan dan `DATABASE_URL` di `backend/.env` benar.
- **CORS error**: `CLIENT_URL` di `backend/.env` harus sama persis dengan URL frontend (tanpa garis miring di akhir).
- **Port bentrok**: ubah `PORT` di `backend/.env` atau `server.port` di `frontend/vite.config.js`.
- **Halaman 404 saat refresh setelah deploy**: server harus mengarahkan semua path ke `index.html` (lihat [docs/DEPLOY.md](docs/DEPLOY.md)).
