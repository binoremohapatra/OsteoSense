'use strict';

const assignmentService = require('../services/assignmentService');
const asyncHandler = require('../utils/asyncHandler');
const ApiError = require('../utils/ApiError');

/**
 * POST /api/v1/village-assignments
 * Create a new village assignment
 */
const createAssignment = asyncHandler(async (req, res) => {
  const assignment = await assignmentService.createAssignment(req.body);

  res.status(201).json({
    success: true,
    data: assignment,
  });
});

/**
 * GET /api/v1/village-assignments
 * Get all village assignments
 */
const getAllAssignments = asyncHandler(async (req, res) => {
  const { location, healthWorkerId } = req.query;

  let assignments;
  if (location) {
    assignments = await assignmentService.getAssignmentsByLocation(location);
  } else if (healthWorkerId) {
    assignments = await assignmentService.getAssignmentsByHealthWorker(healthWorkerId);
  } else {
    assignments = await assignmentService.getAllAssignments();
  }

  res.status(200).json({
    success: true,
    data: assignments,
  });
});

/**
 * PUT /api/v1/village-assignments/:id
 * Update village assignment
 */
const updateAssignment = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const assignment = await assignmentService.updateAssignment(id, req.body);

  res.status(200).json({
    success: true,
    data: assignment,
  });
});

/**
 * DELETE /api/v1/village-assignments/:id
 * Deactivate village assignment
 */
const deleteAssignment = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const assignment = await assignmentService.deactivateAssignment(id);

  res.status(200).json({
    success: true,
    data: assignment,
    message: 'Assignment deactivated successfully',
  });
});

/**
 * GET /api/v1/village-assignments/health-worker/:village
 * Get assigned health worker for a specific village
 */
const getHealthWorkerForVillage = asyncHandler(async (req, res) => {
  const { village } = req.params;
  const healthWorkerId = await assignmentService.assignHealthWorkerByVillage(village);

  if (!healthWorkerId) {
    throw ApiError.notFound('No health worker assigned to this village');
  }

  res.status(200).json({
    success: true,
    data: { healthWorkerId },
  });
});

module.exports = {
  createAssignment,
  getAllAssignments,
  updateAssignment,
  deleteAssignment,
  getHealthWorkerForVillage,
};
