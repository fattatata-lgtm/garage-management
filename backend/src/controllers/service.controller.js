const prisma = require('../lib/prisma');
const { generateInvoiceNo, calcDiscountAmount } = require('../utils/helpers');
const { buildServiceReceipt } = require('../utils/receipt');

const baseInclude = {
  vehicle: { include: { customer: true, vehicleModel: true } },
  technician: true,
  discount: true,
  details: true,
  spareparts: { include: { sparepart: true } },
};
// Halaman detail ikut membawa riwayat tahapan (urut dari yang paling awal)
const fullInclude = { ...baseInclude, logs: { orderBy: { createdAt: 'asc' } } };

const fail = (message, status = 400) => Object.assign(new Error(message), { status });
const rp = (n) => `Rp${Number(n || 0).toLocaleString('id-ID')}`;

// Catat satu baris riwayat tahapan transaksi
function addLog(client, req, serviceId, status, title, note = null) {
  return client.serviceLog.create({
    data: { serviceId, status, title, note, actor: req.user?.username || null },
  });
}

function assertTeknisiOwnership(req, service) {
  if (req.user.role === 'TEKNISI' && service.technicianId !== req.user.technicianId) {
    throw fail('Anda hanya dapat mengakses service yang ditugaskan kepada Anda.', 403);
  }
}

async function list(req, res, next) {
  try {
    const { status, from, to, technicianId, q } = req.query;
    const where = {
      AND: [
        status ? { status } : {},
        technicianId ? { technicianId: Number(technicianId) } : {},
        from ? { date: { gte: new Date(from) } } : {},
        to ? { date: { lte: new Date(to) } } : {},
        q ? { OR: [
              { invoiceNo: { contains: q, mode: 'insensitive' } },
              { vehicle: { plateNumber: { contains: q, mode: 'insensitive' } } },
            ] } : {},
      ],
    };

    // Teknisi hanya boleh lihat service yang ditugaskan kepadanya
    if (req.user.role === 'TEKNISI') {
      where.AND.push({ technicianId: req.user.technicianId || 0 });
    }

    const services = await prisma.serviceTransaction.findMany({
      where,
      include: baseInclude,
      orderBy: { date: 'desc' },
    });
    res.json(services);
  } catch (err) { next(err); }
}

async function detail(req, res, next) {
  try {
    const id = Number(req.params.id);
    const service = await prisma.serviceTransaction.findUnique({ where: { id }, include: fullInclude });
    if (!service) return res.status(404).json({ message: 'Transaksi service tidak ditemukan.' });
    assertTeknisiOwnership(req, service);
    res.json(service);
  } catch (err) { next(err); }
}

// TAHAP 1 - Tambah Service (Diterima)
async function create(req, res, next) {
  try {
    const { vehicleId, technicianId, date, complaint } = req.body;
    if (!vehicleId || !technicianId || !date || !complaint) {
      return res.status(400).json({ message: 'Kendaraan, teknisi, tanggal service, dan keluhan wajib diisi.' });
    }
    const invoiceNo = await generateInvoiceNo('SVC', 'serviceTransaction');

    const service = await prisma.$transaction(async (tx) => {
      const created = await tx.serviceTransaction.create({
        data: {
          invoiceNo,
          vehicleId: Number(vehicleId),
          technicianId: Number(technicianId),
          date: new Date(date),
          complaint,
          status: 'DITERIMA',
          taxAmount: 0,
        },
      });
      await addLog(tx, req, created.id, 'DITERIMA', 'Tahap 1 - Service diterima', complaint);
      return tx.serviceTransaction.findUnique({ where: { id: created.id }, include: fullInclude });
    });
    res.status(201).json(service);
  } catch (err) { next(err); }
}

// EDIT data awal service (kendaraan, teknisi, tanggal, keluhan). Transaksi yang sudah lunas dikunci.
async function update(req, res, next) {
  try {
    const id = Number(req.params.id);
    const { vehicleId, technicianId, date, complaint } = req.body;
    if (!vehicleId || !technicianId || !date || !complaint) {
      return res.status(400).json({ message: 'Kendaraan, teknisi, tanggal service, dan keluhan wajib diisi.' });
    }
    const existing = await prisma.serviceTransaction.findUnique({ where: { id } });
    if (!existing) return res.status(404).json({ message: 'Transaksi tidak ditemukan.' });
    if (existing.status === 'SELESAI') {
      return res.status(400).json({ message: 'Transaksi yang sudah Selesai (Lunas) tidak dapat diedit.' });
    }

    const service = await prisma.$transaction(async (tx) => {
      await tx.serviceTransaction.update({
        where: { id },
        data: {
          vehicleId: Number(vehicleId),
          technicianId: Number(technicianId),
          date: new Date(date),
          complaint,
        },
      });
      await addLog(tx, req, id, existing.status, 'Data service diubah');
      return tx.serviceTransaction.findUnique({ where: { id }, include: fullInclude });
    });
    res.json(service);
  } catch (err) { next(err); }
}

