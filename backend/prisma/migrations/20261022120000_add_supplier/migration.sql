-- CreateTable
CREATE TABLE "Supplier" (
    "id" SERIAL NOT NULL,
    "name" TEXT NOT NULL,
    "contactPerson" TEXT,
    "phone" TEXT,
    "email" TEXT,
    "address" TEXT,
    "note" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Supplier_pkey" PRIMARY KEY ("id")
);

-- AlterTable
ALTER TABLE "Sparepart" ADD COLUMN "supplierId" INTEGER;
ALTER TABLE "StockHistory" ADD COLUMN "supplierId" INTEGER;

-- CreateIndex
CREATE INDEX "Supplier_name_idx" ON "Supplier"("name");
CREATE INDEX "Sparepart_supplierId_idx" ON "Sparepart"("supplierId");
CREATE INDEX "StockHistory_supplierId_idx" ON "StockHistory"("supplierId");

-- AddForeignKey
ALTER TABLE "Sparepart" ADD CONSTRAINT "Sparepart_supplierId_fkey" FOREIGN KEY ("supplierId") REFERENCES "Supplier"("id") ON DELETE SET NULL ON UPDATE CASCADE;
ALTER TABLE "StockHistory" ADD CONSTRAINT "StockHistory_supplierId_fkey" FOREIGN KEY ("supplierId") REFERENCES "Supplier"("id") ON DELETE SET NULL ON UPDATE CASCADE;
