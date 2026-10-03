# Cara Deploy ke Server

Dua cara deploy tersedia:

- **[Cara A: VPS Ubuntu](#cara-a--vps-ubuntu-nginx--pm2)** (disarankan): satu server menjalankan database, backend, dan frontend.
  Semua fitur berfungsi, termasuk upload logo yang awet.
- **[Cara B: Vercel + Render + Neon](#cara-b--vercel--render--neon)**: gratis/murah dan tanpa mengelola server,
  tetapi ada batasan (lihat bagian akhir).

---

## Cara A: VPS Ubuntu (Nginx + PM2)

Diuji untuk Ubuntu 22.04 / 24.04. Butuh VPS (1 GB RAM cukup) dan, sebaiknya, sebuah domain yang sudah
diarahkan (A record) ke IP server. Contoh di bawah memakai domain `bengkel.example.com`; ganti sesuai domain Anda.

### 1. Persiapan server
```bash
ssh root@IP_SERVER
apt update && apt upgrade -y

# (disarankan) buat user biasa
adduser deploy && usermod -aG sudo deploy
su - deploy
```

Install paket yang dibutuhkan:
```bash
# Node.js 20
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt install -y nodejs git nginx postgresql postgresql-contrib

# PM2 (penjaga proses)
sudo npm install -g pm2
```

Firewall:
```bash
sudo ufw allow OpenSSH
sudo ufw allow 'Nginx Full'
sudo ufw enable
```
Port 4000 (backend) **tidak** dibuka ke publik; Nginx yang meneruskan permintaan ke sana.

### 2. Database
```bash
sudo -u postgres psql
```
```sql
CREATE USER bengkel_user WITH PASSWORD 'GANTI_PASSWORD_KUAT';
CREATE DATABASE bengkel_db OWNER bengkel_user;
\q
```

### 3. Ambil kode
```bash
sudo mkdir -p /var/www && sudo chown $USER:$USER /var/www
cd /var/www
git clone https://github.com/fattatata-lgtm/garage-management.git
cd garage-management
```

### 4. Backend
```bash
cd backend
cp .env.example .env
nano .env
```
Isi minimal:
```
DATABASE_URL="postgresql://bengkel_user:GANTI_PASSWORD_KUAT@localhost:5432/bengkel_db?schema=public"
PORT=4000
NODE_ENV=production
JWT_ACCESS_SECRET="<hasil node -e ... di bawah>"
JWT_REFRESH_SECRET="<hasil lain, berbeda>"
JWT_ACCESS_EXPIRES="15m"
JWT_REFRESH_EXPIRES="7d"
CLIENT_URL="https://bengkel.example.com"
UPLOAD_DIR="uploads"
```
Membuat secret acak (jalankan dua kali, satu untuk tiap secret):
```bash
node -e "console.log(require('crypto').randomBytes(48).toString('hex'))"
```

Pasang, buat tabel, isi data awal, lalu jalankan:
```bash
npm ci
npm run prisma:deploy          # atau impor database/garage_management.sql (lihat INSTALASI.md)
npm run seed                   # data awal + akun demo

pm2 start src/server.js --name garage-api
pm2 save
pm2 startup                    # jalankan perintah sudo yang ditampilkan agar otomatis hidup saat reboot
```
Pastikan `pm2 start` dijalankan **dari folder `backend`**, karena folder `uploads` dihitung dari direktori kerja.

Cek: `curl http://localhost:4000/api/health` harus menjawab `{"status":"ok",...}`.

### 5. Frontend (build statis)
```bash
cd ../frontend
cp .env.example .env
nano .env
```
Isi:
```
VITE_API_URL=https://bengkel.example.com/api
```
Nilai ini ditanam saat build, jadi **build ulang** setiap kali diubah.
```bash
npm ci
npm run build                  # hasil: frontend/dist
```

### 6. Nginx
```bash
sudo nano /etc/nginx/sites-available/garage-management
```
Isi:
```nginx
server {
    listen 80;
    server_name bengkel.example.com;

    root /var/www/garage-management/frontend/dist;
    index index.html;

    client_max_body_size 5m;   # upload logo

    # API backend
    location /api/ {
        proxy_pass http://127.0.0.1:4000;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }

    # File upload (logo)
    location /uploads/ {
        proxy_pass http://127.0.0.1:4000;
    }

    # Frontend SPA: semua path diarahkan ke index.html
    location / {
        try_files $uri /index.html;
    }
}
```
Aktifkan:
```bash
sudo ln -s /etc/nginx/sites-available/garage-management /etc/nginx/sites-enabled/
sudo nginx -t
sudo systemctl reload nginx
```

### 7. HTTPS (Let's Encrypt)
```bash
sudo apt install -y certbot python3-certbot-nginx
sudo certbot --nginx -d bengkel.example.com
```
HTTPS **wajib** bila ingin memakai scan barcode (kamera), WebUSB, dan Web Serial di browser.

Buka https://bengkel.example.com lalu login. **Segera ganti password akun demo** (menu Users), atau hapus akun
yang tidak dipakai.

> Tanpa domain (hanya IP): pakai `server_name _;`, `VITE_API_URL=http://IP_SERVER/api`, dan
> `CLIENT_URL=http://IP_SERVER`. Fitur yang butuh HTTPS (kamera, WebUSB) tidak akan berjalan.

### Memperbarui aplikasi
```bash
cd /var/www/garage-management
git pull

cd backend
npm ci
npm run prisma:deploy
pm2 restart garage-api

cd ../frontend
npm ci
npm run build
```
Tidak perlu me-restart Nginx, karena `dist` dibaca langsung.

### Backup database
Simpan password di `~/.pgpass` agar tanpa prompt:
```bash
echo "localhost:5432:bengkel_db:bengkel_user:GANTI_PASSWORD_KUAT" > ~/.pgpass
chmod 600 ~/.pgpass
mkdir -p ~/backup
```
Backup manual:
```bash
pg_dump -h localhost -U bengkel_user bengkel_db | gzip > ~/backup/bengkel_$(date +%F).sql.gz
```
Backup otomatis tiap hari pukul 02.00 (`crontab -e`):
```
0 2 * * * pg_dump -h localhost -U bengkel_user bengkel_db | gzip > $HOME/backup/bengkel_$(date +\%F).sql.gz
```
Cadangkan juga folder `backend/uploads` (logo). Pulihkan dengan:
```bash
gunzip -c ~/backup/bengkel_2026-10-03.sql.gz | psql -h localhost -U bengkel_user -d bengkel_db
```
(database tujuan harus kosong).

### Perintah PM2 yang berguna
```bash
pm2 status                    # daftar proses
pm2 logs garage-api           # log
pm2 restart garage-api        # restart
```

### Cetak ke printer di server
Mode cetak RAW (printer terpasang di komputer server) dan printer jaringan hanya bekerja bila backend satu
komputer/jaringan dengan printer. Untuk VPS di internet, gunakan mode **Dialog cetak browser**, **USB langsung
(WebUSB)**, atau **Serial/Bluetooth** (dari browser kasir, via HTTPS). Jika bengkel butuh cetak langsung ke
printer jaringan, jalankan backend di komputer bengkel (lihat [MENJALANKAN.md](MENJALANKAN.md)).

---

## Cara B: Vercel + Render + Neon

Frontend di **Vercel**, backend di **Render**, database di **Neon**. Urutan: database, backend, frontend.

### 1. Database (Neon)
1. Daftar di https://neon.tech lalu buat project baru.
2. Salin *connection string* (`postgresql://...`) sebagai `DATABASE_URL`.

### 2. Backend (Render)
1. Di https://render.com: **New → Web Service**, hubungkan repo `garage-management`.
2. Pengaturan:
   - **Root Directory**: `backend`
   - **Build Command**: `npm install && npx prisma generate && npx prisma migrate deploy`
   - **Start Command**: `npm start`
3. **Environment Variables**: `DATABASE_URL`, `NODE_ENV=production`, `JWT_ACCESS_SECRET`, `JWT_REFRESH_SECRET`,
   `JWT_ACCESS_EXPIRES=15m`, `JWT_REFRESH_EXPIRES=7d`, `UPLOAD_DIR=uploads`, dan `CLIENT_URL` (isi setelah langkah 3).
4. Setelah deploy, buka `https://NAMA-ANDA.onrender.com/api/health`.
5. Isi data awal sekali saja: dari komputer Anda, isi `DATABASE_URL` Neon di `backend/.env` lalu jalankan
   `npm run seed`, atau impor `database/garage_management.sql` ke Neon.

### 3. Frontend (Vercel)
File `frontend/vercel.json` sudah disertakan agar halaman tidak 404 saat di-refresh.
1. Di https://vercel.com: **Add New → Project**, pilih repo `garage-management`.
2. **Root Directory**: `frontend`, **Framework Preset**: Vite.
3. **Environment Variables**: `VITE_API_URL` = `https://NAMA-ANDA.onrender.com/api`.
4. Klik **Deploy**.

### 4. Hubungkan
Isi `CLIENT_URL` di Render dengan URL Vercel (mis. `https://garage-management.vercel.app`, tanpa garis miring di akhir),
lalu simpan agar backend restart. Tanpa ini login akan gagal karena CORS.

### Batasan Cara B
- **Logo yang diupload hilang** saat Render restart/deploy ulang (disk gratis bersifat sementara). Gunakan Render Disk
  (berbayar) atau penyimpanan eksternal.
- **Backend gratis tertidur** sekitar 15 menit tanpa trafik; request pertama setelahnya bisa lambat 30-60 detik.
- **Cetak ke printer server/jaringan tidak tersedia** (lihat catatan printer di atas).

---

## Daftar Periksa Sebelum Go-Live

- [ ] `JWT_ACCESS_SECRET` dan `JWT_REFRESH_SECRET` diganti dengan string acak yang kuat
- [ ] Password database bukan `bengkel_pass`
- [ ] Password akun demo (`admin`, `staff`, `teknisi1`) diganti atau akunnya dihapus
- [ ] `CLIENT_URL` sama persis dengan alamat frontend
- [ ] HTTPS aktif
- [ ] File `.env` tidak ada di GitHub (sudah dikecualikan oleh `.gitignore`)
- [ ] Backup database terjadwal