// TAHAP 2 - Mulai Kerjakan
async function start(req, res, next) {
  try {
    const id = Number(req.params.id);
    const existing = await prisma.serviceTransaction.findUnique({ where: { id } });
    if (!existing) return res.status(404).json({ message: 'Transaksi tidak ditemukan.' });
    if (existing.status !== 'DITERIMA') {
      return res.status(400).json({ message: 'Hanya transaksi berstatus Diterima yang bisa dimulai.' });
    }
    assertTeknisiOwnership(req, existing);
    const service = await prisma.$transaction(async (tx) => {
      await tx.serviceTransaction.update({ where: { id }, data: { status: 'DIKERJAKAN' } });
      await addLog(tx, req, id, 'DIKERJAKAN', 'Tahap 2 - Mulai dikerjakan');
      return tx.serviceTransaction.findUnique({ where: { id }, include: fullInclude });
    });
    res.json(service);
  } catch (err) { next(err); }
}

// Simpan pekerjaan / edit tagihan: km, detail jasa, sparepart, rekomendasi, diskon -> hitung ulang total
// Berlaku saat status Dikerjakan (Tahap 2) dan Menunggu Pembayaran (Tahap 3, hanya Admin/Staff).
// Memotong / mengembalikan stok sparepart secara otomatis & atomik (prisma.$transaction)
async function saveWork(req, res, next) {
  try {
    const id = Number(req.params.id);
    const {
      km, details, spareparts, nextServiceRecommendation, nextServiceDate,
      internalNote, discountId,
    } = req.body;

    if (!Array.isArray(details)) {
      return res.status(400).json({ message: 'Detail service (jasa) wajib berupa array.' });
    }

    const result = await prisma.$transaction(async (tx) => {
      const service = await tx.serviceTransaction.findUnique({
        where: { id },
        include: { spareparts: true },
      });
      if (!service) throw fail('Transaksi tidak ditemukan.', 404);
      assertTeknisiOwnership(req, service);
      if (service.status === 'SELESAI') {
        throw fail('Transaksi yang sudah Selesai (Lunas) tidak dapat diubah.');
      }
      if (service.status !== 'DIKERJAKAN' && service.status !== 'MENUNGGU_PEMBAYARAN') {
        throw fail('Pekerjaan hanya dapat disimpan saat status Dikerjakan atau Menunggu Pembayaran.');
      }
      if (service.status === 'MENUNGGU_PEMBAYARAN' && req.user.role === 'TEKNISI') {
        throw fail('Tagihan hanya dapat diubah oleh Admin/Staff.', 403);
      }

      // 1) Kembalikan stok dari pemakaian sparepart sebelumnya (jika ada perubahan)
      for (const old of service.spareparts) {
        await tx.sparepart.update({
          where: { id: old.sparepartId },
          data: { stock: { increment: old.qty } },
        });
      }
      await tx.serviceSparepart.deleteMany({ where: { serviceId: id } });
      await tx.serviceDetail.deleteMany({ where: { serviceId: id } });

      // 2) Simpan detail jasa baru
      let subtotal = 0;
      for (const d of details) {
        if (!d.name || d.cost == null || d.cost === '') continue;
        subtotal += Number(d.cost);
        await tx.serviceDetail.create({
          data: { serviceId: id, name: d.name, description: d.description || null, cost: Number(d.cost) },
        });
      }

      // 3) Simpan pemakaian sparepart baru & potong stok (validasi cukup)
      const sparepartList = Array.isArray(spareparts) ? spareparts : [];
      for (const s of sparepartList) {
        const qty = Number(s.qty);
        if (!s.sparepartId || !qty || qty <= 0) continue;
        const sp = await tx.sparepart.findUnique({ where: { id: Number(s.sparepartId) } });
        if (!sp) throw fail('Sparepart tidak ditemukan.', 404);
        if (sp.stock < qty) {
          throw fail(`Stok ${sp.name} tidak mencukupi (tersedia ${sp.stock}).`);
        }
        const price = s.price != null ? Number(s.price) : Number(sp.sellPrice);
        subtotal += price * qty;

        await tx.sparepart.update({ where: { id: sp.id }, data: { stock: { decrement: qty } } });
        await tx.stockHistory.create({
          data: {
            sparepartId: sp.id, direction: 'KELUAR', source: 'SERVICE',
            quantity: qty, note: `Dipakai pada service ${service.invoiceNo}`, refInvoice: service.invoiceNo,
          },
        });
        await tx.serviceSparepart.create({
          data: { serviceId: id, sparepartId: sp.id, qty, price },
        });
      }

      // 4) Hitung diskon & pajak.
      // Jika discountId tidak dikirim (mis. form pengerjaan yang tidak punya kolom diskon), diskon lama dipertahankan.
      const effectiveDiscountId = discountId === undefined ? service.discountId : (discountId ? Number(discountId) : null);
      let discount = null;
      if (effectiveDiscountId) {
        discount = await tx.discount.findUnique({ where: { id: effectiveDiscountId } });
      }
      const discountAmount = calcDiscountAmount(subtotal, discount);
      const settings = await tx.settings.findUnique({ where: { id: 1 } });
      const taxRate = settings ? Number(settings.taxService) : 10;
      const afterDiscount = Math.max(subtotal - discountAmount, 0);
      const taxAmount = (afterDiscount * taxRate) / 100;
      const total = afterDiscount + taxAmount;

      await tx.serviceTransaction.update({
        where: { id },
        data: {
          km: km != null ? Number(km) : undefined,
          nextServiceRecommendation,
          nextServiceDate: nextServiceDate ? new Date(nextServiceDate) : null,
          internalNote,
          discountId: effectiveDiscountId,
          subtotal,
          discountAmount,
          taxAmount,
          total,
        },
      });

      await addLog(
        tx, req, id, service.status,
        service.status === 'DIKERJAKAN' ? 'Detail pengerjaan disimpan' : 'Rincian tagihan diperbarui',
        service.status === 'MENUNGGU_PEMBAYARAN' ? `Total tagihan ${rp(total)}` : null,
      );

      return tx.serviceTransaction.findUnique({ where: { id }, include: fullInclude });
    });

    res.json(result);
  } catch (err) { next(err); }
}

