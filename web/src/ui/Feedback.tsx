import React, { createContext, useCallback, useContext, useEffect, useRef, useState } from 'react';
import { useApp } from '../store/AppStore';
import { Icon, IconName } from './Icon';
import { Button } from './Kit';

/**
 * Feedback used the same way everywhere:
 *  - confirm(): blocking decision dialog. Buttons name the action ("Delete reading", never "OK");
 *    destructive = red; Cancel always present; Esc = cancel. Native <dialog> traps focus.
 *  - toast(): short message after an action, announced to screen readers, optional Undo.
 */

interface ConfirmOpts {
  title: string;
  body?: string;
  confirmLabel: string;
  danger?: boolean;
  icon?: IconName;
}
interface ToastOpts {
  message: string;
  undo?: () => void;
}

const Ctx = createContext<{ confirm: (o: ConfirmOpts) => Promise<boolean>; toast: (o: ToastOpts) => void } | null>(null);

/** A reusable modal built on <dialog>. */
export function Modal({
  open,
  onClose,
  title,
  children,
  footer,
  wide,
  icon,
  iconColor,
}: {
  open: boolean;
  onClose: () => void;
  title: string;
  children?: React.ReactNode;
  footer?: React.ReactNode;
  wide?: boolean;
  icon?: IconName;
  iconColor?: string;
}) {
  const ref = useRef<HTMLDialogElement>(null);
  const { i18n } = useApp();
  useEffect(() => {
    const d = ref.current;
    if (!d) return;
    if (open && !d.open) d.showModal();
    if (!open && d.open) d.close();
  }, [open]);
  return (
    <dialog
      ref={ref}
      className={`dialog${wide ? ' wide' : ''}`}
      aria-labelledby="dialog-title"
      onCancel={(e) => {
        e.preventDefault();
        onClose();
      }}
    >
      {open ? (
        <>
          <div className="dialog-head">
            {icon ? (
              <span style={{ color: iconColor ?? 'var(--primary)', marginTop: 2 }}>
                <Icon name={icon} size={28} />
              </span>
            ) : null}
            <h2 id="dialog-title">{title}</h2>
            <button type="button" className="icon-btn" aria-label={i18n.t('close')} onClick={onClose}>
              <Icon name="close" size={22} />
            </button>
          </div>
          {children ? <div className="dialog-body">{children}</div> : null}
          {footer ? <div className="dialog-foot">{footer}</div> : null}
        </>
      ) : null}
    </dialog>
  );
}

export function FeedbackProvider({ children }: { children: React.ReactNode }) {
  const { i18n } = useApp();
  const [dlg, setDlg] = useState<(ConfirmOpts & { resolve: (v: boolean) => void }) | null>(null);
  const [toastState, setToast] = useState<(ToastOpts & { key: number }) | null>(null);

  const confirm = useCallback((o: ConfirmOpts) => new Promise<boolean>((resolve) => setDlg({ ...o, resolve })), []);
  const toast = useCallback((o: ToastOpts) => setToast({ ...o, key: Date.now() }), []);

  useEffect(() => {
    if (!toastState) return;
    const id = setTimeout(() => setToast(null), toastState.undo ? 7000 : 4000);
    return () => clearTimeout(id);
  }, [toastState]);

  const done = (v: boolean) => {
    dlg?.resolve(v);
    setDlg(null);
  };

  return (
    <Ctx.Provider value={{ confirm, toast }}>
      {children}
      <Modal
        open={!!dlg}
        onClose={() => done(false)}
        title={dlg?.title ?? ''}
        icon={dlg?.icon}
        iconColor={dlg?.danger ? 'var(--danger)' : undefined}
        footer={
          <>
            <Button variant="secondary" onClick={() => done(false)}>
              {i18n.t('cancel')}
            </Button>
            <Button variant={dlg?.danger ? 'danger' : 'primary'} onClick={() => done(true)} autoFocus={!dlg?.danger}>
              {dlg?.confirmLabel}
            </Button>
          </>
        }
      >
        {dlg?.body ? <p className="muted">{dlg.body}</p> : null}
      </Modal>
      <div className="toast-region" role="status" aria-live="polite">
        {toastState ? (
          <div className="toast" key={toastState.key}>
            <Icon name="normal" size={22} />
            <span>{toastState.message}</span>
            {toastState.undo ? (
              <button
                type="button"
                onClick={() => {
                  toastState.undo?.();
                  setToast(null);
                }}
              >
                {i18n.t('undo')}
              </button>
            ) : null}
          </div>
        ) : null}
      </div>
    </Ctx.Provider>
  );
}

export function useFeedback() {
  const c = useContext(Ctx);
  if (!c) throw new Error('useFeedback outside provider');
  return c;
}
