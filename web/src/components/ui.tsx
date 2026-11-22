// Shared UI kit (claude/ui-component-contract.md, web side).
// Pages assemble screens only from these.

import type { ReactNode } from 'react';
import { Icon } from './Icon';
import { useApp } from '../state/AppState';

export type Tone = 'crit' | 'warn' | 'ok' | 'info' | 'gray';

const TONE_ICON: Record<Tone, string | undefined> = { crit: 'alert', warn: 'clock', ok: 'check', info: 'info', gray: undefined };

/** Rectangular badge: border + icon + bold text. Never colour alone. */
export function Badge({ tone = 'gray', icon, children }: { tone?: Tone; icon?: string | null; children: ReactNode }) {
  const name = icon === null ? undefined : icon ?? TONE_ICON[tone];
  return (
    <span className={`badge b-${tone}`}>
      {name && <Icon name={name} strokeWidth={tone === 'ok' ? 3 : 2} />}
      {children}
    </span>
  );
}

export type Severity = 'ok' | 'warn' | 'err' | 'info';
const SEV_ICON: Record<Severity, string> = { ok: 'checkCircle', warn: 'alert', err: 'xCircle', info: 'info' };

/** Tinted box + 4px left bar + icon + plain text. Never auto-dismisses. */
export function Alert({ sev, children, icon, action }: { sev: Severity; children: ReactNode; icon?: string; action?: ReactNode }) {
  return (
    <div className={`alert a-${sev}`} role={sev === 'err' ? 'alert' : 'status'}>
      <Icon name={icon ?? SEV_ICON[sev]} size={18} />
      <div className="alert-body">
        <div>{children}</div>
        {action}
      </div>
    </div>
  );
}

export function Panel({ title, icon, right, children, className, bodyClass = 'pb' }: { title?: ReactNode; icon?: string; right?: ReactNode; children: ReactNode; className?: string; bodyClass?: string }) {
  return (
    <section className={`panel ${className ?? ''}`}>
      {title !== undefined && (
        <div className="ph">
          <h2>
            {icon && <Icon name={icon} size={18} />}
            {title}
          </h2>
          {right}
        </div>
      )}
      <div className={bodyClass}>{children}</div>
    </section>
  );
}

export function Segmented<T extends string | number | boolean>({
  options,
  value,
  onChange,
  label,
  className,
}: {
  options: { value: T; label: ReactNode }[];
  value: T;
  onChange: (v: T) => void;
  label: string;
  className?: string;
}) {
  return (
    <div className={`seg ${className ?? ''}`} role="group" aria-label={label}>
      {options.map((o) => (
        <button key={String(o.value)} type="button" aria-pressed={o.value === value} onClick={() => onChange(o.value)}>
          {o.label}
        </button>
      ))}
    </div>
  );
}

/** Numbered pagination (no infinite scroll on web tables). */
export function Pager({ page, pages, onPage }: { page: number; pages: number; onPage: (p: number) => void }) {
  const { t, f } = useApp();
  if (pages <= 1) return null;
  const nums: number[] = [];
  const from = Math.max(0, Math.min(page - 2, pages - 5));
  for (let i = from; i < Math.min(pages, from + 5); i++) nums.push(i);
  return (
    <nav className="row" aria-label="Pages" style={{ gap: 4 }}>
      <button type="button" className="btn btn-gray btn-sm" disabled={page === 0} onClick={() => onPage(page - 1)}>
        {t.prev}
      </button>
      {nums.map((n) => (
        <button key={n} type="button" className={`btn btn-sm ${n === page ? 'btn-navy' : 'btn-gray'}`} aria-current={n === page ? 'page' : undefined} onClick={() => onPage(n)}>
          {f.n(n + 1)}
        </button>
      ))}
      <button type="button" className="btn btn-gray btn-sm" disabled={page >= pages - 1} onClick={() => onPage(page + 1)}>
        {t.next}
      </button>
    </nav>
  );
}

/** State 1 — labelled loading bar (never a bare spinner). */
export function Loading() {
  const { t } = useApp();
  return (
    <div className="panel pb" role="status" aria-live="polite" style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
      <b>{t.loading}</b>
      <div className="progress" aria-hidden="true">
        <div />
      </div>
    </div>
  );
}

/** State 2 — empty: why it's empty + one action if allowed. */
export function Empty({ icon = 'users', title, hint, action }: { icon?: string; title: string; hint?: string; action?: ReactNode }) {
  return (
    <div className="panel pb" style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 8, textAlign: 'center', padding: 28 }}>
      <span style={{ display: 'flex', width: 52, height: 52, alignItems: 'center', justifyContent: 'center', border: '1px solid var(--border)', borderRadius: 4, background: 'var(--panel-h)', color: 'var(--text2)' }}>
        <Icon name={icon} size={26} />
      </span>
      <b>{title}</b>
      {hint && <p className="cap">{hint}</p>}
      {action}
    </div>
  );
}

/** State 5 — error with Retry. */
export function ErrorState({ onRetry, message }: { onRetry: () => void; message?: string }) {
  const { t } = useApp();
  return (
    <Alert
      sev="err"
      action={
        <button type="button" className="btn btn-gray" onClick={onRetry}>
          <Icon name="refresh" />
          {t.retry}
        </button>
      }
    >
      {message ?? t.loadError}
    </Alert>
  );
}
