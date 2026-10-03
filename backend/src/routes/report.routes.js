const router = require('express').Router();
const ctrl = require('../controllers/report.controller');
const { authenticate, authorize } = require('../middleware/auth');

router.use(authenticate, authorize('ADMIN', 'STAFF'));
router.get('/stock', ctrl.stockReport);
router.get('/service', ctrl.serviceReport);
router.get('/sales', ctrl.salesReport);

module.exports = router;
