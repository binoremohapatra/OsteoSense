'use strict';

const { z } = require('zod');

const phoneNumberSchema = z
  .string({ required_error: 'Phone number is required' })
  .trim()
  .regex(/^[6-9]\d{9}$/, 'Phone number must be a valid 10-digit Indian mobile number');

const preprocessAuth = (data) => {
  if (data && typeof data === 'object') {
    if (!data.phoneNumber && data.phone) {
      data.phoneNumber = data.phone;
    }
    if (!data.phoneNumber && data.phone_number) {
      data.phoneNumber = data.phone_number;
    }
    if (!data.fullName && data.full_name) {
      data.fullName = data.full_name;
    }
    if (!data.healthCenterId && data.health_center_id) {
      data.healthCenterId = data.health_center_id;
    }
  }
  return data;
};

const registerSchema = z.preprocess(
  preprocessAuth,
  z.object({
    fullName: z
      .string({ required_error: 'Full name is required' })
      .trim()
      .min(2, 'Full name must be at least 2 characters'),
    phoneNumber: phoneNumberSchema,
    password: z
      .string({ required_error: 'Password is required' })
      .min(6, 'Password must be at least 6 characters'),
    role: z.enum(['agent', 'user', 'admin']).optional().default('agent'),
    healthCenterId: z.string().trim().nullable().optional(),
    location: z.string().trim().nullable().optional(),
  })
);

const loginSchema = z.preprocess(
  preprocessAuth,
  z.object({
    phoneNumber: phoneNumberSchema,
    password: z.string({ required_error: 'Password is required' }).min(1, 'Password is required'),
  })
);

const refreshSchema = z.object({
  refreshToken: z.string({ required_error: 'refreshToken is required' }).min(1),
});

const logoutSchema = z.object({
  refreshToken: z.string({ required_error: 'refreshToken is required' }).min(1),
});

const resetPasswordSchema = z.preprocess(
  preprocessAuth,
  z.object({
    phoneNumber: phoneNumberSchema,
    newPassword: z.string({ required_error: 'New password is required' }).min(6, 'Password must be at least 6 characters'),
  })
);

module.exports = { registerSchema, loginSchema, refreshSchema, logoutSchema, resetPasswordSchema };
