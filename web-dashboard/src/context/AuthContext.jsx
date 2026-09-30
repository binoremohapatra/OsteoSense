import { createContext, useCallback, useContext, useEffect, useState } from 'react';
import { authApi } from '../api/services';
import { clearSession, getStoredUser, getTokens, setStoredUser, setTokens } from '../api/client';

const AuthContext = createContext(null);

export function AuthProvider({ children }) {
  const [user, setUser] = useState(getStoredUser());
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const tokens = getTokens();
    if (!tokens?.accessToken) {
      setLoading(false);
      return;
    }
    authApi
      .me()
      .then((res) => {
        // Handle multiple response structures
        const user = res.data.user || res.data.data?.user || res.user;
        setUser(user);
        setStoredUser(user);
      })
      .catch(() => {
        clearSession();
        setUser(null);
      })
      .finally(() => setLoading(false));
  }, []);

  const login = useCallback(async (phoneNumber, password) => {
    const res = await authApi.login({ phoneNumber, password });
    // Handle multiple response structures from backend
    const user = res.data.user || res.data.data?.user;
    const accessToken = res.data.token || res.data.accessToken || res.data.data?.token || res.data.data?.accessToken;
    const refreshToken = res.data.refreshToken || res.data.data?.refreshToken;
    
    setTokens({ accessToken, refreshToken });
    setStoredUser(user);
    setUser(user);
    return user;
  }, []);

  const register = useCallback(async (payload) => {
    const res = await authApi.register(payload);
    // Handle multiple response structures from backend
    const user = res.data.user || res.data.data?.user;
    const accessToken = res.data.token || res.data.accessToken || res.data.data?.token || res.data.data?.accessToken;
    const refreshToken = res.data.refreshToken || res.data.data?.refreshToken;
    
    setTokens({ accessToken, refreshToken });
    setStoredUser(user);
    setUser(user);
    return user;
  }, []);

  const logout = useCallback(async () => {
    const tokens = getTokens();
    try {
      if (tokens?.refreshToken) await authApi.logout(tokens.refreshToken);
    } catch {
      // ignore — clear local session regardless
    }
    clearSession();
    setUser(null);
  }, []);

  const isAdmin = user?.role === 'admin';

  return (
    <AuthContext.Provider value={{ user, loading, login, register, logout, isAdmin }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}