// TAHAP 3 - Selesai dikerjakan -> masuk halaman tagihan (rincian biaya + pembayaran)
async function finishWork(req, res, next) {
  try {
    const id = Number(req.params.id);
    const service = await prisma.serviceTransaction.findUnique({ where: { id }, include: { details: true } });
    if (!service) return res.status(404).json({ message: 'Transaksi tidak ditemukan.' });
    assertTeknisiOwnership(req, service);
    if (service.status !== 'DIKERJAKAN') {
      return res.status(400).json({ message: 'Transaksi harus berstatus Dikerjakan sebelum ditandai selesai dikerjakan.' });
    }
    if (service.details.length < 1) {
      return res.status(400).json({ message: 'Simpan minimal 1 detail service (jasa) terlebih dahulu.' });
    }
    if (service.km == null) {
      return res.status(400).json({ message: 'Kilometer kendaraan wajib diisi dan disimpan terlebih dahulu.' });
    }

    const updated = await prisma.$transaction(async (tx) => {
      await tx.serviceTransaction.update({ where: { id }, data: { status: 'MENUNGGU_PEMBAYARAN' } });
      await addLog(tx, req, id, 'MENUNGGU_PEMBAYARAN', 'Tahap 3 - Selesai dikerjakan, menunggu pembayaran', `Total tagihan ${rp(service.total)}`);
      return tx.serviceTransaction.findUnique({ where: { id }, include: fullInclude });
    });
    res.json(updated);
  } catch (err) { next(err); }
}

// TAHAP 4 - Pembayaran -> Selesai & Lunas
async function complete(req, res, next) {
  try {
    const id = Number(req.params.id);
    const { paid } = req.body;

    const service = await prisma.serviceTransaction.findUnique({ where: { id }, include: { details: true } });
    if (!service) return res.status(404).json({ message: 'Transaksi tidak ditemukan.' });
    if (service.status !== 'MENUNGGU_PEMBAYARAN') {
      return res.status(400).json({ message: 'Pembayaran hanya dapat dilakukan setelah pekerjaan ditandai selesai dikerjakan.' });
    }
    if (service.details.length < 1) {
      return res.status(400).json({ message: 'Minimal 1 detail service (jasa) wajib ditambahkan.' });
    }
    if (service.km == null) {
      return res.status(400).json({ message: 'Kilometer kendaraan wajib diisi sebelum menyelesaikan service.' });
    }

    const paidNum = Number(paid);
    if (paid == null || paid === '' || isNaN(paidNum) || paidNum < Number(service.total)) {
      return res.status(400).json({ message: 'Jumlah dibayar wajib diisi dan tidak boleh kurang dari total.' });
    }
    const change = paidNum - Number(service.total);

    const updated = await prisma.$transaction(async (tx) => {
      await tx.serviceTransaction.update({
        where: { id },
        data: { status: 'SELESAI', paid: paidNum, change },
      });
      await addLog(tx, req, id, 'SELESAI', 'Tahap 4 - Pembayaran diterima, transaksi Selesai (Lunas)',
        `Dibayar ${rp(paidNum)}, kembalian ${rp(change)}`);
      return tx.serviceTransaction.findUnique({ where: { id }, include: fullInclude });
    });
    res.json(updated);
  } catch (err) { next(err); }
}

