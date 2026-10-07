// Data contoh teknisi, pelanggan + kendaraan, dan diskon.
// Kendaraan merujuk ke vehicleModels lewat kunci 'Merk|Model|Tahun'.

const technicians = [
  { name: 'Budi Santoso', skill: 'Mesin, Kelistrikan', status: 'AKTIF' }, // ditautkan ke akun teknisi1
  { name: 'Agus Setiawan', skill: 'Mesin Mobil, Overhaul, Tune Up', status: 'AKTIF' },
  { name: 'Rudi Hartono', skill: 'Motor Matic, Injeksi, CVT', status: 'AKTIF' },
  { name: 'Dedi Kurniawan', skill: 'Kaki-kaki, Spooring, Balancing, Rem', status: 'AKTIF' },
  { name: 'Eko Prasetyo', skill: 'AC Mobil, Kelistrikan Mobil, Scan OBD', status: 'AKTIF' },
  { name: 'Slamet Riyadi', skill: 'Transmisi, Kopling, Diesel', status: 'AKTIF' },
  { name: 'Yoga Pratama', skill: 'Servis Ringan Motor, Ganti Oli, Ban', status: 'AKTIF' },
  { name: 'Hendra Wijaya', skill: 'Motor Sport, Karburator', status: 'NONAKTIF' },
];

