const router = require('express').Router();

router.use('/auth', require('./auth.routes'));
router.use('/users', require('./user.routes'));
router.use('/customers', require('./customer.routes'));
router.use('/vehicle-models', require('./vehicleModel.routes'));
router.use('/vehicles', require('./vehicle.routes'));
router.use('/categories', require('./category.routes'));
router.use('/spareparts', require('./sparepart.routes'));
router.use('/technicians', require('./technician.routes'));
router.use('/service-types', require('./serviceType.routes'));
router.use('/services', require('./service.routes'));
router.use('/sales', require('./sales.routes'));
router.use('/discounts', require('./discount.routes'));
router.use('/settings', require('./settings.routes'));
router.use('/print', require('./print.routes'));
router.use('/reports', require('./report.routes'));
router.use('/dashboard', require('./dashboard.routes'));

module.exports = router;
