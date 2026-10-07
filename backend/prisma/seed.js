// Seed data awal Aplikasi Bengkel "Self Automotive".
//
//   npm run seed         -> isi/perbarui data master (aman dijalankan berulang, tidak menggandakan data)
//   npm run seed:reset   -> HAPUS data master & transaksi lama dulu (pelanggan, kendaraan, sparepart,
//                           layanan, teknisi, diskon, semua transaksi), lalu isi ulang dengan data bersih.
//                           Akun user & pengaturan aplikasi TIDAK dihapus.
//
// Isi data ada di folder prisma/seed-data/ (mudah diedit).

const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');
const { categories, spareparts } = require('./seed-data/spareparts');
const { serviceTypes } = require('./seed-data/services');
const { vehicleModels } = require('./seed-data/vehicles');
const { technicians, customers, discounts } = require('./seed-data/people');

const prisma = new PrismaClient();
const RESET = process.argv.includes('--reset');

async function resetData() {
  console.log('Mode RESET: menghapus data master & transaksi lama...');
  // Putuskan tautan akun teknisi sebelum data teknisi dihapus
  await prisma.user.updateMany({ data: { technicianId: null } });

  // Urutan hapus mengikuti relasi (anak dulu, baru induk)
  await prisma.serviceLog.deleteMany();
  await prisma.serviceSparepart.deleteMany();
  await prisma.serviceDetail.deleteMany();
  await prisma.serviceTransaction.deleteMany();
  await prisma.salesItem.deleteMany();
  await prisma.salesTransaction.deleteMany();
  await prisma.stockHistory.deleteMany();
  await prisma.sparepart.deleteMany();
  await prisma.category.deleteMany();
  await prisma.vehicle.deleteMany();
  await prisma.vehicleModel.deleteMany();
  await prisma.customer.deleteMany();
  await prisma.technicianSchedule.deleteMany();
  await prisma.technician.deleteMany();
  await prisma.serviceType.deleteMany();
  await prisma.discount.deleteMany();
}

async function seedUsersAndSettings() {
  await prisma.settings.upsert({
    where: { id: 1 },
    update: {},
    create: {
      id: 1,
      businessName: 'Self Automotive',
      address: 'Jl. Raya Bengkel No. 1',
      phone: '021-1234567',
      taxService: 10,
      taxSales: 10,
    },
  });

  const users = [
    { username: 'admin', email: 'admin@selfautomotive.test', pass: 'admin123', role: 'ADMIN' },
    { username: 'staff', email: 'staff@selfautomotive.test', pass: 'staff123', role: 'STAFF' },
    { username: 'teknisi1', email: 'teknisi1@selfautomotive.test', pass: 'teknisi123', role: 'TEKNISI' },
  ];
  for (const u of users) {
    await prisma.user.upsert({
      where: { username: u.username },
      update: {},
      create: { username: u.username, email: u.email, password: await bcrypt.hash(u.pass, 10), role: u.role },
    });
  }
}

async function seedTechnicians() {
  const byName = {};
  for (const t of technicians) {
    let row = await prisma.technician.findFirst({ where: { name: t.name } });
    if (row) row = await prisma.technician.update({ where: { id: row.id }, data: { skill: t.skill, status: t.status } });
    else row = await prisma.technician.create({ data: t });
    byName[t.name] = row;
  }
  // Tautkan akun teknisi1 ke teknisi pertama (jika belum tertaut)
  const teknisi1 = await prisma.user.findUnique({ where: { username: 'teknisi1' } });
  const first = byName[technicians[0].name];
  if (teknisi1 && !teknisi1.technicianId) {
    const taken = await prisma.user.findUnique({ where: { technicianId: first.id } });
    if (!taken) await prisma.user.update({ where: { id: teknisi1.id }, data: { technicianId: first.id } });
  }
  console.log(`  Teknisi        : ${technicians.length}`);
}

