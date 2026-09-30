'use strict';

const mongoose = require('mongoose');
const { Schema } = mongoose;

const adminSchema = new Schema(
  {
    user: {
      type: Schema.Types.ObjectId,
      ref: 'User',
      required: true,
      unique: true,
    },
    fullName: {
      type: String,
      required: true,
      trim: true,
    },
    phoneNumber: {
      type: String,
      required: true,
      trim: true,
    },
    adminRole: {
      type: String,
      enum: ['superadmin', 'district_admin', 'clinical_director', 'system_admin'],
      default: 'system_admin',
    },
    department: {
      type: String,
      default: 'District Public Health & Screening Administration',
      trim: true,
    },
    jurisdiction: {
      type: String,
      default: 'All Health Centers, Districts & Screening Camps',
      trim: true,
    },
    permissions: {
      type: [String],
      default: [
        'dashboard_analytics_full',
        'view_all_patients',
        'view_all_screenings',
        'manage_health_workers',
        'village_assignment_override',
        'audit_logs_read',
        'export_system_reports',
        'system_settings_write',
      ],
    },
    systemSettings: {
      highRiskAlertThreshold: { type: Number, default: 20 },
      autoAssignmentEnabled: { type: Boolean, default: true },
      dataRetentionDays: { type: Number, default: 365 },
      smsAlertsEnabled: { type: Boolean, default: true },
      emailAlertsEnabled: { type: Boolean, default: true },
      adminContactEmail: { type: String, default: 'admin@jointsaathi.org' },
    },
    auditLogs: [
      {
        action: { type: String, required: true },
        details: { type: String },
        ipAddress: { type: String, default: '127.0.0.1' },
        performedBy: { type: String },
        timestamp: { type: Date, default: Date.now },
      },
    ],
    lastLoginAt: {
      type: Date,
      default: Date.now,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
    toJSON: {
      transform: (_doc, ret) => {
        ret.id = ret._id ? ret._id.toString() : '';
        delete ret.__v;
        return ret;
      },
    },
  }
);

module.exports = mongoose.model('Admin', adminSchema);
