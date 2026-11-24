# Garage Management — Aplikasi Manajemen Bengkel

Digitalisasi operasional bengkel: **pelanggan, kendaraan, service, sparepart, supplier, penjualan, teknisi, dan laporan** dalam satu sistem — **web** untuk Admin/Staff/Teknisi dan **aplikasi mobile Android** untuk Staff.

![React](https://img.shields.io/badge/React-18-61dafb) ![Vite](https://img.shields.io/badge/Vite-5-646cff) ![Express](https://img.shields.io/badge/Express-4-000000) ![Prisma](https://img.shields.io/badge/Prisma-5-2d3748) ![PostgreSQL](https://img.shields.io/badge/PostgreSQL-14+-336791) ![Flutter](https://img.shields.io/badge/Flutter-3.x-02569B) ![Platform](https://img.shields.io/badge/Platform-Web%20%7C%20Android-3ddc84)

### Sekilas

| | |
|---|---|
| **Web** (`frontend/` + `backend/`) | React 18 + Vite, REST API Express 4, Prisma 5, PostgreSQL 14+ |
| **Mobile** (`mobile_user/`) | Flutter, khusus role **Staff** (Android): kasir, service, stok, cetak struk thermal |
| **Role** | Admin · Staff · Teknisi, dengan hak akses dibatasi di server |
| **Alur utama** | Pelanggan → Kendaraan → Service 4 tahap → Pembayaran → Invoice/Struk |
| **Cetak** | ESC/POS: USB, Bluetooth, jaringan, printer server, atau PDF |

<p align="center">
  <img src="docs/screenshots/beranda.png" width="190" alt="Beranda aplikasi mobile">
  <img src="docs/screenshots/service-4-pembayaran.png" width="190" alt="Pembayaran service">
  <img src="docs/screenshots/sparepart-detail.png" width="190" alt="Detail sparepart">
  <img src="docs/screenshots/pengaturan-mode-malam.png" width="190" alt="Mode malam">
</p>
<p align="center"><sub>Aplikasi mobile Staff — selengkapnya di <a href="#112-tangkapan-layar">Tangkapan Layar</a></sub></p>

## Daftar Isi

1. [Ringkasan Produk](#1-ringkasan-produk)
2. [Ruang Lingkup](#2-ruang-lingkup)
3. [Detail Fitur per Modul](#3-detail-fitur-per-modul)
4. [Kebutuhan Nonfungsional](#4-kebutuhan-nonfungsional)
5. [Arsitektur Sistem](#5-arsitektur-sistem)
6. [Instalasi & Menjalankan](#6-instalasi--menjalankan)
7. [Alur Pengguna](#7-alur-pengguna)
8. [Risiko dan Mitigasi](#8-risiko-dan-mitigasi)
9. [Skema Database](#9-skema-database)
10. [Troubleshooting](#10-troubleshooting)
11. [Aplikasi Mobile Staff (`mobile_user`)](#11-aplikasi-mobile-staff-mobile_user)

<details>
<summary><b>Ringkasan pembaruan terbaru</b></summary>

- **Aplikasi mobile Android untuk Staff** (`mobile_user/`, Flutter) — beranda, layanan, penjualan, sparepart + scan barcode, supplier, laporan, pengaturan, dan cetak struk thermal Bluetooth/jaringan/PDF. Lihat [bagian 11](#11-aplikasi-mobile-staff-mobile_user).
- **Modul Supplier** — pemasok sparepart, relasi ke sparepart dan Riwayat Stok (supplier asal barang masuk), filter sparepart per supplier.
- **Laporan bertambah menjadi 5**: Layanan, Penjualan, **Sparepart (paling laris)**, **Loyalitas Pelanggan**, dan Stok.
- **Dashboard Teknisi** — ringkasan layanan khusus Teknisi (tanpa data stok, penjualan, dan pendapatan).
- **Hak akses diskon & pengaturan** — API kini mengizinkan **Staff** menambah/mengubah Diskon dan menyimpan Pengaturan Aplikasi (dipakai aplikasi mobile); hapus diskon tetap hanya Admin.
- Total endpoint API menjadi **17 grup** (ditambah `suppliers`).

</details>

---

## 1. Ringkasan Produk

### 1.1 Tujuan Produk

Menggantikan pencatatan manual (kertas/spreadsheet) dengan satu database terpusat:

- **Data terpusat** — pelanggan, kendaraan, dan riwayat service dalam satu tempat.
- **Hitung otomatis** — subtotal, diskon, pajak, dan kembalian; server menghitung ulang sebelum data disimpan.
- **Stok otomatis** — terpotong saat sparepart dipakai (service/penjualan), dikembalikan bila transaksi diubah atau dihapus, lengkap dengan riwayat stok masuk/keluar.
- **Pelacakan teknisi** — jadwal, riwayat, dan statistik service yang ditangani.
- **Dokumen instan** — Bukti Service Diterima, Tagihan, Invoice, Struk Thermal, dan Work Order, termasuk cetak langsung ke printer thermal.
- **Service 4 tahap** — Diterima → Dikerjakan → Menunggu Pembayaran → Selesai (Lunas), dengan riwayat tahapan tercatat otomatis.
- **Laporan periodik** — layanan, penjualan, sparepart terlaris, loyalitas pelanggan, dan stok untuk pengambilan keputusan.
- **Supplier terdata** — asal sparepart dan barang masuk tercatat per supplier.
- **Web + mobile** — kasir dapat bekerja dari komputer atau dari HP Android, dengan satu server dan satu database.

### 1.2 Sasaran Pengguna

| Role | Deskripsi | Kebutuhan Utama |
|---|---|---|
| **Admin** | Pemilik/pengelola bengkel | Akses penuh: laporan, pengaturan aplikasi, diskon, manajemen user, hapus transaksi lunas |
| **Staff** | Kasir / front office | Input pelanggan, kendaraan, supplier, transaksi service & penjualan, lihat laporan; di aplikasi mobile juga mengelola diskon dan pengaturan aplikasi |
| **Teknisi** | Mekanik pelaksana | Melihat service yang ditugaskan, mengisi pengerjaan (KM, jasa, sparepart), menandai selesai dikerjakan |

---

## 2. Ruang Lingkup

### 2.1 Fitur Utama

1. **Dashboard** — total pelanggan, kendaraan, service, pendapatan service (lunas), pendapatan sales, estimasi laba penjualan, alert stok menipis/habis, dan service terbaru (filter Hari/Minggu/Bulan Ini). Teknisi mendapat **Dashboard Teknisi** yang hanya berisi ringkasan layanan.
2. **Pelanggan** — CRUD, validasi email & No. HP, detail dengan daftar kendaraan & riwayat service, aksi cepat Tambah Kendaraan / Buat Service / Buat Penjualan.
3. **Sparepart** — CRUD kategori & sparepart, supplier per sparepart, pemindaian barcode, Stok Masuk/Keluar manual, dan Riwayat Stok (sumber: Manual/Service/Penjualan).
4. **Supplier** — CRUD pemasok sparepart; terhubung ke sparepart dan ke Riwayat Stok barang masuk.
5. **Kendaraan** — Data Master (merk/model/tahun/tipe/roda) dan Data Kendaraan milik pelanggan beserta riwayat service.
6. **Layanan** — Jenis Layanan (master jasa) dan Data Layanan (transaksi service 4 tahap) dengan Panggil ke Kasir, Kirim WhatsApp, dan cetak dokumen.
7. **Penjualan** — jual sparepart retail (pelanggan terdaftar/umum), diskon, pajak, kembalian, cetak Invoice/Struk, Kirim WhatsApp.
8. **Teknisi** — CRUD, status Aktif/Nonaktif, jadwal, riwayat & statistik; akun Teknisi ditautkan ke data teknisi.
9. **Users** — manajemen akun, role, tautan teknisi, reset password.
10. **Laporan** — Layanan, Penjualan, Sparepart (terlaris), Loyalitas Pelanggan, dan Stok; cetak atau simpan PDF.
11. **Admin** — Pengaturan Aplikasi (identitas, logo, printer thermal, pajak) dan CRUD Diskon/Kupon.
12. **Aplikasi Mobile Staff** — aplikasi Android (Flutter) untuk operasional harian Staff, lihat [bagian 11](#11-aplikasi-mobile-staff-mobile_user).

### 2.2 Di Luar Scope (MVP)

- Payment gateway / pembayaran online (pembayaran dicatat manual oleh kasir).
- Notifikasi otomatis SMS/WhatsApp/Email — pesan WhatsApp hanya disiapkan lalu dikirim manual lewat tautan `wa.me`.
- Aplikasi mobile untuk iOS, serta untuk role Admin/Teknisi (aplikasi mobile Android saat ini khusus Staff).
- Multi-cabang / multi-tenant.
- Booking/reservasi service online oleh pelanggan.
- Integrasi akuntansi pihak ketiga.
- Laporan analitik lanjutan (BI/grafik kompleks).
- Backup & restore dari dalam aplikasi (lakukan manual di luar aplikasi, mis. `pg_dump`).

### 2.3 Struktur Menu & Hak Akses

Menu **Dashboard, Pelanggan, Penjualan, Teknisi, Supplier, dan Users** berupa link langsung; menu lainnya (Sparepart, Kendaraan, Layanan, Laporan, Admin) berupa dropdown. Tambah/edit data dibuka sebagai halaman tersendiri (bukan popup).

| Menu | Submenu / Isi | Admin | Staff | Teknisi |
|---|---|:-:|:-:|:-:|
| Dashboard | Ringkasan metrik, alert stok, service terbaru | ✅ | ✅ | ✅ *(ringkasan layanan saja)* |
| Pelanggan | Data, Detail, Form Tambah/Edit | ✅ | ✅ | – |
| Sparepart | Data Sparepart, Kategori, Riwayat Stok | ✅ | ✅ | – |
| Kendaraan | Data Kendaraan, Master Kendaraan | ✅ | ✅ | – |
| Layanan | Data Layanan, Jenis Layanan | ✅ | ✅ | ✅ *(hanya service miliknya)* |
| Penjualan | Data Penjualan, Tambah, Detail/Invoice | ✅ | ✅ | – |
| Teknisi | Data Teknisi, Jadwal, Riwayat & Statistik | ✅ | ✅ | – |
| Supplier | Data Supplier, Form Tambah/Edit | ✅ | ✅ | – |
| Laporan | Layanan, Penjualan, Sparepart, Loyalitas, Stok | ✅ | ✅ | – |
| Users | Pengguna & Hak Akses | ✅ | – | – |
| Admin | Pengaturan Aplikasi & Diskon | ✅ | – *(lihat catatan)* | – |

> **Catatan hak akses Staff:** menu **Admin** di web hanya tampil untuk Admin. Namun di level API, `POST/PUT /api/discounts` serta `PUT /api/settings` (termasuk unggah/hapus logo) mengizinkan **ADMIN dan STAFF** agar aplikasi mobile Staff dapat mengelola diskon dan pengaturan aplikasi. `DELETE /api/discounts/:id` tetap hanya ADMIN.

**Aturan Teknisi:** hanya bisa membuka Dashboard (ringkasan layanan) dan menu Layanan, serta hanya melihat service yang ditugaskan kepadanya (dibatasi di **server** berdasarkan tautan akun ke data teknisi). Saat status *Dikerjakan*, teknisi mengisi KM, jasa, sparepart, rekomendasi, dan catatan internal, lalu menandai selesai dikerjakan. Memulai pengerjaan, mengubah tagihan, pembayaran, edit, dan hapus hanya untuk Admin/Staff. Setelah login, Teknisi melihat Dashboard Teknisi dan dapat membuka Data Layanan.

> Agar akun Teknisi terbatas pada service miliknya, tautkan lewat **Users → Tautkan ke Data Teknisi**.

---

## 3. Detail Fitur per Modul

### 3.1 Pelanggan

- Data: nama (wajib), No. HP (wajib), email & alamat (opsional); validasi format email dan No. HP.
- Daftar dengan pencarian dan aksi Lihat/Edit/Hapus.
- Detail menampilkan kendaraan milik pelanggan, riwayat service, dan aksi cepat Tambah Kendaraan / Buat Service / Buat Penjualan.

### 3.2 Kendaraan

- **Data Master** — referensi Merk, Model, Tahun, Tipe (MPV/SUV/Hatchback), dan Jumlah Roda; menjadi acuan pilihan agar tidak ada duplikasi input.
- **Data Kendaraan** — pilih Pemilik dan Jenis Kendaraan, isi No. Plat (wajib, unik), VIN, No. Mesin, Warna, Tahun Pembelian, Catatan.
- Detail menampilkan info kendaraan, info pemilik, dan seluruh riwayat service; dari sini staff dapat langsung membuat service baru.

### 3.3 Sparepart & Stok

- Buat **Kategori** dahulu, lalu **Sparepart**: kode (unik, bisa scan barcode), nama, kategori, supplier (opsional), harga beli/jual, stok awal, batas stok rendah (bawaan 5).
- Daftar sparepart dapat difilter per kategori, **supplier**, dan status stok.
- **Stok Masuk / Keluar** manual dengan keterangan; stok keluar tidak boleh melebihi stok tersedia. Pada **Stok Masuk**, supplier terisi otomatis dari supplier bawaan sparepart (dapat diganti). Semua tercatat di Riwayat Stok beserta supplier asal barang.
- Stok berkurang otomatis saat dipakai di Service (saat pengerjaan disimpan) atau Penjualan; dikembalikan otomatis bila pemakaian diubah atau transaksi dihapus.
- Status stok: **Baik**, **Rendah** (≤ batas per item), **Habis** (0) — tampil sebagai alert di Dashboard.
- Pencarian sparepart (daftar dan form service/penjualan) mendukung scan barcode lewat kamera.

### 3.4 Layanan (Service Kendaraan)

Status: `DITERIMA` → `DIKERJAKAN` → `MENUNGGU_PEMBAYARAN` → `SELESAI` (Lunas). Rincian alurnya ada di [bagian 7.2](#72-alur-transaksi-service).

| Tahap | Isi | Aksi |
|---|---|---|
| **1. Diterima** | Kendaraan (pemilik & No. WhatsApp terisi otomatis), Teknisi, Tanggal, Keluhan. Nomor `SVC-TTTTBBHH-0001` dibuat otomatis | Kirim WA, Cetak Bukti Diterima, Mulai Kerjakan, Edit, Hapus |
| **2. Dikerjakan** | KM (wajib), Detail Jasa (pilih Jenis Layanan atau manual, multi-jasa), Sparepart, Rekomendasi & Tanggal Service Berikutnya, Catatan Internal | Simpan Pekerjaan (stok terpotong), Selesai Dikerjakan |
| **3. Menunggu Pembayaran** | Rincian dapat diubah, pilih Diskon, ringkasan Subtotal → Diskon → Pajak → Total | Panggil ke Kasir, Cetak Tagihan, Kirim WA |
| **4. Selesai (Lunas)** | Jumlah Dibayar & Kembalian; transaksi terkunci (hanya-lihat) | Cetak Invoice / Struk Thermal / Work Order, Kirim WA |

**Validasi**

- Tahap 1: Kendaraan, Teknisi, Tanggal, Keluhan wajib.
- Selesai Dikerjakan: KM tersimpan dan minimal 1 jasa.
- Pembayaran hanya saat *Menunggu Pembayaran*, dan Jumlah Dibayar ≥ Total.
- Edit hanya untuk Admin/Staff selama belum lunas. Hapus: Admin/Staff; transaksi lunas hanya **Admin**. Stok yang terpakai dikembalikan otomatis dan dicatat di Riwayat Stok.
- Catatan Internal **tidak** tampil di dokumen cetak maupun pesan WhatsApp.
- Setiap perpindahan tahap tercatat di **Riwayat Tahapan** (`ServiceLog`: tahap, keterangan, pelaksana, waktu).

**Panggil ke Kasir** — pada tahap Menunggu Pembayaran, browser mengucapkan (Web Speech API):

> "Perhatian. Atas nama *[nama pelanggan]*, dengan nomor polisi *[plat, dieja per karakter]*, sudah selesai pengerjaan. Silakan ke kasir untuk melakukan pembayaran."

Kalimat dapat diubah di `frontend/src/utils/tts.js` (fungsi `buildCashierCallText`).

### 3.5 Penjualan Sparepart (Retail)

1. Nomor Invoice `SLS-TTTTBBHH-0001` dan tanggal dibuat otomatis saat halaman Tambah Penjualan dibuka.
2. Pilih **Pelanggan Terdaftar** atau **Pelanggan Umum** (walk-in, nama bawaan "Pelanggan Umum").
3. Tambah item sparepart (cari/scan); jumlah tidak boleh melebihi stok, subtotal per item dihitung otomatis, item bisa dihapus sebelum disimpan.
4. Pilih Diskon/Kupon aktif (opsional). Perhitungan: Subtotal → Diskon → Tax Sales → Total.
5. Isi Jumlah Dibayar (≥ Total), kembalian dihitung otomatis.
6. Simpan dalam satu transaksi database: potong stok dan catat Riwayat Stok.
7. Halaman Detail menampilkan Invoice; tersedia Kirim WA (pelanggan terdaftar ber-HP), cetak Invoice, dan Struk Thermal.
8. Hapus transaksi hanya **Admin**; stok dikembalikan otomatis dan dicatat.

### 3.6 Teknisi

- CRUD: nama, keahlian (teks bebas), status Aktif/Tidak Aktif (Tidak Aktif tidak muncul di pilihan Tambah Service).
- Detail: Jadwal (tambah/ubah/hapus manual), Riwayat Service, dan Statistik (total service, jumlah jadwal).
- Akun role Teknisi ditautkan ke satu data teknisi — tautan inilah yang membatasi akses.

### 3.7 Users & Admin

- **Users** (Admin): username, email, role, tautan teknisi, password (bcrypt, minimal 8 karakter), reset password.
- **Pengaturan Aplikasi** (Admin di web; Admin & Staff lewat API/aplikasi mobile): nama/alamat/telepon bengkel, logo (PNG/JPG/WEBP/GIF, maks. 2 MB), ukuran kertas (58/80 mm), cara cetak thermal, pajak Service & Sales, dan **Tes Cetak**.
- **Diskon** (Admin & Staff dapat menambah/mengubah lewat API/aplikasi mobile, hapus hanya Admin; di transaksi Staff memilih diskon aktif): nama, kode kupon (opsional, unik), tipe (Percentage/Nominal), nilai, status, dan cakupan (Semua/Service/Sparepart).

### 3.8 Laporan

| Laporan | Filter | Ringkasan |
|---|---|---|
| Layanan Service | Tanggal mulai–akhir, tampilan *Semua* / *Layanan Paling Laris* | Jumlah service, total biaya, selesai vs berjalan, detail transaksi atau peringkat jenis layanan |
| Penjualan | Tanggal | Total penjualan, total laba, jumlah transaksi & item, detail transaksi |
| Sparepart (paling laris) | Tanggal, sumber *Semua / Service / Penjualan* | Jenis sparepart, total qty & nilai, sparepart terlaris, peringkat dengan qty service, qty penjualan, omzet, dan laba |
| Loyalitas Pelanggan | Tanggal, sumber *Semua / Service / Penjualan* | Total pelanggan, total transaksi, rata-rata transaksi, total belanja, peringkat pelanggan (kunjungan, terakhir datang, status aktif ≤ 90 hari). Hanya service lunas dan penjualan atas nama pelanggan terdaftar |
| Stok | Kategori | Total sparepart, baik/rendah/habis, nilai total stok, detail per sparepart |

Semua laporan dapat dicetak atau disimpan sebagai PDF lewat dialog cetak browser.

### 3.9 Pencetakan & Printer Thermal

Dokumen: Bukti Service Diterima, Tagihan, Invoice Service, Struk Thermal, Work Order, Invoice & Struk Penjualan, serta laporan. Struk dibentuk sebagai perintah **ESC/POS** (32 kolom untuk 58 mm, 48 kolom untuk 80 mm).

Atur di **Admin → Pengaturan Aplikasi**, lalu tekan **Tes Cetak**:

| Mode | Cara kerja | Cocok untuk |
|---|---|---|
| Dialog cetak browser *(bawaan)* | `window.print()` lewat driver | Cadangan / tanpa setup |
| Printer di komputer server (RAW) | Backend mengirim byte ke antrean printer OS | Printer USB di Windows |
| Printer jaringan (IP:9100) | Backend membuka koneksi TCP ke printer | Printer LAN/WiFi |
| USB langsung (WebUSB) | Browser bicara langsung ke printer | Chrome/Edge |
| Serial / Bluetooth COM (Web Serial) | Browser menulis ke port COM | Printer Bluetooth/USB-serial |

- Printer Bluetooth: *pair* di sistem operasi sehingga muncul sebagai port COM, lalu pilih dari Chrome/Edge. Pilihan tersimpan di browser perangkat tersebut.
- Mode RAW dan jaringan dikirim lewat `/api/print/raw` (Admin/Staff); tujuan printer **selalu diambil dari Pengaturan**, bukan dari request, sehingga endpoint tidak bisa dipakai mengirim data ke alamat sembarang.
- RAW dan jaringan membutuhkan backend yang satu komputer/jaringan dengan printer — tidak berfungsi bila backend di cloud.
- WebUSB/Web Serial hanya di Chrome/Edge dan hanya lewat `localhost` atau `https`.
- Jika pengiriman gagal, tampil pesan kesalahan berbahasa Indonesia dan otomatis beralih ke dialog cetak browser.

### 3.10 Supplier

- CRUD pemasok: nama (wajib), kontak person, No. HP, email, alamat, catatan. Akses **Admin dan Staff**.
- Sparepart dapat ditautkan ke satu supplier bawaan; pada Stok Masuk supplier asal barang dicatat di Riwayat Stok.
- Menghapus supplier **tidak** menghapus sparepart maupun riwayat stok — tautan supplier-nya otomatis dilepas (`supplierId` menjadi kosong).

---

## 4. Kebutuhan Nonfungsional

**Keamanan**

- JWT: access token 15 menit + refresh token 7 hari, diperbarui otomatis oleh interceptor Axios. Password di-hash dengan bcrypt (`bcryptjs`).
- RBAC di middleware Express (`authenticate` + `authorize`) pada setiap endpoint; Teknisi dibatasi ke service miliknya. React menambah proteksi route per role.
- Validasi di client dan server (format email/HP, stok, jumlah dibayar); Prisma Client (query berparameter) mencegah SQL Injection.
- Upload logo divalidasi tipe & ukuran maks. 2 MB (Multer).
- Secret JWT dan koneksi database di `.env`; CORS dibatasi ke `CLIENT_URL`.

**Performa**

- Respons API rata-rata < 1 detik untuk CRUD standar.
- Total dihitung instan di client, divalidasi ulang di server.
- Index database (`@@index`) pada kolom yang sering difilter (kode, tanggal, status, no. plat, kategori).

**Kompatibilitas & Usability**

- Responsif (desktop, tablet, mobile) dengan Tailwind CSS.
- Browser modern (Chrome, Firefox, Edge, Safari); cetak langsung WebUSB/Web Serial hanya Chrome/Edge.
- Aplikasi mobile Android (Staff) memakai API dan JWT yang sama dengan web; mendukung mode terang/malam.
- Kode modular: backend (`routes`, `controllers`, `middleware`, `utils`) dan frontend (`pages` per fitur, `components/ui`, `context`, `hooks`, `utils`).
- Antarmuka dan pesan kesalahan berbahasa Indonesia.

---

## 5. Arsitektur Sistem

Web application: **SPA React + Vite** mengonsumsi **REST API Express.js**, dengan **Prisma ORM** ke **PostgreSQL** native (tanpa Docker).

| Layer | Teknologi | Fungsi |
|---|---|---|
| Front-end | React 18, Vite 5, React Router 6, Tailwind CSS 3, Axios, react-icons, `@zxing/browser` | SPA top bar berbasis role, `ProtectedRoute`, pemindai barcode, Panggil ke Kasir (Web Speech API) |
| Back-end | Node.js, Express 4, cors, morgan, dotenv, Multer, express-validator | REST API port 4000: routes → middleware → controllers → utils; logika bisnis dan error handler terpusat |
| ORM | Prisma 5 | Pemetaan model, migrasi, seed, dan operasi atomik via `prisma.$transaction()` |
| Database | PostgreSQL 14+ | Seluruh data aplikasi, dengan index pada kolom yang sering difilter |
| Autentikasi | JWT, bcryptjs, interceptor Axios | `/auth/login`, `/auth/refresh`, `/auth/me`; token sebagai Bearer |
| File Storage | Disk lokal `backend/uploads` + Multer | Logo bengkel, disajikan statis di `/uploads` (DB hanya menyimpan `logoUrl`) |
| Cetak | ESC/POS, WebUSB, Web Serial, TCP 9100, spooler OS | Struk thermal ke USB, Bluetooth, jaringan, atau printer server |
| Integrasi | Tautan WhatsApp (`wa.me`), Web Speech API | Pesan disiapkan backend lalu dikirim manual oleh staff |
| Mobile | Flutter 3, Dio, Provider, `mobile_scanner`, `flutter_blue_plus`, `pdf` + `printing` | Aplikasi Android Staff (`mobile_user/`) yang memakai REST API yang sama |

**API** — REST JSON di `/api/*` (base URL dari `VITE_API_URL`), 17 grup endpoint: `auth`, `users`, `customers`, `vehicle-models`, `vehicles`, `categories`, `suppliers`, `spareparts`, `technicians`, `service-types`, `services`, `sales`, `discounts`, `settings`, `print`, `reports`, `dashboard`, ditambah `/api/health`. Error dikembalikan sebagai `{ "message": "..." }`.

**Alur komunikasi:** React → (Axios + Bearer JWT) → Express memvalidasi token & role, memeriksa payload, menjalankan logika bisnis, menghitung ulang total → Prisma → PostgreSQL. Bila access token kedaluwarsa, interceptor meminta token baru dengan refresh token lalu mengulang request. Operasi multi-tabel (simpan pengerjaan + potong stok + riwayat stok, simpan penjualan, hapus transaksi) dibungkus `prisma.$transaction()` agar atomik.

**Struktur proyek**

```
bengkel-app/
├── backend/      # Express + Prisma API
│   ├── prisma/   #   schema, migrasi, seed
│   └── src/      #   routes, controllers, middleware, utils
├── frontend/     # React + Vite SPA
│   └── src/      #   pages, components/ui, context, hooks, utils
├── mobile_user/  # Aplikasi mobile Flutter (Android, role Staff)
│   └── lib/      #   core, screens, widgets, print
├── database/     # garage_management.sql (struktur + data awal)
└── docs/         # Panduan instalasi, menjalankan, dan deploy
```

---

## 6. Instalasi & Menjalankan

Prasyarat: **Node.js 18+** dan **PostgreSQL 14+**.

| Dokumen | Isi |
|---|---|
| [docs/INSTALASI.md](docs/INSTALASI.md) | Instalasi Node.js, PostgreSQL, backend, frontend, database |
| [docs/MENJALANKAN.md](docs/MENJALANKAN.md) | Menjalankan aplikasi (development & produksi lokal) |
| [docs/DEPLOY.md](docs/DEPLOY.md) | Deploy ke VPS Ubuntu + Nginx + PM2, serta opsi Vercel/Render |
| [database/garage_management.sql](database/garage_management.sql) | File database: struktur tabel + data awal |

### Mulai Cepat

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

Alternatif untuk `prisma:deploy` + `seed`: impor `database/garage_management.sql` (lihat [Opsi B — Impor File SQL](docs/INSTALASI.md#opsi-b--impor-file-sql)).

**Data contoh lengkap** (200 sparepart, 14 kategori, 66 jenis layanan, 83 master kendaraan, 8 teknisi, 25 pelanggan + 29 kendaraan, 8 diskon) ada di `backend/prisma/seed-data/`:

```bash
npm run seed          # isi/perbarui data (aman diulang, tidak menggandakan data)
npm run seed:reset    # HAPUS data master & transaksi lama dulu, lalu isi ulang (user & pengaturan tetap)
```

Tanpa Node/Prisma? Impor `database/data_master.sql` setelah struktur tabel dibuat (dibuat otomatis dari data yang sama lewat `node backend/prisma/export-sql.js`).

### Variabel Lingkungan Penting

| File | Variabel | Keterangan |
|---|---|---|
| `backend/.env` | `DATABASE_URL` | Koneksi PostgreSQL |
| | `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET` | Secret acak yang kuat |
| | `CLIENT_URL` | URL frontend untuk CORS (tanpa `/` di akhir) |
| | `PORT`, `UPLOAD_DIR` | Port API dan folder upload |
| `frontend/.env` | `VITE_API_URL` | Base URL API, mis. `http://localhost:4000/api` |

### Akun Demo

| Username | Password | Role |
|---|---|---|
| admin | admin123 | ADMIN |
| staff | staff123 | STAFF |
| teknisi1 | teknisi123 | TEKNISI |

> ⚠️ Ganti password akun demo dan isi secret JWT yang kuat sebelum dipakai di produksi.

---

## 7. Alur Pengguna

### 7.1 Alur Login

1. User membuka halaman Login, input username/email dan password.
2. Express memvalidasi kredensial (bcrypt compare); bila valid, menerbitkan access & refresh token (JWT berisi `id`, `username`, `role`, `technicianId`).
3. React menyimpan token lalu mengarahkan ke Dashboard: **Admin/Staff** melihat dashboard lengkap, **Teknisi** melihat Dashboard Teknisi (ringkasan layanan) dan hanya dapat membuka service miliknya.

### 7.2 Alur Transaksi Service

```mermaid
flowchart LR
    A[Diterima] -->|Mulai Kerjakan| B[Dikerjakan]
    B -->|Selesai Dikerjakan| C[Menunggu Pembayaran]
    C -->|Konfirmasi Pembayaran| D[Selesai / Lunas]
```

1. Staff pilih/buat **Pelanggan** → tambahkan **Kendaraan** bila belum ada.
2. **Tambah Service**: pilih kendaraan (pemilik & No. WA otomatis), teknisi, tanggal, keluhan → Simpan.
3. Status **Diterima** → Detail Transaksi dengan aksi Kirim WA, Cetak Service Diterima, Mulai Kerjakan, Edit, Hapus.
4. **Mulai Kerjakan** → status **Dikerjakan** → isi KM, jasa, sparepart, rekomendasi & tanggalnya, catatan internal → **Simpan Pekerjaan** (stok terpotong, subtotal dihitung).
5. **Selesai Dikerjakan** (validasi KM + minimal 1 jasa) → status **Menunggu Pembayaran** → halaman Tagihan: periksa/ubah rincian, pilih diskon → Total = setelah Diskon + Pajak. Tersedia Panggil ke Kasir, Cetak Tagihan, Kirim WA.
6. Kasir input **Jumlah Dibayar** → kembalian dihitung → **Konfirmasi Pembayaran** → status **Selesai (Lunas)**, Riwayat Tahapan tercatat.
7. Halaman detail hanya-lihat → Cetak Invoice / Struk Thermal / Work Order dan Kirim WA.

### 7.3 Alur Transaksi Penjualan

1. Staff pilih Pelanggan Terdaftar/Umum → tambah item sparepart & jumlah (cari atau scan barcode).
2. Sistem hitung Subtotal → Diskon → Pajak → Total; input dibayar → hitung kembalian.
3. Simpan → Prisma transaction: insert `SalesTransaction` + `SalesItem`, potong stok, insert `StockHistory`.
4. Tampil Detail Penjualan → Cetak Invoice/Struk Thermal atau Kirim WA.

---

## 8. Risiko dan Mitigasi

| Risiko | Dampak | Mitigasi |
|---|---|---|
| Race condition: 2 transaksi memotong stok yang sama bersamaan | Stok minus/tidak akurat | Cek & potong stok di dalam `prisma.$transaction` (decrement atomik). Bila transaksi bersamaan meningkat: row locking (`SELECT ... FOR UPDATE`) atau isolation level Serializable |
| Kesalahan input harga/diskon | Total tidak sesuai | Validasi & hitung ulang di server; nilai dari client tidak dipercaya sepenuhnya |
| Printer thermal tidak terkoneksi | Struk gagal cetak | Pesan kesalahan + fallback otomatis ke dialog cetak browser; gunakan **Tes Cetak**; pastikan printer Bluetooth sudah di-*pair* di OS |
| Kehilangan data | Data operasional hilang | Backup berkala manual dengan `pg_dump`, disimpan terpisah dari server utama |
| Akses tidak sah ke fitur admin | Perubahan data tidak berwenang | RBAC di setiap endpoint Express + protected route di React |
| HP Staff tidak bisa terhubung ke server (IP berubah / beda jaringan) | Aplikasi mobile tidak bisa dipakai | Gunakan IP tetap/hostname untuk server, satu jaringan WiFi, dan ubah alamat server dari layar Login aplikasi |
| Akun bawaan seed & secret JWT default dipakai di produksi | Akses tidak sah ke seluruh data | Ganti password `admin`, `staff`, `teknisi1` dan isi JWT secret acak di `.env` sebelum go-live |

---

## 9. Skema Database

**Relasi utama:** Customer 1–N Vehicle · VehicleModel 1–N Vehicle · Vehicle 1–N ServiceTransaction · Technician 1–N ServiceTransaction & TechnicianSchedule · User 1–1 Technician (opsional) · ServiceTransaction 1–N ServiceDetail, ServiceSparepart & ServiceLog · Category 1–N Sparepart · Supplier 1–N Sparepart & StockHistory (opsional) · Sparepart 1–N StockHistory, ServiceSparepart & SalesItem · Customer 1–N SalesTransaction (opsional untuk pelanggan umum) · SalesTransaction 1–N SalesItem · Discount 1–N ServiceTransaction & SalesTransaction. Tabel `Settings` hanya berisi satu baris (`id = 1`).

```mermaid
erDiagram
    User |o--o| Technician : "akun teknisi"
    Customer ||--o{ Vehicle : memiliki
    VehicleModel ||--o{ Vehicle : "referensi"
    Vehicle ||--o{ ServiceTransaction : "diservis"
    Technician ||--o{ ServiceTransaction : menangani
    Technician ||--o{ TechnicianSchedule : "jadwal"
    ServiceTransaction ||--o{ ServiceDetail : "jasa"
    ServiceTransaction ||--o{ ServiceSparepart : "sparepart"
    ServiceTransaction ||--o{ ServiceLog : "riwayat tahapan"
    Category ||--o{ Sparepart : mengelompokkan
    Supplier |o--o{ Sparepart : memasok
    Supplier |o--o{ StockHistory : "asal barang masuk"
    Sparepart ||--o{ StockHistory : "riwayat stok"
    Sparepart ||--o{ ServiceSparepart : dipakai
    Sparepart ||--o{ SalesItem : dijual
    Customer |o--o{ SalesTransaction : membeli
    SalesTransaction ||--o{ SalesItem : "item"
    Discount |o--o{ ServiceTransaction : potongan
    Discount |o--o{ SalesTransaction : potongan
```

Skema lengkap (enum, model, index) ada di [`backend/prisma/schema.prisma`](backend/prisma/schema.prisma).

**Enum utama**

| Enum | Nilai |
|---|---|
| `Role` | `ADMIN`, `STAFF`, `TEKNISI` |
| `ServiceStatus` | `DITERIMA`, `DIKERJAKAN`, `MENUNGGU_PEMBAYARAN`, `SELESAI` |
| `StockDirection` / `StockSource` | `MASUK`, `KELUAR` / `MANUAL`, `SERVICE`, `PENJUALAN` |
| `DiscountType` / `DiscountScope` | `PERCENTAGE`, `NOMINAL` / `SEMUA`, `SERVICE`, `SPAREPART` |
| `StatusAktif` | `AKTIF`, `NONAKTIF` |

---

## 10. Troubleshooting

| Masalah | Solusi |
|---|---|
| Error koneksi database | Pastikan PostgreSQL berjalan dan `DATABASE_URL` di `backend/.env` benar |
| CORS error | `CLIENT_URL` di `backend/.env` harus sama persis dengan URL frontend (tanpa `/` di akhir) |
| Port bentrok | Ubah `PORT` di `backend/.env` atau `server.port` di `frontend/vite.config.js` |
| 404 saat refresh setelah deploy | Server harus mengarahkan semua path ke `index.html` (lihat [docs/DEPLOY.md](docs/DEPLOY.md)) |
| Cetak WebUSB/Serial tidak muncul | Gunakan Chrome/Edge lewat `localhost` atau `https` |
| Cetak RAW/jaringan gagal | Backend harus satu komputer/jaringan dengan printer; periksa Pengaturan Aplikasi dan jalankan Tes Cetak |
| Aplikasi mobile tidak bisa login / "tidak terhubung" | Di HP asli ubah alamat server dari layar Login menjadi IP komputer (mis. `192.168.1.10:4000`) — bukan `localhost`; HP dan komputer harus satu WiFi, dan port 4000 tidak diblokir firewall |
| Staff ditolak saat menyimpan diskon/pengaturan dari mobile | Pastikan backend sudah memakai izin `authorize('ADMIN', 'STAFF')` pada `POST/PUT /discounts` dan `PUT/POST/DELETE /settings` (lihat [bagian 2.3](#23-struktur-menu--hak-akses)) |
| Build Android gagal: `this and base files have different roots` | Proyek di drive berbeda dengan Pub Cache (mis. `D:` vs `C:`): tambahkan `kotlin.incremental=false` di `mobile_user/android/gradle.properties`, lalu `flutter clean` |

---

---

## 11. Aplikasi Mobile Staff (`mobile_user`)

Aplikasi Android berbasis **Flutter** untuk Staff/kasir. Memakai **REST API dan akun yang sama** dengan web, sehingga data, stok, dan transaksi selalu sinkron.

> **Khusus role Staff.** Login role lain ditolak. Untuk mengizinkan Admin, ubah `allowedRoles` di `mobile_user/lib/core/config.dart`.

### 11.1 Fitur

| Area | Isi |
|---|---|
| **Beranda** | Statistik per periode (Hari/Minggu/Bulan Ini), **Aksi Cepat** (Service Baru, Jual Sparepart, Pelanggan, Sparepart, Supplier, Scan Stok, Kendaraan, Teknisi), antrian service, stok menipis |
| **Layanan** | Service 4 tahap (Diterima → Dikerjakan → Menunggu Pembayaran → Selesai), Panggil ke Kasir, Kirim WhatsApp, cetak struk, hapus transaksi |
| **Penjualan** | Penjualan sparepart retail, diskon & pajak, kembalian, Kirim Struk via WhatsApp, cetak, hapus transaksi |
| **Sparepart** | Daftar, detail, kategori, **scan barcode** lewat kamera, Stok Masuk/Keluar, Riwayat Stok |
| **Data master** | Pelanggan, Kendaraan & Master Kendaraan, Teknisi, Supplier, Jenis Layanan |
| **Diskon** | Staff dapat **menambah dan mengubah** diskon; hapus hanya Admin |
| **Laporan** | Layanan, Penjualan, Sparepart, Loyalitas, dan Stok (sama dengan web) |
| **Pengaturan Aplikasi** | Logo (unggah/ganti/hapus), nama, alamat, telepon, pajak Service & Sales, **Mode Malam**, dan akses ke Pengaturan Printer |
| **Cetak struk** | Bluetooth (BLE), jaringan WiFi/LAN (IP:port), lewat server, atau dialog cetak/PDF; ukuran kertas 58/80 mm dan Tes Cetak |
| **Lainnya** | Mode demo tanpa server, tampilan terang/malam dan animasi antarmuka yang halus |

### 11.2 Tangkapan Layar

> Nama pelanggan dan nomor HP pada tangkapan layar sudah disamarkan.

**Masuk, Beranda, dan Menu**

<table>
<tr>
<td align="center" valign="top"><img src="docs/screenshots/login.png" width="200" alt="Login Staff"><br><sub><b>Login Staff</b></sub></td>
<td align="center" valign="top"><img src="docs/screenshots/beranda.png" width="200" alt="Beranda & Aksi Cepat"><br><sub><b>Beranda & Aksi Cepat</b></sub></td>
<td align="center" valign="top"><img src="docs/screenshots/menu.png" width="200" alt="Menu"><br><sub><b>Menu</b></sub></td>
<td align="center" valign="top"><img src="docs/screenshots/menu-laporan.png" width="200" alt="Laporan & Aplikasi"><br><sub><b>Laporan & Aplikasi</b></sub></td>
</tr>
</table>

**Alur Service** — buat service → diterima → dikerjakan → pembayaran → selesai

<table>
<tr>
<td align="center" valign="top"><img src="docs/screenshots/layanan-daftar.png" width="200" alt="Daftar Layanan"><br><sub><b>Daftar Layanan</b></sub></td>
<td align="center" valign="top"><img src="docs/screenshots/service-1-baru.png" width="200" alt="1. Service Baru"><br><sub><b>1. Service Baru</b></sub></td>
<td align="center" valign="top"><img src="docs/screenshots/service-2-diterima.png" width="200" alt="2. Diterima"><br><sub><b>2. Diterima</b></sub></td>
</tr>
<tr>
<td align="center" valign="top"><img src="docs/screenshots/service-3-dikerjakan.png" width="200" alt="3. Mulai Dikerjakan"><br><sub><b>3. Mulai Dikerjakan</b></sub></td>
<td align="center" valign="top"><img src="docs/screenshots/service-4-pembayaran.png" width="200" alt="4. Selesai & Pembayaran"><br><sub><b>4. Selesai & Pembayaran</b></sub></td>
<td align="center" valign="top"><img src="docs/screenshots/service-5-lunas.png" width="200" alt="5. Detail (Lunas)"><br><sub><b>5. Detail (Lunas)</b></sub></td>
</tr>
</table>

**Penjualan**

<table>
<tr>
<td align="center" valign="top"><img src="docs/screenshots/penjualan-baru.png" width="200" alt="Penjualan Baru"><br><sub><b>Penjualan Baru</b></sub></td>
<td align="center" valign="top"><img src="docs/screenshots/penjualan-detail.png" width="200" alt="Detail Penjualan"><br><sub><b>Detail Penjualan</b></sub></td>
</tr>
</table>

**Sparepart & Stok**

<table>
<tr>
<td align="center" valign="top"><img src="docs/screenshots/sparepart-daftar.png" width="200" alt="Daftar Sparepart"><br><sub><b>Daftar Sparepart</b></sub></td>
<td align="center" valign="top"><img src="docs/screenshots/sparepart-tambah.png" width="200" alt="Tambah Sparepart"><br><sub><b>Tambah Sparepart</b></sub></td>
<td align="center" valign="top"><img src="docs/screenshots/sparepart-detail.png" width="200" alt="Detail & Riwayat Stok"><br><sub><b>Detail & Riwayat Stok</b></sub></td>
</tr>
<tr>
<td align="center" valign="top"><img src="docs/screenshots/sparepart-stok-masuk.png" width="200" alt="Stok Masuk"><br><sub><b>Stok Masuk</b></sub></td>
<td align="center" valign="top"><img src="docs/screenshots/sparepart-stok-keluar.png" width="200" alt="Stok Keluar"><br><sub><b>Stok Keluar</b></sub></td>
</tr>
</table>

**Pengaturan Aplikasi & Mode Malam**

<table>
<tr>
<td align="center" valign="top"><img src="docs/screenshots/pengaturan-mode-malam.png" width="200" alt="Pengaturan Aplikasi (Mode Malam)"><br><sub><b>Pengaturan Aplikasi (Mode Malam)</b></sub></td>
</tr>
</table>

### 11.3 Menjalankan

Prasyarat: **Flutter 3.x** (Dart 3.4+), Android SDK, dan backend yang sudah berjalan ([bagian 6](#6-instalasi--menjalankan)).

```bash
cd mobile_user
flutter pub get
flutter run                  # HP tersambung USB (debugging USB aktif) atau emulator
```

Alamat server bawaan `http://10.0.2.2:4000` hanya berlaku untuk **emulator** Android. Di HP asli, buka layar **Login → ikon server** lalu isi IP komputer, mis. `192.168.1.10:4000` (satu WiFi, port 4000 terbuka).

Build APK untuk dibagikan ke HP Staff:

```bash
flutter build apk --release
# hasil: mobile_user/build/app/outputs/flutter-apk/app-release.apk
```

Tidak punya server? Pilih **Coba Mode Demo (tanpa server)** di layar Login untuk mencoba tampilan dengan data contoh.

### 11.4 Struktur Folder

```
mobile_user/
├── lib/
│   ├── core/      # api_client (Dio), auth, settings, tema, model, demo_backend
│   ├── screens/   # beranda, layanan, penjualan, sparepart, pelanggan, kendaraan, supplier, diskon, laporan, menu
│   ├── widgets/   # komponen UI (kartu, tombol, kolom isian, scanner, animasi)
│   └── print/     # ESC/POS, PDF, dan pengirim ke printer
├── android/       # konfigurasi Android (izin kamera, Bluetooth, ikon aplikasi)
└── pubspec.yaml
```

### 11.5 Catatan

- **Izin Android:** internet, kamera (scan barcode), dan Bluetooth (printer thermal). Lalu lintas HTTP non-HTTPS diizinkan agar dapat terhubung ke server lokal; gunakan **HTTPS** bila server diakses lewat internet.
- **Logo aplikasi:** ikon di layar HP ditanam saat build (`android/app/src/main/res/mipmap-*`), terpisah dari logo bengkel di Pengaturan Aplikasi.
- **Printer Bluetooth:** dirancang untuk printer thermal BLE (mis. Rongta RPP02N); pilih printer dari Pengaturan Printer lalu jalankan Tes Cetak.

