'use strict';

const express = require('express');
const analyticsController = require('../controllers/analyticsController');
const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

router.use(authMiddleware);

/**
 * @swagger
 * tags:
 *   name: Analytics
 *   description: Aggregate insights scoped to the authenticated agent's data
 */

/**
 * @swagger
 * /analytics/overview:
 *   get:
 *     summary: High-level overview stats (patients, screenings, risk distribution, avg confidence)
 *     tags: [Analytics]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Overview stats
 */
router.get('/overview', analyticsController.getOverview);

/**
 * @swagger
 * /analytics/trends:
 *   get:
 *     summary: Screening volume over time, for a line chart
 *     tags: [Analytics]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: period
 *         schema: { type: string, enum: [7d, 30d, 90d], default: 30d }
 *     responses:
 *       200:
 *         description: Array of { date, count }
 */
router.get('/trends', analyticsController.getTrends);

/**
 * @swagger
 * /analytics/risk-distribution:
 *   get:
 *     summary: Lightweight risk-level distribution for chart widgets
 *     tags: [Analytics]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Risk distribution counts (low, medium, high)
 */
router.get('/risk-distribution', analyticsController.getRiskDistribution);

/**
 * @swagger
 * /analytics/locations:
 *   get:
 *     summary: Screening counts and high-risk rates grouped by village
 *     tags: [Analytics]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Villages sorted by high-risk count descending
 */
router.get('/locations', analyticsController.getLocations);

/**
 * @swagger
 * /analytics/screening-trends:
 *   get:
 *     summary: Alias for /analytics/trends — screening volume over time
 *     description: >
 *       The Flutter mobile app calls this path via getAnalyticsData('screening-trends').
 *       Internally delegates to the same handler as GET /analytics/trends.
 *     tags: [Analytics]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: period
 *         schema: { type: string, enum: [7d, 30d, 90d], default: 30d }
 *     responses:
 *       200:
 *         description: Array of { date, count }
 */
router.get('/screening-trends', analyticsController.getTrends);

/**
 * @swagger
 * /analytics/population-insights:
 *   get:
 *     summary: Population-level OA risk insights (alias for overview)
 *     description: >
 *       The Flutter mobile app's api_service.dart calls this path via
 *       getPopulationInsights(). Returns the same overview payload
 *       (totalPatients, totalScreenings, riskDistribution, avgConfidence).
 *     tags: [Analytics]
 *     security:
 *       - bearerAuth: []
 *     responses:
 *       200:
 *         description: Overview stats with risk distribution
 */
router.get('/population-insights', analyticsController.getOverview);

module.exports = router;
