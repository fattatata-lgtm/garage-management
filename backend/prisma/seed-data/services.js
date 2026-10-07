// Data master Jenis Layanan (jasa). estimatedCost = perkiraan biaya JASA saja (belum termasuk sparepart).
// Format: { name, description, estimatedCost }

const serviceTypes = [
  // ───────── Motor ─────────
  { name: 'Ganti Oli Mesin Motor', description: 'Kuras & ganti oli mesin motor, cek kebocoran dan level oli', estimatedCost: 10000 },
  { name: 'Ganti Oli Gardan Motor Matic', description: 'Kuras & ganti oli gardan (final gear) motor matic', estimatedCost: 10000 },
  { name: 'Servis Ringan Motor', description: 'Cek & setel rem, rantai/CVT, kelistrikan, bersihkan filter udara dan busi', estimatedCost: 50000 },
  { name: 'Servis Lengkap Motor Matic', description: 'Bongkar & bersihkan CVT, cek roller, V-belt, kampas ganda, rem, kelistrikan', estimatedCost: 100000 },
  { name: 'Servis CVT Motor Matic', description: 'Bongkar, bersihkan, dan periksa komponen CVT (roller, V-belt, pully, kampas ganda)', estimatedCost: 75000 },
  { name: 'Tune Up Motor Injeksi', description: 'Scan ECU, bersihkan throttle body, cek busi, filter udara, tekanan bensin', estimatedCost: 80000 },
  { name: 'Tune Up Motor Karburator', description: 'Bersihkan & setel karburator, ganti busi, setel celah klep', estimatedCost: 70000 },
  { name: 'Servis Besar / Turun Mesin Motor', description: 'Overhaul mesin motor: bongkar blok mesin, ganti seher, paking, dan komponen aus', estimatedCost: 650000 },
  { name: 'Ganti Kampas Rem Motor', description: 'Ganti kampas rem depan/belakang motor beserta pembersihan dan penyetelan', estimatedCost: 20000 },
  { name: 'Ganti Ban Motor (per ban)', description: 'Lepas-pasang ban motor, balancing ringan, cek tekanan angin', estimatedCost: 20000 },
  { name: 'Tambal Ban Motor (Tubeless)', description: 'Tambal ban tubeless motor dengan cara tusuk/tambal dalam', estimatedCost: 15000 },
  { name: 'Ganti V-Belt & Roller Motor Matic', description: 'Penggantian V-belt dan roller CVT motor matic', estimatedCost: 60000 },
  { name: 'Ganti Rantai & Gear Set Motor', description: 'Penggantian rantai dan gir depan-belakang, setel kekencangan rantai', estimatedCost: 60000 },
  { name: 'Ganti Aki Motor', description: 'Lepas-pasang aki motor, cek pengisian (kiprok) dan kelistrikan', estimatedCost: 10000 },
  { name: 'Ganti Shockbreaker Motor', description: 'Pemasangan shockbreaker belakang atau depan motor', estimatedCost: 40000 },
  { name: 'Servis Kelistrikan Motor', description: 'Diagnosa & perbaikan kelistrikan: lampu, klakson, starter, pengisian aki', estimatedCost: 60000 },
  { name: 'Ganti Seal Shock Depan Motor', description: 'Bongkar tabung shock depan, ganti seal & oli shock', estimatedCost: 80000 },
  { name: 'Cuci Motor + Poles', description: 'Cuci motor menyeluruh, semir body dan ban', estimatedCost: 20000 },

  // ───────── Mobil – Perawatan Berkala ─────────
  { name: 'Ganti Oli Mesin Mobil', description: 'Kuras & ganti oli mesin mobil, cek kebocoran dan level cairan', estimatedCost: 30000 },
  { name: 'Ganti Oli Transmisi Manual', description: 'Kuras & ganti oli transmisi manual mobil', estimatedCost: 50000 },
  { name: 'Kuras Oli Transmisi Otomatis (ATF)', description: 'Kuras ATF dengan mesin (flushing) dan ganti filter ATF bila perlu', estimatedCost: 250000 },
  { name: 'Servis Berkala Mobil 10.000 KM', description: 'Ganti oli & filter oli, cek rem, kaki-kaki, kelistrikan, dan level cairan', estimatedCost: 200000 },
  { name: 'Servis Berkala Mobil 20.000 KM', description: 'Servis 10.000 KM + ganti filter udara, cek busi, rem, dan sistem pendingin', estimatedCost: 300000 },
  { name: 'Servis Berkala Mobil 40.000 KM', description: 'Servis 20.000 KM + ganti busi, filter bensin, minyak rem, dan cek menyeluruh', estimatedCost: 450000 },
  { name: 'Tune Up Mobil Bensin', description: 'Bersihkan throttle body, ganti busi, filter udara, cek sistem pengapian dan bahan bakar', estimatedCost: 250000 },
  { name: 'Tune Up Mobil Diesel', description: 'Setel injeksi, ganti filter solar & udara, cek kompresi dan sistem bahan bakar', estimatedCost: 350000 },
  { name: 'Servis Injektor Bensin', description: 'Pembersihan injektor dengan alat ultrasonic/flushing', estimatedCost: 350000 },
  { name: 'Scan Komputer / Diagnosa OBD', description: 'Pembacaan kode error ECU dengan scanner OBD dan pemeriksaan sensor', estimatedCost: 100000 },
  { name: 'Ganti Busi Mobil (4 Silinder)', description: 'Penggantian satu set busi mobil, termasuk pembersihan ruang busi', estimatedCost: 60000 },
  { name: 'Ganti Filter Udara & Filter Kabin', description: 'Penggantian filter udara mesin dan filter AC kabin', estimatedCost: 40000 },
  { name: 'Ganti Filter Bensin / Solar', description: 'Penggantian filter bahan bakar dan pembuangan udara sistem', estimatedCost: 50000 },

  // ───────── Mobil – Rem, Kaki-kaki & Ban ─────────
  { name: 'Ganti Kampas Rem Depan Mobil', description: 'Ganti kampas rem cakram depan, bersihkan & lumasi caliper', estimatedCost: 120000 },
  { name: 'Ganti Kampas Rem Belakang Mobil', description: 'Ganti kampas/sepatu rem belakang, bersihkan tromol & setel rem', estimatedCost: 130000 },
  { name: 'Skir Piringan Cakram (per roda)', description: 'Bubut/skir piringan cakram agar rata kembali', estimatedCost: 100000 },
  { name: 'Ganti Minyak Rem & Bleeding', description: 'Kuras & ganti minyak rem, bleeding seluruh saluran rem', estimatedCost: 100000 },
  { name: 'Spooring (Alignment 4 Roda)', description: 'Penyetelan geometri roda (toe, camber, caster) dengan alat komputer', estimatedCost: 150000 },
  { name: 'Balancing Roda (4 Roda)', description: 'Balancing 4 roda mobil dengan mesin balancing', estimatedCost: 140000 },
  { name: 'Spooring + Balancing', description: 'Paket spooring dan balancing 4 roda', estimatedCost: 260000 },
  { name: 'Ganti Ban Mobil (per ban)', description: 'Lepas-pasang ban mobil, termasuk pemasangan pentil dan cek tekanan', estimatedCost: 30000 },
  { name: 'Tambal Ban Tubeless Mobil', description: 'Tambal ban tubeless mobil dengan metode tambal dalam', estimatedCost: 30000 },
  { name: 'Rotasi Ban (4 Roda)', description: 'Rotasi posisi ban untuk keausan merata', estimatedCost: 60000 },
  { name: 'Ganti Shockbreaker Mobil (per pasang)', description: 'Ganti sepasang shockbreaker depan atau belakang', estimatedCost: 200000 },
  { name: 'Ganti Tie Rod & Ball Joint', description: 'Penggantian tie rod end dan ball joint, ditutup dengan spooring', estimatedCost: 250000 },
  { name: 'Ganti Bearing Roda (per roda)', description: 'Penggantian bearing/laker roda depan atau belakang', estimatedCost: 150000 },
  { name: 'Ganti Karet Boot As Roda', description: 'Penggantian boot CV joint, bersihkan dan isi gemuk baru', estimatedCost: 180000 },

  // ───────── Mobil – Pendingin & AC ─────────
  { name: 'Kuras Radiator & Ganti Coolant', description: 'Kuras sistem pendingin dengan flushing dan isi coolant baru', estimatedCost: 150000 },
  { name: 'Isi Freon AC Mobil', description: 'Vakum sistem AC dan isi ulang freon R134a', estimatedCost: 200000 },
  { name: 'Servis AC Mobil (Cuci Evaporator)', description: 'Cuci evaporator & kondensor, cek tekanan, kompresor, dan kebocoran', estimatedCost: 350000 },
  { name: 'Ganti Kompresor AC', description: 'Penggantian kompresor AC, receiver dryer, vakum, dan isi freon', estimatedCost: 500000 },
  { name: 'Ganti Water Pump & Thermostat', description: 'Penggantian water pump dan thermostat, kuras dan isi coolant baru', estimatedCost: 350000 },

  // ───────── Mobil – Mesin, Transmisi & Kelistrikan ─────────
  { name: 'Ganti Timing Belt', description: 'Penggantian timing belt, tensioner, dan roller (sesuai interval pabrikan)', estimatedCost: 450000 },
  { name: 'Ganti Fan Belt', description: 'Penggantian tali kipas / serpentine belt dan cek tensioner', estimatedCost: 80000 },
  { name: 'Ganti Paking Kepala Silinder', description: 'Turun kepala silinder, ganti head gasket, skir kepala bila diperlukan', estimatedCost: 1500000 },
  { name: 'Ganti Kopling Mobil (Satu Set)', description: 'Bongkar transmisi, ganti plat kopling, matahari, dan bearing', estimatedCost: 800000 },
  { name: 'Overhaul Mesin Mobil', description: 'Turun mesin lengkap: ganti ring piston, bearing, paking, skir blok & kepala silinder', estimatedCost: 5000000 },
  { name: 'Ganti Aki Mobil', description: 'Lepas-pasang aki, cek sistem pengisian (alternator) dan kebersihan terminal', estimatedCost: 30000 },
  { name: 'Servis Alternator / Dinamo Ampere', description: 'Bongkar, cek, dan ganti arang serta bearing alternator', estimatedCost: 250000 },
  { name: 'Servis Dinamo Starter', description: 'Bongkar, bersihkan, ganti bendix/arang starter', estimatedCost: 250000 },
  { name: 'Ganti Engine Mounting', description: 'Penggantian dudukan mesin untuk mengurangi getaran', estimatedCost: 250000 },
  { name: 'Servis Kelistrikan Mobil', description: 'Diagnosa & perbaikan kelistrikan: lampu, power window, central lock, wiring', estimatedCost: 150000 },
  { name: 'Ganti Lampu Utama / Sein', description: 'Penggantian bohlam lampu depan, belakang, atau sein', estimatedCost: 25000 },
  { name: 'Ganti Wiper Blade', description: 'Pemasangan wiper blade baru depan/belakang', estimatedCost: 10000 },

  // ───────── Lain-lain ─────────
  { name: 'Cuci Mobil Steam + Vakum Interior', description: 'Cuci steam, vakum interior, semir ban, dan dashboard', estimatedCost: 60000 },
  { name: 'Poles Body & Wax Mobil', description: 'Poles body mobil menghilangkan baret halus, lapis wax pelindung', estimatedCost: 400000 },
  { name: 'Pengecekan Menyeluruh (General Check-up)', description: 'Inspeksi lengkap mesin, rem, kaki-kaki, kelistrikan, dan cairan sebelum perjalanan jauh', estimatedCost: 100000 },
  { name: 'Derek / Towing Dalam Kota', description: 'Layanan derek kendaraan mogok ke bengkel dalam kota', estimatedCost: 250000 },
];

module.exports = { serviceTypes };
