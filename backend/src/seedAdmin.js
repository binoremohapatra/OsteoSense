'use strict';

/**
 * Seed script to create an admin user
 * Run via: node src/seedAdmin.js
 */

const mongoose = require('mongoose');
const bcrypt = require('bcrypt');
const connectDB = require('./config/db');
const User = require('./models/User');
const Admin = require('./models/Admin');
const logger = require('./utils/logger');

const SALT_ROUNDS = 12;

async function seedAdmin() {
  try {
    await connectDB();
    logger.info('Seeding admin user and admin database section...');

    // Check if admin user already exists
    let existingUser = await User.findOne({ phoneNumber: '9999999999' }).select('+passwordHash');
    const passwordHash = await bcrypt.hash('admin123', SALT_ROUNDS);

    if (existingUser) {
      logger.info('Admin user already exists. Resetting password and ensuring active admin role...');
      existingUser.role = 'admin';
      existingUser.isActive = true;
      existingUser.passwordHash = passwordHash;
      await existingUser.save();
      logger.info('Admin user password and role updated successfully.');
    } else {
      // Create admin user
      existingUser = await User.create({
        fullName: 'System Administrator',
        phoneNumber: '9999999999',
        passwordHash,
        role: 'admin',
        healthCenterId: null,
        location: 'System Command Center',
        isActive: true,
      });
      logger.info('Admin user created successfully.');
    }

    // Ensure Admin section entry in database
    let adminSection = await Admin.findOne({ user: existingUser._id });
    if (!adminSection) {
      adminSection = await Admin.create({
        user: existingUser._id,
        fullName: existingUser.fullName,
        phoneNumber: existingUser.phoneNumber,
        adminRole: 'superadmin',
        department: 'District Public Health & Screening Administration',
        jurisdiction: 'All Districts & Primary Health Centers',
        permissions: [
          'dashboard_analytics_full',
          'view_all_patients',
          'view_all_screenings',
          'manage_health_workers',
          'village_assignment_override',
          'audit_logs_read',
          'export_system_reports',
          'system_settings_write',
        ],
        auditLogs: [
          {
            action: 'ADMIN_SEEDED',
            details: 'Initial system administrator section seeded in database',
            performedBy: 'System Seed Script',
            timestamp: new Date(),
          },
        ],
      });
      logger.info('Admin database section created successfully.');
    } else {
      logger.info('Admin database section already exists.');
    }

    logger.info('Admin credentials:');
    logger.info('  Phone: 9999999999');
    logger.info('  Password: admin123');
    logger.info(`  Role: admin (superadmin)`);
  } catch (err) {
    logger.error('Admin seeding failed', { error: err.message });
    process.exitCode = 1;
  } finally {
    await mongoose.connection.close();
  }
}

seedAdmin();
