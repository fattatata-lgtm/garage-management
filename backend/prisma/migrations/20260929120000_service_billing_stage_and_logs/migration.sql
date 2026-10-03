-- AlterEnum
ALTER TYPE "ServiceStatus" ADD VALUE 'MENUNGGU_PEMBAYARAN';

-- CreateTable
CREATE TABLE "ServiceLog" (
    "id" SERIAL NOT NULL,
    "serviceId" INTEGER NOT NULL,
    "status" "ServiceStatus",
    "title" TEXT NOT NULL,
    "note" TEXT,
    "actor" TEXT,
    "createdAt" TIMESTAMP(3) NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "ServiceLog_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "ServiceLog_serviceId_idx" ON "ServiceLog"("serviceId");

-- AddForeignKey
ALTER TABLE "ServiceLog" ADD CONSTRAINT "ServiceLog_serviceId_fkey" FOREIGN KEY ("serviceId") REFERENCES "ServiceTransaction"("id") ON DELETE CASCADE ON UPDATE CASCADE;
