'use strict';

const { z } = require('zod');

const contactSchema = z
  .string()
  .trim()
  .regex(/^[6-9]\d{9}$/, 'Contact must be a valid 10-digit number')
  .optional()
  .or(z.literal('').transform(() => undefined));

const preprocessPatient = (data) => {
  if (data && typeof data === 'object') {
    if (!data.name && data.fullName) {
      data.name = data.fullName;
    }
    if (typeof data.gender === 'string') {
      data.gender = data.gender.trim().toLowerCase();
    }
  }
  return data;
};

const patientBaseSchema = z.object({
  name: z.string({ required_error: 'Name is required' }).trim().min(1, 'Name is required'),
  age: z.coerce
    .number({ required_error: 'Age is required' })
    .min(0, 'Age cannot be negative')
    .max(150, 'Age is not realistic'),
  gender: z.enum(['male', 'female', 'other'], {
    required_error: 'Gender is required',
    invalid_type_error: 'Gender must be one of male, female, other',
  }),
  contact: contactSchema,
  village: z.string().trim().optional(),
  address: z.string().trim().optional(),
  occupation: z.string().trim().optional(),
  height: z.coerce.number().positive().optional(),
  weight: z.coerce.number().positive().optional(),
  localId: z.any().optional(),
});

const createPatientSchema = z.preprocess(preprocessPatient, patientBaseSchema);

const updatePatientSchema = z.preprocess(preprocessPatient, patientBaseSchema.partial());

const listPatientsQuerySchema = z.object({
  page: z.coerce.number().int().positive().optional(),
  limit: z.coerce.number().int().positive().max(100).optional(),
  village: z.string().trim().optional(),
  riskLevel: z.enum(['low', 'medium', 'high']).optional(),
});

const searchPatientsQuerySchema = z.object({
  q: z.string().trim().min(2, 'Search query must be at least 2 characters'),
});

module.exports = {
  createPatientSchema,
  updatePatientSchema,
  listPatientsQuerySchema,
  searchPatientsQuerySchema,
};
