function toPoints(values) {
  if (!Array.isArray(values)) return [];
  return values
    .map((value, index) => {
      if (typeof value === 'number' && Number.isFinite(value)) return { t: index, v: value };
      if (value && typeof value === 'object') {
        const n = Number(value.v ?? value.y ?? value.value ?? value.ax ?? value.ay ?? value.az);
        if (Number.isFinite(n)) return { t: Number(value.t ?? value.x ?? index), v: n };
      }
      const n = Number(value);
      return Number.isFinite(n) ? { t: index, v: n } : null;
    })
    .filter(Boolean);
}

function pickChannel(source, keys) {
  for (const key of keys) {
    if (Array.isArray(source?.[key]) && source[key].length) return toPoints(source[key]);
  }
  return [];
}

export function extractSensorSeries(screening) {
  const raw = screening?.gaitRawData ?? screening?.gaitData ?? screening?.gaitFeatures ?? null;
  const empty = { imu: [], emg: [], piezo: [] };

  if (!raw) return empty;

  if (Array.isArray(raw)) {
    if (!raw.length) return empty;
    if (typeof raw[0] === 'number' || typeof raw[0] === 'string') {
      return { imu: toPoints(raw), emg: [], piezo: [] };
    }
    if (typeof raw[0] === 'object') {
      return {
        imu: toPoints(raw.map((row) => row?.imu ?? row?.accel ?? row?.ax ?? row?.x)),
        emg: toPoints(raw.map((row) => row?.emg ?? row?.muscle ?? row?.y)),
        piezo: toPoints(raw.map((row) => row?.piezo ?? row?.acoustic ?? row?.z)),
      };
    }
  }

  if (typeof raw === 'object') {
    return {
      imu: pickChannel(raw, ['imu', 'IMU', 'accel', 'accelerometer', 'gait', 'motion']),
      emg: pickChannel(raw, ['emg', 'EMG', 'muscle']),
      piezo: pickChannel(raw, ['piezo', 'acoustic', 'sound']),
    };
  }

  return empty;
}

export function hasSensorData(series) {
  return Boolean(series?.imu?.length || series?.emg?.length || series?.piezo?.length);
}
