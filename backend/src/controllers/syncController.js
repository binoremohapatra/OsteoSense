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

async function syncAppBatch(patients = [], screenings = [], agentId) {
  const patientResults = [];
  const screeningResults = [];
  const localIdMap = new Map();

  // 1. Process Patients
  for (const p of patients) {
    const localId = p.localId ?? p.id ?? 'unknown';
    const action = (p._sync_action || p.action || 'insert').toLowerCase();

    try {
      if (action === 'insert' || action === 'create') {
        const patientData = {
          name: p.name || p.fullName,
          age: Number(p.age),
          gender: (p.gender || 'other').toLowerCase(),
          contact: p.contact || undefined,
          village: p.village || undefined,
          address: p.address || undefined,
          occupation: p.occupation || undefined,
          agentId,
        };

        const created = await Patient.create(patientData);
        const serverId = created._id.toString();

        localIdMap.set(String(localId), serverId);
        if (p.id) localIdMap.set(String(p.id), serverId);

        patientResults.push({ localId, serverId, success: true });
      } else if (action === 'update') {
        const patientId = p.server_id || p.serverId || p._id || p.id;
        if (!patientId || !mongoose.Types.ObjectId.isValid(patientId)) {
          throw new Error('Valid patient ID is required for update');
        }

        const updateData = {
          name: p.name || p.fullName,
          age: p.age !== undefined ? Number(p.age) : undefined,
          gender: p.gender ? p.gender.toLowerCase() : undefined,
          contact: p.contact,
          village: p.village,
          address: p.address,
          occupation: p.occupation,
        };
        Object.keys(updateData).forEach((k) => updateData[k] === undefined && delete updateData[k]);

        const updated = await Patient.findOneAndUpdate(
          { _id: patientId, agentId, isDeleted: false },
          { $set: updateData },
          { new: true, runValidators: true }
        );
        if (!updated) throw new Error('Patient not found or not owned by this agent');

        const serverId = updated._id.toString();
        localIdMap.set(String(localId), serverId);
        patientResults.push({ localId, serverId, success: true });
      } else {
        throw new Error(`Unsupported patient action: ${action}`);
      }
    } catch (err) {
      logger.warn('Patient sync item failed', { localId, error: err.message });
      patientResults.push({ localId, success: false, error: err.message });
    }
  }

  // 2. Process Screenings
  for (const s of screenings) {
    const localId = s.localId ?? s.id ?? 'unknown';
    const action = (s._sync_action || s.action || 'insert').toLowerCase();

    try {
      if (action === 'insert' || action === 'create') {
        let patientId = s.patient_id ?? s.patientId;

        // Reconcile local ID from the newly created patients in this batch
        if (patientId !== undefined && localIdMap.has(String(patientId))) {
          patientId = localIdMap.get(String(patientId));
        }

        if (!patientId || !mongoose.Types.ObjectId.isValid(patientId)) {
          throw new Error(`Invalid patient ID: ${patientId || 'missing'}`);
        }

        const patient = await Patient.findOne({
          _id: patientId,
          agentId,
          isDeleted: false,
        });
        if (!patient) {
          throw new Error('Patient not found or not owned by this agent');
        }

        // Parse gait features
        let gaitFeatures = [];
        const rawGait = s.gait_data ?? s.gaitData ?? s.gaitFeatures;
        if (typeof rawGait === 'string') {
          try {
            const parsed = JSON.parse(rawGait);
            gaitFeatures = Array.isArray(parsed) ? parsed : [];
          } catch (_) {
            try {
              gaitFeatures = rawGait.replace(/[\[\]]/g, '').split(',').map((v) => parseFloat(v.trim())).filter((v) => !isNaN(v));
            } catch (e) {}
          }
        } else if (Array.isArray(rawGait)) {
          gaitFeatures = rawGait;
        }

        const swelling = s.swelling === 1 || s.swelling === '1' || s.swelling === true;
        const painLevel = Number(s.pain_level ?? s.painLevel ?? 0);
        const stiffnessDuration = s.stiffness_duration ?? s.stiffnessDuration ?? '';
        const pastInjury = s.past_injury ?? s.pastInjury ?? '';

        const prediction = await aiService.predictRisk({
          painLevel,
          stiffnessDuration,
          swelling,
          pastInjury,
          gaitFeatures,
        });

        const createdScreening = await Screening.create({
          patientId,
          agentId,
          painLevel,
          stiffnessDuration,
          swelling,
          pastInjury,
          gaitRawData: gaitFeatures,
          riskLevel: prediction.riskLevel,
          confidence: prediction.confidence,
          contributingFactors: prediction.contributingFactors,
          aiReasoning: prediction.aiReasoning,
          doctorRecommendations: prediction.doctorRecommendations,
          source: prediction.source,
          screeningDate: s.screening_date ? new Date(s.screening_date) : new Date(),
          synced: true,
        });

        screeningResults.push({
          localId,
          serverId: createdScreening._id.toString(),
          success: true,
        });
      } else {
        throw new Error(`Unsupported screening action: ${action}`);
      }
    } catch (err) {
      logger.warn('Screening sync item failed', { localId, error: err.message });
      screeningResults.push({ localId, success: false, error: err.message });
    }
  }

  return { patients: patientResults, screenings: screeningResults };
}

/**
 * POST /api/v1/sync/batch
 * Reconciles the mobile app's offline-queued records with the server.
 * Supports Flutter mobile app's { patients: [...], screenings: [...] } format
 * as well as the legacy { items: [...] } format.
 */
const batchSync = asyncHandler(async (req, res) => {
  const agentId = req.user._id;

  // 1. Mobile app payload: { patients: [...], screenings: [...] }
  if (req.body.patients || req.body.screenings) {
    const results = await syncAppBatch(
      req.body.patients || [],
      req.body.screenings || [],
      agentId
    );
    return res.status(200).json({ success: true, results });
  }

  // 2. Generic items array: { items: [...] }
  const items = req.body.items || [];
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
