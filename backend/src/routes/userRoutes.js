'use strict';

const express = require('express');
const userController = require('../controllers/userController');
const authMiddleware = require('../middleware/authMiddleware');

const router = express.Router();

// All user-management routes require authentication.
router.use(authMiddleware);

/**
 * @swagger
 * tags:
 *   name: Users
 *   description: Authenticated user profile and password management
 */

/**
 * @swagger
 * /users/profile:
 *   put:
 *     summary: Update the authenticated user's profile
 *     description: >
 *       Updates fullName, healthCenterId, and/or location for the currently
 *       authenticated user. Phone number is immutable; use change-password
 *       to update the password.
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             properties:
 *               fullName: { type: string, example: "Priya Sharma" }
 *               healthCenterId: { type: string, example: "PHC-KHONSA-01" }
 *               location: { type: string, example: "Khonsa, Arunachal Pradesh" }
 *     responses:
 *       200:
 *         description: Profile updated successfully
 *         content:
 *           application/json:
 *             schema:
 *               type: object
 *               properties:
 *                 success: { type: boolean, example: true }
 *                 data:
 *                   type: object
 *                   properties:
 *                     user:
 *                       type: object
 *       401:
 *         description: Unauthorized
 *       404:
 *         description: User not found
 */
router.put('/profile', userController.updateProfile);

/**
 * @swagger
 * /users/change-password:
 *   post:
 *     summary: Change the authenticated user's password
 *     tags: [Users]
 *     security:
 *       - bearerAuth: []
 *     requestBody:
 *       required: true
 *       content:
 *         application/json:
 *           schema:
 *             type: object
 *             required: [currentPassword, newPassword]
 *             properties:
 *               currentPassword: { type: string }
 *               newPassword: { type: string, minLength: 8 }
 *     responses:
 *       200:
 *         description: Password changed successfully
 *       401:
 *         description: Current password incorrect or unauthorized
 */
router.post('/change-password', userController.changePassword);

module.exports = router;
