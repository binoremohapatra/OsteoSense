'use strict';

const mongoose = require('mongoose');
const Patient = require('../models/Patient');
const Screening = require('../models/Screening');
const ApiError = require('../utils/ApiError');
const asyncHandler = require('../utils/asyncHandler');
const aiService = require('../services/aiService');
const { generateScreeningReportPdf } = require('../services/pdfService');

function formatScreeningForApp(screening) {
  const obj = screening.toJSON ? screening.toJSON() : { ...screening };
  const idStr = (screening._id || obj._id || '').toString();

  let factors = obj.contributingFactors;
  if (!Array.isArray(factors)) {
    factors = factors ? String(factors).split(',').map((s) => s.trim()).filter(Boolean) : [];
  }

  return {
    ...obj,
    _id: idStr,
    id: idStr,
    server_id: idStr,
    serverId: idStr,
    contributingFactors: factors,
  };
}

/**
 * POST /api/v1/screenings
 */
const createScreening = asyncHandler(async (req, res) => {
  const { patientId, painLevel, stiffnessDuration, swelling, pastInjury, gaitFeatures, gaitData } = req.body;

  if (!mongoose.Types.ObjectId.isValid(patientId)) {
    throw ApiError.badRequest('Invalid patientId');
  }

  const patient = await Patient.findOne({
    _id: patientId,
    agentId: req.user._id,
    isDeleted: false,
  });
  if (!patient) {
    throw ApiError.notFound('Patient not found');
  }

  const rawGait = gaitFeatures || gaitData || [];

  const prediction = await aiService.predictRisk({
    painLevel,
    stiffnessDuration,
    swelling,
    pastInjury,
    gaitFeatures: rawGait,
  });

  const screening = await Screening.create({
    patientId,
    agentId: req.user._id,
    painLevel,
    stiffnessDuration,
    swelling,
    pastInjury,
    gaitData: rawGait,
    riskLevel: prediction.riskLevel,
    confidence: prediction.confidence,
    contributingFactors: prediction.contributingFactors,
    aiReasoning: prediction.aiReasoning,
    doctorRecommendations: prediction.doctorRecommendations,
    source: prediction.source,
    synced: true,
  });

  const screeningObj = formatScreeningForApp(screening);

  res.status(201).json({
    success: true,
    screening: screeningObj,
    data: screeningObj,
  });
});

/**
 * GET /api/v1/screenings
 */
const listScreenings = asyncHandler(async (req, res) => {
  const { page, limit, riskLevel, startDate, endDate, patientId } = req.query;

  const filter = { agentId: req.user._id };
  if (riskLevel) filter.riskLevel = riskLevel;
  if (patientId) filter.patientId = patientId;
  if (startDate || endDate) {
    filter.screeningDate = {};
    if (startDate) filter.screeningDate.$gte = startDate;
    if (endDate) filter.screeningDate.$lte = endDate;
  }

  const pNum = Number(page) || 1;
  const lNum = Number(limit) || 20;

  const [data, total] = await Promise.all([
    Screening.find(filter)
      .sort({ screeningDate: -1 })
      .skip((pNum - 1) * lNum)
      .limit(lNum),
    Screening.countDocuments(filter),
  ]);

  res.status(200).json({
    success: true,
    data,
    pagination: { page: pNum, limit: lNum, total, totalPages: Math.ceil(total / lNum) || 0 },
  });
});

/**
 * GET /api/v1/screenings/:id
 */
const getScreeningById = asyncHandler(async (req, res) => {
  const { id } = req.params;
  if (!mongoose.Types.ObjectId.isValid(id)) {
    throw ApiError.notFound('Screening not found');
  }

  const screening = await Screening.findOne({ _id: id, agentId: req.user._id }).populate(
    'patientId',
    'name age village gender'
  );

  if (!screening) {
    throw ApiError.notFound('Screening not found');
  }

  res.status(200).json({ success: true, data: screening, screening: formatScreeningForApp(screening) });
});

/**
 * GET /api/v1/screenings/patient/:patientId
 */
const getScreeningsByPatient = asyncHandler(async (req, res) => {
  const { patientId } = req.params;

  const patient = await Patient.findOne({
    _id: patientId,
    agentId: req.user._id,
    isDeleted: false,
  });
  if (!patient) {
    throw ApiError.notFound('Patient not found');
  }

  const screenings = await Screening.find({ patientId }).sort({ screeningDate: -1 });

  res.status(200).json({ success: true, data: screenings });
});

/**
 * GET /api/v1/screenings/:id/report
 */
const getScreeningReport = asyncHandler(async (req, res) => {
  const { id } = req.params;
  if (!mongoose.Types.ObjectId.isValid(id)) {
    throw ApiError.notFound('Screening not found');
  }

  const screening = await Screening.findOne({ _id: id, agentId: req.user._id }).populate(
    'patientId',
    'name age village gender'
  );

  if (!screening) {
    throw ApiError.notFound('Screening not found');
  }

  const pdfBuffer = await generateScreeningReportPdf(screening.toObject());

  res.setHeader('Content-Type', 'application/pdf');
  res.setHeader(
    'Content-Disposition',
    `attachment; filename="screening-report-${screening._id}.pdf"`
  );
  res.status(200).send(pdfBuffer);
});

/**
 * PUT /api/v1/screenings/:id
 * Allows partial update of mutable fields (painLevel, notes, etc.).
 * AI-generated fields (riskLevel, confidence, etc.) are NOT re-run
 * automatically — the client should create a new screening to get a
 * fresh prediction.
 */
const updateScreening = asyncHandler(async (req, res) => {
  const { id } = req.params;
  if (!mongoose.Types.ObjectId.isValid(id)) {
    throw ApiError.notFound('Screening not found');
  }

  // Strip fields the client must not overwrite
  const allowed = { ...req.body };
  for (const f of ['_id', 'id', 'agentId', 'patientId', 'source', 'riskLevel', 'confidence', 'synced']) {
    delete allowed[f];
  }

  const screening = await Screening.findOneAndUpdate(
    { _id: id, agentId: req.user._id },
    { $set: allowed },
    { new: true, runValidators: true }
  );

  if (!screening) {
    throw ApiError.notFound('Screening not found');
  }

  const screeningObj = formatScreeningForApp(screening);
  res.status(200).json({ success: true, screening: screeningObj, data: screeningObj });
});

/**
 * DELETE /api/v1/screenings/:id
 * Hard-deletes the record (screenings have no business need for soft-delete,
 * unlike patients). Returns 200 to match the mobile app's expectation.
 */
const deleteScreening = asyncHandler(async (req, res) => {
  const { id } = req.params;
  if (!mongoose.Types.ObjectId.isValid(id)) {
    throw ApiError.notFound('Screening not found');
  }

  const screening = await Screening.findOneAndDelete({ _id: id, agentId: req.user._id });

  if (!screening) {
    throw ApiError.notFound('Screening not found');
  }

  res.status(200).json({ success: true, message: 'Screening deleted' });
});

module.exports = {
  createScreening,
  listScreenings,
  getScreeningById,
  getScreeningsByPatient,
  getScreeningReport,
  updateScreening,
  deleteScreening,
};