const customers = [
  { name: 'Ahmad Fauzi', phone: '0812-3456-7801', email: 'ahmad.fauzi@gmail.com', address: 'Jl. Melati No. 12, RT 03/RW 05',
    vehicles: [{ model: 'Toyota|Avanza|2019', plate: 'B 1234 KFA', color: 'Silver', purchaseYear: 2019 }] },
  { name: 'Siti Nurhaliza', phone: '0813-2211-4402', email: 'siti.nurhaliza@gmail.com', address: 'Jl. Kenanga No. 7, Perumahan Griya Asri Blok C2',
    vehicles: [{ model: 'Honda|Beat|2021', plate: 'B 3345 TQL', color: 'Putih', purchaseYear: 2021 }] },
  { name: 'Rizky Pratama', phone: '0857-9001-3321', email: null, address: 'Jl. Cempaka Raya No. 45',
    vehicles: [
      { model: 'Yamaha|NMAX|2020', plate: 'B 6721 UCD', color: 'Hitam', purchaseYear: 2020 },
      { model: 'Honda|Brio RS|2020', plate: 'B 1902 SRP', color: 'Merah', purchaseYear: 2020 },
    ] },
  { name: 'Dewi Lestari', phone: '0821-5567-8890', email: 'dewi.lestari@yahoo.com', address: 'Jl. Anggrek No. 3, RT 01/RW 02',
    vehicles: [{ model: 'Honda|Vario 125|2022', plate: 'B 4410 FDE', color: 'Merah Doff', purchaseYear: 2022 }] },
  { name: 'Hendra Gunawan', phone: '0878-1234-5566', email: 'hendra.gunawan@gmail.com', address: 'Jl. Pahlawan No. 88',
    vehicles: [{ model: 'Toyota|Kijang Innova Reborn|2016', plate: 'B 2788 PHG', color: 'Hitam', purchaseYear: 2016 }] },
  { name: 'Putri Maharani', phone: '0896-7788-1203', email: null, address: 'Jl. Dahlia No. 21, Komplek Taman Sari',
    vehicles: [{ model: 'Daihatsu|Ayla|2023', plate: 'B 5521 NJM', color: 'Kuning', purchaseYear: 2023 }] },
  { name: 'Bambang Sutrisno', phone: '0811-2299-3344', email: 'bambang.s@gmail.com', address: 'Jl. Raya Industri No. 150',
    vehicles: [{ model: 'Mitsubishi|L300|2016', plate: 'B 9087 UYZ', color: 'Hitam', purchaseYear: 2016, note: 'Kendaraan operasional usaha, servis rutin tiap 5.000 KM' }] },
  { name: 'Wulan Sari', phone: '0852-3344-9981', email: 'wulan.sari@gmail.com', address: 'Jl. Teratai No. 19, RT 06/RW 03',
    vehicles: [{ model: 'Honda|Scoopy|2021', plate: 'B 3012 WLS', color: 'Cream', purchaseYear: 2021 }] },
  { name: 'Yusuf Maulana', phone: '0838-4455-6612', email: null, address: 'Jl. Merdeka No. 5',
    vehicles: [{ model: 'Suzuki|Ertiga|2019', plate: 'B 7766 KYM', color: 'Putih', purchaseYear: 2019 }] },
  { name: 'Indah Permata', phone: '0813-9988-2271', email: 'indah.permata@gmail.com', address: 'Jl. Flamboyan No. 14, Perumahan Bumi Indah',
    vehicles: [{ model: 'Toyota|Raize|2021', plate: 'B 1450 IPR', color: 'Oranye', purchaseYear: 2021 }] },
  { name: 'Teguh Wibowo', phone: '0819-6677-8123', email: 'teguh.wibowo@gmail.com', address: 'Jl. Gatot Subroto No. 102',
    vehicles: [{ model: 'Mitsubishi|Pajero Sport|2017', plate: 'B 8821 TGW', color: 'Putih', purchaseYear: 2017 }] },
  { name: 'Nur Aisyah', phone: '0877-2211-0045', email: null, address: 'Jl. Kamboja No. 27',
    vehicles: [{ model: 'Yamaha|Aerox 155|2021', plate: 'B 6032 NAA', color: 'Biru', purchaseYear: 2021 }] },
  { name: 'Fajar Nugroho', phone: '0856-1122-3399', email: 'fajar.nugroho@gmail.com', address: 'Jl. Sudirman No. 63, RT 04/RW 01',
    vehicles: [
      { model: 'Toyota|Fortuner|2021', plate: 'B 1111 FJN', color: 'Hitam Metalik', purchaseYear: 2021 },
      { model: 'Honda|PCX 160|2022', plate: 'B 3199 FJN', color: 'Abu-abu', purchaseYear: 2022 },
    ] },
  { name: 'Lina Marlina', phone: '0822-7733-4456', email: 'lina.marlina@yahoo.com', address: 'Jl. Bougenville No. 9',
    vehicles: [{ model: 'Daihatsu|Xenia|2012', plate: 'B 2290 LNM', color: 'Silver', purchaseYear: 2012 }] },
  { name: 'Eko Susanto', phone: '0813-4400-5566', email: null, address: 'Jl. Veteran No. 31',
    vehicles: [{ model: 'Honda|Supra X 125|2018', plate: 'B 4075 EKS', color: 'Hitam', purchaseYear: 2018 }] },
  { name: 'Mega Wati', phone: '0895-3321-7788', email: 'mega.wati@gmail.com', address: 'Jl. Seruni No. 16, Komplek Mutiara',
    vehicles: [{ model: 'Toyota|Agya|2017', plate: 'B 1688 MGW', color: 'Merah', purchaseYear: 2017 }] },
  { name: 'Andi Saputra', phone: '0821-9911-2233', email: 'andi.saputra@gmail.com', address: 'Jl. Pemuda No. 74',
    vehicles: [{ model: 'Yamaha|Vixion|2016', plate: 'B 5309 ADS', color: 'Hitam', purchaseYear: 2016 }] },
  { name: 'CV Maju Jaya Logistik', phone: '021-5566-7788', email: 'admin@majujayalogistik.test', address: 'Jl. Raya Pergudangan Blok D No. 8',
    vehicles: [
      { model: 'Daihatsu|Gran Max Pick Up|2015', plate: 'B 9501 BXA', color: 'Putih', purchaseYear: 2015, note: 'Armada operasional perusahaan (1/3)' },
      { model: 'Suzuki|Carry Pick Up|2015', plate: 'B 9502 BXA', color: 'Putih', purchaseYear: 2015, note: 'Armada operasional perusahaan (2/3)' },
      { model: 'Isuzu|Elf NMR|2016', plate: 'B 9503 BXA', color: 'Kuning', purchaseYear: 2016, note: 'Armada operasional perusahaan (3/3)' },
    ] },
  { name: 'Rina Kartika', phone: '0812-6655-4432', email: 'rina.kartika@gmail.com', address: 'Jl. Mawar No. 52, RT 02/RW 07',
    vehicles: [{ model: 'Honda|HR-V|2018', plate: 'B 2054 RNK', color: 'Putih', purchaseYear: 2018 }] },
  { name: 'Doni Setiawan', phone: '0857-2200-1199', email: null, address: 'Jl. Kartini No. 40',
    vehicles: [{ model: 'Kawasaki|Ninja 250|2018', plate: 'B 3777 DNS', color: 'Hijau', purchaseYear: 2018 }] },
  { name: 'Ayu Wulandari', phone: '0878-9090-4567', email: 'ayu.wulandari@gmail.com', address: 'Jl. Cut Nyak Dien No. 11',
    vehicles: [{ model: 'Mitsubishi|Xpander|2021', plate: 'B 1832 AYW', color: 'Abu-abu', purchaseYear: 2021 }] },
  { name: 'Joko Widodo Prasetyo', phone: '0813-1020-3040', email: 'joko.prasetyo@gmail.com', address: 'Jl. Diponegoro No. 29',
    vehicles: [{ model: 'Isuzu|Panther|2010', plate: 'B 8190 JWP', color: 'Hijau Tua', purchaseYear: 2010, note: 'Mesin diesel, perlu cek rutin filter solar' }] },
  { name: 'Citra Dewi', phone: '0838-7766-5544', email: 'citra.dewi@gmail.com', address: 'Jl. Sawo No. 8, Perumahan Citra Garden',
    vehicles: [{ model: 'Honda|Genio|2021', plate: 'B 4902 CTD', color: 'Pink', purchaseYear: 2021 }] },
  { name: 'Hasan Basri', phone: '0852-1100-9988', email: null, address: 'Jl. Jambu No. 23',
    vehicles: [{ model: 'Suzuki|APV|2012', plate: 'B 7120 HSB', color: 'Hitam', purchaseYear: 2012 }] },
  { name: 'Maya Anggraini', phone: '0899-6655-3322', email: 'maya.anggraini@gmail.com', address: 'Jl. Pelita No. 6, RT 05/RW 04',
    vehicles: [{ model: 'Toyota|Veloz|2022', plate: 'B 1201 MYA', color: 'Putih', purchaseYear: 2022 }] },
];

