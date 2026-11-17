// Data master supplier. Nama, kontak, dan alamat di bawah adalah CONTOH — ganti dengan supplier asli bengkel Anda.
// Format: { name, contactPerson, phone, email, address, note }

const suppliers = [
  {
    name: 'CV Sumber Pelumas Jaya',
    contactPerson: 'Hendro Wibowo',
    phone: '0812-3456-1001',
    email: 'order@sumberpelumasjaya.test',
    address: 'Jl. Rungkut Industri Raya No. 21, Surabaya, Jawa Timur',
    note: 'Oli mesin, oli gardan, ATF, CVT fluid, dan cairan/aditif. Kirim H+1, minimal order 1 dus.',
  },
  {
    name: 'PT Filtrasi Mandiri Utama',
    contactPerson: 'Linda Kusuma',
    phone: '0813-5566-1002',
    email: 'sales@filtrasimandiri.test',
    address: 'Jl. Raya Bekasi KM 28 No. 5, Bekasi, Jawa Barat',
    note: 'Filter oli, udara, bensin, solar, dan kabin untuk motor & mobil. Termin 14 hari.',
  },
  {
    name: 'UD Ban Makmur Abadi',
    contactPerson: 'Sugeng Raharjo',
    phone: '0857-2200-1003',
    email: 'banmakmur@example.test',
    address: 'Jl. Gajah Mada No. 88, Semarang, Jawa Tengah',
    note: 'Ban luar/dalam, velg, dan ventil. Bisa tukar tambah ban bekas.',
  },
  {
    name: 'CV Prima Rem Nusantara',
    contactPerson: 'Ahmad Fauzi',
    phone: '0821-7788-1004',
    email: 'prima.rem@example.test',
    address: 'Jl. Kopo Permai No. 14, Bandung, Jawa Barat',
    note: 'Kampas rem, cakram, minyak rem, serta kopling dan komponen transmisi. Garansi 1 bulan.',
  },
  {
    name: 'PT Daya Aki Sentosa',
    contactPerson: 'Maria Setiawati',
    phone: '0811-9900-1005',
    email: 'penjualan@dayaaki.test',
    address: 'Jl. Margomulyo Indah Blok C No. 9, Surabaya, Jawa Timur',
    note: 'Aki, busi, koil, lampu, relay, sekring, dan kelistrikan. Garansi aki 6 bulan.',
  },
  {
    name: 'CV Sinar Suspensi Motor',
    contactPerson: 'Rizky Maulana',
    phone: '0878-4433-1006',
    email: 'sinarsuspensi@example.test',
    address: 'Jl. Ahmad Yani No. 150, Malang, Jawa Timur',
    note: 'Shock breaker, tie rod, ball joint, bushing, serta V-belt, rantai, dan gear set.',
  },
  {
    name: 'PT Dingin Jaya Teknik',
    contactPerson: 'Yudi Hermawan',
    phone: '0819-6655-1007',
    email: 'cs@dinginjayateknik.test',
    address: 'Jl. Daan Mogot KM 11 No. 32, Jakarta Barat, DKI Jakarta',
    note: 'Radiator, kompresor, freon, dan komponen AC mobil. Termin 30 hari.',
  },
  {
    name: 'UD Mesin Karya Mandiri',
    contactPerson: 'Bambang Suprapto',
    phone: '0856-1122-1008',
    email: 'mesinkarya@example.test',
    address: 'Jl. Dr. Soetomo No. 7, Kediri, Jawa Timur',
    note: 'Paking, seal, piston kit, engine mounting, serta aksesoris dan perlengkapan perawatan.',
  },
];

// Kategori sparepart -> nama supplier utamanya
const supplierByCategory = {
  'Oli & Pelumas': 'CV Sumber Pelumas Jaya',
  'Cairan & Aditif': 'CV Sumber Pelumas Jaya',
  'Filter': 'PT Filtrasi Mandiri Utama',
  'Ban & Velg': 'UD Ban Makmur Abadi',
  'Rem': 'CV Prima Rem Nusantara',
  'Kopling & Transmisi': 'CV Prima Rem Nusantara',
  'Aki & Kelistrikan': 'PT Daya Aki Sentosa',
  'Busi & Pengapian': 'PT Daya Aki Sentosa',
  'Lampu': 'PT Daya Aki Sentosa',
  'Suspensi & Kaki-kaki': 'CV Sinar Suspensi Motor',
  'Belt, Rantai & Gear': 'CV Sinar Suspensi Motor',
  'Pendingin & AC': 'PT Dingin Jaya Teknik',
  'Mesin & Gasket': 'UD Mesin Karya Mandiri',
  'Aksesoris & Perawatan': 'UD Mesin Karya Mandiri',
};

module.exports = { suppliers, supplierByCategory };
