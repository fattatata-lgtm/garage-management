const router = require('express').Router();
const ctrl = require('../controllers/sales.controller');
const { authenticate, authorize } = require('../middleware/auth');

router.use(authenticate, authorize('ADMIN', 'STAFF'));
router.get('/', ctrl.list);
router.get('/next-invoice', ctrl.nextInvoice);
router.get('/:id', ctrl.detail);
router.get('/:id/whatsapp-message', ctrl.whatsappMessage);
router.post('/', ctrl.create);
router.delete('/:id', authorize('ADMIN'), ctrl.remove); // transaksi lunas: hanya Admin

module.exports = router;
