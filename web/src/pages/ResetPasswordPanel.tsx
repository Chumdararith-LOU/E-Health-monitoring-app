import { useState } from 'react';
import { fromKhmerDigits } from '../i18n';
import { useApp } from '../store/AppStore';
import { Banner, Button, Field } from '../ui/Kit';
import { accountErrorText, apiForgotPassword, apiResetPassword } from './accountsApi';

const MIN_PASSWORD = 8;
const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;

/** Forgot password: ask for a code by email, then set a new password with it. */
export function ResetPasswordPanel({ onBack }: { onBack: (done: boolean) => void }) {
  const { i18n } = useApp();
  const { t } = i18n;
  const [step, setStep] = useState<'email' | 'code'>('email');
  const [email, setEmail] = useState('');
  const [code, setCode] = useState('');
  const [pw, setPw] = useState('');
  const [err, setErr] = useState<{ email?: string; code?: string; pw?: string; form?: string }>({});
  const [busy, setBusy] = useState(false);

  const sendCode = async (e?: React.FormEvent) => {
    e?.preventDefault();
    if (!EMAIL.test(email.trim())) return setErr({ email: t('acctErrEmail') });
    setBusy(true);
    try {
      await apiForgotPassword({ email: email.trim() });
      setStep('code');
      setErr({});
    } catch (error) {
      setErr({ form: accountErrorText(i18n, error) });
    } finally {
      setBusy(false);
    }
  };

  const reset = async (e: React.FormEvent) => {
    e.preventDefault();
    const digits = fromKhmerDigits(code).replace(/\s/g, '');
    const next: typeof err = {};
    if (!/^\d{6}$/.test(digits)) next.code = t('acctErrCode');
    if (pw.length < MIN_PASSWORD) next.pw = t('acctErrNewPassword', { n: MIN_PASSWORD });
    if (next.code || next.pw) return setErr(next);
    setBusy(true);
    try {
      await apiResetPassword({ email: email.trim(), code: digits, newPassword: pw });
      onBack(true);
    } catch (error) {
      setErr({ form: accountErrorText(i18n, error) });
    } finally {
      setBusy(false);
    }
  };

  return (
    <div className="stack">
      <div>
        <h1 id="page-title">{t('acctResetTitle')}</h1>
        {step === 'email' ? <p className="muted">{t('acctResetIntro')}</p> : null}
      </div>

      {step === 'email' ? (
        <form className="stack" onSubmit={sendCode} noValidate>
          {err.form ? <Banner kind="error">{err.form}</Banner> : null}
          <Field label={t('acctEmail')} error={err.email}>
            {(p) => (
              <input
                {...p}
                className="input"
                type="email"
                value={email}
                autoComplete="email"
                onChange={(e) => {
                  setEmail(e.target.value);
                  setErr({});
                }}
              />
            )}
          </Field>
          <Button type="submit" icon="login" block disabled={busy}>
            {t('acctSendCode')}
          </Button>
        </form>
      ) : (
        <form className="stack" onSubmit={reset} noValidate>
          <Banner>{t('acctCodeSent', { email: email.trim() })}</Banner>
          {err.form ? <Banner kind="error">{err.form}</Banner> : null}
          <Field label={t('acctCode')} error={err.code}>
            {(p) => (
              <input
                {...p}
                className="input"
                inputMode="numeric"
                maxLength={6}
                autoComplete="one-time-code"
                value={code}
                onChange={(e) => {
                  setCode(e.target.value);
                  setErr({});
                }}
              />
            )}
          </Field>
          <Field label={t('acctNewPassword')} error={err.pw}>
            {(p) => (
              <input
                {...p}
                className="input"
                type="password"
                autoComplete="new-password"
                value={pw}
                onChange={(e) => {
                  setPw(e.target.value);
                  setErr({});
                }}
              />
            )}
          </Field>
          <Button type="submit" icon="login" block disabled={busy}>
            {t('acctSetPassword')}
          </Button>
          <Button variant="ghost" block disabled={busy} onClick={() => void sendCode()}>
            {t('acctResendCode')}
          </Button>
        </form>
      )}

      <Button variant="ghost" block onClick={() => onBack(false)}>
        {t('acctBackToSignIn')}
      </Button>
    </div>
  );
}
