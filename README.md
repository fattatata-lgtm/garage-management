# Self Automotive — Aplikasi Manajemen Bengkel

Full-stack web app sesuai PRD "Aplikasi Bengkel Self Automotive":

- **Frontend**: React 18 + Vite + React Router + Tailwind CSS — navigasi **top bar**, role-based (Admin/Staff/Teknisi)
- **Backend**: Node.js + Express.js + REST API
- **ORM**: Prisma
- **Database**: **PostgreSQL native** (bukan Docker) — dijalankan langsung di OS (Windows/Linux/Mac)

Struktur folder:
```
bengkel-app/
├── backend/     # Express + Prisma API
└── frontend/    # React + Vite SPA
```

---

## 1. Install PostgreSQL Native (tanpa Docker)

### Windows
1. Unduh installer di https://www.postgresql.org/download/windows/ lalu jalankan.
2. Catat password superuser `postgres` yang Anda buat saat instalasi.
3. PgAdmin akan otomatis terpasang untuk GUI (opsional).

### macOS
```bash
brew install postgresql@16
brew services start postgresql@16
```

### Ubuntu / Debian Linux
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl enable --now postgresql
```

### Buat database & user untuk aplikasi
Masuk ke psql sebagai superuser:
```bash
sudo -u postgres psql        # Linux
psql -U postgres             # Windows/Mac (masukkan password saat diminta)
```
Lalu jalankan:
```sql
CREATE USER bengkel_user WITH PASSWORD 'bengkel_pass';
CREATE DATABASE bengkel_db OWNER bengkel_user;
GRANT ALL PRIVILEGES ON DATABASE bengkel_db TO bengkel_user;
\q
```

Pastikan PostgreSQL berjalan di port default `5432` (cek dengan `psql -h localhost -U bengkel_user -d bengkel_db`).

---

## 2. Setup Backend (Express + Prisma)

```bash
cd backend
cp .env.example .env
```

Edit file `.env` dan sesuaikan `DATABASE_URL` dengan kredensial yang Anda buat di langkah 1:
```
DATABASE_URL="postgresql://bengkel_user:bengkel_pass@localhost:5432/bengkel_db?schema=public"
```
Juga ganti `JWT_ACCESS_SECRET` dan `JWT_REFRESH_SECRET` dengan string acak yang aman.

Install dependencies:
```bash
npm install
```

Buat tabel-tabel di database (migration) dan generate Prisma Client:
```bash
npm run prisma:migrate
```
Perintah ini akan membuat semua tabel sesuai `prisma/schema.prisma` di database `bengkel_db`.

Isi data awal (akun demo, kategori, sparepart contoh, jenis service):
```bash
npm run seed
```

Jalankan server backend (development, auto-reload):
```bash
npm run dev
```
API akan berjalan di **http://localhost:4000/api** (cek kesehatan di `/api/health`).

**Akun demo hasil seeding:**
| Username   | Password    | Role    |
|------------|-------------|---------|
| admin      | admin123    | ADMIN   |
| staff      | staff123    | STAFF   |
| teknisi1   | teknisi123  | TEKNISI |

---

## 3. Setup Frontend (React + Vite)

Buka terminal baru:
```bash
cd frontend
cp .env.example .env
```
Pastikan `.env` berisi:
```
VITE_API_URL=http://localhost:4000/api
```

Install dependencies & jalankan:
```bash
npm install
npm run dev
```
Buka **http://localhost:5173** di browser. Login dengan salah satu akun demo di atas.

Untuk build production:
```bash
npm run build      # hasil ada di frontend/dist
npm run preview    # preview hasil build
```

---

## 4. Struktur Menu (Top Bar) & Hak Akses

Menu **Dashboard, Pelanggan, Penjualan, Teknisi, dan Users** berupa **link langsung** (tanpa dropdown);
menu lainnya (Sparepart, Kendaraan, Layanan, Laporan, Admin) tetap dropdown. Tombol tambah data ada di
dalam halaman daftar masing-masing. Proses tambah/edit data dibuka sebagai **halaman tersendiri**
(bukan popup), mis. `/customers/new`, `/spareparts/categories/new`.

| Menu | Isi | Admin | Staff | Teknisi |
|-----------------|--------------|:-----:|:-----:|:-------:|
| Dashboard   | (link langsung) | ✅ | ✅ | – |
| Pelanggan   | (link langsung) | ✅ | ✅ | – |
| Sparepart   | Data Sparepart, Kategori, Riwayat Stok | ✅ | ✅ | – |
| Kendaraan   | Data Kendaraan, Master Kendaraan | ✅ | ✅ | – |
| Layanan     | Data Layanan, Jenis Layanan | ✅ | ✅ (Jenis Layanan: ya) | ✅ (Data Layanan saja, hanya miliknya) |
| Penjualan   | (link langsung) | ✅ | ✅ | – |
| Teknisi     | (link langsung) | ✅ | ✅ | – |
| Laporan     | Laporan Stok, Laporan Layanan, Laporan Penjualan | ✅ | ✅ | – |
| Users       | (link langsung) | ✅ | – | – |
| Admin       | Pengaturan Aplikasi, Diskon | ✅ | – | – |

> **Jenis Layanan** (sebelumnya "Jenis Service" di menu Admin) kini berada di dropdown **Layanan**.

Akun bertipe **Teknisi** yang ingin dibatasi hanya melihat/mengerjakan service miliknya harus ditautkan ke data master Teknisi melalui menu **Users → Tautkan ke Data Teknisi**.

---

## 5. Alur Transaksi Service (4 Tahap)

Status: `DITERIMA` → `DIKERJAKAN` → `MENUNGGU_PEMBAYARAN` → `SELESAI` (Lunas). Setiap perpindahan tahap
dan perubahan penting tercatat di **Riwayat Transaksi** (tabel `ServiceLog`) yang tampil di halaman detail.

1. **Diterima** — Staff/Admin membuat transaksi baru (pilih kendaraan, teknisi, tanggal, keluhan). Bisa Kirim WA & Cetak Bukti Diterima.
2. **Dikerjakan** — Klik "Mulai Kerjakan". Teknisi/Staff mengisi KM, detail jasa, sparepart yang dipakai (stok otomatis terpotong & tercatat di riwayat stok), rekomendasi service berikutnya. Pada tahap ini **belum ada total maupun opsi pembayaran**.
   - Klik **+ Tambah Jasa** → muncul dropdown berisi *Jenis Layanan* dengan kolom pencarian, plus opsi **Manual / Lainnya** untuk mengetik jasa sendiri. Memilih jenis layanan mengisi nama, deskripsi, dan biaya (biaya tetap bisa diubah).
   - Klik **Selesai Dikerjakan** (butuh KM + minimal 1 jasa) untuk pindah ke tahap 3.
3. **Menunggu Pembayaran (Tagihan)** — Halaman yang sama dengan tahap 2 (masih bisa diedit oleh Admin/Staff) ditambah **Total Rincian Biaya & Pembayaran**: diskon, subtotal, pajak (dari Pengaturan Aplikasi), total, jumlah dibayar & kembalian. Tersedia **Panggil ke Kasir** (text-to-speech browser), **Cetak Tagihan**, dan **Kirim WA** (pesan berisi tagihan).
4. **Selesai (Lunas)** — Setelah "Konfirmasi Pembayaran", transaksi pindah ke halaman detail transaksi (hanya lihat) dengan tombol Cetak Invoice / Struk Thermal / Work Order dan Kirim WA.

**Data Layanan (CRUD)**: kolom Aksi berisi **Lihat** (detail + tahapan + riwayat), **Edit** (data awal: kendaraan, teknisi, tanggal, keluhan; tidak tersedia untuk transaksi Lunas), dan **Hapus** (stok sparepart yang terpakai dikembalikan otomatis; transaksi Lunas hanya bisa dihapus Admin).

> Setelah update kode ini jalankan migration baru: `cd backend && npm run prisma:migrate`
> (menambah status `MENUNGGU_PEMBAYARAN` dan tabel `ServiceLog`). Transaksi lama berstatus `DIKERJAKAN`
> tetap berjalan normal; transaksi lama yang belum punya riwayat menampilkan riwayat ringkas dari waktu buat/ubah terakhir.

---

## 6. Catatan Implementasi

- Semua endpoint yang mengubah data mutasi stok (service, penjualan, stok masuk/keluar) dibungkus dalam `prisma.$transaction` agar atomik dan konsisten.
- Autentikasi menggunakan JWT access token (15 menit) + refresh token (7 hari), dengan auto-refresh di sisi frontend (axios interceptor).
- Fitur "Kirim WA" membuka `wa.me` dengan pesan siap kirim (bukan integrasi otomatis/API WhatsApp Business, sesuai batasan PRD).
- Fitur "Panggil Kasir" menggunakan Web Speech API bawaan browser (tidak memerlukan layanan eksternal).
- **Struk Thermal** dapat dicetak ke printer thermal asli (perintah ESC/POS, potong kertas otomatis, logo) — lihat bagian 7. Invoice A4/Work Order/Laporan dan mode bawaan menggunakan `window.print()` pada jendela baru yang sudah diformat siap cetak; bisa disimpan sebagai PDF melalui dialog cetak browser ("Simpan sebagai PDF").
- Status stok sparepart: **Baik** (di atas ambang), **Rendah** (≤ ambang, dapat diatur per-item), **Habis** (0) — muncul sebagai alert di Dashboard.

## 7. Cetak Struk ke Printer Thermal Asli (ESC/POS)

Atur di **Admin > Pengaturan Aplikasi**: *Ukuran Kertas* (58/80 mm) dan *Cara Cetak Struk Thermal*, lalu tekan **Tes Cetak**.
Struk dibuat sebagai perintah ESC/POS (teks rata kiri/kanan, tebal, total besar, logo, potong kertas), bukan halaman HTML.

| Mode | Cara kerja | Cocok untuk |
|------|-----------|-------------|
| Dialog cetak browser | `window.print()` lewat driver (perilaku lama) | Cadangan / tanpa setup |
| Printer terpasang di komputer server (RAW) | Backend mengirim byte ke antrean printer OS (Windows: winspool, Linux/Mac: `lp -o raw`) | **Printer USB di Windows** dengan driver bawaan |
| Printer jaringan (IP:9100) | Backend membuka koneksi TCP ke printer | Printer LAN/WiFi |
| USB langsung (WebUSB) | Browser bicara langsung ke printer | Chrome/Edge, butuh driver WinUSB |
| Serial / Bluetooth COM (Web Serial) | Browser menulis ke port COM | Printer Bluetooth/USB-serial |

Catatan:
- Mode *server* (RAW & jaringan) memakai pengaturan **tersimpan**; simpan dulu sebelum Tes Cetak. Backend harus berjalan di komputer yang tersambung ke printer (mode RAW).
- WebUSB/Web Serial hanya di Chrome/Edge dan hanya lewat `localhost` atau `https`. Pilihan perangkat tersimpan per-browser.
- Bila pengiriman ke printer gagal, aplikasi menampilkan pesan lalu membuka dialog cetak browser sebagai cadangan.
- Setelah update: `cd backend && npm run prisma:migrate` (menambah kolom `printerConnection` & `printerName`).

## 8. Troubleshooting Singkat

- **Error koneksi database**: pastikan service PostgreSQL berjalan (`sudo systemctl status postgresql` di Linux) dan `DATABASE_URL` di `backend/.env` sudah benar.
- **CORS error di browser**: pastikan `CLIENT_URL` di `backend/.env` sesuai URL frontend (default `http://localhost:5173`).
- **Port bentrok**: ubah `PORT` di `backend/.env` atau `server.port` di `frontend/vite.config.js`.
