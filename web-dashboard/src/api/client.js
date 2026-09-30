import axios from 'axios';

export const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || 'https://osteosense-tt0q.onrender.com/api/v1';

const TOKENS_KEY = 'jointsaathi.tokens';
const USER_KEY = 'jointsaathi.user';

export function getTokens() {
  try {
    return JSON.parse(localStorage.getItem(TOKENS_KEY)) || null;
  } catch {
    return null;
  }
}

export function setTokens(tokens) {
  localStorage.setItem(TOKENS_KEY, JSON.stringify(tokens));
}

export function clearSession() {
  localStorage.removeItem(TOKENS_KEY);
  localStorage.removeItem(USER_KEY);
}

export function getStoredUser() {
  try {
    return JSON.parse(localStorage.getItem(USER_KEY)) || null;
  } catch {
    return null;
  }
}

export function setStoredUser(user) {
  localStorage.setItem(USER_KEY, JSON.stringify(user));
}

const client = axios.create({ baseURL: API_BASE_URL });

client.interceptors.request.use((config) => {
  const tokens = getTokens();
  if (tokens?.accessToken) {
    config.headers.Authorization = `Bearer ${tokens.accessToken}`;
  }
  return config;
});

let refreshPromise = null;

async function refreshAccessToken() {
  const tokens = getTokens();
  if (!tokens?.refreshToken) throw new Error('No refresh token');

  const res = await axios.post(`${API_BASE_URL}/auth/refresh`, {
    refreshToken: tokens.refreshToken,
  });
  // Handle both response structures: res.data.data and res.data
  const responseData = res.data.data || res.data;
  const { accessToken, refreshToken } = responseData;
  const next = { accessToken, refreshToken };
  setTokens(next);
  return next;
}

client.interceptors.response.use(
  (res) => res,
  async (error) => {
    const original = error.config;
    const status = error.response?.status;
    const isAuthRoute = original?.url?.includes('/auth/login') || original?.url?.includes('/auth/register') || original?.url?.includes('/auth/refresh');

    if (status === 401 && !original._retry && !isAuthRoute && getTokens()?.refreshToken) {
      original._retry = true;
      try {
        if (!refreshPromise) {
          refreshPromise = refreshAccessToken().finally(() => {
            refreshPromise = null;
          });
        }
        const tokens = await refreshPromise;
        original.headers.Authorization = `Bearer ${tokens.accessToken}`;
        return client(original);
      } catch (refreshErr) {
        clearSession();
        window.location.href = '/login';
        return Promise.reject(refreshErr);
      }
    }

    return Promise.reject(error);
  }
);

export default client;
