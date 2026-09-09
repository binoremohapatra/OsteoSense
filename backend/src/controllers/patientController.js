'use strict';

const mongoose = require('mongoose');
const Patient = require('../models/Patient');
const Screening = require('../models/Screening');
const ApiError = require('../utils/ApiError');
const asyncHandler = require('../utils/asyncHandler');

/**
 * POST /api/v1/patients
 */
const createPatient = asyncHandler(async (req, res) => {
  const patientData = { ...req.body };
  if (!patientData.name && patientData.fullName) {
    patientData.name = patientData.fullName;
  }
  delete patientData.localId;
  delete patientData._id;
  delete patientData.id;

  const patient = await Patient.create({
    ...patientData,
    agentId: req.user._id, // always derived from the authenticated agent, never from client input
  });

  const isoCreated = patient.createdAt ? new Date(patient.createdAt).toISOString() : new Date().toISOString();
  const isoUpdated = patient.updatedAt ? new Date(patient.updatedAt).toISOString() : new Date().toISOString();

  const patientObj = {
    _id: patient._id.toString(),
    id: patient._id.toString(),
    server_id: patient._id.toString(),
    serverId: patient._id.toString(),
    name: patient.name,
    fullName: patient.name,
    age: patient.age,
    gender: patient.gender,
    contact: patient.contact || null,
    village: patient.village || null,
    address: patient.address || null,
    occupation: patient.occupation || null,
    created_at: isoCreated,
    createdAt: isoCreated,
    updated_at: isoUpdated,
    updatedAt: isoUpdated,
    synced: 1,
    ...patient.toObject(),
  };

  res.status(201).json({
    success: true,
    data: patient,
    patient: patientObj,
  });
});

/**
 * GET /api/v1/patients
 * Attaches each patient's latest screening (riskLevel, screeningDate) via $lookup
 * for the mobile app's patient-list risk badges.
 *
 * If called without pagination query params (standard Flutter ApiService().getPatients()),
 * returns a direct JSON array compatible with Future<List<dynamic>>.
 */
const listPatients = asyncHandler(async (req, res) => {
  const { page, limit, village, riskLevel } = req.query;

  // IDOR guard: every query MUST scope to req.user.id so one agent can never see another's patients.
  const match = { agentId: req.user._id, isDeleted: false };
  if (village) match.village = village;

  const basePipeline = [
    { $match: match },
    { $sort: { createdAt: -1 } },
    {
      $lookup: {
        from: 'screenings',
        let: { patientId: '$_id' },
        pipeline: [
          { $match: { $expr: { $eq: ['$patientId', '$$patientId'] } } },
          { $sort: { screeningDate: -1 } },
          { $limit: 1 },
          { $project: { riskLevel: 1, screeningDate: 1, confidence: 1, _id: 0 } },
        ],
        as: 'latestScreening',
      },
    },
    {
      $addFields: {
        latestScreening: { $arrayElemAt: ['$latestScreening', 0] },
      },
    },
  ];

  // Optional filter on latest screening's risk level (post-lookup)
  if (riskLevel) {
    basePipeline.push({ $match: { 'latestScreening.riskLevel': riskLevel } });
  }

  // Flutter mobile app calls ApiService().getPatients() without page/limit params
  if (!page && !limit) {
    const rawPatients = await Patient.aggregate(basePipeline);
    const formatted = rawPatients.map((doc) => {
      const isoCreated = doc.createdAt ? new Date(doc.createdAt).toISOString() : new Date().toISOString();
      const isoUpdated = doc.updatedAt ? new Date(doc.updatedAt).toISOString() : new Date().toISOString();
      return {
        _id: doc._id.toString(),
        server_id: doc._id.toString(),
        serverId: doc._id.toString(),
        id: null, // Keep null so Patient.fromMap's (map['id'] as int?) does not throw type error
        name: doc.name,
        fullName: doc.name,
        age: doc.age,
        gender: doc.gender,
        contact: doc.contact || null,
        village: doc.village || null,
        address: doc.address || null,
        occupation: doc.occupation || null,
        created_at: isoCreated,
        createdAt: isoCreated,
        updated_at: isoUpdated,
        updatedAt: isoUpdated,
        synced: 1,
        latestScreening: doc.latestScreening || null,
      };
    });

    return res.status(200).json(formatted);
  }

  const pNum = Number(page) || 1;
  const lNum = Number(limit) || 20;

  const pipeline = [
    ...basePipeline,
    {
      $facet: {
        data: [{ $skip: (pNum - 1) * lNum }, { $limit: lNum }],
        totalCount: [{ $count: 'count' }],
      },
    },
  ];

  const [result] = await Patient.aggregate(pipeline);
  const data = (result?.data || []).map((doc) => {
    doc.id = doc._id.toString();
    doc._id = doc._id.toString();
    doc.server_id = doc._id.toString();
    doc.fullName = doc.name;
    delete doc.__v;
    return doc;
  });
  const total = result?.totalCount?.[0]?.count || 0;

  res.status(200).json({
    success: true,
    data,
    pagination: {
      page: pNum,
      limit: lNum,
      total,
      totalPages: Math.ceil(total / lNum) || 0,
    },
  });
});