// Hapus transaksi. Stok sparepart yang sempat terpotong dikembalikan otomatis.
// Transaksi yang sudah Selesai (Lunas) hanya boleh dihapus Admin.
async function remove(req, res, next) {
  try {
    const id = Number(req.params.id);
    await prisma.$transaction(async (tx) => {
      const service = await tx.serviceTransaction.findUnique({ where: { id }, include: { spareparts: true } });
      if (!service) throw fail('Transaksi tidak ditemukan.', 404);
      if (service.status === 'SELESAI' && req.user.role !== 'ADMIN') {
        throw fail('Transaksi yang sudah Selesai (Lunas) hanya dapat dihapus oleh Admin.', 403);
      }
      for (const sp of service.spareparts) {
        await tx.sparepart.update({ where: { id: sp.sparepartId }, data: { stock: { increment: sp.qty } } });
        await tx.stockHistory.create({
          data: {
            sparepartId: sp.sparepartId, direction: 'MASUK', source: 'SERVICE', quantity: sp.qty,
            note: `Stok dikembalikan: service ${service.invoiceNo} dihapus`, refInvoice: service.invoiceNo,
          },
        });
      }
      await tx.serviceTransaction.delete({ where: { id } });
    });
    res.json({ message: 'Transaksi service berhasil dihapus.' });
  } catch (err) { next(err); }
}

// Teks pesan WhatsApp (dibuka via wa.me di sisi client). Isi pesan menyesuaikan tahap transaksi.
async function whatsappMessage(req, res, next) {
  try {
    const id = Number(req.params.id);
    const service = await prisma.serviceTransaction.findUnique({ where: { id }, include: fullInclude });
    if (!service) return res.status(404).json({ message: 'Transaksi tidak ditemukan.' });
    assertTeknisiOwnership(req, service);

    const owner = service.vehicle.customer;
    const plate = service.vehicle.plateNumber;
    const jasa = service.details.map((d) => `- ${d.name}: ${rp(d.cost)}`).join('\n') || '-';
    const spare = service.spareparts.map((s) => `- ${s.sparepart.name} x${s.qty}: ${rp(Number(s.price) * s.qty)}`).join('\n') || '-';

    let text = '';
    if (service.status === 'DITERIMA') {
      const settings = await prisma.settings.findUnique({ where: { id: 1 } });
      const garage = settings?.businessName || 'bengkel kami';
      const complaint = (service.complaint || '').trim() || '-';
      text = [
        `Halo *${owner.name}* 👋`,
        '',
        `Kendaraan Anda (${plate}) telah kami terima dan sedang dalam proses servis di *${garage}*.`,
        '',
        `Keluhan tercatat: _${complaint}_`,
        '',
        `Mekanik: *${service.technician.name}*`,
        '',
        `No. Servis: *${service.invoiceNo}*`,
        '',
        'Kami akan menghubungi Anda lagi setelah servis selesai. Terima kasih 🙏',
      ].join('\n');
    } else if (service.status === 'DIKERJAKAN') {
      text = `Halo ${owner.name}, kendaraan Anda (${plate}) dengan No. ${service.invoiceNo} sedang dalam pengerjaan oleh teknisi kami. Kami akan menghubungi Anda kembali setelah selesai. Terima kasih.`;
    } else if (service.status === 'MENUNGGU_PEMBAYARAN') {
      text = `Halo ${owner.name}, service kendaraan ${plate} (${service.invoiceNo}) telah selesai dikerjakan. Berikut tagihan Anda:\n\nJasa:\n${jasa}\n\nSparepart:\n${spare}\n\nSubtotal: ${rp(service.subtotal)}\nDiskon: -${rp(service.discountAmount)}\nPajak: ${rp(service.taxAmount)}\n*Total Tagihan: ${rp(service.total)}*\n\nSilakan lakukan pembayaran di kasir. Terima kasih.`;
    } else {
      text = [
        `Halo *${owner.name}* 👋`,
        '',
        'Servis sudah selesai dan *LUNAS* ✅',
        '',
        'Berikut struk Anda:',
        '',
        buildServiceReceipt(service),
      ].join('\n');
    }
    res.json({ phone: owner.phone, message: text });
  } catch (err) { next(err); }
}

module.exports = { list, detail, create, update, start, saveWork, finishWork, complete, remove, whatsappMessage };
