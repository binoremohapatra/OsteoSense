import { villageAssignmentApi } from '../api/services';
import { authApi } from '../api/services';

/**
 * Backend-integrated assignment service that uses the server-side village-to-worker mapping
 * This replaces the client-side autoAssign.js calculation with actual backend assignments
 */

let assignmentCache = new Map();
let workersCache = [];
let lastFetchTime = 0;
const CACHE_DURATION = 5 * 60 * 1000; // 5 minutes

/**
 * Fetch all village assignments from backend
 */
async function fetchAssignments() {
  const now = Date.now();
  if (now - lastFetchTime < CACHE_DURATION && assignmentCache.size > 0) {
    return assignmentCache;
  }

  try {
    const response = await villageAssignmentApi.list();
    const assignments = response.data || [];
    
    assignmentCache.clear();
    assignments.forEach(assignment => {
      if (assignment.isActive && assignment.village) {
        assignmentCache.set(assignment.village.toLowerCase().trim(), assignment);
      }
    });
    
    lastFetchTime = now;
    return assignmentCache;
  } catch (error) {
    console.error('Failed to fetch assignments:', error);
    return assignmentCache;
  }
}

/**
 * Fetch all health workers from backend
 */
async function fetchWorkers() {
  try {
    const response = await authApi.healthWorkers();
    workersCache = response.data || [];
    return workersCache;
  } catch (error) {
    console.error('Failed to fetch workers:', error);
    return workersCache;
  }
}

/**
 * Get assigned health worker for a specific village using backend mapping
 * @param {string} village - Patient's village
 * @returns {Promise<Object|null>} - Worker object or null
 */
export async function getAssignedWorkerForVillage(village) {
  if (!village) return null;
  
  const assignments = await fetchAssignments();
  const assignment = assignments.get(village.toLowerCase().trim());
  
  if (!assignment || !assignment.assignedHealthWorkerId) {
    return null;
  }
  
  // Get worker details
  const workers = await fetchWorkers();
  const worker = workers.find(w => 
    (w.id === assignment.assignedHealthWorkerId || w._id === assignment.assignedHealthWorkerId)
  );
  
  return worker || null;
}

/**
 * Get assignment information for a patient
 * @param {Object} patient - Patient object with village
 * @returns {Promise<Object>} - Assignment info with worker and reason
 */
export async function getPatientAssignment(patient) {
  const village = patient?.village;
  
  if (!village) {
    const workers = await fetchWorkers();
    // Fallback: balanced assignment if no village
    if (workers.length > 0) {
      const hash = simpleHash(patient?.id || patient?._id || 'unknown');
      const worker = workers[hash % workers.length];
      return { 
        worker, 
        reason: 'unspecified_village',
        score: 0 
      };
    }
    return { worker: null, reason: 'no_workers', score: 0 };
  }
  
  const worker = await getAssignedWorkerForVillage(village);
  
  if (worker) {
    return { 
      worker, 
      reason: 'location_match',
      score: 100 
    };
  }
  
  // Fallback if no assignment exists
  const workers = await fetchWorkers();
  if (workers.length > 0) {
    const hash = simpleHash(village);
    const fallbackWorker = workers[hash % workers.length];
    return { 
      worker: fallbackWorker, 
      reason: 'balanced_fallback',
      score: 0 
    };
  }
  
  return { worker: null, reason: 'no_workers', score: 0 };
}

/**
 * Simple hash function for deterministic fallback
 */
function simpleHash(str) {
  let hash = 0;
  const text = String(str || '');
  for (let i = 0; i < text.length; i++) {
    hash = (hash * 31 + text.charCodeAt(i)) >>> 0;
  }
  return hash;
}

/**
 * Get assignment label for display
 */
export function assignmentLabel(reason) {
  if (reason === 'location_match') return 'Village / location match';
  if (reason === 'balanced_fallback') return 'Balanced across catchment';
  if (reason === 'unspecified_village') return 'No village on file';
  if (reason === 'no_workers') return 'No active workers';
  return 'Unassigned';
}

/**
 * Get all village assignments for admin view
 */
export async function getAllVillageAssignments() {
  const assignments = await fetchAssignments();
  const workers = await fetchWorkers();
  
  return Array.from(assignments.values()).map(assignment => {
    const worker = workers.find(w => 
      (w.id === assignment.assignedHealthWorkerId || w._id === assignment.assignedHealthWorkerId)
    );
    return {
      ...assignment,
      worker
    };
  });
}

/**
 * Clear cache (useful for testing or manual refresh)
 */
export function clearAssignmentCache() {
  assignmentCache.clear();
  workersCache = [];
  lastFetchTime = 0;
}

/**
 * Get worker by ID
 */
export async function getWorkerById(workerId) {
  const workers = await fetchWorkers();
  return workers.find(w => w.id === workerId || w._id === workerId) || null;
}