'use strict';

const express = require('express');
const adminController = require('../controllers/adminController');
const authMiddleware = require('../middleware/authMiddleware');
const adminMiddleware = require('../middleware/adminMiddleware');

const router = express.Router();

// All admin routes require valid authentication AND admin role
router.use(authMiddleware);
router.use(adminMiddleware);

/**
 * @swagger
 * tags:
 *   name: Admin
 *   description: System administrator database section, metrics, audit logs, and settings
 */

router.get('/overview', adminController.getOverview);
router.get('/section', adminController.getAdminSection);
router.get('/audit-logs', adminController.getAuditLogs);
router.post('/audit-logs', adminController.logAction);
router.get('/settings', adminController.getSettings);
router.put('/settings', adminController.updateSettings);
router.post('/create', adminController.createAdmin);

module.exports = router;
