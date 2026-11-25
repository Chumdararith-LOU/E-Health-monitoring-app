import React, { useId, useRef } from 'react';
import { Link } from 'react-router-dom';
import { Level, levelOf } from '../data/ranges';
import { MeasureKey } from '../data/types';
import { useApp } from '../store/AppStore';
import { Icon, IconName } from './Icon';

/* One component per concept, used everywhere → the same look and behaviour on every page. */

type BtnVariant = 'primary' | 'secondary' | 'danger' | 'ghost' | 'ghost-danger';

export function Button({
  variant = 'primary',
  icon,
  small,
  block,
  children,
  className,
  ...rest
}: React.ButtonHTMLAttributes<HTMLButtonElement> & { variant?: BtnVariant; icon?: IconName; small?: boolean; block?: boolean }) {
  return (
    <button type="button" className={`btn btn-${variant}${small ? ' btn-sm' : ''}${block ? ' btn-block' : ''} ${className ?? ''}`} {...rest}>
      {icon ? <Icon name={icon} size={small ? 18 : 20} /> : null}
      {children}
    </button>
  );
}

export function IconButton({ icon, label, ...rest }: React.ButtonHTMLAttributes<HTMLButtonElement> & { icon: IconName; label: string }) {
  return (
    <button type="button" className="icon-btn" aria-label={label} title={label} {...rest}>
      <Icon name={icon} size={22} />
    </button>
  );
}

export function Card({ children, className, ...rest }: React.HTMLAttributes<HTMLElement> & { as?: 'section' | 'div' }) {
  return (
    <section className={`card ${className ?? ''}`} {...rest}>
      {children}
    </section>
  );
}

export function PageHeader({ title, subtitle, actions, crumbs }: { title: React.ReactNode; subtitle?: React.ReactNode; actions?: React.ReactNode; crumbs?: { to: string; label: string }[] }) {
  return (
    <header className="page-header">
      <div className="titles">
        {crumbs ? (
          <nav className="breadcrumb no-print" aria-label="Breadcrumb">
            {crumbs.map((c) => (
              <Link key={c.to} to={c.to}>
                <Icon name="chevronLeft" size={18} />
                {c.label}
              </Link>
            ))}
          </nav>
        ) : null}
        <h1 id="page-title">{title}</h1>
        {subtitle ? <p className="muted">{subtitle}</p> : null}
      </div>
      {actions ? <div className="actions no-print">{actions}</div> : null}
    </header>
  );
}

export function Banner({ kind = 'info', children, icon }: { kind?: 'info' | 'warning' | 'error'; children: React.ReactNode; icon?: IconName }) {
  const ic: IconName = icon ?? (kind === 'error' ? 'error' : kind === 'warning' ? 'warning' : 'info');
  return (
    <div className={`banner banner-${kind}`} role={kind === 'error' ? 'alert' : undefined}>
      <Icon name={ic} />
      <div>{children}</div>
    </div>
  );
}

export function Empty({ icon, title, children }: { icon: IconName; title: string; children?: React.ReactNode }) {
  return (
    <div className="empty">
      <Icon name={icon} size={44} />
      <strong style={{ color: 'var(--text)' }}>{title}</strong>
      {children}
    </div>
  );
}

/** Status: icon + word + colour. */
export function StatusBadge({ level }: { level: Level | 'missed' }) {
  const { i18n } = useApp();
  const m = {
    normal: { icon: 'normal' as IconName, label: i18n.t('lvl_normal') },
    high: { icon: 'highCircle' as IconName, label: i18n.t('lvl_high') },
    low: { icon: 'lowCircle' as IconName, label: i18n.t('lvl_low') },
    missed: { icon: 'missed' as IconName, label: i18n.t('missed') },
  }[level];
  return (
    <span className={`badge badge-${level}`}>
      <Icon name={m.icon} size={16} />
      {m.label}
    </span>
  );
}

export function Badge({ kind = 'neutral', icon, children }: { kind?: 'neutral' | 'info' | 'high' | 'low' | 'normal'; icon?: IconName; children: React.ReactNode }) {
  return (
    <span className={`badge badge-${kind}`}>
      {icon ? <Icon name={icon} size={16} /> : null}
      {children}
    </span>
  );
}

/** A measured value; out-of-range values get colour AND an arrow (and a hidden word for screen readers). */
export function Value({ k, v }: { k: MeasureKey; v?: number }) {
  const { i18n } = useApp();
  const lvl = levelOf(k, v);
  if (v == null) return <span className="muted">–</span>;
  return (
    <span className={`val ${lvl === 'high' ? 'val-high' : lvl === 'low' ? 'val-low' : ''}`}>
      {lvl === 'high' ? <Icon name="up" size={14} /> : lvl === 'low' ? <Icon name="down" size={14} /> : null}
      {i18n.num(v)}
      {lvl && lvl !== 'normal' ? <span className="sr-only"> ({i18n.t(`lvl_${lvl}`)})</span> : null}
    </span>
  );
}

