const prisma = require('../lib/prisma');
const { stockStatus } = require('../utils/helpers');

function rangeFor(period) {
  const now = new Date();
  let start;
  if (period === 'week') {
    const day = now.getDay() || 7;
    start = new Date(now);
    start.setDate(now.getDate() - day + 1);
    start.setHours(0, 0, 0, 0);
  } else if (period === 'month') {
    start = new Date(now.getFullYear(), now.getMonth(), 1);
  } else {
    start = new Date(now);
    start.setHours(0, 0, 0, 0);
  }
  return { start, end: new Date() };
}

async function summary(req, res, next) {
  try {
    const period = req.query.period || 'day'; // day | week | month
    const { start, end } = rangeFor(period);

    const [totalCustomers, totalVehicles, totalServices, services, sales, spareparts, recentServices] =
      await Promise.all([
        prisma.customer.count(),
        prisma.vehicle.count(),
        prisma.serviceTransaction.count({ where: { date: { gte: start, lte: end } } }),
        prisma.serviceTransaction.findMany({ where: { date: { gte: start, lte: end }, status: 'SELESAI' } }),
        prisma.salesTransaction.findMany({ where: { date: { gte: start, lte: end } }, include: { items: { include: { sparepart: true } } } }),
        prisma.sparepart.findMany(),
        prisma.serviceTransaction.findMany({
          take: 8,
          orderBy: { date: 'desc' },
          include: { vehicle: { include: { customer: true } }, technician: true },
        }),
      ]);

    const pendapatanService = services.reduce((s, d) => s + Number(d.total), 0);
    const pendapatanSales = sales.reduce((s, d) => s + Number(d.total), 0);

    let labaSales = 0;
    for (const s of sales) {
      for (const it of s.items) {
        labaSales += (Number(it.price) - Number(it.sparepart.buyPrice)) * it.qty;
      }
    }

    const lowStockAlerts = spareparts
      .map((sp) => ({ ...sp, status: stockStatus(sp.stock, sp.lowStockThreshold) }))
      .filter((sp) => sp.status !== 'BAIK');

    res.json({
      period,
      totalCustomers,
      totalVehicles,
      totalServices,
      pendapatanService,
      pendapatanSales,
      totalPendapatan: pendapatanService + pendapatanSales,
      labaEstimasi: labaSales,
      lowStockAlerts,
      recentServices,
    });
  } catch (err) { next(err); }
}

module.exports = { summary };
