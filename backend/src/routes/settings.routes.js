const router = require('express').Router();
const ctrl = require('../controllers/settings.controller');
const { authenticate, authorize } = require('../middleware/auth');

router.get('/public', ctrl.getPublic); // nama & logo untuk halaman Login (tanpa token)
router.get('/', authenticate, ctrl.get);
router.put('/', authenticate, authorize('ADMIN'), ctrl.update);
router.post('/logo', authenticate, authorize('ADMIN'), ctrl.receiveLogo, ctrl.uploadLogo);
router.delete('/logo', authenticate, authorize('ADMIN'), ctrl.deleteLogo);

module.exports = router;
