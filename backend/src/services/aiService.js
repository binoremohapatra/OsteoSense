'use strict';

const axios = require('axios');
const env = require('../config/env');
const logger = require('../utils/logger');

const AI_REQUEST_TIMEOUT_MS = 5000;

function parseStiffnessDuration(raw) {
  if (!raw || typeof raw !== 'string') return 0;
  const str = raw.toLowerCase().trim();

  const numberMatch = str.match(/(\d+(?:\.\d+)?)/);
  if (!numberMatch) return 0;

  const value = parseFloat(numberMatch[1]);

  if (str.includes('hour') || str.includes('hr')) {
    return value * 60;
  }
  return value;
}

function computeGaitVariance(gaitFeatures) {
  if (!Array.isArray(gaitFeatures) || gaitFeatures.length < 2) return 0;

  const numeric = gaitFeatures.filter((v) => typeof v === 'number' && !Number.isNaN(v));
  if (numeric.length < 2) return 0;

  const mean = numeric.reduce((sum, v) => sum + v, 0) / numeric.length;
  const variance =
    numeric.reduce((sum, v) => sum + (v - mean) ** 2, 0) / numeric.length;

  return variance;
}

function fallbackRuleBasedPredict({ painLevel, stiffnessMinutes, swelling, pastInjury, gaitFeatures }) {
  const contributingFactors = [];
  let score = 0;

  const painComponent = (painLevel / 10) * 0.3;
  score += painComponent;
  if (painLevel >= 7) {
    contributingFactors.push('Severe pain level reported');
  } else if (painLevel >= 4) {
    contributingFactors.push('Moderate pain level reported');
  }

  if (stiffnessMinutes > 30) {
    score += 0.25;
    contributingFactors.push('Prolonged joint stiffness (>30 minutes)');
  } else if (stiffnessMinutes > 15) {
    score += 0.12;
    contributingFactors.push('Moderate joint stiffness (>15 minutes)');
  }

  if (swelling) {
    score += 0.15;
    contributingFactors.push('Joint swelling present');
  }

  if (pastInjury) {
    score += 0.15;
    contributingFactors.push('History of joint injury');
  }

  const gaitVariance = computeGaitVariance(gaitFeatures);
  const GAIT_VARIANCE_CEILING = 4.0;
  const gaitComponent = Math.min(gaitVariance / GAIT_VARIANCE_CEILING, 1) * 0.15;
  score += gaitComponent;
  if (gaitComponent > 0.08) {
    contributingFactors.push('Irregular gait pattern detected');
  }

  score = Math.min(score, 1);

  let riskLevel;
  if (score >= 0.6) riskLevel = 'high';
  else if (score >= 0.25) riskLevel = 'medium';
  else riskLevel = 'low';

  if (contributingFactors.length === 0) {
    contributingFactors.push('No significant risk factors identified');
  }

  const doctorRecommendations = buildRecommendation(riskLevel);

  return {
    riskLevel,
    confidence: Math.round((0.55 + score * 0.15) * 100) / 100,
    contributingFactors,
    aiReasoning:
      `Rule-based triage score ${score.toFixed(2)} derived from pain level, stiffness ` +
      `duration, swelling, injury history, and gait variance.`,
    doctorRecommendations,
  };
}

function buildRecommendation(riskLevel) {
  switch (riskLevel) {
    case 'high':
      return 'Refer to an orthopedic specialist for clinical evaluation and imaging (X-ray/MRI) as soon as possible.';
    case 'medium':
      return 'Recommend follow-up screening in 4-6 weeks; advise preventive exercises and weight management in the meantime.';
    default:
      return 'No immediate referral needed; share preventive care guidance and re-screen at next camp visit.';
  }
}

function mapStiffnessToCategory(stiffnessDuration, stiffnessMinutes) {
  if (typeof stiffnessDuration === 'string') {
    const s = stiffnessDuration.toLowerCase();
    if (s.includes('under') || s.includes('<') || s.includes('15 min')) return '<30';
    if (s.includes('30') || s.includes('45')) return '30-60';
    if (s.includes('hour') || s.includes('hr') || s.includes('>60')) return '>60';
    if (s.includes('none') || s.includes('no')) return 'none';
  }
  if (stiffnessMinutes > 60) return '>60';
  if (stiffnessMinutes >= 30) return '30-60';
  if (stiffnessMinutes > 0) return '<30';
  return 'none';
}

async function predictRisk({ painLevel, stiffnessDuration, swelling, pastInjury, gaitFeatures }) {
  const stiffnessMinutes = parseStiffnessDuration(stiffnessDuration);
  const variance = computeGaitVariance(gaitFeatures);

  const fastApiPayload = {
    pain_level: Number(painLevel),
    stiffness_duration: mapStiffnessToCategory(stiffnessDuration, stiffnessMinutes),
    swelling: Boolean(swelling),
    past_injury: Boolean(pastInjury && pastInjury.toString().trim().length > 0),
    gait_data: JSON.stringify({ variance }),
  };

  try {
    const response = await axios.post(`${env.AI_SERVICE_URL}/predict`, fastApiPayload, {
      timeout: AI_REQUEST_TIMEOUT_MS,
    });

    const data = response.data || {};
    const riskLevel = data.risk_level || data.riskLevel;
    if (!riskLevel) {
      throw new Error('Malformed AI response: missing risk level');
    }

    const confidence = typeof data.confidence === 'number' ? data.confidence : 0.75;
    const contributingFactors = data.contributing_factors || data.contributingFactors || [];
    const aiReasoning = data.reasoning || data.aiReasoning || 'AI prediction based on clinical symptoms and gait analysis.';
    const doctorRecommendations = data.doctorRecommendations || buildRecommendation(riskLevel);

    return {
      riskLevel,
      confidence,
      contributingFactors,
      aiReasoning,
      doctorRecommendations,
      source: 'ml_model',
    };
  } catch (err) {
    logger.warn('AI microservice unreachable, using fallback', { error: err.message });

    const fallbackResult = fallbackRuleBasedPredict({
      painLevel,
      stiffnessMinutes,
      swelling: Boolean(swelling),
      pastInjury: Boolean(pastInjury && pastInjury.toString().trim().length > 0),
      gaitFeatures: gaitFeatures || [],
    });

    return { ...fallbackResult, source: 'fallback_rules' };
  }
}

module.exports = {
  predictRisk,
  fallbackRuleBasedPredict,
  parseStiffnessDuration,
  computeGaitVariance,
  buildRecommendation,
  mapStiffnessToCategory,
};
