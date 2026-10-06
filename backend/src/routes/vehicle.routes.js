const router = require('express').Router();
const ctrl = require('../controllers/vehicle.controller');
const { authenticate, authorize } = require('../middleware/auth');

// Teknisi hanya boleh melihat daftar kendaraan (untuk memilih kendaraan saat tambah service)
router.get('/', authenticate, authorize('ADMIN', 'STAFF', 'TEKNISI'), ctrl.list);

router.use(authenticate, authorize('ADMIN', 'STAFF'));
router.get('/:id', ctrl.detail);
router.post('/', ctrl.create);
router.put('/:id', ctrl.update);
router.delete('/:id', ctrl.remove);

module.exports = router;
