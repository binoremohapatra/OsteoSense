'use strict';

const { z } = require('zod');

const objectIdRegex = /^[0-9a-fA-F]{24}$/;

const objectId = (fieldName) =>
  z
    .string({ required_error: `${fieldName} is required` })
    .regex(objectIdRegex, `${fieldName} must be a valid ObjectId`);

const createScreeningSchema = z.object({
  patientId: objectId('patientId'),
  painLevel: z.coerce
    .number({ required_error: 'painLevel is required' })
    .min(0, 'painLevel must be between 0 and 10')
    .max(10, 'painLevel must be between 0 and 10'),
  stiffnessDuration: z.string().trim().nullish().transform((v) => v || ''),
  swelling: z
    .preprocess((val) => (val === true || val === 1 || val === '1' || val === 'true' ? true : false), z.boolean())
    .optional()
    .default(false),
  pastInjury: z.string().trim().nullish().transform((v) => v || ''),
  gaitFeatures: z.array(z.coerce.number()).optional().default([]),
  gaitData: z.any().optional(),
});

const listScreeningsQuerySchema = z.object({
  page: z.coerce.number().int().positive().optional().default(1),
  limit: z.coerce.number().int().positive().max(100).optional().default(20),
  riskLevel: z.enum(['low', 'medium', 'high']).optional(),
  startDate: z.coerce.date().optional(),
  endDate: z.coerce.date().optional(),
  patientId: z
    .string()
    .regex(objectIdRegex, 'patientId must be a valid ObjectId')
    .optional(),
});

const patientIdParamSchema = z.object({
  patientId: objectId('patientId'),
});

/**
 * Schema for PUT /screenings/:id — all fields optional (patch-style update).
 * AI-derived fields (riskLevel, confidence, source) are intentionally excluded
 * and stripped in the controller anyway.
 */
const updateScreeningSchema = z.object({
  painLevel: z.coerce.number().min(0).max(10).optional(),
  stiffnessDuration: z.string().trim().nullish().transform((v) => v || ''),
  swelling: z
    .preprocess((val) => (val === true || val === 1 || val === '1' || val === 'true' ? true : false), z.boolean())
    .optional(),
  pastInjury: z.string().trim().nullish().transform((v) => v || ''),
  gaitFeatures: z.array(z.coerce.number()).optional(),
  gaitData: z.any().optional(),
  notes: z.string().trim().optional(),
});

const screeningIdParamSchema = z.object({
  id: objectId('id'),
});

module.exports = {
  createScreeningSchema,
  listScreeningsQuerySchema,
  patientIdParamSchema,
  updateScreeningSchema,
  screeningIdParamSchema,
};
