const router = require('express').Router();
const ctrl = require('../controllers/serviceType.controller');
const { authenticate, authorize } = require('../middleware/auth');

router.use(authenticate);
// Teknisi ikut boleh membaca daftar jenis layanan (dipakai pemilih jasa di halaman pengerjaan)
router.get('/', authorize('ADMIN', 'STAFF', 'TEKNISI'), ctrl.list);
router.post('/', authorize('ADMIN', 'STAFF'), ctrl.create);
router.put('/:id', authorize('ADMIN', 'STAFF'), ctrl.update);
router.delete('/:id', authorize('ADMIN', 'STAFF'), ctrl.remove);

module.exports = router;
