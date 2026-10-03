const router = require('express').Router();
const ctrl = require('../controllers/service.controller');
const { authenticate, authorize } = require('../middleware/auth');

// Admin, Staff, dan Teknisi semua boleh masuk ke modul Layanan (RBAC detail di controller)
router.use(authenticate, authorize('ADMIN', 'STAFF', 'TEKNISI'));

router.get('/', ctrl.list);
router.get('/:id', ctrl.detail);
router.get('/:id/whatsapp-message', ctrl.whatsappMessage);
router.post('/', authorize('ADMIN', 'STAFF'), ctrl.create);
router.put('/:id', authorize('ADMIN', 'STAFF'), ctrl.update);                 // edit data tahap 1
router.patch('/:id/start', ctrl.start);                                       // Tahap 2: mulai kerjakan
router.put('/:id/work', ctrl.saveWork);                                       // simpan pengerjaan / tagihan
router.patch('/:id/finish-work', ctrl.finishWork);                            // Tahap 3: selesai dikerjakan -> tagihan
router.post('/:id/complete', authorize('ADMIN', 'STAFF'), ctrl.complete);     // Tahap 4: pembayaran -> lunas
router.delete('/:id', authorize('ADMIN', 'STAFF'), ctrl.remove);

module.exports = router;
