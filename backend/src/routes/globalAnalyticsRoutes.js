'use strict';

const express = require('express');
const globalAnalyticsController = require('../controllers/globalAnalyticsController');
const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

router.use(authMiddleware);

/**
 * @swagger
 * tags:
 *   name: Global Analytics
 *   description: Aggregate insights across all patients and screenings (not scoped to individual agents)
 */

/**
 * @swagger
 * /global-analytics/overview:
 *   get:
 *     summary: Global overview stats (all patients, screenings, risk distribution, avg confidence)
 *     tags: [Global Analytics]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Global overview stats
 */
router.get('/overview', globalAnalyticsController.getGlobalOverview);

/**
 * @swagger
 * /global-analytics/trends:
 *   get:
 *     summary: Global screening volume over time, for a line chart
 *     tags: [Global Analytics]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: period
 *         schema: { type: string, enum: [7d, 30d, 90d, 365d], default: 30d }
 *     responses:
 *       200:
 *         description: Array of { date, count }
 */
router.get('/trends', globalAnalyticsController.getGlobalTrends);

/**
 * @swagger
 * /global-analytics/risk-distribution:
 *   get:
 *     summary: Global risk-level distribution for chart widgets
 *     tags: [Global Analytics]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Risk distribution counts (low, medium, high)
 */
router.get('/risk-distribution', globalAnalyticsController.getGlobalRiskDistribution);

/**
 * @swagger
 * /global-analytics/locations:
 *   get:
 *     summary: Global screening counts and high-risk rates grouped by village
 *     tags: [Global Analytics]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Villages sorted by high-risk count descending
 */
router.get('/locations', globalAnalyticsController.getGlobalLocations);

module.exports = router;
