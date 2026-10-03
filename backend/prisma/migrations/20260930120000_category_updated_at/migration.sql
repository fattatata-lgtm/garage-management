-- AlterTable
-- Baris lama diisi dengan createdAt agar "Diperbarui pada" tidak kosong.
ALTER TABLE "Category" ADD COLUMN "updatedAt" TIMESTAMP(3);
UPDATE "Category" SET "updatedAt" = "createdAt";
ALTER TABLE "Category" ALTER COLUMN "updatedAt" SET NOT NULL;
