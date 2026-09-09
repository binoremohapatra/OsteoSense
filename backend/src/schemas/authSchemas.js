'use strict';

const { z } = require('zod');

const phoneNumberSchema = z
  .string({ required_error: 'Phone number is required' })
  .trim()
  .regex(/^[6-9]\d{9}$/, 'Phone number must be a valid 10-digit Indian mobile number');

const preprocessPhone = (data) => {
  if (data && typeof data === 'object') {
    if (!data.phoneNumber && data.phone) {
      data.phoneNumber = data.phone;
    }
  }
  return data;
};

const registerSchema = z.preprocess(
  preprocessPhone,
  z.object({
    fullName: z
      .string({ required_error: 'Full name is required' })
      .trim()
      .min(2, 'Full name must be at least 2 characters'),
    phoneNumber: phoneNumberSchema,
    password: z
      .string({ required_error: 'Password is required' })
      .min(8, 'Password must be at least 8 characters'),
    role: z.enum(['agent', 'user']).optional().default('agent'),
    healthCenterId: z.string().trim().optional(),
    location: z.string().trim().optional(),
  })
);

const loginSchema = z.preprocess(
  preprocessPhone,
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

module.exports = {
  registerSchema,
  loginSchema,
  refreshSchema,
  logoutSchema,
};
