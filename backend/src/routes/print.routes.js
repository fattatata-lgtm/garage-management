const router = require('express').Router();
const ctrl = require('../controllers/print.controller');
const { authenticate, authorize } = require('../middleware/auth');

router.post('/raw', authenticate, authorize('ADMIN', 'STAFF'), ctrl.printRaw);

module.exports = router;
