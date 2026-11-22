// One place for app state while there is no backend. Pages read it with
// useApp(). Swap the actions for API calls later (Phayuk: auth + users,
// Seyla: fields, Rith: summaries).

import { createContext, useCallback, useContext, useEffect, useMemo, useState, type ReactNode } from 'react';
import { buildSampleData, DEMO_ACCOUNTS, ADMIN_NAME, DOCTOR_NAME, CORE_FIELDS } from '../data/mock';
import type { ClinicalNote, Lang, Role, Session, User, VitalField } from '../data/types';
import { makeFormat, STRINGS, type Format, type Strings } from '../i18n/strings';
import { apiDevLogin } from '../lib/api';

/** Dev-only switch to show each of the 5 required screen states. */
export type Simulate = 'none' | 'loading' | 'empty' | 'error' | 'offline' | 'revoked';

const SESSION_DAYS = 7;
const LS_KEY = 'ehealth.web.prefs';
const LS_SESSION = 'ehealth.web.session';

function load<T>(key: string, fallback: T): T {
  try {
    const raw = localStorage.getItem(key);
    return raw ? (JSON.parse(raw) as T) : fallback;
  } catch {
    return fallback;
  }
}

function store(key: string, value: unknown) {
  try {
    if (value === null) localStorage.removeItem(key);
    else localStorage.setItem(key, JSON.stringify(value));
  } catch {
    /* storage can be unavailable (private mode) — the app still works */
  }
}

interface AppValue {
  lang: Lang;
  khmerDigits: boolean;
  t: Strings;
  f: Format;
  setLang: (l: Lang) => void;
  setKhmerDigits: (v: boolean) => void;

  session: Session | null;
  sessionExpired: boolean;
  login: (id: string, password: string) => boolean;
  devLogin: (role: 'doctor' | 'admin') => Promise<void>;
  logout: () => void;

  simulate: Simulate;
  setSimulate: (s: Simulate) => void;

  data: ReturnType<typeof buildSampleData>;
  fields: VitalField[];
  addNote: (patientId: string, text: string) => void;
  setUserRole: (userId: string, role: Role) => boolean;
  setUserActive: (userId: string, active: boolean) => void;
  saveField: (field: VitalField) => void;
  setFieldActive: (id: string, active: boolean) => void;
}

const Ctx = createContext<AppValue | null>(null);

export function AppProvider({ children }: { children: ReactNode }) {
  const prefs = load<{ lang: Lang; khmerDigits: boolean }>(LS_KEY, { lang: 'km', khmerDigits: false });
  const [lang, setLangState] = useState<Lang>(prefs.lang);
  const [khmerDigits, setDigitsState] = useState<boolean>(prefs.khmerDigits);

  const initialSession = load<Session | null>(LS_SESSION, null);
  const expired = !!initialSession && initialSession.expiresAt < Date.now();
  const [session, setSession] = useState<Session | null>(expired ? null : initialSession);
  const [sessionExpired, setSessionExpired] = useState(expired);

  const [simulate, setSimulate] = useState<Simulate>('none');
  const [data, setData] = useState(() => buildSampleData());

  useEffect(() => store(LS_KEY, { lang, khmerDigits }), [lang, khmerDigits]);
  useEffect(() => {
    document.documentElement.lang = lang;
  }, [lang]);

  const startSession = useCallback((s: Omit<Session, 'expiresAt'>) => {
    const full: Session = { ...s, expiresAt: Date.now() + SESSION_DAYS * 24 * 3600 * 1000 };
    setSession(full);
    setSessionExpired(false);
    store(LS_SESSION, full);
  }, []);

  const login = useCallback(
    (id: string, password: string) => {
      const norm = id.replace(/\s+/g, '').toLowerCase();
      const acc = DEMO_ACCOUNTS.find((a) => a.id.replace(/\s+/g, '').toLowerCase() === norm && a.password === password);
      if (!acc) return false;
      startSession({ userId: acc.userId, role: acc.role, name: acc.name });
      return true;
    },
    [startSession],
  );

  const devLogin = useCallback(
    async (role: 'doctor' | 'admin') => {
      const fallback =
        role === 'doctor'
          ? { userId: 'u-vannak', role, name: DOCTOR_NAME }
          : { userId: 'u-rathana', role, name: ADMIN_NAME };
      try {
        const { token, user } = await apiDevLogin(role);
        startSession({
          userId: user.id,
          role,
          name: { km: user.name, en: user.name },
          token,
        });
      } catch {
        // API not running — fall back to mock session so standalone demos still work.
        startSession(fallback);
      }
    },
    [startSession],
  );

  const logout = useCallback(() => {
    setSession(null);
    store(LS_SESSION, null);
    setSimulate('none');
    setData(buildSampleData());
  }, []);

  const addNote = useCallback((patientId: string, text: string) => {
    const note: ClinicalNote = {
      id: `n-${Date.now()}`,
      patientId,
      time: new Date(),
      author: DOCTOR_NAME,
      text: { km: text, en: text },
    };
    setData((d) => ({ ...d, notes: [note, ...d.notes] }));
  }, []);

  const setUserRole = useCallback(
    (userId: string, role: Role) => {
      // Guard: never remove the last active administrator.
      const target = data.users.find((u) => u.id === userId);
      const admins = data.users.filter((u) => u.role === 'admin' && u.active);
      if (target && target.role === 'admin' && role !== 'admin' && admins.length <= 1) return false;
      setData((d) => ({ ...d, users: d.users.map((u): User => (u.id === userId ? { ...u, role } : u)) }));
      return true;
    },
    [data.users],
  );

  const setUserActive = useCallback((userId: string, active: boolean) => {
    setData((d) => ({ ...d, users: d.users.map((u): User => (u.id === userId ? { ...u, active } : u)) }));
  }, []);

  const saveField = useCallback((field: VitalField) => {
    setData((d) => {
      const exists = d.customFields.some((x) => x.id === field.id);
      return { ...d, customFields: exists ? d.customFields.map((x) => (x.id === field.id ? field : x)) : [...d.customFields, field] };
    });
  }, []);

  const setFieldActive = useCallback((id: string, active: boolean) => {
    setData((d) => ({ ...d, customFields: d.customFields.map((x) => (x.id === id ? { ...x, active } : x)) }));
  }, []);

  const value = useMemo<AppValue>(
    () => ({
      lang,
      khmerDigits,
      t: STRINGS[lang],
      f: makeFormat(lang, khmerDigits),
      setLang: setLangState,
      setKhmerDigits: setDigitsState,
      session,
      sessionExpired,
      login,
      devLogin,
      logout,
      simulate,
      setSimulate,
      data,
      fields: [...CORE_FIELDS, ...data.customFields],
      addNote,
      setUserRole,
      setUserActive,
      saveField,
      setFieldActive,
    }),
    [lang, khmerDigits, session, sessionExpired, login, devLogin, logout, simulate, data, addNote, setUserRole, setUserActive, saveField, setFieldActive],
  );

  return <Ctx.Provider value={value}>{children}</Ctx.Provider>;
}

export function useApp(): AppValue {
  const v = useContext(Ctx);
  if (!v) throw new Error('useApp must be used inside <AppProvider>');
  return v;
}
