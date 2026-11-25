import React, { createContext, useCallback, useContext, useEffect, useMemo, useReducer } from 'react';
import { makeSeed, SEED_VERSION } from '../data/seed';
import { CustomField, DataState, DoctorNote, Reading, Role, Settings, User } from '../data/types';
import { I18n, makeI18n } from '../i18n';
import { apiDevLogin } from '../lib/api';

/**
 * Browser-only store with optional live API token (from /dev/login when the API is running).
 * Every read goes through canView(), so the screens already behave as with the real server (NFR-03).
 */
const STORAGE_KEY = 'ehealth-web-demo-v1';

interface State {
  data: DataState;
  settings: Settings;
  userId: string | null;
  token: string | null;
}

const DEFAULT_SETTINGS: Settings = { lang: 'km', numerals: 'western', textScale: 1 };

type Action =
  | { type: 'signIn'; userId: string }
  | { type: 'setToken'; userId: string; token: string | null }
  | { type: 'signOut' }
  | { type: 'settings'; patch: Partial<Settings> }
  | { type: 'upsertReading'; reading: Reading }
  | { type: 'deleteReading'; id: string }
  | { type: 'addNote'; note: DoctorNote }
  | { type: 'setRole'; userId: string; role: Role }
  | { type: 'upsertField'; field: CustomField }
  | { type: 'removeLink'; id: string }
  | { type: 'restoreLink'; link: DataState['links'][number] }
  | { type: 'resetData' };

function reducer(s: State, a: Action): State {
  const d = s.data;
  switch (a.type) {
    case 'signIn':
      return { ...s, userId: a.userId, token: null };
    case 'setToken':
      return s.userId === a.userId ? { ...s, token: a.token } : s;
    case 'signOut':
      return { ...s, userId: null, token: null };
    case 'settings':
      return { ...s, settings: { ...s.settings, ...a.patch } };
    case 'upsertReading':
      return { ...s, data: { ...d, readings: [...d.readings.filter((r) => r.id !== a.reading.id), a.reading] } };
    case 'deleteReading':
      return { ...s, data: { ...d, readings: d.readings.filter((r) => r.id !== a.id) } };
    case 'addNote':
      return { ...s, data: { ...d, notes: [...d.notes, a.note] } };
    case 'setRole':
      return { ...s, data: { ...d, users: d.users.map((u) => (u.id === a.userId ? { ...u, role: a.role } : u)) } };
    case 'upsertField': {
      const exists = d.fields.some((f) => f.id === a.field.id);
      return { ...s, data: { ...d, fields: exists ? d.fields.map((f) => (f.id === a.field.id ? a.field : f)) : [...d.fields, a.field] } };
    }
    case 'removeLink':
      return { ...s, data: { ...d, links: d.links.filter((l) => l.id !== a.id) } };
    case 'restoreLink':
      return { ...s, data: { ...d, links: [...d.links, a.link] } };
    case 'resetData':
      return { ...s, data: makeSeed() };
  }
}

function load(): State {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (raw) {
      const saved = JSON.parse(raw);
      if (saved.data?.version === SEED_VERSION) {
        return {
          data: saved.data,
          settings: { ...DEFAULT_SETTINGS, ...saved.settings },
          userId: saved.userId ?? null,
          token: typeof saved.token === 'string' ? saved.token : null,
        };
      }
      return { data: makeSeed(), settings: { ...DEFAULT_SETTINGS, ...saved.settings }, userId: null, token: null };
    }
  } catch {
    /* storage blocked or corrupted → start from demo data */
  }
  return { data: makeSeed(), settings: DEFAULT_SETTINGS, userId: null, token: null };
}

export const newId = (p: string) => `${p}-${Date.now().toString(36)}-${Math.random().toString(36).slice(2, 7)}`;

interface Ctx {
  state: State;
  i18n: I18n;
  user: User | null;
  token: string | null;
  /** patients this user may see: linked (doctor) or all (admin, support only) */
  patients: User[];
  userById: (id: string) => User | undefined;
  canView: (patientId: string) => boolean;
  readingsOf: (patientId: string) => Reading[]; // newest first
  dispatch: React.Dispatch<Action>;
  signIn: (id: string) => void;
  signOut: () => void;
  setSettings: (p: Partial<Settings>) => void;
}

const AppCtx = createContext<Ctx | null>(null);

export function AppProvider({ children }: { children: React.ReactNode }) {
  const [state, dispatch] = useReducer(reducer, undefined, load);

  useEffect(() => {
    const id = setTimeout(() => {
      try {
        localStorage.setItem(STORAGE_KEY, JSON.stringify(state));
      } catch {
        /* ignore */
      }
    }, 200);
    return () => clearTimeout(id);
  }, [state]);

  // Language, text size and font: one place, applied to <html> so every rem-based size follows.
  useEffect(() => {
    const html = document.documentElement;
    html.lang = state.settings.lang;
    html.style.fontSize = `${16 * state.settings.textScale}px`;
    document.title = state.settings.lang === 'km' ? 'អេ-សុខភាព' : 'E-Health';
  }, [state.settings.lang, state.settings.textScale]);

  const i18n = useMemo(() => makeI18n(state.settings.lang, state.settings.numerals), [state.settings.lang, state.settings.numerals]);
  const userById = useCallback((id: string) => state.data.users.find((u) => u.id === id), [state.data.users]);
  const user = state.userId ? userById(state.userId) ?? null : null;

  const patients = useMemo(() => {
    if (!user) return [];
    if (user.role === 'admin') return state.data.users.filter((u) => u.role === 'patient');
    const ids = new Set(state.data.links.filter((l) => l.userId === user.id && l.status === 'active').map((l) => l.patientId));
    return state.data.users.filter((u) => ids.has(u.id) && u.role === 'patient');
  }, [user, state.data.links, state.data.users]);

  const canView = useCallback((pid: string) => patients.some((p) => p.id === pid), [patients]);
  const readingsOf = useCallback(
    (pid: string) =>
      canView(pid) ? state.data.readings.filter((r) => r.patientId === pid).sort((a, b) => b.takenAt.localeCompare(a.takenAt)) : [],
    [state.data.readings, canView],
  );

  const signIn = useCallback(
    (id: string) => {
      dispatch({ type: 'signIn', userId: id });
      const target = state.data.users.find((u) => u.id === id);
      if (target && (target.role === 'doctor' || target.role === 'admin')) {
        void apiDevLogin(target.role)
          .then(({ token }) => {
            dispatch({ type: 'setToken', userId: id, token });
          })
          .catch(() => {
            // API not running — standalone demo mode continues without a token.
          });
      }
    },
    [state.data.users],
  );

  const value: Ctx = {
    state,
    i18n,
    user,
    token: state.token,
    patients,
    userById,
    canView,
    readingsOf,
    dispatch,
    signIn,
    signOut: () => dispatch({ type: 'signOut' }),
    setSettings: (patch) => dispatch({ type: 'settings', patch }),
  };
  return <AppCtx.Provider value={value}>{children}</AppCtx.Provider>;
}

export function useApp() {
  const c = useContext(AppCtx);
  if (!c) throw new Error('useApp outside AppProvider');
  return c;
}
