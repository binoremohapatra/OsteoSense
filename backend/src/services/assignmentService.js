'use strict';

const VillageAssignment = require('../models/VillageAssignment');
const User = require('../models/User');

/**
 * Auto-assign a health worker based on patient's village
 * @param {string} village - Patient's village
 * @returns {Promise<string|null>} - Returns health worker ID or null if no assignment found
 */
async function assignHealthWorkerByVillage(village) {
  if (!village || typeof village !== 'string') {
    return null;
  }

  const assignment = await VillageAssignment.findOne({
    village: village.trim(),
    isActive: true,
  }).populate('assignedHealthWorkerId');

  if (!assignment || !assignment.assignedHealthWorkerId) {
    return null;
  }

  // Check if the assigned health worker is active
  const healthWorker = await User.findOne({
    _id: assignment.assignedHealthWorkerId._id,
    isActive: true,
    role: 'agent',
  });

  if (!healthWorker) {
    return null;
  }

  return healthWorker._id;
}

/**
 * Get all village assignments for a specific location
 * @param {string} location - Location/area name
 * @returns {Promise<Array>} - Array of village assignments
 */
async function getAssignmentsByLocation(location) {
  if (!location || typeof location !== 'string') {
    return [];
  }

  const assignments = await VillageAssignment.find({
    location: location.trim(),
    isActive: true,
  }).populate('assignedHealthWorkerId', 'fullName phoneNumber location');

  return assignments;
}

/**
 * Get all village assignments for a specific health worker
 * @param {string} healthWorkerId - Health worker's user ID
 * @returns {Promise<Array>} - Array of village assignments
 */
async function getAssignmentsByHealthWorker(healthWorkerId) {
  if (!healthWorkerId) {
    return [];
  }

  const assignments = await VillageAssignment.find({
    assignedHealthWorkerId: healthWorkerId,
    isActive: true,
  });

  return assignments;
}

/**
 * Create a new village assignment
 * @param {Object} assignmentData - Assignment data
 * @returns {Promise<Object>} - Created assignment
 */
async function createAssignment(assignmentData) {
  const { village, location, assignedHealthWorkerId } = assignmentData;

  if (!village || !location || !assignedHealthWorkerId) {
    throw new Error('village, location, and assignedHealthWorkerId are required');
  }

  // Check if health worker exists and is an active agent
  const healthWorker = await User.findOne({
    _id: assignedHealthWorkerId,
    isActive: true,
    role: 'agent',
  });

  if (!healthWorker) {
    throw new Error('Invalid health worker ID or worker is not active');
  }

  // Check if assignment already exists for this village
  const existing = await VillageAssignment.findOne({
    village: village.trim(),
    isActive: true,
  });

  if (existing) {
    throw new Error(`Village "${village}" is already assigned to a health worker`);
  }

  const assignment = await VillageAssignment.create({
    village: village.trim(),
    location: location.trim(),
    assignedHealthWorkerId,
  });

  return assignment;
}

/**
 * Update village assignment
 * @param {string} assignmentId - Assignment ID
 * @param {Object} updateData - Data to update
 * @returns {Promise<Object>} - Updated assignment
 */
async function updateAssignment(assignmentId, updateData) {
  const { village, location, assignedHealthWorkerId } = updateData;

  if (assignedHealthWorkerId) {
    // Check if health worker exists and is an active agent
    const healthWorker = await User.findOne({
      _id: assignedHealthWorkerId,
      isActive: true,
      role: 'agent',
    });

    if (!healthWorker) {
      throw new Error('Invalid health worker ID or worker is not active');
    }
  }

  if (village) {
    // Check if another assignment already exists for this village
    const existing = await VillageAssignment.findOne({
      village: village.trim(),
      isActive: true,
      _id: { $ne: assignmentId },
    });

    if (existing) {
      throw new Error(`Village "${village}" is already assigned to another health worker`);
    }
  }

  const assignment = await VillageAssignment.findByIdAndUpdate(
    assignmentId,
    {
      ...(village && { village: village.trim() }),
      ...(location && { location: location.trim() }),
      ...(assignedHealthWorkerId && { assignedHealthWorkerId }),
    },
    { new: true, runValidators: true }
  );

  if (!assignment) {
    throw new Error('Assignment not found');
  }

  return assignment;
}

/**
 * Deactivate village assignment
 * @param {string} assignmentId - Assignment ID
 * @returns {Promise<Object>} - Updated assignment
 */
async function deactivateAssignment(assignmentId) {
  const assignment = await VillageAssignment.findByIdAndUpdate(
    assignmentId,
    { isActive: false },
    { new: true }
  );

  if (!assignment) {
    throw new Error('Assignment not found');
  }

  return assignment;
}

/**
 * Get all active village assignments
 * @returns {Promise<Array>} - Array of all active assignments
 */
async function getAllAssignments() {
  const assignments = await VillageAssignment.find({
    isActive: true,
  }).populate('assignedHealthWorkerId', 'fullName phoneNumber location');

  return assignments;
}

module.exports = {
  assignHealthWorkerByVillage,
  getAssignmentsByLocation,
  getAssignmentsByHealthWorker,
  createAssignment,
  updateAssignment,
  deactivateAssignment,
  getAllAssignments,
};
