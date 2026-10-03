-- CreateEnum
CREATE TYPE "Role" AS ENUM ('ADMIN', 'STAFF', 'TEKNISI');

-- CreateEnum
CREATE TYPE "StockDirection" AS ENUM ('MASUK', 'KELUAR');

-- CreateEnum
CREATE TYPE "StockSource" AS ENUM ('MANUAL', 'SERVICE', 'PENJUALAN');

-- CreateEnum
CREATE TYPE "ServiceStatus" AS ENUM ('DITERIMA', 'DIKERJAKAN', 'SELESAI');

-- CreateEnum
CREATE TYPE "DiscountType" AS ENUM ('PERCENTAGE', 'NOMINAL');

-- CreateEnum
CREATE TYPE "DiscountScope" AS ENUM ('SEMUA', 'SERVICE', 'SPAREPART');

-- CreateEnum
CREATE TYPE "StatusAktif" AS ENUM ('AKTIF', 'NONAKTIF');

-- CreateTable
CREATE TABLE "User" (
    "id" SERIAL NOT NULL,
    "username" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "password" TEXT NOT NULL,
    "role" "Role" NOT NULL DEFAULT 'STAFF',
    "isActive" BOOLEAN NOT NULL DEFAULT true,
    "technicianId" INTEGER,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "User_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Customer" (
    "id" SERIAL NOT NULL,
    "name" TEXT NOT NULL,
    "phone" TEXT NOT NULL,
    "email" TEXT,
    "address" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Customer_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "VehicleModel" (
    "id" SERIAL NOT NULL,
    "brand" TEXT NOT NULL,
    "model" TEXT NOT NULL,
    "year" INTEGER NOT NULL,
    "type" TEXT NOT NULL,
    "wheels" INTEGER NOT NULL DEFAULT 4,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "VehicleModel_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Vehicle" (
    "id" SERIAL NOT NULL,
    "customerId" INTEGER NOT NULL,
    "vehicleModelId" INTEGER NOT NULL,
    "plateNumber" TEXT NOT NULL,
    "vin" TEXT,
    "engineNumber" TEXT,
    "color" TEXT,
    "purchaseYear" INTEGER,
    "note" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Vehicle_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Category" (
    "id" SERIAL NOT NULL,
    "name" TEXT NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Category_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Sparepart" (
    "id" SERIAL NOT NULL,
    "code" TEXT NOT NULL,
    "name" TEXT NOT NULL,
    "categoryId" INTEGER NOT NULL,
    "buyPrice" DECIMAL(14,2) NOT NULL,
    "sellPrice" DECIMAL(14,2) NOT NULL,
    "stock" INTEGER NOT NULL DEFAULT 0,
    "lowStockThreshold" INTEGER NOT NULL DEFAULT 5,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Sparepart_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "StockHistory" (
    "id" SERIAL NOT NULL,
    "sparepartId" INTEGER NOT NULL,
    "direction" "StockDirection" NOT NULL,
    "source" "StockSource" NOT NULL DEFAULT 'MANUAL',
    "quantity" INTEGER NOT NULL,
    "note" TEXT,
    "refInvoice" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "StockHistory_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Technician" (
    "id" SERIAL NOT NULL,
    "name" TEXT NOT NULL,
    "skill" TEXT,
    "status" "StatusAktif" NOT NULL DEFAULT 'AKTIF',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Technician_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "TechnicianSchedule" (
    "id" SERIAL NOT NULL,
    "technicianId" INTEGER NOT NULL,
    "date" TIMESTAMP(3) NOT NULL,
    "note" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "TechnicianSchedule_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ServiceType" (
    "id" SERIAL NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "estimatedCost" DECIMAL(14,2) NOT NULL,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ServiceType_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ServiceTransaction" (
    "id" SERIAL NOT NULL,
    "invoiceNo" TEXT NOT NULL,
    "vehicleId" INTEGER NOT NULL,
    "technicianId" INTEGER NOT NULL,
    "date" TIMESTAMP(3) NOT NULL,
    "km" INTEGER,
    "complaint" TEXT,
    "internalNote" TEXT,
    "status" "ServiceStatus" NOT NULL DEFAULT 'DITERIMA',
    "discountId" INTEGER,
    "nextServiceRecommendation" TEXT,
    "nextServiceDate" TIMESTAMP(3),
    "subtotal" DECIMAL(14,2) NOT NULL DEFAULT 0,
    "discountAmount" DECIMAL(14,2) NOT NULL DEFAULT 0,
    "taxAmount" DECIMAL(14,2) NOT NULL DEFAULT 0,
    "total" DECIMAL(14,2) NOT NULL DEFAULT 0,
    "paid" DECIMAL(14,2) NOT NULL DEFAULT 0,
    "change" DECIMAL(14,2) NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "ServiceTransaction_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ServiceDetail" (
    "id" SERIAL NOT NULL,
    "serviceId" INTEGER NOT NULL,
    "name" TEXT NOT NULL,
    "description" TEXT,
    "cost" DECIMAL(14,2) NOT NULL,

    CONSTRAINT "ServiceDetail_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ServiceSparepart" (
    "id" SERIAL NOT NULL,
    "serviceId" INTEGER NOT NULL,
    "sparepartId" INTEGER NOT NULL,
    "qty" INTEGER NOT NULL,
    "price" DECIMAL(14,2) NOT NULL,

    CONSTRAINT "ServiceSparepart_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SalesTransaction" (
    "id" SERIAL NOT NULL,
    "invoiceNo" TEXT NOT NULL,
    "customerId" INTEGER,
    "walkInName" TEXT,
    "date" TIMESTAMP(3) NOT NULL,
    "discountId" INTEGER,
    "subtotal" DECIMAL(14,2) NOT NULL DEFAULT 0,
    "discountAmount" DECIMAL(14,2) NOT NULL DEFAULT 0,
    "taxAmount" DECIMAL(14,2) NOT NULL DEFAULT 0,
    "total" DECIMAL(14,2) NOT NULL DEFAULT 0,
    "paid" DECIMAL(14,2) NOT NULL DEFAULT 0,
    "change" DECIMAL(14,2) NOT NULL DEFAULT 0,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "SalesTransaction_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "SalesItem" (
    "id" SERIAL NOT NULL,
    "salesId" INTEGER NOT NULL,
    "sparepartId" INTEGER NOT NULL,
    "qty" INTEGER NOT NULL,
    "price" DECIMAL(14,2) NOT NULL,

    CONSTRAINT "SalesItem_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Discount" (
    "id" SERIAL NOT NULL,
    "name" TEXT NOT NULL,
    "code" TEXT,
    "type" "DiscountType" NOT NULL,
    "value" DECIMAL(14,2) NOT NULL,
    "status" "StatusAktif" NOT NULL DEFAULT 'AKTIF',
    "scope" "DiscountScope" NOT NULL DEFAULT 'SEMUA',
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "Discount_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "Settings" (
    "id" INTEGER NOT NULL DEFAULT 1,
    "businessName" TEXT NOT NULL DEFAULT 'Self Automotive',
    "address" TEXT,
    "phone" TEXT,
    "logoUrl" TEXT,
    "printerType" TEXT,
    "printBridgeHost" TEXT,
    "printBridgePort" INTEGER,
    "taxService" DECIMAL(5,2) NOT NULL DEFAULT 10,
    "taxSales" DECIMAL(5,2) NOT NULL DEFAULT 10,
    "updatedAt" TIMESTAMP(3) NOT NULL,

    CONSTRAINT "Settings_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "User_username_key" ON "User"("username");

-- CreateIndex
CREATE UNIQUE INDEX "User_email_key" ON "User"("email");

-- CreateIndex
CREATE UNIQUE INDEX "User_technicianId_key" ON "User"("technicianId");

-- CreateIndex
CREATE INDEX "User_role_idx" ON "User"("role");

-- CreateIndex
CREATE INDEX "Customer_name_idx" ON "Customer"("name");

-- CreateIndex
CREATE INDEX "Customer_phone_idx" ON "Customer"("phone");

-- CreateIndex
CREATE INDEX "VehicleModel_brand_model_idx" ON "VehicleModel"("brand", "model");

-- CreateIndex
CREATE UNIQUE INDEX "Vehicle_plateNumber_key" ON "Vehicle"("plateNumber");

-- CreateIndex
CREATE INDEX "Vehicle_customerId_idx" ON "Vehicle"("customerId");

-- CreateIndex
CREATE INDEX "Vehicle_plateNumber_idx" ON "Vehicle"("plateNumber");

-- CreateIndex
CREATE UNIQUE INDEX "Category_name_key" ON "Category"("name");

-- CreateIndex
CREATE INDEX "Category_name_idx" ON "Category"("name");

-- CreateIndex
CREATE UNIQUE INDEX "Sparepart_code_key" ON "Sparepart"("code");

-- CreateIndex
CREATE INDEX "Sparepart_code_idx" ON "Sparepart"("code");

-- CreateIndex
CREATE INDEX "Sparepart_categoryId_idx" ON "Sparepart"("categoryId");

-- CreateIndex
CREATE INDEX "StockHistory_sparepartId_idx" ON "StockHistory"("sparepartId");

-- CreateIndex
CREATE INDEX "StockHistory_createdAt_idx" ON "StockHistory"("createdAt");

-- CreateIndex
CREATE INDEX "Technician_status_idx" ON "Technician"("status");

-- CreateIndex
CREATE INDEX "TechnicianSchedule_technicianId_idx" ON "TechnicianSchedule"("technicianId");

-- CreateIndex
CREATE INDEX "TechnicianSchedule_date_idx" ON "TechnicianSchedule"("date");

-- CreateIndex
CREATE INDEX "ServiceType_name_idx" ON "ServiceType"("name");

-- CreateIndex
CREATE UNIQUE INDEX "ServiceTransaction_invoiceNo_key" ON "ServiceTransaction"("invoiceNo");

-- CreateIndex
CREATE INDEX "ServiceTransaction_status_idx" ON "ServiceTransaction"("status");

-- CreateIndex
CREATE INDEX "ServiceTransaction_vehicleId_idx" ON "ServiceTransaction"("vehicleId");

-- CreateIndex
CREATE INDEX "ServiceTransaction_technicianId_idx" ON "ServiceTransaction"("technicianId");

-- CreateIndex
CREATE INDEX "ServiceTransaction_date_idx" ON "ServiceTransaction"("date");

-- CreateIndex
CREATE INDEX "ServiceDetail_serviceId_idx" ON "ServiceDetail"("serviceId");

-- CreateIndex
CREATE INDEX "ServiceSparepart_serviceId_idx" ON "ServiceSparepart"("serviceId");

-- CreateIndex
CREATE INDEX "ServiceSparepart_sparepartId_idx" ON "ServiceSparepart"("sparepartId");

-- CreateIndex
CREATE UNIQUE INDEX "SalesTransaction_invoiceNo_key" ON "SalesTransaction"("invoiceNo");

-- CreateIndex
CREATE INDEX "SalesTransaction_date_idx" ON "SalesTransaction"("date");

-- CreateIndex
CREATE INDEX "SalesTransaction_customerId_idx" ON "SalesTransaction"("customerId");

-- CreateIndex
CREATE INDEX "SalesItem_salesId_idx" ON "SalesItem"("salesId");

-- CreateIndex
CREATE INDEX "SalesItem_sparepartId_idx" ON "SalesItem"("sparepartId");

-- CreateIndex
CREATE UNIQUE INDEX "Discount_code_key" ON "Discount"("code");

-- CreateIndex
CREATE INDEX "Discount_code_idx" ON "Discount"("code");

-- CreateIndex
CREATE INDEX "Discount_status_idx" ON "Discount"("status");

-- AddForeignKey
ALTER TABLE "User" ADD CONSTRAINT "User_technicianId_fkey" FOREIGN KEY ("technicianId") REFERENCES "Technician"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Vehicle" ADD CONSTRAINT "Vehicle_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "Customer"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Vehicle" ADD CONSTRAINT "Vehicle_vehicleModelId_fkey" FOREIGN KEY ("vehicleModelId") REFERENCES "VehicleModel"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "Sparepart" ADD CONSTRAINT "Sparepart_categoryId_fkey" FOREIGN KEY ("categoryId") REFERENCES "Category"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "StockHistory" ADD CONSTRAINT "StockHistory_sparepartId_fkey" FOREIGN KEY ("sparepartId") REFERENCES "Sparepart"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "TechnicianSchedule" ADD CONSTRAINT "TechnicianSchedule_technicianId_fkey" FOREIGN KEY ("technicianId") REFERENCES "Technician"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ServiceTransaction" ADD CONSTRAINT "ServiceTransaction_vehicleId_fkey" FOREIGN KEY ("vehicleId") REFERENCES "Vehicle"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ServiceTransaction" ADD CONSTRAINT "ServiceTransaction_technicianId_fkey" FOREIGN KEY ("technicianId") REFERENCES "Technician"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ServiceTransaction" ADD CONSTRAINT "ServiceTransaction_discountId_fkey" FOREIGN KEY ("discountId") REFERENCES "Discount"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ServiceDetail" ADD CONSTRAINT "ServiceDetail_serviceId_fkey" FOREIGN KEY ("serviceId") REFERENCES "ServiceTransaction"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ServiceSparepart" ADD CONSTRAINT "ServiceSparepart_serviceId_fkey" FOREIGN KEY ("serviceId") REFERENCES "ServiceTransaction"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ServiceSparepart" ADD CONSTRAINT "ServiceSparepart_sparepartId_fkey" FOREIGN KEY ("sparepartId") REFERENCES "Sparepart"("id") ON DELETE RESTRICT ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SalesTransaction" ADD CONSTRAINT "SalesTransaction_customerId_fkey" FOREIGN KEY ("customerId") REFERENCES "Customer"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SalesTransaction" ADD CONSTRAINT "SalesTransaction_discountId_fkey" FOREIGN KEY ("discountId") REFERENCES "Discount"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SalesItem" ADD CONSTRAINT "SalesItem_salesId_fkey" FOREIGN KEY ("salesId") REFERENCES "SalesTransaction"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "SalesItem" ADD CONSTRAINT "SalesItem_sparepartId_fkey" FOREIGN KEY ("sparepartId") REFERENCES "Sparepart"("id") ON DELETE RESTRICT ON UPDATE CASCADE;