function escapeRegex(text) {
  return text.replace(/[-[\]{}()*+?.,\\^$|#\s]/g, '\\$&');
}

/**
 * GET /api/v1/patients/search?q=
 * Scoped to req.user's own patients only.
 * Supports partial matching across name and village and attaches latestScreening.
 */
const searchPatients = asyncHandler(async (req, res) => {
  const { q } = req.query;
  const escaped = escapeRegex(q);
  const regex = new RegExp(escaped, 'i');

  const pipeline = [
    {
      $match: {
        agentId: req.user._id,
        isDeleted: false,
        $or: [{ name: regex }, { village: regex }],
      },
    },
    { $sort: { createdAt: -1 } },
    { $limit: 20 },
    {
      $lookup: {
        from: 'screenings',
        let: { patientId: '$_id' },
        pipeline: [
          { $match: { $expr: { $eq: ['$patientId', '$$patientId'] } } },
          { $sort: { screeningDate: -1 } },
          { $limit: 1 },
          { $project: { riskLevel: 1, screeningDate: 1, confidence: 1, _id: 0 } },
        ],
        as: 'latestScreening',
      },
    },
    {
      $addFields: {
        latestScreening: { $arrayElemAt: ['$latestScreening', 0] },
      },
    },
  ];

  const results = await Patient.aggregate(pipeline);
  const data = results.map((doc) => {
    doc.id = doc._id;
    delete doc._id;
    delete doc.__v;
    return doc;
  });

  res.status(200).json({ success: true, data });
});

/**
 * GET /api/v1/patients/:id
 */
const getPatientById = asyncHandler(async (req, res) => {
  const { id } = req.params;
  if (!mongoose.Types.ObjectId.isValid(id)) {
    throw ApiError.notFound('Patient not found');
  }

  // IDOR guard: agentId must match req.user._id
  const patient = await Patient.findOne({ _id: id, agentId: req.user._id, isDeleted: false });
  if (!patient) {
    throw ApiError.notFound('Patient not found');
  }

  const [screeningCount, mostRecentScreening] = await Promise.all([
    Screening.countDocuments({ patientId: patient._id }),
    Screening.findOne({ patientId: patient._id }).sort({ screeningDate: -1 }),
  ]);

  const payload = patient.toJSON();
  payload.screeningHistoryCount = screeningCount;
  payload.mostRecentScreening = mostRecentScreening || null;

  res.status(200).json({ success: true, data: payload });
});

/**
 * PUT /api/v1/patients/:id
 */
const updatePatient = asyncHandler(async (req, res) => {
  const { id } = req.params;
  if (!mongoose.Types.ObjectId.isValid(id)) {
    throw ApiError.notFound('Patient not found');
  }

  const updateData = { ...req.body };
  if (!updateData.name && updateData.fullName) {
    updateData.name = updateData.fullName;
  }
  delete updateData.agentId;
  delete updateData._id;
  delete updateData.id;
  delete updateData.localId;

  // IDOR guard: only update if it belongs to req.user
  const patient = await Patient.findOneAndUpdate(
    { _id: id, agentId: req.user._id, isDeleted: false },
    { $set: updateData },
    { new: true, runValidators: true }
  );

  if (!patient) {
    throw ApiError.notFound('Patient not found');
  }

  const isoCreated = patient.createdAt ? new Date(patient.createdAt).toISOString() : new Date().toISOString();
  const isoUpdated = patient.updatedAt ? new Date(patient.updatedAt).toISOString() : new Date().toISOString();

  const patientObj = {
    _id: patient._id.toString(),
    id: patient._id.toString(),
    server_id: patient._id.toString(),
    serverId: patient._id.toString(),
    name: patient.name,
    fullName: patient.name,
    age: patient.age,
    gender: patient.gender,
    contact: patient.contact || null,
    village: patient.village || null,
    address: patient.address || null,
    occupation: patient.occupation || null,
    created_at: isoCreated,
    createdAt: isoCreated,
    updated_at: isoUpdated,
    updatedAt: isoUpdated,
    synced: 1,
    ...patient.toObject(),
  };

  res.status(200).json({ success: true, data: patient, patient: patientObj });
});

/**
 * DELETE /api/v1/patients/:id
 * Soft delete only.
 */
const deletePatient = asyncHandler(async (req, res) => {
  const { id } = req.params;
  if (!mongoose.Types.ObjectId.isValid(id)) {
    throw ApiError.notFound('Patient not found');
  }

  // IDOR guard: only soft-delete if it belongs to req.user
  const patient = await Patient.findOneAndUpdate(
    { _id: id, agentId: req.user._id, isDeleted: false },
    { $set: { isDeleted: true } },
    { new: true }
  );

  if (!patient) {
    throw ApiError.notFound('Patient not found');
  }

  res.status(200).json({ success: true, message: 'Patient deleted' });
});

module.exports = {
  createPatient,
  listPatients,
  searchPatients,
  getPatientById,
  updatePatient,
  deletePatient,
};
