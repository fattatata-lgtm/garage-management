-- AlterTable
-- Cara kirim struk thermal (BROWSER = dialog cetak browser seperti sebelumnya) dan nama printer di OS server.
ALTER TABLE "Settings" ADD COLUMN "printerConnection" TEXT NOT NULL DEFAULT 'BROWSER';
ALTER TABLE "Settings" ADD COLUMN "printerName" TEXT;
