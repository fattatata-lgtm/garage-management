const router = require('express').Router();
const ctrl = require('../controllers/discount.controller');
const { authenticate, authorize } = require('../middleware/auth');

router.get('/', authenticate, authorize('ADMIN', 'STAFF'), ctrl.list);
router.get('/code/:code', authenticate, authorize('ADMIN', 'STAFF'), ctrl.findByCode);
router.post('/', authenticate, authorize('ADMIN'), ctrl.create);
router.put('/:id', authenticate, authorize('ADMIN'), ctrl.update);
router.delete('/:id', authenticate, authorize('ADMIN'), ctrl.remove);

module.exports = router;
