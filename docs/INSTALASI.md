# Panduan Instalasi

Panduan ini untuk memasang Garage Management di komputer lokal (Windows, macOS, atau Linux).
Untuk memasang di server, lihat [DEPLOY.md](DEPLOY.md).

## 1. Prasyarat

| Perangkat lunak | Versi | Cek |
|---|---|---|
| Node.js | 18 atau lebih baru (disarankan 20 LTS) | `node -v` |
| npm | ikut Node.js | `npm -v` |
| PostgreSQL | 14 atau lebih baru | `psql --version` |
| Git | terbaru | `git --version` |

### Install Node.js
Unduh dari https://nodejs.org (pilih LTS), atau di Ubuntu/Debian:
```bash
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs
```

### Install PostgreSQL

**Windows**: unduh installer di https://www.postgresql.org/download/windows/, jalankan, lalu catat password
user `postgres` yang Anda buat. pgAdmin ikut terpasang (opsional).

**macOS**:
```bash
brew install postgresql@16
brew services start postgresql@16
```

**Ubuntu / Debian**:
```bash
sudo apt update
sudo apt install -y postgresql postgresql-contrib
sudo systemctl enable --now postgresql
```

## 2. Ambil Kode

```bash
git clone https://github.com/fattatata-lgtm/garage-management.git
cd garage-management
```

## 3. Buat Database

Masuk ke psql sebagai superuser:
```bash
sudo -u postgres psql        # Linux
psql -U postgres             # Windows / macOS (masukkan password saat diminta)
```
Lalu jalankan:
```sql
CREATE USER bengkel_user WITH PASSWORD 'bengkel_pass';
CREATE DATABASE bengkel_db OWNER bengkel_user;
\q
```
Ganti `bengkel_pass` dengan password yang lebih kuat untuk penggunaan sungguhan.

Cek koneksi:
```bash
psql -h localhost -U bengkel_user -d bengkel_db
```

## 4. Siapkan Backend

```bash
cd backend
cp .env.example .env          # Windows PowerShell: copy .env.example .env
```

Edit `backend/.env`:

| Variabel | Keterangan | Contoh |
|---|---|---|
| `DATABASE_URL` | Koneksi PostgreSQL | `postgresql://bengkel_user:bengkel_pass@localhost:5432/bengkel_db?schema=public` |
| `PORT` | Port API | `4000` |
| `NODE_ENV` | `development` atau `production` | `development` |
| `JWT_ACCESS_SECRET` | Rahasia token akses (string acak panjang) | |
| `JWT_REFRESH_SECRET` | Rahasia refresh token (berbeda dari di atas) | |
| `JWT_ACCESS_EXPIRES` | Masa berlaku access token | `15m` |
| `JWT_REFRESH_EXPIRES` | Masa berlaku refresh token | `7d` |
| `DEFAULT_TAX_SERVICE` / `DEFAULT_TAX_SALES` | Pajak default (%) | `10` |
| `CLIENT_URL` | URL frontend (untuk CORS) | `http://localhost:5173` |
| `UPLOAD_DIR` | Folder upload (logo) | `uploads` |

Membuat secret acak:
```bash
node -e "console.log(require('crypto').randomBytes(48).toString('hex'))"
```

Install dependensi:
```bash
npm install
```

## 5. Isi Database

Pilih salah satu.

### Opsi A: Migrasi Prisma + seed (disarankan)
```bash
npm run prisma:deploy     # membuat semua tabel dari folder prisma/migrations
npm run seed              # data awal + akun demo
```

### Opsi B: Impor file SQL
Dari folder utama proyek:
```bash
psql -h localhost -U bengkel_user -d bengkel_db -f database/garage_management.sql
```
Perintah ini membuat semua tabel sekaligus mengisi data awal (akun demo, kategori, sparepart contoh, jenis
layanan). Database harus kosong. Di Windows PowerShell, jika `psql` tidak dikenali, tambahkan folder `bin`
PostgreSQL ke PATH atau panggil dengan path lengkap, misalnya
`& "C:\Program Files\PostgreSQL\16\bin\psql.exe" -h localhost -U bengkel_user -d bengkel_db -f database\garage_management.sql`.

Setelah impor SQL, jalankan `npx prisma generate` di folder `backend`. Bila nanti ingin memakai
`npm run prisma:deploy` untuk migrasi baru, tandai migrasi yang sudah termuat sebagai selesai:
```bash
npx prisma migrate resolve --applied 20260928195410_init
npx prisma migrate resolve --applied 20260929120000_service_billing_stage_and_logs
npx prisma migrate resolve --applied 20260930120000_category_updated_at
npx prisma migrate resolve --applied 20260930130000_remove_user_is_active
npx prisma migrate resolve --applied 20261002120000_printer_connection
```

### Data awal yang tersedia
- Pengaturan: nama usaha "Self Automotive", pajak 10%
- Akun: `admin`, `staff`, `teknisi1` (lihat [README](../README.md#akun-demo))
- 1 teknisi, 2 master kendaraan, 2 kategori, 2 sparepart, 3 jenis layanan

## 6. Siapkan Frontend

```bash
cd ../frontend
cp .env.example .env
npm install
```

Pastikan `frontend/.env` berisi alamat API backend:
```
VITE_API_URL=http://localhost:4000/api
```

## 7. Selesai

Lanjut ke [MENJALANKAN.md](MENJALANKAN.md) untuk menjalankan aplikasi.

## Masalah Umum

| Gejala | Penyebab / solusi |
|---|---|
| `password authentication failed` | User/password di `DATABASE_URL` tidak cocok dengan yang dibuat di langkah 3. |
| `database "bengkel_db" does not exist` | Langkah 3 belum dijalankan. |
| `permission denied for schema public` (PostgreSQL 15+) | Jalankan sebagai superuser: `GRANT ALL ON SCHEMA public TO bengkel_user;` setelah `\c bengkel_db`. |
| `relation "User" already exists` saat impor SQL | Database tidak kosong. Gunakan database baru atau hapus tabel lama. |
| `psql` tidak dikenali di Windows | Tambahkan `C:\Program Files\PostgreSQL\16\bin` ke PATH. |
| Prisma gagal mengunduh engine | Periksa koneksi internet/proxy, lalu ulangi `npm install`. |
