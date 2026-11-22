// AppShellWeb: navy header with role-filtered tabs, user, ខ្មែរ | EN,
// numerals, sign out, plus the yellow DEV strip (non-production only).

import type { ReactNode } from 'react';
import { Emblem, Icon } from './Icon';
import { Segmented } from './ui';
import { useApp, type Simulate } from '../state/AppState';
import { navigate } from '../lib/router';

/** Hide the yellow DEV strip for a clean demo: build with VITE_HIDE_DEV=1. */
export const SHOW_DEV_STRIP = import.meta.env.VITE_HIDE_DEV !== '1';

export type TabId = 'dashboard' | 'reports' | 'users' | 'fields';

export function Header({ active, reportHref }: { active: TabId; reportHref?: string }) {
  const { t, session, lang, setLang, khmerDigits, setKhmerDigits, logout } = useApp();
  if (!session) return null;
  const isAdmin = session.role === 'admin';
  const tabs: { id: TabId; label: string; href: string }[] = isAdmin
    ? [
        { id: 'users', label: t.tabUsers, href: '#/admin/users' },
        { id: 'fields', label: t.tabFields, href: '#/admin/fields' },
      ]
    : [
        { id: 'dashboard', label: t.tabDashboard, href: '#/doctor' },
        { id: 'reports', label: t.tabReports, href: reportHref ?? '#/doctor/patient/sokha' },
      ];

  return (
    <>
      <header className="hdr">
        <div className="wrap hdr-in">
          <a className="brand" href={isAdmin ? '#/admin/users' : '#/doctor'}>
            <Emblem />
            <span>
              <b>{t.appName}</b> <span style={{ opacity: 0.9 }}>· {isAdmin ? t.adminPortal : t.doctorPortal}</span>
            </span>
          </a>
          <nav className="tabs" aria-label="Main">
            {tabs.map((tab) => (
              <a key={tab.id} className={`tab ${tab.id === active ? 'on' : ''}`} href={tab.href} aria-current={tab.id === active ? 'page' : undefined}>
                {tab.label}
              </a>
            ))}
          </nav>
          <div className="hdr-right">
            <span className="row" style={{ gap: 6, whiteSpace: 'nowrap' }}>
              <Icon name="user" size={18} />
              <b>{session.name[lang]}</b>
              <span style={{ opacity: 0.9 }}>· {isAdmin ? t.roleAdmin : t.roleDoctor}</span>
            </span>
            <Segmented
              className="on-dark"
              label={t.language}
              value={lang}
              onChange={setLang}
              options={[
                { value: 'km', label: 'ខ្មែរ' },
                { value: 'en', label: 'EN' },
              ]}
            />
            <Segmented
              className="on-dark"
              label={t.numerals}
              value={khmerDigits}
              onChange={setKhmerDigits}
              options={[
                { value: false, label: '123' },
                { value: true, label: '១២៣' },
              ]}
            />
            <button
              type="button"
              className="hdr-btn"
              onClick={() => {
                logout();
                navigate('/login');
              }}
            >
              <Icon name="logout" />
              {t.signOut}
            </button>
          </div>
        </div>
      </header>
      {SHOW_DEV_STRIP && <DevStrip />}
    </>
  );
}

const SIMS: Simulate[] = ['none', 'loading', 'empty', 'error', 'offline', 'revoked'];

/** Developer role + state switcher (claude/ui-component-contract.md). English on purpose. */
function DevStrip() {
  const { session, devLogin, simulate, setSimulate } = useApp();
  return (
    <div className="dev no-print">
      <div className="wrap dev-in">
        <b>DEV</b>
        <span>role:</span>
        <button
          type="button"
          aria-pressed={session?.role === 'doctor'}
          onClick={() => {
            devLogin('doctor');
            navigate('/doctor');
          }}
        >
          Doctor
        </button>
        <button
          type="button"
          aria-pressed={session?.role === 'admin'}
          onClick={() => {
            devLogin('admin');
            navigate('/admin/users');
          }}
        >
          Admin
        </button>
        <span style={{ color: 'var(--text2)' }}>Patient · Caretaker · Family → mobile app</span>
        <span>state:</span>
        {SIMS.map((s) => (
          <button key={s} type="button" aria-pressed={simulate === s} onClick={() => setSimulate(s)}>
            {s}
          </button>
        ))}
      </div>
    </div>
  );
}

export function Crumbs({ items, right }: { items: { label: string; href?: string }[]; right?: ReactNode }) {
  return (
    <div className="crumbs">
      <div className="wrap crumbs-in">
        <nav aria-label="Breadcrumb">
          {items.map((it, i) => (
            <span key={i}>
              {i > 0 && <span className="sep">/</span>}
              {it.href ? <a href={it.href}>{it.label}</a> : <b aria-current="page">{it.label}</b>}
            </span>
          ))}
        </nav>
        {right}
      </div>
    </div>
  );
}
