# Self Automotive — Aplikasi Staff (Flutter / Android)

Aplikasi HP untuk **role Staff** yang memakai backend Express + Prisma yang sama dengan versi web
(tidak ada perubahan backend). Navigasi memakai **Bottom Navigation Bar**:

| Tab | Isi |
|---|---|
| **Beranda** | Dashboard: pendapatan (hari/minggu/bulan), aksi cepat, antrian service, tagihan menunggu, alert stok, service terbaru |
| **Layanan** | Daftar + filter status, form, detail alur 4 tahap (Diterima → Dikerjakan → Menunggu Pembayaran → Lunas), Panggil ke Kasir, WhatsApp |
| **Penjualan** | Daftar, kasir penjualan sparepart (scan barcode, diskon, pajak, kembalian), detail |
| **Sparepart** | Daftar + scan barcode, filter kategori/supplier/stok, tambah/edit (dengan supplier), stok masuk (pilih supplier)/keluar, riwayat |
| **Menu** | Pelanggan, Kendaraan (filter Merk/Model/Roda), Teknisi, **Supplier**, Jenis Layanan, Master Kendaraan, **Diskon** (STAFF: lihat; ADMIN: tambah/ubah/hapus), Kategori, Riwayat Stok, **5 Laporan** (Layanan + Layanan Terlaris, Penjualan, Sparepart, Loyalitas, Stok), alamat server, keluar |

Hanya akun **STAFF** yang bisa login (ubah di `lib/core/config.dart` → `allowedRoles`).

## 1. Prasyarat
- Flutter SDK 3.22 atau lebih baru (`flutter doctor` harus hijau untuk Android)
- Backend berjalan, dan HP + komputer di **WiFi yang sama**
- Windows Firewall: izinkan port **4000** (inbound) untuk Node.js

## 2. Proyek
Proyek Flutter sudah lengkap di folder ini (`lib/`, `android/`, `web/`). Cukup jalankan `flutter pub get` sekali.
Catatan: `pubspec.yaml` memakai `dependency_overrides: archive ^4.0.10`.

## 3a. Lihat cepat di browser (tanpa HP)
```bash
flutter run -d chrome
```
Di layar Login pilih **Coba Mode Demo**. Bluetooth, kamera, dan cetak jaringan langsung tidak berfungsi di browser; cetak PDF tetap bisa.
Jika proyek dibuat sebelum ada platform web, jalankan sekali: `flutter create --platforms web .` di folder ini.

## 3. Menjalankan & membuat APK
```bash
flutter run                      # HP tersambung USB (mode debug)
flutter build apk --release      # hasil: build/app/outputs/flutter-apk/app-release.apk
```
Kirim file `app-release.apk` ke HP lalu install (izinkan "install dari sumber tidak dikenal").

## 3b. Cek tampilan TANPA backend (Mode Demo)
Di layar Login tekan **Coba Mode Demo (tanpa server)**. App terisi data contoh (pelanggan, service di tiap tahap, stok, penjualan, laporan). Tambah/ubah/bayar tetap berfungsi selama sesi, tetapi data hilang saat app ditutup. Keluar dari demo lewat Menu → Keluar.

## 4. Menyambungkan ke server
Di layar Login ketuk **Server** → isi `IP-komputer:4000` (mis. `192.168.1.10:4000`) → **Tes Koneksi** → **Simpan**.
Cek IP komputer dengan `ipconfig` (Windows) / `ip a` (Linux). Emulator Android memakai `10.0.2.2:4000`.
Akun demo: `staff` / `staff123`.

> Jika server memakai HTTPS, tulis alamat lengkap `https://...`. HTTP biasa sudah diizinkan lewat manifest.

## 4b. Cetak struk & invoice
Sama seperti web, tersedia:
- **Invoice A4 (PDF)**: Cetak Invoice (service lunas & penjualan) dan Tagihan. Muncul dialog cetak Android; bisa juga *Simpan sebagai PDF*.
- **Struk thermal 58/80 mm**: Struk lunas, Tagihan, Bukti Service Diterima, Work Order, Struk Penjualan.
- **Laporan**: tombol cetak (ikon printer) di Laporan menyimpan/mencetak PDF lengkap.

Atur cara kirim di **Menu → Pengaturan Printer**:
| Mode | Keterangan |
|---|---|
| Ikuti pengaturan server | Memakai mode printer di Admin > Pengaturan (jaringan / komputer server → lewat server; lainnya → PDF) |
| Bluetooth | Kirim langsung ke printer thermal BLE (mis. Rongta RPP02N). Tekan *Cari & Pilih Printer* |
| Jaringan WiFi/LAN | Kirim langsung ke IP:9100 printer jaringan |
| Lewat server | Server meneruskan ke printer yang diatur di Pengaturan Aplikasi |
| PDF | Tanpa printer thermal: dialog cetak / simpan PDF |

Bila printer gagal, struk otomatis ditampilkan sebagai PDF (cadangan). Gunakan **Cetak Tes** untuk menguji.
Printer Bluetooth harus mendukung **BLE**; printer yang hanya Bluetooth klasik tidak muncul saat pencarian (pakai mode jaringan/server).

## 5. Yang belum dipindahkan dari web
- Cetak thermal via USB langsung (WebUSB/Serial) — tidak tersedia di HP; pakai Bluetooth, jaringan, atau server.
- Menu khusus Admin (Users, Pengaturan, Diskon) — sesuai permintaan, app ini hanya untuk Staff.

## Struktur kode
```
lib/
  core/      api_client (JWT + auto refresh), models, auth/settings provider, tema, format Rupiah
  widgets/   komponen bersama: kartu, chip status, AsyncBody (pull-to-refresh), picker, scanner
  screens/   dashboard, shell (bottom bar), login, services/, sales/, spareparts/, customers/, vehicles/, more/
```
