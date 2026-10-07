// Membuat database/data_master.sql dari data di prisma/seed-data/.
// Dipakai bila Anda deploy lewat impor SQL (mis. Neon) dan tidak menjalankan `npm run seed`.
//   node prisma/export-sql.js
const fs = require('fs');
const path = require('path');
const { categories, spareparts } = require('./seed-data/spareparts');
const { serviceTypes } = require('./seed-data/services');
const { vehicleModels } = require('./seed-data/vehicles');
const { technicians, customers, discounts } = require('./seed-data/people');

const q = (v) => (v === null || v === undefined ? 'NULL' : typeof v === 'number' ? String(v) : `'${String(v).replace(/'/g, "''")}'`);
const rows = (arr) => arr.map((r) => `  (${r.map(q).join(', ')})`).join(',\n');

const out = [];
out.push(`-- =============================================================================
-- Garage Management - Data Master (sparepart, layanan, kendaraan, teknisi, pelanggan, diskon)
-- DIBUAT OTOMATIS dari backend/prisma/seed-data/ lewat: node backend/prisma/export-sql.js
--
-- Cara impor (setelah struktur tabel ada / garage_management.sql sudah diimpor):
--   psql -U bengkel_user -d bengkel_db -f database/data_master.sql
--
-- Aman dijalankan berulang: data yang sama diperbarui, bukan digandakan.
-- Stok sparepart yang sudah berjalan TIDAK diubah.
-- Harga & kode adalah contoh realistis - sesuaikan dengan harga supplier Anda.
--
-- Ingin mulai dari data bersih? Hapus data lama dulu (blok di bawah, lepas komentarnya).
-- Akun user & pengaturan aplikasi tidak ikut dihapus.
-- =============================================================================

-- BEGIN;
-- UPDATE "User" SET "technicianId" = NULL;
-- DELETE FROM "ServiceLog"; DELETE FROM "ServiceSparepart"; DELETE FROM "ServiceDetail"; DELETE FROM "ServiceTransaction";
-- DELETE FROM "SalesItem"; DELETE FROM "SalesTransaction"; DELETE FROM "StockHistory";
-- DELETE FROM "Sparepart"; DELETE FROM "Category"; DELETE FROM "Vehicle"; DELETE FROM "VehicleModel";
-- DELETE FROM "Customer"; DELETE FROM "TechnicianSchedule"; DELETE FROM "Technician";
-- DELETE FROM "ServiceType"; DELETE FROM "Discount";
-- COMMIT;

BEGIN;
`);

// Teknisi
out.push(`-- Teknisi (${technicians.length})
UPDATE "Technician" t SET skill = v.skill, status = v.status::"StatusAktif", "updatedAt" = CURRENT_TIMESTAMP
FROM (VALUES
${rows(technicians.map((t) => [t.name, t.skill, t.status]))}
) AS v(name, skill, status) WHERE t.name = v.name;

INSERT INTO "Technician" (name, skill, status, "updatedAt")
SELECT v.name, v.skill, v.status::"StatusAktif", CURRENT_TIMESTAMP
FROM (VALUES
${rows(technicians.map((t) => [t.name, t.skill, t.status]))}
) AS v(name, skill, status)
WHERE NOT EXISTS (SELECT 1 FROM "Technician" t WHERE t.name = v.name);

-- Tautkan akun teknisi1 ke teknisi pertama (bila belum tertaut)
UPDATE "User" SET "technicianId" = (SELECT id FROM "Technician" WHERE name = ${q(technicians[0].name)} ORDER BY id LIMIT 1)
WHERE username = 'teknisi1' AND "technicianId" IS NULL
  AND NOT EXISTS (SELECT 1 FROM "User" u2 WHERE u2."technicianId" = (SELECT id FROM "Technician" WHERE name = ${q(technicians[0].name)} ORDER BY id LIMIT 1));
`);

// Kategori + sparepart
out.push(`-- Kategori (${categories.length})
INSERT INTO "Category" (name, "updatedAt") VALUES
${categories.map((c) => `  (${q(c)}, CURRENT_TIMESTAMP)`).join(',\n')}
ON CONFLICT (name) DO NOTHING;
`);