const discounts = [
  { name: 'Diskon Pelanggan Baru', code: 'BARU25', type: 'NOMINAL', value: 25000, scope: 'SEMUA', status: 'AKTIF' },
  { name: 'Diskon Member 5%', code: 'MEMBER5', type: 'PERCENTAGE', value: 5, scope: 'SEMUA', status: 'AKTIF' },
  { name: 'Hemat Jasa Service 10%', code: 'SERVIS10', type: 'PERCENTAGE', value: 10, scope: 'SERVICE', status: 'AKTIF' },
  { name: 'Potongan Servis Berkala Rp50.000', code: 'BERKALA50', type: 'NOMINAL', value: 50000, scope: 'SERVICE', status: 'AKTIF' },
  { name: 'Diskon Sparepart 5%', code: 'PART5', type: 'PERCENTAGE', value: 5, scope: 'SPAREPART', status: 'AKTIF' },
  { name: 'Potongan Oli Rp10.000', code: 'OLI10', type: 'NOMINAL', value: 10000, scope: 'SPAREPART', status: 'AKTIF' },
  { name: 'Promo Akhir Tahun 15%', code: 'AKHIRTAHUN15', type: 'PERCENTAGE', value: 15, scope: 'SEMUA', status: 'NONAKTIF' },
  { name: 'Promo Lebaran Rp100.000', code: 'LEBARAN100', type: 'NOMINAL', value: 100000, scope: 'SEMUA', status: 'NONAKTIF' },
];

module.exports = { technicians, customers, discounts };
