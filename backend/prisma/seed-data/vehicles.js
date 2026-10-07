// Data master kendaraan (merk/model/tahun/tipe/roda) — pasar Indonesia.
// Format: [merk, model, tahun, tipe, roda]

const vehicleModels = [
  // ───────── Toyota ─────────
  ['Toyota', 'Avanza', 2012, 'MPV', 4],
  ['Toyota', 'Avanza', 2019, 'MPV', 4],
  ['Toyota', 'Avanza', 2022, 'MPV', 4],
  ['Toyota', 'Veloz', 2022, 'MPV', 4],
  ['Toyota', 'Agya', 2017, 'LCGC Hatchback', 4],
  ['Toyota', 'Agya', 2023, 'LCGC Hatchback', 4],
  ['Toyota', 'Calya', 2016, 'LCGC MPV', 4],
  ['Toyota', 'Rush', 2018, 'SUV', 4],
  ['Toyota', 'Kijang Innova Reborn', 2016, 'MPV', 4],
  ['Toyota', 'Kijang Innova Reborn', 2020, 'MPV', 4],
  ['Toyota', 'Fortuner', 2016, 'SUV', 4],
  ['Toyota', 'Fortuner', 2021, 'SUV', 4],
  ['Toyota', 'Yaris', 2018, 'Hatchback', 4],
  ['Toyota', 'Raize', 2021, 'SUV', 4],
  ['Toyota', 'Hilux Double Cabin', 2020, 'Double Cabin', 4],

  // ───────── Daihatsu ─────────
  ['Daihatsu', 'Xenia', 2012, 'MPV', 4],
  ['Daihatsu', 'Xenia', 2019, 'MPV', 4],
  ['Daihatsu', 'Xenia', 2022, 'MPV', 4],
  ['Daihatsu', 'Sigra', 2017, 'LCGC MPV', 4],
  ['Daihatsu', 'Ayla', 2017, 'LCGC Hatchback', 4],
  ['Daihatsu', 'Ayla', 2023, 'LCGC Hatchback', 4],
  ['Daihatsu', 'Terios', 2018, 'SUV', 4],
  ['Daihatsu', 'Rocky', 2022, 'SUV', 4],
  ['Daihatsu', 'Gran Max Pick Up', 2015, 'Pick Up', 4],
  ['Daihatsu', 'Gran Max Blind Van', 2018, 'Blind Van', 4],

  // ───────── Honda (Mobil) ─────────
  ['Honda', 'Brio Satya', 2018, 'LCGC Hatchback', 4],
  ['Honda', 'Brio RS', 2020, 'Hatchback', 4],
  ['Honda', 'Jazz', 2014, 'Hatchback', 4],
  ['Honda', 'Mobilio', 2016, 'MPV', 4],
  ['Honda', 'BR-V', 2022, 'SUV', 4],
  ['Honda', 'HR-V', 2018, 'SUV', 4],
  ['Honda', 'CR-V', 2019, 'SUV', 4],
  ['Honda', 'City Hatchback RS', 2021, 'Hatchback', 4],

  // ───────── Honda (Motor) ─────────
  ['Honda', 'Beat', 2016, 'Motor Matic', 2],
  ['Honda', 'Beat', 2021, 'Motor Matic', 2],
  ['Honda', 'Beat Street', 2020, 'Motor Matic', 2],
  ['Honda', 'Scoopy', 2021, 'Motor Matic', 2],
  ['Honda', 'Vario 125', 2019, 'Motor Matic', 2],
  ['Honda', 'Vario 125', 2022, 'Motor Matic', 2],
  ['Honda', 'Vario 160', 2022, 'Motor Matic', 2],
  ['Honda', 'Genio', 2021, 'Motor Matic', 2],
  ['Honda', 'PCX 160', 2022, 'Motor Matic', 2],
  ['Honda', 'Revo', 2015, 'Motor Bebek', 2],
  ['Honda', 'Supra X 125', 2018, 'Motor Bebek', 2],
  ['Honda', 'CB150R', 2019, 'Motor Sport', 2],
  ['Honda', 'CRF150L', 2021, 'Motor Trail', 2],

  // ───────── Suzuki ─────────
  ['Suzuki', 'Ertiga', 2016, 'MPV', 4],
  ['Suzuki', 'Ertiga', 2019, 'MPV', 4],
  ['Suzuki', 'XL7', 2020, 'SUV', 4],
  ['Suzuki', 'Baleno', 2018, 'Hatchback', 4],
  ['Suzuki', 'Swift', 2014, 'Hatchback', 4],
  ['Suzuki', 'APV', 2012, 'MPV', 4],
  ['Suzuki', 'Carry Pick Up', 2015, 'Pick Up', 4],
  ['Suzuki', 'Satria F150', 2016, 'Motor Sport', 2],
  ['Suzuki', 'Nex II', 2020, 'Motor Matic', 2],
  ['Suzuki', 'Address', 2019, 'Motor Matic', 2],

  // ───────── Mitsubishi ─────────
  ['Mitsubishi', 'Xpander', 2018, 'MPV', 4],
  ['Mitsubishi', 'Xpander', 2021, 'MPV', 4],
  ['Mitsubishi', 'Pajero Sport', 2017, 'SUV', 4],
  ['Mitsubishi', 'Triton', 2019, 'Double Cabin', 4],
  ['Mitsubishi', 'L300', 2016, 'Pick Up', 4],
  ['Mitsubishi', 'Mirage', 2014, 'Hatchback', 4],

  // ───────── Nissan, Isuzu, Wuling ─────────
  ['Nissan', 'Grand Livina', 2013, 'MPV', 4],
  ['Nissan', 'March', 2014, 'Hatchback', 4],
  ['Isuzu', 'Panther', 2010, 'MPV', 4],
  ['Isuzu', 'D-Max', 2018, 'Double Cabin', 4],
  ['Isuzu', 'Elf NMR', 2016, 'Truk Ringan', 4],
  ['Wuling', 'Confero', 2018, 'MPV', 4],

  // ───────── Yamaha ─────────
  ['Yamaha', 'NMAX', 2020, 'Motor Matic', 2],
  ['Yamaha', 'NMAX', 2023, 'Motor Matic', 2],
  ['Yamaha', 'Aerox 155', 2021, 'Motor Matic', 2],
  ['Yamaha', 'Mio M3', 2018, 'Motor Matic', 2],
  ['Yamaha', 'Fino 125', 2020, 'Motor Matic', 2],
  ['Yamaha', 'Gear 125', 2022, 'Motor Matic', 2],
  ['Yamaha', 'Lexi', 2021, 'Motor Matic', 2],
  ['Yamaha', 'Vixion', 2016, 'Motor Sport', 2],
  ['Yamaha', 'R15', 2019, 'Motor Sport', 2],
  ['Yamaha', 'XSR 155', 2021, 'Motor Sport', 2],
  ['Yamaha', 'Jupiter Z1', 2015, 'Motor Bebek', 2],
  ['Yamaha', 'Vega Force', 2014, 'Motor Bebek', 2],

  // ───────── Kawasaki ─────────
  ['Kawasaki', 'Ninja 250', 2018, 'Motor Sport', 2],
  ['Kawasaki', 'KLX 150', 2019, 'Motor Trail', 2],
  ['Kawasaki', 'W175', 2020, 'Motor Retro', 2],
];

module.exports = { vehicleModels };
