const router = require('express').Router();
const ctrl = require('../controllers/dashboard.controller');
const { authenticate, authorize } = require('../middleware/auth');

router.get('/summary', authenticate, authorize('ADMIN', 'STAFF', 'TEKNISI'), ctrl.summary);

module.exports = router;
