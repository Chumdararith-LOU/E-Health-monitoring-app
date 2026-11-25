import { HashRouter, Navigate, NavLink, Outlet, Route, Routes, useLocation } from 'react-router-dom';
import { useEffect } from 'react';
import { Role } from './data/types';
import type { StringKey } from './i18n/en';
import { DashboardPage } from './pages/DashboardPage';
import { PatientPage } from './pages/PatientPage';
import { SettingsPage } from './pages/SettingsPage';
import { SignInPage } from './pages/SignInPage';
import { FieldsPage } from './pages/admin/FieldsPage';
import { LinksPage } from './pages/admin/LinksPage';
import { ReadingsSupportPage } from './pages/admin/ReadingsSupportPage';
import { UsersPage } from './pages/admin/UsersPage';
import { AppProvider, useApp } from './store/AppStore';
import { FeedbackProvider, useFeedback } from './ui/Feedback';
import { Icon, IconName } from './ui/Icon';
import { Avatar, Button, Empty, Segmented } from './ui/Kit';

interface NavItem {
  to: string;
  label: StringKey;
  icon: IconName;
}

/** Navigation depends on the role; order and icons never change. */
const NAV: Record<'doctor' | 'admin', NavItem[]> = {
  doctor: [
    { to: '/patients', label: 'nav_patients', icon: 'patients' },
    { to: '/settings', label: 'nav_settings', icon: 'settings' },
  ],
  admin: [
    { to: '/admin/users', label: 'nav_users', icon: 'users' },
    { to: '/admin/fields', label: 'nav_fields', icon: 'fields' },
    { to: '/admin/links', label: 'nav_links', icon: 'link' },
    { to: '/admin/readings', label: 'nav_readings', icon: 'readings' },
    { to: '/settings', label: 'nav_settings', icon: 'settings' },
  ],
};

export const homeFor = (role?: Role) => (role === 'admin' ? '/admin/users' : '/patients');

function Brand() {
  const { i18n } = useApp();
  return (
    <>
      <span className="brand-logo">
        <Icon name="heartPulse" size={24} />
      </span>
      <span>
        <span className="brand-name">{i18n.t('appName')}</span>
        <br />
        <span className="brand-sub">{i18n.t('webTagline')}</span>
      </span>
    </>
  );
}

function Shell() {
  const { user, i18n, state, setSettings, signOut } = useApp();
  const { confirm } = useFeedback();
  const loc = useLocation();
  useEffect(() => {
    // Move focus to the page heading on navigation so screen readers announce the new page.
    const h = document.getElementById('page-title');
    h?.setAttribute('tabindex', '-1');
    h?.focus({ preventScroll: true });
    window.scrollTo(0, 0);
  }, [loc.pathname]);

  if (!user) return <Navigate to="/signin" replace />;
  if (user.role !== 'doctor' && user.role !== 'admin') return <Navigate to="/signin" replace />;
  const items = NAV[user.role];
  const doSignOut = async () => {
    if (await confirm({ title: i18n.t('signOutConfirm'), confirmLabel: i18n.t('signOut'), icon: 'logout' })) signOut();
  };

  return (
    <div className="shell">
      <a className="skip-link" href="#main">
        {i18n.t('skipToContent')}
      </a>
      <aside className="sidebar">
        <NavLink to={homeFor(user.role)} className="brand">
          <Brand />
        </NavLink>
        <nav className="nav" aria-label={i18n.t('mainNav')}>
          {items.map((it) => (
            <NavLink key={it.to} to={it.to}>
              <Icon name={it.icon} size={22} />
              {i18n.t(it.label)}
            </NavLink>
          ))}
        </nav>
        <div className="sidebar-foot">
          <Segmented
            label={i18n.t('language')}
            value={state.settings.lang}
            onChange={(lang) => setSettings({ lang })}
            options={[
              { value: 'km', label: 'ខ្មែរ' },
              { value: 'en', label: 'English' },
            ]}
          />
          <div className="user-chip">
            <Avatar name={i18n.name(user)} />
            <div className="grow">
              <div className="strong" style={{ overflow: 'hidden', textOverflow: 'ellipsis', whiteSpace: 'nowrap' }}>
                {i18n.name(user)}
              </div>
              <div className="small muted">{i18n.role(user.role)}</div>
            </div>
          </div>
          <Button variant="ghost" icon="logout" onClick={doSignOut} className="btn-block" style={{ justifyContent: 'flex-start' }}>
            {i18n.t('signOut')}
          </Button>
        </div>
      </aside>
      <div className="main">
        <header className="topbar">
          <NavLink to={homeFor(user.role)} className="brand" style={{ padding: 0 }}>
            <span className="brand-logo" style={{ width: '2rem', height: '2rem' }}>
              <Icon name="heartPulse" size={20} />
            </span>
            <span className="brand-name">{i18n.t('appName')}</span>
          </NavLink>
          <span className="right" />
          <Segmented
            label={i18n.t('language')}
            value={state.settings.lang}
            onChange={(lang) => setSettings({ lang })}
            options={[
              { value: 'km', label: 'ខ្មែរ' },
              { value: 'en', label: 'EN' },
            ]}
          />
        </header>
        <main id="main" className="content">
          <Outlet />
        </main>
        <nav className="bottom-nav" aria-label={i18n.t('mainNav')}>
          {items.map((it) => (
            <NavLink key={it.to} to={it.to}>
              <Icon name={it.icon} size={24} />
              {i18n.t(it.label)}
            </NavLink>
          ))}
        </nav>
      </div>
    </div>
  );
}

function RequireRole({ roles, children }: { roles: Role[]; children: React.ReactNode }) {
  const { user } = useApp();
  if (!user) return <Navigate to="/signin" replace />;
  if (!roles.includes(user.role)) return <Navigate to={homeFor(user.role)} replace />;
  return <>{children}</>;
}

function Home() {
  const { user } = useApp();
  return <Navigate to={user ? homeFor(user.role) : '/signin'} replace />;
}

function NotFound() {
  const { i18n, user } = useApp();
  return (
    <Empty icon="search" title={i18n.t('notFound')}>
      <NavLink className="btn btn-secondary" to={homeFor(user?.role)}>
        {i18n.t('goHome')}
      </NavLink>
    </Empty>
  );
}

function SignInRoute() {
  const { user } = useApp();
  if (user && (user.role === 'doctor' || user.role === 'admin')) return <Navigate to={homeFor(user.role)} replace />;
  return <SignInPage />;
}

export default function App() {
  return (
    <AppProvider>
      <FeedbackProvider>
        <HashRouter>
          <Routes>
            <Route path="/signin" element={<SignInRoute />} />
            <Route element={<Shell />}>
              <Route index element={<Home />} />
              <Route path="/patients" element={<RequireRole roles={['doctor']}><DashboardPage /></RequireRole>} />
              <Route path="/patients/:id" element={<RequireRole roles={['doctor', 'admin']}><PatientPage /></RequireRole>} />
              <Route path="/admin/users" element={<RequireRole roles={['admin']}><UsersPage /></RequireRole>} />
              <Route path="/admin/fields" element={<RequireRole roles={['admin']}><FieldsPage /></RequireRole>} />
              <Route path="/admin/links" element={<RequireRole roles={['admin']}><LinksPage /></RequireRole>} />
              <Route path="/admin/readings" element={<RequireRole roles={['admin']}><ReadingsSupportPage /></RequireRole>} />
              <Route path="/settings" element={<SettingsPage />} />
              <Route path="*" element={<NotFound />} />
            </Route>
          </Routes>
        </HashRouter>
      </FeedbackProvider>
    </AppProvider>
  );
}
