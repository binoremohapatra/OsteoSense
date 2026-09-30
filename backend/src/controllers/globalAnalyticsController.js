'use strict';

const mongoose = require('mongoose');
const Patient = require('../models/Patient');
const Screening = require('../models/Screening');
const asyncHandler = require('../utils/asyncHandler');
const ApiError = require('../utils/ApiError');

/**
 * GET /api/v1/global-analytics/overview
 * Global analytics across all patients and screenings (not scoped to individual agents)
 */
const getGlobalOverview = asyncHandler(async (req, res) => {
  const [totalPatients, totalScreenings, riskAgg, confidenceAgg] = await Promise.all([
    Patient.countDocuments({ isDeleted: false }),
    Screening.countDocuments(),
    Screening.aggregate([
      { $group: { _id: '$riskLevel', count: { $sum: 1 } } },
    ]),
    Screening.aggregate([
      { $match: { confidence: { $ne: null } } },
      { $group: { _id: null, avgConfidence: { $avg: '$confidence' } } },
    ]),
  ]);

  const riskDistribution = { low: 0, medium: 0, high: 0 };
  riskAgg.forEach((bucket) => {
    if (bucket._id in riskDistribution) riskDistribution[bucket._id] = bucket.count;
  });

  const avgConfidence = confidenceAgg[0]?.avgConfidence ?? null;

  res.status(200).json({
    success: true,
    data: {
      totalPatients,
      totalScreenings,
      riskDistribution,
      avgConfidence: avgConfidence !== null ? Math.round(avgConfidence * 100) / 100 : null,
    },
  });
});

/**
 * GET /api/v1/global-analytics/trends?period=30d
 * Global screening trends across all agents
 */
const getGlobalTrends = asyncHandler(async (req, res) => {
  const rawPeriod = req.query.period;
  const period = typeof rawPeriod === 'string' ? rawPeriod.trim() : '30d';

  const match = period.match(/^(\d+)d$/);
  if (!match) {
    throw ApiError.badRequest('period must be one of: 7d, 30d, 90d, 365d');
  }
  const days = parseInt(match[1], 10);
  if (![7, 30, 90, 365].includes(days)) {
    throw ApiError.badRequest('period must be one of: 7d, 30d, 90d, 365d');
  }

  const startDate = new Date();
  startDate.setDate(startDate.getDate() - days);

  const groupByWeek = days > 30;
  const dateFormat = groupByWeek ? '%G-W%V' : '%Y-%m-%d';

  const trends = await Screening.aggregate([
    { $match: { screeningDate: { $gte: startDate } } },
    {
      $group: {
        _id: { $dateToString: { format: dateFormat, date: '$screeningDate' } },
        count: { $sum: 1 },
      },
    },
    { $sort: { _id: 1 } },
    { $project: { _id: 0, date: '$_id', count: 1 } },
  ]);

  res.status(200).json({ success: true, data: trends });
});

/**
 * GET /api/v1/global-analytics/risk-distribution
 * Global risk distribution across all screenings
 */
const getGlobalRiskDistribution = asyncHandler(async (req, res) => {
  const riskAgg = await Screening.aggregate([
    { $group: { _id: '$riskLevel', count: { $sum: 1 } } },
  ]);

  const riskDistribution = { low: 0, medium: 0, high: 0 };
  riskAgg.forEach((bucket) => {
    if (bucket._id in riskDistribution) riskDistribution[bucket._id] = bucket.count;
  });

  res.status(200).json({ success: true, data: riskDistribution });
});

/**
 * GET /api/v1/global-analytics/locations
 * Global village breakdown across all screenings
 */
const getGlobalLocations = asyncHandler(async (req, res) => {
  const locations = await Screening.aggregate([
    {
      $lookup: {
        from: 'patients',
        localField: 'patientId',
        foreignField: '_id',
        as: 'patient',
      },
    },
    { $unwind: '$patient' },
    { $match: { 'patient.isDeleted': false } },
    {
      $group: {
        _id: { $ifNull: ['$patient.village', 'Unknown'] },
        totalScreenings: { $sum: 1 },
        highRiskCount: {
          $sum: { $cond: [{ $eq: ['$riskLevel', 'high'] }, 1, 0] },
        },
      },
    },
    {
      $project: {
        _id: 0,
        village: '$_id',
        totalScreenings: 1,
        highRiskCount: 1,
        riskPercentage: {
          $round: [
            {
              $multiply: [
                { $cond: [{ $eq: ['$totalScreenings', 0] }, 0, { $divide: ['$highRiskCount', '$totalScreenings'] }] },
                100,
              ],
            },
            1,
          ],
        },
      },
    },
    { $sort: { highRiskCount: -1 } },
  ]);

  res.status(200).json({ success: true, data: locations });
});

module.exports = { getGlobalOverview, getGlobalTrends, getGlobalRiskDistribution, getGlobalLocations };
