import { useMemo, useState } from 'react';
import { Link } from 'react-router-dom';
import { MEASURES, readingLevel } from '../../data/ranges';
import { inRange, lastNDays } from '../../data/stats';
import { Reading } from '../../data/types';
import { validateReading, Vals } from '../../data/validate';
import { useApp } from '../../store/AppStore';
import { Modal, useFeedback } from '../../ui/Feedback';
import { Icon } from '../../ui/Icon';
import { Banner, Button, Card, Empty, Field, PageHeader, Segmented, StatusBadge, Value } from '../../ui/Kit';

const PAGE = 20;
type P = '7' | '30' | '90';

/** Admin support: find a reading, fix it (same validation as the mobile form) or delete it (confirm + undo). */
export function ReadingsSupportPage() {
  const { i18n, state, patients, userById, dispatch } = useApp();
  const { confirm, toast } = useFeedback();
  const { t } = i18n;
  const [pid, setPid] = useState('all');
  const [period, setPeriod] = useState<P>('7');
  const [page, setPage] = useState(0);
  const [edit, setEdit] = useState<Reading | null>(null);

  const list = useMemo(() => {
    const rs = state.data.readings.filter((r) => pid === 'all' || r.patientId === pid);
    return inRange(rs, lastNDays(Number(period))).sort((a, b) => b.takenAt.localeCompare(a.takenAt));
  }, [state.data.readings, pid, period]);
  const pages = Math.max(1, Math.ceil(list.length / PAGE));
  const rows = list.slice(page * PAGE, page * PAGE + PAGE);

  const del = async (r: Reading) => {
    const ok = await confirm({
      title: t('deleteReadingTitle'),
      body: t('deleteReadingBody', { name: i18n.name(userById(r.patientId)), date: `${i18n.date(r.takenAt)} ${i18n.time(r.takenAt)}` }),
      confirmLabel: t('deleteReading'),
      danger: true,
      icon: 'delete',
    });
    if (!ok) return;
    dispatch({ type: 'deleteReading', id: r.id });
    toast({ message: t('readingDeleted'), undo: () => dispatch({ type: 'upsertReading', reading: r }) });
  };

  return (
    <>
      <PageHeader title={t('nav_readings')} subtitle={t('readingsSubtitle')} />
      <Banner kind="warning" icon="shield">{t('supportBanner')}</Banner>
      <Card className="card-tight">
        <div className="toolbar" style={{ padding: 'var(--s4)' }}>
          <label className="row">
            <span className="strong">{t('colPatient')}</span>
            <select className="select" style={{ width: 'auto', minWidth: '14rem' }} value={pid} onChange={(e) => { setPid(e.target.value); setPage(0); }}>
              <option value="all">{t('allPatients')}</option>
              {patients.map((p) => (
                <option key={p.id} value={p.id}>{i18n.name(p)}</option>
              ))}
            </select>
          </label>
          <Segmented<P>
            label={t('period')}
            value={period}
            onChange={(v) => { setPeriod(v); setPage(0); }}
            options={[
              { value: '7', label: t('nDays', { n: 7 }) },
              { value: '30', label: t('nDays', { n: 30 }) },
              { value: '90', label: t('nDays', { n: 90 }) },
            ]}
          />
          <span className="right small muted">{t('readingsCount', { n: list.length })}</span>
        </div>
        {!list.length ? (
          <Empty icon="readings" title={t('noData')} />
        ) : (
          <>
            <div className="table-wrap">
              <table className="table responsive">
                <caption className="sr-only">{t('nav_readings')}</caption>
                <thead>
                  <tr>
                    <th scope="col">{t('date')}</th>
                    <th scope="col">{t('colPatient')}</th>
                    <th scope="col" className="num">{t('bp')}</th>
                    <th scope="col" className="num">{t('m_pulse')}</th>
                    <th scope="col" className="num">{t('m_glucose')}</th>
                    <th scope="col">{t('status')}</th>
                    <th scope="col">{t('enteredBy')}</th>
                    <th scope="col"><span className="sr-only">{t('actions')}</span></th>
                  </tr>
                </thead>
                <tbody>
                  {rows.map((r) => (
                    <tr key={r.id}>
                      <td data-label={t('date')}>
                        {i18n.dateRelative(r.takenAt)}
                        <div className="cell-sub">{i18n.time(r.takenAt)}</div>
                      </td>
                      <td data-label={t('colPatient')}>
                        <Link className="row-link" to={`/patients/${r.patientId}`}>{i18n.name(userById(r.patientId))}</Link>
                      </td>
                      <td data-label={t('bp')} className="num">{r.systolic != null ? <><Value k="systolic" v={r.systolic} />/<Value k="diastolic" v={r.diastolic} /></> : '–'}</td>
                      <td data-label={t('m_pulse')} className="num"><Value k="pulse" v={r.pulse} /></td>
                      <td data-label={t('m_glucose')} className="num"><Value k="glucose" v={r.glucose} /></td>
                      <td data-label={t('status')}><StatusBadge level={readingLevel(r)} /></td>
                      <td data-label={t('enteredBy')}>
                        <span className="row" style={{ gap: 4 }}>
                          <Icon name={r.method === 'ocr' ? 'camera' : 'keyboard'} size={16} title={t(`method_${r.method}`)} />
                          {i18n.name(userById(r.enteredBy))}
                        </span>
                      </td>
                      <td>
                        <div className="row" style={{ justifyContent: 'flex-end' }}>
                          <Button small variant="ghost" icon="edit" onClick={() => setEdit(r)} aria-label={`${t('edit')}: ${i18n.date(r.takenAt)}`}>{t('edit')}</Button>
                          <Button small variant="ghost-danger" icon="delete" onClick={() => del(r)} aria-label={`${t('delete')}: ${i18n.date(r.takenAt)}`}>{t('delete')}</Button>
                        </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
            <div className="pager">
              <span className="small muted">{t('showingOf', { from: page * PAGE + 1, to: Math.min(list.length, page * PAGE + PAGE), total: list.length })}</span>
              <span className="right" />
              <Button small variant="secondary" icon="chevronLeft" disabled={page === 0} onClick={() => setPage(page - 1)}>{t('prev')}</Button>
              <span className="small">{t('pageOf', { n: page + 1, total: pages })}</span>
              <Button small variant="secondary" disabled={page >= pages - 1} onClick={() => setPage(page + 1)}>
                {t('next')}
                <Icon name="chevronRight" size={18} />
              </Button>
            </div>
          </>
        )}
      </Card>
      {edit ? <EditReading reading={edit} onClose={() => setEdit(null)} /> : null}
    </>
  );
}

function EditReading({ reading, onClose }: { reading: Reading; onClose: () => void }) {
  const { i18n, state, userById, dispatch } = useApp();
  const { confirm, toast } = useFeedback();
  const { t } = i18n;
  const fields = state.data.fields.filter((f) => f.active || reading.extra?.[f.id] != null);
  const init: Vals = useMemo(() => {
    const v: Vals = {};
    (['systolic', 'diastolic', 'pulse', 'glucose'] as const).forEach((k) => (v[k] = reading[k] != null ? String(reading[k]) : ''));
    fields.forEach((f) => (v[f.id] = reading.extra?.[f.id] != null ? String(reading.extra[f.id]) : ''));
    return v;
  }, [reading]); // eslint-disable-line react-hooks/exhaustive-deps
  const [vals, setVals] = useState<Vals>(init);
  const [note, setNote] = useState(reading.note ?? '');
  const [touched, setTouched] = useState<Record<string, boolean>>({});
  const [submitted, setSubmitted] = useState(false);
  const res = validateReading(vals, fields, i18n);
  const dirty = JSON.stringify(vals) !== JSON.stringify(init) || note !== (reading.note ?? '');
  const show = (k: string) => submitted || touched[k];

  const close = async () => {
    if (dirty && !(await confirm({ title: t('discardTitle'), confirmLabel: t('discard'), danger: true }))) return;
    onClose();
  };
  const save = () => {
    setSubmitted(true);
    if (!res.ok) {
      const first = ['systolic', 'diastolic', 'pulse', 'glucose', ...fields.map((f) => f.id)].find((k) => res.errors[k]);
      if (first) document.getElementById(`e-${first}`)?.focus();
      return;
    }
    const updated: Reading = { ...reading, systolic: undefined, diastolic: undefined, pulse: undefined, glucose: undefined, ...res.out, extra: res.extra, note: note.trim() || undefined, updatedAt: new Date().toISOString() };
    dispatch({ type: 'upsertReading', reading: updated });
    toast({ message: t('readingUpdated'), undo: () => dispatch({ type: 'upsertReading', reading }) });
    onClose();
  };

  const num = (k: string, label: string, unit: string, decimal = false) => (
    <Field label={label} error={show(k) ? res.errors[k] : undefined} warning={show(k) ? res.warnings[k] : undefined}>
      {(p) => (
        <div className="input-wrap">
          <input
            {...p}
            id={`e-${k}`}
            className={`input input-big${show(k) && res.warnings[k] ? ' warn' : ''}`}
            inputMode={decimal ? 'decimal' : 'numeric'}
            value={vals[k]}
            onChange={(e) => setVals({ ...vals, [k]: e.target.value })}
            onBlur={() => setTouched({ ...touched, [k]: true })}
          />
          <span className="suffix">{unit}</span>
        </div>
      )}
    </Field>
  );

  return (
    <Modal
      open
      wide
      onClose={close}
      icon="edit"
      title={`${t('editReading')} · ${i18n.name(userById(reading.patientId))}`}
      footer={
        <>
          <Button variant="secondary" onClick={close}>{t('cancel')}</Button>
          <Button icon="check" onClick={save}>{t('saveChanges')}</Button>
        </>
      }
    >
      <p className="muted">
        {i18n.date(reading.takenAt)} · {i18n.time(reading.takenAt)} · {t('enteredBy')}: {i18n.name(userById(reading.enteredBy))}
      </p>
      {submitted && !res.ok ? <Banner kind="error">{res.form ?? t('errFixBelow')}</Banner> : null}
      <div className="form-grid">
        {num('systolic', t('m_systolic'), MEASURES.systolic.unit)}
        {num('diastolic', t('m_diastolic'), MEASURES.diastolic.unit)}
        {num('pulse', t('m_pulse'), MEASURES.pulse.unit)}
        {num('glucose', t('m_glucose'), MEASURES.glucose.unit)}
        {fields.map((f) => <div key={f.id}>{num(f.id, `${i18n.name(f)} (${t('optional')})`, f.unit, f.decimals > 0)}</div>)}
        <div className="span-2">
          <Field label={`${t('note')} (${t('optional')})`}>
            {(p) => <textarea {...p} className="textarea" style={{ minHeight: '4.5rem' }} value={note} onChange={(e) => setNote(e.target.value)} maxLength={200} />}
          </Field>
        </div>
      </div>
    </Modal>
  );
}