export function Segmented<T extends string | number>({ value, onChange, options, label }: { value: T; onChange: (v: T) => void; options: { value: T; label: string }[]; label: string }) {
  const refs = useRef<(HTMLButtonElement | null)[]>([]);
  const idx = options.findIndex((o) => o.value === value);
  const onKey = (e: React.KeyboardEvent) => {
    if (e.key !== 'ArrowRight' && e.key !== 'ArrowLeft') return;
    e.preventDefault();
    const n = (idx + (e.key === 'ArrowRight' ? 1 : -1) + options.length) % options.length;
    onChange(options[n].value);
    refs.current[n]?.focus();
  };
  return (
    <div className="segmented" role="radiogroup" aria-label={label} onKeyDown={onKey}>
      {options.map((o, i) => (
        <button
          key={String(o.value)}
          ref={(r) => {
            refs.current[i] = r;
          }}
          type="button"
          role="radio"
          aria-checked={o.value === value}
          tabIndex={o.value === value ? 0 : -1}
          onClick={() => onChange(o.value)}
        >
          {o.label}
        </button>
      ))}
    </div>
  );
}

export function Chip({ pressed, onClick, children, count, icon }: { pressed: boolean; onClick: () => void; children: React.ReactNode; count?: string; icon?: IconName }) {
  return (
    <button type="button" className="chip" aria-pressed={pressed} onClick={onClick}>
      {pressed ? <Icon name="check" size={18} /> : icon ? <Icon name={icon} size={18} /> : null}
      {children}
      {count != null ? <span className="count">{count}</span> : null}
    </button>
  );
}

/** Label above, hint or message below. Error replaces the hint and is linked with aria-describedby. */
export function Field({
  label,
  hint,
  error,
  warning,
  children,
}: {
  label: string;
  hint?: string;
  error?: string;
  warning?: string;
  children: (p: { id: string; 'aria-invalid': boolean; 'aria-describedby'?: string }) => React.ReactNode;
}) {
  const id = useId();
  const msgId = `${id}-msg`;
  const hasMsg = !!(error || warning || hint);
  return (
    <div className="field">
      <label htmlFor={id}>{label}</label>
      {children({ id, 'aria-invalid': !!error, 'aria-describedby': hasMsg ? msgId : undefined })}
      {error ? (
        <div id={msgId} className="msg msg-error">
          <Icon name="error" size={16} />
          {error}
        </div>
      ) : warning ? (
        <div id={msgId} className="msg msg-warn">
          <Icon name="alert" size={16} />
          {warning}
        </div>
      ) : hint ? (
        <div id={msgId} className="hint">
          {hint}
        </div>
      ) : null}
    </div>
  );
}

export function Tabs<T extends string>({ value, onChange, tabs, label }: { value: T; onChange: (v: T) => void; tabs: { value: T; label: string; count?: number }[]; label: string }) {
  const refs = useRef<(HTMLButtonElement | null)[]>([]);
  const { i18n } = useApp();
  const idx = tabs.findIndex((t) => t.value === value);
  return (
    <div
      className="tabs no-print"
      role="tablist"
      aria-label={label}
      onKeyDown={(e) => {
        if (e.key !== 'ArrowRight' && e.key !== 'ArrowLeft') return;
        const n = (idx + (e.key === 'ArrowRight' ? 1 : -1) + tabs.length) % tabs.length;
        onChange(tabs[n].value);
        refs.current[n]?.focus();
      }}
    >
      {tabs.map((t, i) => (
        <button
          key={t.value}
          ref={(r) => {
            refs.current[i] = r;
          }}
          role="tab"
          type="button"
          id={`tab-${t.value}`}
          aria-selected={t.value === value}
          aria-controls={`panel-${t.value}`}
          tabIndex={t.value === value ? 0 : -1}
          onClick={() => onChange(t.value)}
        >
          {t.label}
          {t.count != null ? <span className="badge badge-neutral">{i18n.num(t.count)}</span> : null}
        </button>
      ))}
    </div>
  );
}

export function Avatar({ name, big }: { name: string; big?: boolean }) {
  const initials = name
    .replace(/^(Dr\.|វេជ្ជ\.)\s*/, '')
    .split(/\s+/)
    .slice(0, 2)
    .map((w) => [...w][0])
    .join('');
  return (
    <span className={big ? 'patient-avatar' : 'avatar'} aria-hidden>
      {initials}
    </span>
  );
}
