'use strict';

const mongoose = require('mongoose');
const Patient = require('../models/Patient');
const Screening = require('../models/Screening');
const asyncHandler = require('../utils/asyncHandler');
const logger = require('../utils/logger');
const aiService = require('../services/aiService');

async function processSyncItem(item, agentId, localIdMap = new Map()) {
  const { type, localId, action, data } = item;

  if (type === 'patient') {
    if (action === 'create' || action === 'insert') {
      const patient = await Patient.create({
        name: data.name || data.fullName,
        age: Number(data.age),
        gender: (data.gender || 'other').toLowerCase(),
        contact: data.contact || undefined,
        village: data.village || undefined,
        address: data.address || undefined,
        occupation: data.occupation || undefined,
        agentId,
      });

      if (localId) {
        localIdMap.set(localId, patient._id.toString());
      }

      return { localId, serverId: patient._id.toString(), success: true };
    }
    if ((action === 'update') && (data.id || data._id || data.serverId || data.server_id)) {
      const patientId = data.id || data._id || data.serverId || data.server_id;
      const patient = await Patient.findOneAndUpdate(
        { _id: patientId, agentId, isDeleted: false },
        { $set: data },
        { new: true }
      );
      if (!patient) throw new Error('Patient not found or not owned by this agent');

      if (localId) {
        localIdMap.set(localId, patient._id.toString());
      }

      return { localId, serverId: patient._id.toString(), success: true };
    }
    throw new Error(`Unsupported patient sync action: ${action}`);
  }

  if (type === 'screening') {
    if (action === 'create' || action === 'insert') {
      let patientId = data.patientId || data.patient_id;
      if (patientId && localIdMap.has(patientId)) {
        patientId = localIdMap.get(patientId);
      }

      if (!patientId || !mongoose.Types.ObjectId.isValid(patientId)) {
        throw new Error('Valid patient ID is required for screening sync');
      }

      const patient = await Patient.findOne({ _id: patientId, agentId, isDeleted: false });
      if (!patient) {
        throw new Error('Patient not found or not owned by this agent');
      }

      const painLevel = Number(data.painLevel ?? data.pain_level ?? 0);
      const stiffnessDuration = data.stiffnessDuration ?? data.stiffness_duration ?? '';
      const swelling = data.swelling === 1 || data.swelling === '1' || data.swelling === true;
      const pastInjury = data.pastInjury ?? data.past_injury ?? '';

      let gaitFeatures = [];
      const rawGait = data.gaitFeatures ?? data.gait_data ?? data.gaitData;
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

      const prediction = await aiService.predictRisk({
        painLevel,
        stiffnessDuration,
        swelling,
        pastInjury,
        gaitFeatures,
      });

      const screening = await Screening.create({
        patientId,
        agentId,
        painLevel,
        stiffnessDuration,
        swelling,
        pastInjury,
        gaitData: gaitFeatures,
        riskLevel: prediction.riskLevel,
        confidence: prediction.confidence,
        contributingFactors: prediction.contributingFactors,
        aiReasoning: prediction.aiReasoning,
        doctorRecommendations: prediction.doctorRecommendations,
        source: prediction.source,
        screeningDate: data.screeningDate ? new Date(data.screeningDate) : new Date(),
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

  for (const s of screenings) {
    const localId = s.localId ?? s.id ?? 'unknown';
    const action = (s._sync_action || s.action || 'insert').toLowerCase();

    try {
      if (action === 'insert' || action === 'create') {
        let patientId = s.patient_id ?? s.patientId;

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
          gaitData: gaitFeatures,
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

const batchSync = asyncHandler(async (req, res) => {
  const agentId = req.user._id;

  if (req.body.patients || req.body.screenings) {
    const results = await syncAppBatch(
      req.body.patients || [],
      req.body.screenings || [],
      agentId
    );
    return res.status(200).json({ success: true, results });
  }

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
