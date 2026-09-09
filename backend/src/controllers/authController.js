'use strict';

const bcrypt = require('bcrypt');
const User = require('../models/User');
const ApiError = require('../utils/ApiError');
const asyncHandler = require('../utils/asyncHandler');
const tokenService = require('../services/tokenService');

const SALT_ROUNDS = 12;

/**
 * Normalizes user objects to satisfy the Flutter mobile app's User.fromMap contract:
 * - id: positive 32-bit int (derived from mongo _id hex)
 * - full_name: String
 * - phone_number: String
 * - password: String (empty string default so non-nullable cast succeeds)
 * - created_at: ISO8601 String
 * - updated_at: ISO8601 String
 */
function formatUserForApp(user) {
  if (!user) return null;
  const obj = user.toObject ? user.toObject() : { ...user };
  delete obj.passwordHash;
  delete obj.refreshTokens;

  const hex = (user._id || '').toString().slice(-6);
  const intId = (parseInt(hex, 16) % 2147483647) || 1;

  const createdAtIso = user.createdAt ? new Date(user.createdAt).toISOString() : new Date().toISOString();
  const updatedAtIso = user.updatedAt ? new Date(user.updatedAt).toISOString() : new Date().toISOString();

  return {
    ...obj,
    id: intId,
    _id: (user._id || '').toString(),
    server_id: (user._id || '').toString(),
    full_name: user.fullName || '',
    fullName: user.fullName || '',
    phone_number: user.phoneNumber || '',
    phoneNumber: user.phoneNumber || '',
    password: '',
    health_center_id: user.healthCenterId || null,
    healthCenterId: user.healthCenterId || null,
    location: user.location || null,
    created_at: createdAtIso,
    createdAt: createdAtIso,
    updated_at: updatedAtIso,
    updatedAt: updatedAtIso,
  };
}

/**
 * POST /api/v1/auth/register
 */
const register = asyncHandler(async (req, res) => {
  const { fullName, phoneNumber, password, role, healthCenterId, location } = req.body;

  const existing = await User.findOne({ phoneNumber });
  if (existing) {
    throw ApiError.conflict('An account with this phone number already exists');
  }

  const passwordHash = await bcrypt.hash(password, SALT_ROUNDS);

  const user = await User.create({
    fullName,
    phoneNumber,
    passwordHash,
    role,
    healthCenterId,
    location,
  });

  const { accessToken, refreshToken } = tokenService.issueTokenPair(user);
  await user.save();

  const appUser = formatUserForApp(user);

  res.status(201).json({
    success: true,
    data: { user: appUser, accessToken, refreshToken, token: accessToken },
    token: accessToken,
    refreshToken,
    user: appUser,
  });
});

/**
 * POST /api/v1/auth/login
 */
const login = asyncHandler(async (req, res) => {
  const { phoneNumber, password } = req.body;

  // select('+passwordHash') needed since it's select:false on the schema
  const user = await User.findOne({ phoneNumber }).select('+passwordHash +refreshTokens');

  // Generic message regardless of whether phone or password was wrong,
  // to avoid leaking which one was incorrect (user enumeration protection).
  if (!user || !user.isActive) {
    throw ApiError.unauthorized('Invalid credentials');
  }

  const isMatch = await user.comparePassword(password);
  if (!isMatch) {
    throw ApiError.unauthorized('Invalid credentials');
  }

  const { accessToken, refreshToken } = tokenService.issueTokenPair(user);
  await user.save();

  const appUser = formatUserForApp(user);

  res.status(200).json({
    success: true,
    data: { user: appUser, accessToken, refreshToken, token: accessToken },
    token: accessToken,
    refreshToken,
    user: appUser,
  });
});

/**
 * POST /api/v1/auth/refresh
 */
const refresh = asyncHandler(async (req, res) => {
  const { refreshToken } = req.body;

  let decoded;
  try {
    decoded = tokenService.verifyRefreshToken(refreshToken);
  } catch (err) {
    throw ApiError.unauthorized('Invalid or expired refresh token');
  }

  const user = await User.findById(decoded.sub).select('+refreshTokens');
  if (!user || !user.isActive) {
    throw ApiError.unauthorized('Invalid or expired refresh token');
  }

  // Ensures the token hasn't been revoked (e.g. via logout) even if its signature is still valid.
  if (!user.refreshTokens.includes(refreshToken)) {
    throw ApiError.unauthorized('Refresh token has been revoked');
  }

  // Rotate: remove the old refresh token, issue a fresh pair.
  user.refreshTokens = user.refreshTokens.filter((t) => t !== refreshToken);
  const { accessToken, refreshToken: newRefreshToken } = tokenService.issueTokenPair(user);
  await user.save();

  res.status(200).json({
    success: true,
    data: { accessToken, refreshToken: newRefreshToken, token: accessToken },
    token: accessToken,
    refreshToken: newRefreshToken,
  });
});

/**
 * POST /api/v1/auth/logout
 * Protected route.
 */
const logout = asyncHandler(async (req, res) => {
  const { refreshToken } = req.body;

  const user = await User.findById(req.user._id).select('+refreshTokens');
  if (user) {
    user.refreshTokens = user.refreshTokens.filter((t) => t !== refreshToken);
    await user.save();
  }

  res.status(200).json({ success: true, message: 'Logged out' });
});

/**
 * GET /api/v1/auth/me
 * Protected route.
 */
const me = asyncHandler(async (req, res) => {
  const appUser = formatUserForApp(req.user);
  res.status(200).json({
    success: true,
    data: { ...appUser, user: appUser },
    user: appUser,
  });
});

module.exports = { register, login, refresh, logout, me };
