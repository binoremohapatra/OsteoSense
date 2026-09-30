'use strict';

const express = require('express');
const villageAssignmentController = require('../controllers/villageAssignmentController');
const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

router.use(authMiddleware);

/**
 * @swagger
 * tags:
 *   name: Village Assignments
 *   description: Manage village-to-health-worker assignments
 */

/**
 * @swagger
 * /village-assignments:
 *   post:
 *     summary: Create a new village assignment
 *     tags: [Village Assignments]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required:
 *               - village
 *               - location
 *               - assignedHealthWorkerId
 *             properties:
 *               village:
 *                 type: string
 *               location:
 *                 type: string
 *               assignedHealthWorkerId:
 *                 type: string
 *     responses:
 *       201:
 *         description: Assignment created successfully
 */
router.post('/', villageAssignmentController.createAssignment);

/**
 * @swagger
 * /village-assignments:
 *   get:
 *     summary: Get all village assignments
 *     tags: [Village Assignments]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: query
 *         name: location
 *         schema:
 *           type: string
 *         description: Filter by location
 *       - in: query
 *         name: healthWorkerId
 *         schema:
 *           type: string
 *         description: Filter by health worker ID
 *     responses:
 *       200:
 *         description: List of assignments
 */
router.get('/', villageAssignmentController.getAllAssignments);

/**
 * @swagger
 * /village-assignments/{id}:
 *   put:
 *     summary: Update village assignment
 *     tags: [Village Assignments]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               village:
 *                 type: string
 *               location:
 *                 type: string
 *               assignedHealthWorkerId:
 *                 type: string
 *     responses:
 *       200:
 *         description: Assignment updated successfully
 */
router.put('/:id', villageAssignmentController.updateAssignment);

/**
 * @swagger
 * /village-assignments/{id}:
 *   delete:
 *     summary: Deactivate village assignment
 *     tags: [Village Assignments]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: id
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Assignment deactivated successfully
 */
router.delete('/:id', villageAssignmentController.deleteAssignment);

/**
 * @swagger
 * /village-assignments/health-worker/{village}:
 *   get:
 *     summary: Get assigned health worker for a specific village
 *     tags: [Village Assignments]
 *     security:
 *       - bearerAuth: []
 *     parameters:
 *       - in: path
 *         name: village
 *         required: true
 *         schema:
 *           type: string
 *     responses:
 *       200:
 *         description: Health worker ID for the village
 */
router.get('/health-worker/:village', villageAssignmentController.getHealthWorkerForVillage);

module.exports = router;
