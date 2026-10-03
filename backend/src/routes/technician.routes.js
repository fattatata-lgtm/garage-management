const router = require('express').Router();
const ctrl = require('../controllers/technician.controller');
const { authenticate, authorize } = require('../middleware/auth');

router.get('/', authenticate, ctrl.list); // dipakai juga saat pilih teknisi di form service
router.get('/:id', authenticate, ctrl.detail);
router.post('/', authenticate, authorize('ADMIN', 'STAFF'), ctrl.create);
router.put('/:id', authenticate, authorize('ADMIN', 'STAFF'), ctrl.update);
router.delete('/:id', authenticate, authorize('ADMIN', 'STAFF'), ctrl.remove);
router.post('/:id/schedules', authenticate, authorize('ADMIN', 'STAFF'), ctrl.addSchedule);
router.put('/:id/schedules/:scheduleId', authenticate, authorize('ADMIN', 'STAFF'), ctrl.updateSchedule);
router.delete('/:id/schedules/:scheduleId', authenticate, authorize('ADMIN', 'STAFF'), ctrl.removeSchedule);

module.exports = router;
