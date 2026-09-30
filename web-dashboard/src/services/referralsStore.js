const KEY = 'jointsaathi.referrals';
const FAILED_SYNC_KEY = 'jointsaathi.failedSyncs';

export function loadReferrals() {
  try {
    return JSON.parse(localStorage.getItem(KEY)) || [];
  } catch {
    return [];
  }
}

export function saveReferrals(rows) {
  localStorage.setItem(KEY, JSON.stringify(rows));
}

export function upsertReferral(entry) {
  const rows = loadReferrals();
  const idx = rows.findIndex((row) => row.screeningId === entry.screeningId);
  if (idx >= 0) rows[idx] = { ...rows[idx], ...entry, updatedAt: new Date().toISOString() };
  else rows.unshift({ ...entry, createdAt: new Date().toISOString(), updatedAt: new Date().toISOString() });
  saveReferrals(rows);
  return rows;
}

export function loadFailedSyncs() {
  try {
    return JSON.parse(localStorage.getItem(FAILED_SYNC_KEY)) || [];
  } catch {
    return [];
  }
}

export function recordFailedSyncs(results = []) {
  const failed = results
    .filter((row) => row && row.success === false)
    .map((row) => ({
      localId: row.localId,
      error: row.error || 'Upload failed',
      at: new Date().toISOString(),
    }));
  if (!failed.length) return loadFailedSyncs();
  const next = [...failed, ...loadFailedSyncs()].slice(0, 40);
  localStorage.setItem(FAILED_SYNC_KEY, JSON.stringify(next));
  return next;
}
