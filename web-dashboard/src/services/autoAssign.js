/** Deterministic village/location → health-worker mapping (dashboard-only). */

export function workerId(worker) {
  return String(worker?.id || worker?._id || '');
}

export function normalizePlace(value) {
  return String(value || '')
    .toLowerCase()
    .replace(/[^a-z0-9\s]/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
}

export function placeTokens(value) {
  return normalizePlace(value).split(' ').filter((token) => token.length > 1);
}

function hashString(value) {
  let hash = 0;
  const text = String(value || '');
  for (let i = 0; i < text.length; i += 1) {
    hash = (hash * 31 + text.charCodeAt(i)) >>> 0;
  }
  return hash;
}

export function scoreWorkerForVillage(worker, village, address = '') {
  const villageNorm = normalizePlace(village);
  if (!villageNorm) return 0;

  const locationNorm = normalizePlace(worker?.location);
  const centerNorm = normalizePlace(worker?.healthCenterId);
  const addressNorm = normalizePlace(address);
  let score = 0;

  if (locationNorm && locationNorm === villageNorm) score += 100;
  else if (locationNorm && (locationNorm.includes(villageNorm) || villageNorm.includes(locationNorm))) score += 80;

  if (addressNorm && locationNorm && (addressNorm.includes(locationNorm) || locationNorm.includes(addressNorm))) {
    score += 24;
  }

  const villageBits = placeTokens(village);
  const locationBits = placeTokens(worker?.location);
  const centerBits = placeTokens(worker?.healthCenterId);
  const overlap = villageBits.filter((token) => locationBits.includes(token) || centerBits.includes(token));
  score += overlap.length * 18;

  if (centerNorm && (villageNorm.includes(centerNorm) || centerNorm.includes(villageNorm))) score += 12;

  return score;
}

export function assignWorker(patient, workers) {
  const list = Array.isArray(workers) ? workers.filter(Boolean) : [];
  if (!list.length) {
    return { worker: null, reason: 'no_workers', score: 0 };
  }

  const village = patient?.village || '';
  const address = patient?.address || '';
  const villageKey = normalizePlace(village) || `unspecified:${patient?.id || patient?._id || 'x'}`;

  const scored = list.map((worker) => ({
    worker,
    score: scoreWorkerForVillage(worker, village, address),
  }));
  const best = Math.max(...scored.map((row) => row.score));

  if (best > 0) {
    const tied = scored.filter((row) => row.score === best);
    const pick = tied[hashString(villageKey) % tied.length];
    return { worker: pick.worker, reason: 'location_match', score: pick.score };
  }

  const fallback = list[hashString(villageKey) % list.length];
  return { worker: fallback, reason: village ? 'balanced_fallback' : 'unspecified_village', score: 0 };
}

export function assignmentLabel(reason) {
  if (reason === 'location_match') return 'Village / location match';
  if (reason === 'balanced_fallback') return 'Balanced across catchment';
  if (reason === 'unspecified_village') return 'No village on file';
  if (reason === 'no_workers') return 'No active workers';
  return 'Unassigned';
}

export function wearableId(worker) {
  const id = workerId(worker).slice(-6).toUpperCase() || '000000';
  const center = normalizePlace(worker?.healthCenterId).slice(0, 4).toUpperCase() || 'PHC';
  return `WS-${center}-${id}`;
}

export function buildVillageCoverage(villages, workers) {
  const uniqueVillages = [...new Set((villages || []).map((row) => row.village || row).filter(Boolean))];
  return uniqueVillages.map((village) => {
    const assignment = assignWorker({ village }, workers);
    return {
      village,
      ...assignment,
      healthCenter: assignment.worker?.healthCenterId || 'Unassigned center',
    };
  });
}

export function groupWorkersByCenter(workers) {
  const groups = new Map();
  (workers || []).forEach((worker) => {
    const key = worker.healthCenterId || 'Unassigned center';
    if (!groups.has(key)) groups.set(key, []);
    groups.get(key).push(worker);
  });
  return [...groups.entries()].map(([center, members]) => ({ center, members }));
}
