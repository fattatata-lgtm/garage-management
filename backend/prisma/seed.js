const { PrismaClient } = require('@prisma/client');
const bcrypt = require('bcryptjs');

const prisma = new PrismaClient();

async function main() {
  console.log('Seeding data awal...');

  // Settings
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

  // Admin user
  const adminPass = await bcrypt.hash('admin123', 10);
  await prisma.user.upsert({
    where: { username: 'admin' },
    update: {},
    create: { username: 'admin', email: 'admin@selfautomotive.test', password: adminPass, role: 'ADMIN' },
  });

  // Staff user
  const staffPass = await bcrypt.hash('staff123', 10);
  await prisma.user.upsert({
    where: { username: 'staff' },
    update: {},
    create: { username: 'staff', email: 'staff@selfautomotive.test', password: staffPass, role: 'STAFF' },
  });

  // Contoh teknisi + akun teknisi
  const technician = await prisma.technician.upsert({
    where: { id: 1 },
    update: {},
    create: { id: 1, name: 'Budi Santoso', skill: 'Mesin, Kelistrikan', status: 'AKTIF' },
  });
  const teknisiPass = await bcrypt.hash('teknisi123', 10);
  await prisma.user.upsert({
    where: { username: 'teknisi1' },
    update: {},
    create: {
      username: 'teknisi1', email: 'teknisi1@selfautomotive.test',
      password: teknisiPass, role: 'TEKNISI', technicianId: technician.id,
    },
  });

  // Data master kendaraan contoh
  await prisma.vehicleModel.upsert({
    where: { id: 1 },
    update: {},
    create: { id: 1, brand: 'Toyota', model: 'Avanza', year: 2020, type: 'MPV', wheels: 4 },
  });
  await prisma.vehicleModel.upsert({
    where: { id: 2 },
    update: {},
    create: { id: 2, brand: 'Honda', model: 'Beat', year: 2021, type: 'Motor Matic', wheels: 2 },
  });

  // Kategori & sparepart contoh
  const kategoriOli = await prisma.category.upsert({
    where: { name: 'Oli' }, update: {}, create: { name: 'Oli' },
  });
  const kategoriBan = await prisma.category.upsert({
    where: { name: 'Ban' }, update: {}, create: { name: 'Ban' },
  });

  await prisma.sparepart.upsert({
    where: { code: 'OLI-001' },
    update: {},
    create: {
      code: 'OLI-001', name: 'Oli Mesin 4T 1L', categoryId: kategoriOli.id,
      buyPrice: 35000, sellPrice: 55000, stock: 50, lowStockThreshold: 10,
    },
  });
  await prisma.sparepart.upsert({
    where: { code: 'BAN-001' },
    update: {},
    create: {
      code: 'BAN-001', name: 'Ban Motor Ring 14', categoryId: kategoriBan.id,
      buyPrice: 180000, sellPrice: 250000, stock: 8, lowStockThreshold: 5,
    },
  });

  // Jenis service contoh
  await prisma.serviceType.createMany({
    data: [
      { name: 'Ganti Oli', description: 'Ganti oli mesin', estimatedCost: 50000 },
      { name: 'Servis Rutin', description: 'Pengecekan & penyetelan rutin', estimatedCost: 100000 },
      { name: 'Tune Up', description: 'Penyetelan performa mesin', estimatedCost: 150000 },
    ],
    skipDuplicates: true,
  });

  console.log('Seeding selesai.');
  console.log('Login admin   : admin / admin123');
  console.log('Login staff   : staff / staff123');
  console.log('Login teknisi : teknisi1 / teknisi123');
}

main()
  .catch((e) => { console.error(e); process.exit(1); })
  .finally(async () => { await prisma.$disconnect(); });
