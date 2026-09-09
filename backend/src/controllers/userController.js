'use strict';

const bcrypt = require('bcrypt');
const User = require('../models/User');
const ApiError = require('../utils/ApiError');
const asyncHandler = require('../utils/asyncHandler');

const SALT_ROUNDS = 12;

/**
 * PUT /api/v1/users/profile
 * Allows the authenticated user to update their own profile fields
 * (fullName, healthCenterId, location). Phone number and password
 * are intentionally NOT updatable here — use change-password for password.
 */
const updateProfile = asyncHandler(async (req, res) => {
  const { fullName, healthCenterId, location } = req.body;

  const user = await User.findByIdAndUpdate(
    req.user._id,
    { $set: { fullName, healthCenterId, location } },
    { new: true, runValidators: true }
  );

  if (!user) {
    throw ApiError.notFound('User not found');
  }

  res.status(200).json({ success: true, data: { user } });
});

/**
 * POST /api/v1/users/change-password
 * Allows the authenticated user to change their own password.
 * Requires the current password for verification.
 */
const changePassword = asyncHandler(async (req, res) => {
  const { currentPassword, newPassword } = req.body;

  if (!currentPassword || !newPassword) {
    throw ApiError.badRequest('currentPassword and newPassword are required');
  }
  if (newPassword.length < 8) {
    throw ApiError.badRequest('New password must be at least 8 characters');
  }

  // Re-fetch with passwordHash (select:false by default)
  const user = await User.findById(req.user._id).select('+passwordHash');
  if (!user) {
    throw ApiError.notFound('User not found');
  }

  const isMatch = await user.comparePassword(currentPassword);
  if (!isMatch) {
    throw ApiError.unauthorized('Current password is incorrect');
  }

  user.passwordHash = await bcrypt.hash(newPassword, SALT_ROUNDS);
  await user.save();

  res.status(200).json({ success: true, message: 'Password changed successfully' });
});

module.exports = { updateProfile, changePassword };
