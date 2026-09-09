'use strict';

const axios = require('axios');
const {
  predictRisk,
  fallbackRuleBasedPredict,
  parseStiffnessDuration,
  computeGaitVariance,
} = require('../src/services/aiService');

jest.mock('axios');

describe('AI Service Integration & Fallback Unit Tests', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  describe('parseStiffnessDuration', () => {
    it('correctly parses minutes and hours', () => {
      expect(parseStiffnessDuration('15 minutes')).toBe(15);
      expect(parseStiffnessDuration('30 mins')).toBe(30);
      expect(parseStiffnessDuration('1 hour')).toBe(60);
      expect(parseStiffnessDuration('2 hrs')).toBe(120);
      expect(parseStiffnessDuration('invalid')).toBe(0);
      expect(parseStiffnessDuration('')).toBe(0);
      expect(parseStiffnessDuration(null)).toBe(0);
    });
  });

  describe('computeGaitVariance', () => {
    it('computes variance for valid float array', () => {
      const v = computeGaitVariance([1, 2, 3]);
      expect(v).toBeCloseTo(0.6666, 3);
    });

    it('returns 0 for arrays with less than 2 numeric values', () => {
      expect(computeGaitVariance([])).toBe(0);
      expect(computeGaitVariance([1])).toBe(0);
      expect(computeGaitVariance(null)).toBe(0);
    });
  });

  describe('predictRisk -> FastAPI translation', () => {
    it('translates camelCase into snake_case and sends correct payload to FastAPI', async () => {
      axios.post.mockResolvedValueOnce({
        status: 200,
        data: {
          risk_level: 'high',
          confidence: 0.89,
          contributing_factors: ['Severe pain level (≥7/10)', 'Joint swelling observed'],
          reasoning: 'Multiple significant risk factors detected.',
          model_version: 'rule_based_v1.0',
        },
      });

      const res = await predictRisk({
        painLevel: 8,
        stiffnessDuration: '45 minutes',
        swelling: true,
        pastInjury: 'Twisted knee',
        gaitFeatures: [0.2, 0.4, 0.6],
      });

      expect(axios.post).toHaveBeenCalledTimes(1);
      const [url, sentPayload] = axios.post.mock.calls[0];
      expect(url).toContain('/predict');
      expect(sentPayload).toEqual({
        pain_level: 8,
        stiffness_duration: '30-60',
        swelling: true,
        past_injury: true,
        gait_data: expect.any(String),
      });

      // Verify response is mapped back to backend model
      expect(res.riskLevel).toBe('high');
      expect(res.confidence).toBe(0.89);
      expect(res.contributingFactors).toEqual(['Severe pain level (≥7/10)', 'Joint swelling observed']);
      expect(res.aiReasoning).toBe('Multiple significant risk factors detected.');
      expect(res.source).toBe('ml_model');
      expect(res.doctorRecommendations).toBeDefined();
    });

    it('falls back to rule-based triage when FastAPI is unreachable or errors', async () => {
      axios.post.mockRejectedValueOnce(new Error('Connection refused'));

      const res = await predictRisk({
        painLevel: 7,
        stiffnessDuration: '30 minutes',
        swelling: true,
        pastInjury: '',
        gaitFeatures: [],
      });

      expect(res.source).toBe('fallback_rules');
      expect(res.riskLevel).toBeDefined();
      expect(res.confidence).toBeGreaterThan(0);
      expect(res.aiReasoning).toContain('Rule-based triage');
      expect(res.doctorRecommendations).toBeDefined();
    });

    it('falls back to rule-based triage when FastAPI returns malformed response', async () => {
      axios.post.mockResolvedValueOnce({
        status: 200,
        data: { invalid_field: 'nothing' }, // Missing risk_level
      });

      const res = await predictRisk({
        painLevel: 2,
        stiffnessDuration: 'none',
        swelling: false,
        pastInjury: '',
        gaitFeatures: [],
      });

      expect(res.source).toBe('fallback_rules');
      expect(res.riskLevel).toBe('low');
    });
  });

  describe('fallbackRuleBasedPredict', () => {
    it('returns high risk for severe pain and multiple symptoms', () => {
      const res = fallbackRuleBasedPredict({
        painLevel: 9,
        stiffnessMinutes: 45,
        swelling: true,
        pastInjury: true,
        gaitFeatures: [0.1, 0.9, 0.2, 0.8],
      });

      expect(res.riskLevel).toBe('high');
      expect(res.confidence).toBeGreaterThanOrEqual(0.6);
      expect(res.contributingFactors).toContain('Severe pain level reported');
      expect(res.contributingFactors).toContain('Prolonged joint stiffness (>30 minutes)');
    });

    it('returns low risk for minimal pain and no symptoms', () => {
      const res = fallbackRuleBasedPredict({
        painLevel: 1,
        stiffnessMinutes: 0,
        swelling: false,
        pastInjury: false,
        gaitFeatures: [],
      });

      expect(res.riskLevel).toBe('low');
      expect(res.contributingFactors).toContain('No significant risk factors identified');
    });
  });
});
