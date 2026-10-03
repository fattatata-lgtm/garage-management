const router = require('express').Router();
const ctrl = require('../controllers/customer.controller');
const { authenticate, authorize } = require('../middleware/auth');

router.use(authenticate, authorize('ADMIN', 'STAFF'));
router.get('/', ctrl.list);
router.get('/:id', ctrl.detail);
router.post('/', ctrl.create);
router.put('/:id', ctrl.update);
router.delete('/:id', ctrl.remove);

module.exports = router;
