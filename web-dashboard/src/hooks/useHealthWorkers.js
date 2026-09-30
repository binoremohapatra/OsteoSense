import { useEffect, useState } from 'react';
import { authApi } from '../api/services';

export default function useHealthWorkers() {
  const [workers, setWorkers] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    let cancelled = false;
    authApi
      .healthWorkers()
      .then((res) => {
        if (!cancelled) setWorkers(res.data || []);
      })
      .catch(() => {
        if (!cancelled) setWorkers([]);
      })
      .finally(() => {
        if (!cancelled) setLoading(false);
      });
    return () => {
      cancelled = true;
    };
  }, []);

  return { workers, loading };
}
