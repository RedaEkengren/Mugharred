import { useState, useEffect, useCallback } from 'react';
import { TokenManager, User } from './jwt-utils.js';
import { JWTApiClient } from './jwt-api.js';

export interface AuthState {
  user: User | null;
  isAuthenticated: boolean;
  isLoading: boolean;
}

export function useJWTAuth() {
  const [authState, setAuthState] = useState<AuthState>({
    user: null,
    isAuthenticated: false,
    isLoading: true
  });

  // Initialize auth state
  useEffect(() => {
    const user = TokenManager.getUser();
    setAuthState({
      user,
      isAuthenticated: user !== null,
      isLoading: false
    });
  }, []);

  // Listen for token expiry events
  useEffect(() => {
    const handleTokenExpired = () => {
      setAuthState({
        user: null,
        isAuthenticated: false,
        isLoading: false
      });
    };

    const handleTokenRefreshNeeded = async () => {
      try {
        const response = await JWTApiClient.refreshToken();
        if (response.ok) {
          const user = TokenManager.getUser();
          setAuthState(prev => ({
            ...prev,
            user,
            isAuthenticated: user !== null
          }));
        } else {
          handleTokenExpired();
        }
      } catch (error) {
        console.error('Token refresh failed:', error);
        handleTokenExpired();
      }
    };

    window.addEventListener('token-expired', handleTokenExpired);
    window.addEventListener('token-refresh-needed', handleTokenRefreshNeeded);

    return () => {
      window.removeEventListener('token-expired', handleTokenExpired);
      window.removeEventListener('token-refresh-needed', handleTokenRefreshNeeded);
    };
  }, []);

  // Auto-refresh token when needed
  useEffect(() => {
    if (!authState.isAuthenticated) return;

    const checkTokenRefresh = () => {
      const token = TokenManager.getToken();
      if (token && TokenManager.needsRefresh(token)) {
        window.dispatchEvent(new CustomEvent('token-refresh-needed'));
      }
    };

    // Check every minute
    const interval = setInterval(checkTokenRefresh, 60000);
    
    return () => clearInterval(interval);
  }, [authState.isAuthenticated]);

  const login = useCallback(async (name: string) => {
    setAuthState(prev => ({ ...prev, isLoading: true }));
    
    try {
      const response = await JWTApiClient.login(name);
      
      if (response.ok) {
        const user = TokenManager.getUser();
        setAuthState({
          user,
          isAuthenticated: user !== null,
          isLoading: false
        });
        return { success: true };
      } else {
        setAuthState(prev => ({ ...prev, isLoading: false }));
        return { success: false, error: response.error };
      }
    } catch (error) {
      setAuthState(prev => ({ ...prev, isLoading: false }));
      return { success: false, error: 'Network error' };
    }
  }, []);

  const logout = useCallback(() => {
    JWTApiClient.logout();
    setAuthState({
      user: null,
      isAuthenticated: false,
      isLoading: false
    });
  }, []);

  const updateUser = useCallback((updates: Partial<User>) => {
    setAuthState(prev => ({
      ...prev,
      user: prev.user ? { ...prev.user, ...updates } : null
    }));
  }, []);

  return {
    ...authState,
    login,
    logout,
    updateUser
  };
}
