// Sign in (US-01). Demo accounts until Phayuk's real auth API exists.

import { useState, type FormEvent } from 'react';
import { useApp } from '../state/AppState';
import { DEMO_ACCOUNTS } from '../data/mock';
import { navigate } from '../lib/router';
import { Emblem, Icon } from '../components/Icon';
import { Alert, Segmented } from '../components/ui';
import { SHOW_DEV_STRIP } from '../components/Header';

export function Login() {
  const { t, f, lang, setLang, login, devLogin, sessionExpired } = useApp();
  const [id, setId] = useState('');
  const [pw, setPw] = useState('');
  const [show, setShow] = useState(false);
  const [error, setError] = useState<string | null>(null);

  function submit(e: FormEvent) {
    e.preventDefault();
    if (!id.trim() || !pw) {
      setError(t.loginRequired);
      return;
    }
    const norm = (s: string) => s.replace(/\s+/g, '').toLowerCase();
    const acc = DEMO_ACCOUNTS.find((a) => norm(a.id) === norm(id));
    if (login(id, pw)) {
      navigate(acc?.role === 'admin' ? '/admin/users' : '/doctor');
    } else {
      setError(t.loginWrong);
    }
  }

  return (
    <div style={{ minHeight: '100vh', display: 'flex', flexDirection: 'column' }}>
      <header className="hdr">
        <div className="wrap hdr-in" style={{ justifyContent: 'space-between' }}>
          <span className="brand">
            <Emblem />
            <b>{t.appName}</b>
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
        </div>
      </header>

      <main style={{ flex: 1, display: 'flex', justifyContent: 'center', padding: '56px 16px 32px' }}>
        <div style={{ width: '100%', maxWidth: 440, display: 'flex', flexDirection: 'column', gap: 16 }}>
          {sessionExpired && (
            <Alert sev="warn" icon="clock">
              {t.sessionExpired}
            </Alert>
          )}
          <section className="panel">
            <div className="ph" style={{ display: 'block', padding: '10px 18px' }}>
              <h1 style={{ fontSize: 20 }}>{t.loginTitle}</h1>
              <p className="cap">{t.loginSub}</p>
            </div>
            <form className="pb" style={{ padding: 18, display: 'flex', flexDirection: 'column', gap: 14 }} onSubmit={submit} noValidate>
              {error && <Alert sev="err">{error}</Alert>}
              <div>
                <label className="label" htmlFor="login-id">
                  {t.loginId}
                </label>
                <input id="login-id" className="input input-block" value={id} onChange={(e) => setId(e.target.value)} autoComplete="username" autoFocus />
              </div>
              <div>
                <label className="label" htmlFor="login-pw">
                  {t.password}
                </label>
                <div style={{ display: 'flex' }}>
                  <input
                    id="login-pw"
                    className="input input-block"
                    type={show ? 'text' : 'password'}
                    value={pw}
                    onChange={(e) => setPw(e.target.value)}
                    autoComplete="current-password"
                    style={{ borderRadius: '3px 0 0 3px' }}
                  />
                  <button type="button" className="btn btn-gray" style={{ borderRadius: '0 3px 3px 0', borderLeft: 0, minHeight: 40 }} onClick={() => setShow((v) => !v)} aria-pressed={show}>
                    <Icon name="eye" />
                    {show ? t.hide : t.show}
                  </button>
                </div>
              </div>
              <button type="submit" className="btn btn-navy btn-block" style={{ minHeight: 42, fontSize: 15 }}>
                <Icon name="login" size={18} />
                {t.signIn}
              </button>
              <p className="cap">{f.n(t.loginHint)}</p>
            </form>
          </section>

          <Alert sev="info">{t.mobileUsers}</Alert>

          {SHOW_DEV_STRIP && (
            <section style={{ border: '1px solid var(--dev-border)', borderRadius: 4, background: '#FFF6D5', padding: '12px 14px', display: 'flex', flexDirection: 'column', gap: 8 }}>
              <b style={{ fontSize: 13 }}>DEV · {t.demoAccounts}</b>
              <table style={{ fontSize: 13, borderCollapse: 'collapse' }}>
                <tbody>
                  {DEMO_ACCOUNTS.map((a) => (
                    <tr key={a.id}>
                      <td style={{ paddingRight: 12 }}>{a.role === 'doctor' ? 'Doctor' : 'Admin'}</td>
                      <td style={{ paddingRight: 12, fontFamily: 'monospace' }}>{a.id}</td>
                      <td style={{ fontFamily: 'monospace' }}>{a.password}</td>
                    </tr>
                  ))}
                </tbody>
              </table>
              <div className="grid2">
                <button
                  type="button"
                  className="btn btn-gray"
                  onClick={() => {
                    devLogin('doctor');
                    navigate('/doctor');
                  }}
                >
                  <Icon name="pulse" />
                  Doctor
                </button>
                <button
                  type="button"
                  className="btn btn-gray"
                  onClick={() => {
                    devLogin('admin');
                    navigate('/admin/users');
                  }}
                >
                  <Icon name="sliders" />
                  Admin
                </button>
              </div>
            </section>
          )}

          <p className="cap" style={{ textAlign: 'center' }}>
            {t.disclaimer}
          </p>
        </div>
      </main>
    </div>
  );
}