async function seedCategoriesAndSpareparts() {
  const catId = {};
  for (const name of categories) {
    const c = await prisma.category.upsert({ where: { name }, update: {}, create: { name } });
    catId[name] = c.id;
  }

  let created = 0, updated = 0;
  for (const [code, name, cat, buyPrice, sellPrice, stock, lowStockThreshold] of spareparts) {
    const existing = await prisma.sparepart.findUnique({ where: { code } });
    if (existing) {
      // Perbarui nama/kategori/harga, TAPI jangan ubah stok yang sudah berjalan
      await prisma.sparepart.update({
        where: { code },
        data: { name, categoryId: catId[cat], buyPrice, sellPrice, lowStockThreshold },
      });
      updated++;
    } else {
      const sp = await prisma.sparepart.create({
        data: { code, name, categoryId: catId[cat], buyPrice, sellPrice, stock, lowStockThreshold },
      });
      if (stock > 0) {
        await prisma.stockHistory.create({
          data: { sparepartId: sp.id, direction: 'MASUK', source: 'MANUAL', quantity: stock, note: 'Stok awal' },
        });
      }
      created++;
    }
  }
  console.log(`  Kategori       : ${categories.length}`);
  console.log(`  Sparepart      : ${spareparts.length} (baru ${created}, diperbarui ${updated})`);
}

async function seedServiceTypes() {
  for (const s of serviceTypes) {
    const existing = await prisma.serviceType.findFirst({ where: { name: s.name } });
    if (existing) await prisma.serviceType.update({ where: { id: existing.id }, data: s });
    else await prisma.serviceType.create({ data: s });
  }
  console.log(`  Jenis layanan  : ${serviceTypes.length}`);
}

async function seedVehicleModels() {
  const idByKey = {};
  for (const [brand, model, year, type, wheels] of vehicleModels) {
    let row = await prisma.vehicleModel.findFirst({ where: { brand, model, year } });
    if (row) row = await prisma.vehicleModel.update({ where: { id: row.id }, data: { type, wheels } });
    else row = await prisma.vehicleModel.create({ data: { brand, model, year, type, wheels } });
    idByKey[`${brand}|${model}|${year}`] = row.id;
  }
  console.log(`  Master kendaraan: ${vehicleModels.length}`);
  return idByKey;
}

async function seedCustomersAndVehicles(modelId) {
  let vehicleCount = 0;
  for (const c of customers) {
    let cust = await prisma.customer.findFirst({ where: { name: c.name, phone: c.phone } });
    if (!cust) {
      cust = await prisma.customer.create({
        data: { name: c.name, phone: c.phone, email: c.email, address: c.address },
      });
    }
    for (const v of c.vehicles) {
      const vehicleModelId = modelId[v.model];
      if (!vehicleModelId) throw new Error(`Model kendaraan tidak ditemukan: ${v.model}`);
      await prisma.vehicle.upsert({
        where: { plateNumber: v.plate },
        update: {},
        create: {
          customerId: cust.id,
          vehicleModelId,
          plateNumber: v.plate,
          color: v.color,
          purchaseYear: v.purchaseYear,
          note: v.note || null,
        },
      });
      vehicleCount++;
    }
  }
  console.log(`  Pelanggan      : ${customers.length}`);
  console.log(`  Kendaraan      : ${vehicleCount}`);
}

async function seedDiscounts() {
  for (const d of discounts) {
    await prisma.discount.upsert({ where: { code: d.code }, update: d, create: d });
  }
  console.log(`  Diskon/kupon   : ${discounts.length}`);
}

async function main() {
  console.log('Seeding data awal...');
  if (RESET) await resetData();

  await seedUsersAndSettings();
  await seedTechnicians();
  await seedCategoriesAndSpareparts();
  await seedServiceTypes();
  const modelId = await seedVehicleModels();
  await seedCustomersAndVehicles(modelId);
  await seedDiscounts();

  console.log('Seeding selesai.');
  console.log('Login admin   : admin / admin123');
  console.log('Login staff   : staff / staff123');
  console.log('Login teknisi : teknisi1 / teknisi123');
}

main()
  .catch((e) => { console.error(e); process.exit(1); })
  .finally(async () => { await prisma.$disconnect(); });
