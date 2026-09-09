'use strict';

const mongoose = require('mongoose');
const Patient = require('../models/Patient');
const Screening = require('../models/Screening');
const asyncHandler = require('../utils/asyncHandler');
const logger = require('../utils/logger');
const aiService = require('../services/aiService');

/**
 * Processes a single offline-queued sync item (create/update of a
 * patient or screening).
 *
 * Reconciles local IDs: if a screening references a patient created
 * earlier in the same batch via localId, it automatically resolves to
 * the newly generated serverId.
 */
async function processSyncItem(item, agentId, localIdMap) {
  const { type, localId, action, data } = item;
  if (!data || typeof data !== 'object') {
    throw new Error('Sync item data must be an object');
  }

  if (type === 'patient') {
    if (action === 'create') {
      const patientData = { ...data };
      delete patientData._id;
      delete patientData.id;
      delete patientData.agentId;

      const patient = await Patient.create({ ...patientData, agentId });
      if (localId) {
        localIdMap.set(localId, patient._id.toString());
      }
      return { localId, serverId: patient._id.toString(), success: true };
    }

    if (action === 'update') {
      const patientId = data.id || data._id;
      if (!patientId || !mongoose.Types.ObjectId.isValid(patientId)) {
        throw new Error('Valid patient ID is required for update');
      }

      const updateData = { ...data };
      delete updateData._id;
      delete updateData.id;
      delete updateData.agentId;

      // IDOR guard: only update patients belonging to this agent and not deleted.
      const patient = await Patient.findOneAndUpdate(
        { _id: patientId, agentId, isDeleted: false },
        { $set: updateData },
        { new: true, runValidators: true }
      );
      if (!patient) throw new Error('Patient not found or not owned by this agent');
      return { localId, serverId: patient._id.toString(), success: true };
    }

    throw new Error(`Unsupported patient sync action: ${action}`);
  }

  if (type === 'screening') {
    if (action === 'create') {
      let patientId = data.patientId || data.patient_id;

      // Reconcile localId if this screening references a patient created in this batch
      if (patientId && localIdMap.has(patientId)) {
        patientId = localIdMap.get(patientId);
      }

      if (!patientId || !mongoose.Types.ObjectId.isValid(patientId)) {
        throw new Error(`Invalid patient ID: ${patientId || 'missing'}`);
      }

      // IDOR guard: verify the patient belongs to this agent before creating screening
      const patient = await Patient.findOne({
        _id: patientId,
        agentId,
        isDeleted: false,
      });
      if (!patient) {
        throw new Error('Patient not found or not owned by this agent');
      }

      const prediction = await aiService.predictRisk({
        painLevel: data.painLevel,
        stiffnessDuration: data.stiffnessDuration,
        swelling: data.swelling,
        pastInjury: data.pastInjury,
        gaitFeatures: data.gaitFeatures,
      });

      const screening = await Screening.create({
        patientId,
        agentId,
        painLevel: data.painLevel,
        stiffnessDuration: data.stiffnessDuration,
        swelling: data.swelling,
        pastInjury: data.pastInjury,
        gaitRawData: data.gaitFeatures,
        riskLevel: prediction.riskLevel,
        confidence: prediction.confidence,
        contributingFactors: prediction.contributingFactors,
        aiReasoning: prediction.aiReasoning,
        doctorRecommendations: prediction.doctorRecommendations,
        source: prediction.source,
        synced: true,
      });

      if (localId) {
        localIdMap.set(localId, screening._id.toString());
      }

      return { localId, serverId: screening._id.toString(), success: true };
    }

    throw new Error(`Unsupported screening sync action: ${action}`);
  }

  throw new Error(`Unsupported sync item type: ${type}`);
}

/**
 * POST /api/v1/sync/batch
 * Reconciles the mobile app's offline-queued records with the server.
 * Individual item failures are caught and reported without failing
 * the whole batch, so a single malformed record doesn't block the rest.
 */
const batchSync = asyncHandler(async (req, res) => {
  const items = req.body.items || [];
  const agentId = req.user._id;

  if (items.length === 0) {
    return res.status(200).json({ success: true, results: [] });
  }

  const results = [];
  const localIdMap = new Map();

  for (const item of items) {
    try {
      const result = await processSyncItem(item, agentId, localIdMap);
      results.push(result);
    } catch (err) {
      logger.warn('Sync item failed', { localId: item?.localId, error: err.message });
      results.push({
        localId: item?.localId || 'unknown',
        success: false,
        error: err.message,
      });
    }
  }

  res.status(200).json({ success: true, results });
});

/**
 * GET /api/v1/sync/status
 * Returns server time + last-modified timestamps for this agent's data,
 * so the mobile app can decide what needs re-fetching.
 */
const getSyncStatus = asyncHandler(async (req, res) => {
  const agentId = req.user._id;

  const [lastPatientUpdate, lastScreeningUpdate] = await Promise.all([
    Patient.findOne({ agentId }).sort({ updatedAt: -1 }).select('updatedAt'),
    Screening.findOne({ agentId }).sort({ updatedAt: -1 }).select('updatedAt'),
  ]);

  res.status(200).json({
    success: true,
    data: {
      serverTime: new Date().toISOString(),
      lastPatientUpdate: lastPatientUpdate?.updatedAt || null,
      lastScreeningUpdate: lastScreeningUpdate?.updatedAt || null,
    },
  });
});

module.exports = { batchSync, getSyncStatus };
