'use strict';

const Admin = require('../models/Admin');
const User = require('../models/User');
const Patient = require('../models/Patient');
const Screening = require('../models/Screening');
const ApiError = require('../utils/ApiError');
const asyncHandler = require('../utils/asyncHandler');
const bcrypt = require('bcrypt');

const SALT_ROUNDS = 12;

/**
 * Ensures an Admin document exists for the admin user
 */
async function ensureAdminDoc(user) {
  let admin = await Admin.findOne({ user: user._id });
  if (!admin) {
    admin = await Admin.create({
      user: user._id,
      fullName: user.fullName || 'System Administrator',
      phoneNumber: user.phoneNumber,
      adminRole: 'superadmin',
      department: 'District Public Health & Screening Administration',
      jurisdiction: 'All Health Centers & Screening Camps',
      auditLogs: [
        {
          action: 'ADMIN_SESSION_INITIALIZED',
          details: 'Admin database section initialized for user',
          ipAddress: '127.0.0.1',
          performedBy: user.fullName || 'Admin',
          timestamp: new Date(),
        },
      ],
    });
  }
  return admin;
}

/**
 * GET /api/v1/admin/overview
 * Overview of system-wide health, workers, patients, and screenings.
 */
const getOverview = asyncHandler(async (req, res) => {
  const [
    totalPatients,
    totalScreenings,
    totalWorkers,
    highRiskScreenings,
    mediumRiskScreenings,
    lowRiskScreenings,
    adminDoc,
  ] = await Promise.all([
    Patient.countDocuments(),
    Screening.countDocuments(),
    User.countDocuments({ role: 'agent' }),
    Screening.countDocuments({ riskLevel: 'high' }),
    Screening.countDocuments({ riskLevel: 'medium' }),
    Screening.countDocuments({ riskLevel: 'low' }),
    ensureAdminDoc(req.user),
  ]);

  // Update lastLoginAt
  adminDoc.lastLoginAt = new Date();
  await adminDoc.save();

  res.status(200).json({
    success: true,
    data: {
      metrics: {
        totalPatients,
        totalScreenings,
        totalWorkers,
        highRiskCount: highRiskScreenings,
        mediumRiskCount: mediumRiskScreenings,
        lowRiskCount: lowRiskScreenings,
        highRiskRate: totalScreenings > 0 ? Math.round((highRiskScreenings / totalScreenings) * 100) : 0,
      },
      admin: {
        id: adminDoc._id,
        fullName: adminDoc.fullName,
        phoneNumber: adminDoc.phoneNumber,
        adminRole: adminDoc.adminRole,
        department: adminDoc.department,
        jurisdiction: adminDoc.jurisdiction,
        permissions: adminDoc.permissions,
        systemSettings: adminDoc.systemSettings,
        lastLoginAt: adminDoc.lastLoginAt,
      },
    },
  });
});

/**
 * GET /api/v1/admin/section
 * Retrieves all registered admin accounts and administrative settings from DB.
 */
const getAdminSection = asyncHandler(async (req, res) => {
  const [admins, currentAdmin] = await Promise.all([
    Admin.find().populate('user', 'fullName phoneNumber role isActive createdAt'),
    ensureAdminDoc(req.user),
  ]);

  res.status(200).json({
    success: true,
    data: {
      admins,
      currentAdmin,
    },
  });
});

/**
 * GET /api/v1/admin/audit-logs
 * Retrieves audit logs.
 */
const getAuditLogs = asyncHandler(async (req, res) => {
  const adminDoc = await ensureAdminDoc(req.user);
  const logs = adminDoc.auditLogs.slice(-50).reverse();

  res.status(200).json({
    success: true,
    data: logs,
  });
});

/**
 * POST /api/v1/admin/audit-logs
 * Logs an administrative action.
 */
const logAction = asyncHandler(async (req, res) => {
  const { action, details } = req.body;
  const adminDoc = await ensureAdminDoc(req.user);

  adminDoc.auditLogs.push({
    action: action || 'ADMIN_ACTION',
    details: details || '',
    ipAddress: req.ip || '127.0.0.1',
    performedBy: req.user.fullName || 'Admin',
    timestamp: new Date(),
  });

  await adminDoc.save();

  res.status(201).json({
    success: true,
    message: 'Audit log recorded',
    data: adminDoc.auditLogs[adminDoc.auditLogs.length - 1],
  });
});

/**
 * GET /api/v1/admin/settings
 * Retrieves admin system configuration.
 */
const getSettings = asyncHandler(async (req, res) => {
  const adminDoc = await ensureAdminDoc(req.user);

  res.status(200).json({
    success: true,
    data: adminDoc.systemSettings,
  });
});

/**
 * PUT /api/v1/admin/settings
 * Updates admin system configuration.
 */
const updateSettings = asyncHandler(async (req, res) => {
  const adminDoc = await ensureAdminDoc(req.user);
  adminDoc.systemSettings = {
    ...adminDoc.systemSettings.toObject(),
    ...req.body,
  };

  adminDoc.auditLogs.push({
    action: 'SETTINGS_UPDATED',
    details: `Updated settings: ${Object.keys(req.body).join(', ')}`,
    ipAddress: req.ip || '127.0.0.1',
    performedBy: req.user.fullName || 'Admin',
    timestamp: new Date(),
  });

  await adminDoc.save();

  res.status(200).json({
    success: true,
    message: 'Settings updated successfully',
    data: adminDoc.systemSettings,
  });
});

/**
 * POST /api/v1/admin/create
 * Creates a new administrator account in DB.
 */
const createAdmin = asyncHandler(async (req, res) => {
  const { fullName, phoneNumber, password, adminRole, department, jurisdiction } = req.body;

  const existingUser = await User.findOne({ phoneNumber });
  if (existingUser) {
    throw ApiError.conflict('An account with this phone number already exists');
  }

  const passwordHash = await bcrypt.hash(password || 'admin123', SALT_ROUNDS);
  const newUser = await User.create({
    fullName,
    phoneNumber,
    passwordHash,
    role: 'admin',
    location: 'System Admin',
    isActive: true,
  });

  const newAdmin = await Admin.create({
    user: newUser._id,
    fullName,
    phoneNumber,
    adminRole: adminRole || 'district_admin',
    department: department || 'District Public Health Administration',
    jurisdiction: jurisdiction || 'District Wide',
    auditLogs: [
      {
        action: 'ADMIN_CREATED',
        details: `Admin account created by ${req.user.fullName}`,
        performedBy: req.user.fullName,
        timestamp: new Date(),
      },
    ],
  });

  res.status(201).json({
    success: true,
    message: 'New administrator created successfully',
    data: newAdmin,
  });
});

module.exports = {
  getOverview,
  getAdminSection,
  getAuditLogs,
  logAction,
  getSettings,
  updateSettings,
  createAdmin,
};
