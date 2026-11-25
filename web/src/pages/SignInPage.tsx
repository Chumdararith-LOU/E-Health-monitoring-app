import { useState } from 'react';
import { DEMO_LOGINS } from '../data/seed';
import { fromKhmerDigits } from '../i18n';
import { useApp } from '../store/AppStore';
import { Icon } from '../ui/Icon';
import { Avatar, Banner, Button, Field, Segmented } from '../ui/Kit';

export function SignInPage() {
  const { i18n, state, setSettings, signIn, userById } = useApp();
  const { t } = i18n;
  const [id, setId] = useState('');
  const [pw, setPw] = useState('');
  const [show, setShow] = useState(false);
  const [err, setErr] = useState<{ id?: string; pw?: string; form?: string }>({});

  const submit = (e: React.FormEvent) => {
    e.preventDefault();
    const next: typeof err = {};
    if (!id.trim()) next.id = t('errIdRequired');
    if (pw.length < 6) next.pw = t('errPasswordShort', { n: 6 });
    if (!next.id && !next.pw) {
      const norm = (s: string) => fromKhmerDigits(s).toLowerCase().replace(/[\s-]/g, '');
      const u = state.data.users.find((x) => norm(x.phone) === norm(id));
      if (!u) next.form = t('errNoAccount');
      else if (u.role !== 'doctor' && u.role !== 'admin') next.form = t('errMobileOnly');
      else return signIn(u.id);
    }
    setErr(next);
  };

  return (
    <div className="signin">
      <aside className="signin-aside">
        <div className="row" style={{ gap: 'var(--s3)' }}>
          <span className="brand-logo" style={{ background: '#fff', color: 'var(--primary)' }}>
            <Icon name="heartPulse" size={26} />
          </span>
          <div>
            <div className="brand-name">{t('appName')}</div>
            <div style={{ opacity: 0.85 }}>{t('webTagline')}</div>
          </div>
        </div>
        <ul>
          {[
            ['patients', t('dashTitle'), t('kpiAttention')],
            ['chart', t('summary'), `${t('min')} · ${t('avg')} · ${t('max')}`],
            ['note', t('notes'), t('visibleTo')],
          ].map(([icon, a, b]) => (
            <li key={icon}>
              <Icon name={icon as 'chart'} size={24} />
              <div>
                <strong>{a}</strong>
                <div style={{ opacity: 0.85 }}>{b}</div>
              </div>
            </li>
          ))}
        </ul>
        <p style={{ opacity: 0.75 }} className="small">
          {t('aboutDemoBody')}
        </p>
      </aside>

      <main className="signin-main" id="main">
        <div className="signin-box">
          <div className="row">
            <Icon name="translate" />
            <Segmented
              label={t('language')}
              value={state.settings.lang}
              onChange={(lang) => setSettings({ lang })}
              options={[
                { value: 'km', label: 'ខ្មែរ' },
                { value: 'en', label: 'English' },
              ]}
            />
          </div>
          <div>
            <h1 id="page-title">{t('signIn')}</h1>
            <p className="muted">{t('signInSubtitle')}</p>
          </div>
          <form className="stack" onSubmit={submit} noValidate>
            {err.form ? <Banner kind="error">{err.form}</Banner> : null}
            <Field label={t('emailOrPhone')} error={err.id}>
              {(p) => (
                <input
                  {...p}
                  className="input"
                  value={id}
                  autoComplete="username"
                  placeholder="023 900 100"
                  onChange={(e) => {
                    setId(e.target.value);
                    setErr({});
                  }}
                />
              )}
            </Field>
            <Field label={t('password')} error={err.pw}>
              {(p) => (
                <div className="input-wrap">
                  <input
                    {...p}
                    className="input"
                    type={show ? 'text' : 'password'}
                    value={pw}
                    autoComplete="current-password"
                    onChange={(e) => {
                      setPw(e.target.value);
                      setErr({});
                    }}
                  />
                  <button type="button" className="btn btn-ghost btn-sm" style={{ position: 'absolute', right: 4 }} onClick={() => setShow(!show)} aria-pressed={show}>
                    <Icon name={show ? 'eyeOff' : 'eye'} size={18} />
                    {show ? t('hidePassword') : t('showPassword')}
                  </button>
                </div>
              )}
            </Field>
            <Button type="submit" icon="login" block>
              {t('signIn')}
            </Button>
          </form>

          <section className="stack-sm" aria-labelledby="demo-h">
            <h2 id="demo-h" className="small muted" style={{ fontWeight: 600 }}>
              {t('demoAccounts')}
            </h2>
            <Banner>{t('demoHint')}</Banner>
            {DEMO_LOGINS.map((d) => {
              const u = userById(d.userId);
              return (
                <button key={d.userId} type="button" className="account-btn" onClick={() => signIn(d.userId)}>
                  <Avatar name={i18n.name(u)} />
                  <span className="grow">
                    <strong>{i18n.name(u)}</strong>
                    <br />
                    <span className="small muted">
                      {i18n.role(d.role)} · {u?.phone} — {t(d.role === 'admin' ? 'roleDesc_admin' : 'roleDesc_doctor')}
                    </span>
                  </span>
                  <Icon name="chevronRight" />
                </button>
              );
            })}
          </section>
        </div>
      </main>
    </div>
  );
}