const spRows = rows(spareparts);
out.push(`-- Sparepart (${spareparts.length})
INSERT INTO "Sparepart" (code, name, "categoryId", "buyPrice", "sellPrice", stock, "lowStockThreshold", "updatedAt")
SELECT v.code, v.name, c.id, v.buy, v.sell, v.stock, v.low, CURRENT_TIMESTAMP
FROM (VALUES
${spRows}
) AS v(code, name, cat, buy, sell, stock, low)
JOIN "Category" c ON c.name = v.cat
ON CONFLICT (code) DO UPDATE SET
  name = EXCLUDED.name, "categoryId" = EXCLUDED."categoryId",
  "buyPrice" = EXCLUDED."buyPrice", "sellPrice" = EXCLUDED."sellPrice",
  "lowStockThreshold" = EXCLUDED."lowStockThreshold", "updatedAt" = CURRENT_TIMESTAMP;

-- Riwayat stok awal (hanya untuk sparepart yang belum punya riwayat)
INSERT INTO "StockHistory" ("sparepartId", direction, source, quantity, note)
SELECT s.id, 'MASUK'::"StockDirection", 'MANUAL'::"StockSource", s.stock, 'Stok awal'
FROM "Sparepart" s
WHERE s.code IN (${spareparts.map((s) => q(s[0])).join(', ')})
  AND s.stock > 0
  AND NOT EXISTS (SELECT 1 FROM "StockHistory" h WHERE h."sparepartId" = s.id);
`);

// Jenis layanan
const stRows = rows(serviceTypes.map((s) => [s.name, s.description, s.estimatedCost]));
out.push(`-- Jenis layanan (${serviceTypes.length})
UPDATE "ServiceType" t SET description = v.description, "estimatedCost" = v.cost
FROM (VALUES
${stRows}
) AS v(name, description, cost) WHERE t.name = v.name;

INSERT INTO "ServiceType" (name, description, "estimatedCost")
SELECT v.name, v.description, v.cost
FROM (VALUES
${stRows}
) AS v(name, description, cost)
WHERE NOT EXISTS (SELECT 1 FROM "ServiceType" t WHERE t.name = v.name);
`);

// Master kendaraan
out.push(`-- Master kendaraan (${vehicleModels.length})
UPDATE "VehicleModel" m SET type = v.type, wheels = v.wheels
FROM (VALUES
${rows(vehicleModels)}
) AS v(brand, model, year, type, wheels)
WHERE m.brand = v.brand AND m.model = v.model AND m.year = v.year;

INSERT INTO "VehicleModel" (brand, model, year, type, wheels)
SELECT v.brand, v.model, v.year, v.type, v.wheels
FROM (VALUES
${rows(vehicleModels)}
) AS v(brand, model, year, type, wheels)
WHERE NOT EXISTS (SELECT 1 FROM "VehicleModel" m WHERE m.brand = v.brand AND m.model = v.model AND m.year = v.year);
`);

// Pelanggan
const custRows = rows(customers.map((c) => [c.name, c.phone, c.email, c.address]));
out.push(`-- Pelanggan (${customers.length})
INSERT INTO "Customer" (name, phone, email, address, "updatedAt")
SELECT v.name, v.phone, v.email, v.address, CURRENT_TIMESTAMP
FROM (VALUES
${custRows}
) AS v(name, phone, email, address)
WHERE NOT EXISTS (SELECT 1 FROM "Customer" c WHERE c.name = v.name AND c.phone = v.phone);
`);

// Kendaraan pelanggan
const vRows = [];
for (const c of customers) {
  for (const v of c.vehicles) {
    const [brand, model, year] = v.model.split('|');
    vRows.push([c.name, c.phone, brand, model, Number(year), v.plate, v.color, v.purchaseYear, v.note || null]);
  }
}
out.push(`-- Kendaraan pelanggan (${vRows.length})
INSERT INTO "Vehicle" ("customerId", "vehicleModelId", "plateNumber", color, "purchaseYear", note, "updatedAt")
SELECT
  (SELECT MIN(c.id) FROM "Customer" c WHERE c.name = v.cname AND c.phone = v.cphone),
  (SELECT MIN(m.id) FROM "VehicleModel" m WHERE m.brand = v.brand AND m.model = v.model AND m.year = v.year),
  v.plate, v.color, v."purchaseYear", v.note, CURRENT_TIMESTAMP
FROM (VALUES
${rows(vRows)}
) AS v(cname, cphone, brand, model, year, plate, color, "purchaseYear", note)
ON CONFLICT ("plateNumber") DO NOTHING;
`);

// Diskon
out.push(`-- Diskon / kupon (${discounts.length})
INSERT INTO "Discount" (name, code, type, value, scope, status)
SELECT v.name, v.code, v.type::"DiscountType", v.value, v.scope::"DiscountScope", v.status::"StatusAktif"
FROM (VALUES
${rows(discounts.map((d) => [d.name, d.code, d.type, d.value, d.scope, d.status]))}
) AS v(name, code, type, value, scope, status)
ON CONFLICT (code) DO UPDATE SET
  name = EXCLUDED.name, type = EXCLUDED.type, value = EXCLUDED.value,
  scope = EXCLUDED.scope, status = EXCLUDED.status;
`);

out.push('COMMIT;\n');

const target = path.join(__dirname, '..', '..', 'database', 'data_master.sql');
fs.writeFileSync(target, out.join('\n'));
console.log('Tertulis:', target);
