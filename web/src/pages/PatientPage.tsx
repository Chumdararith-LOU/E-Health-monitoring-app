import { useEffect, useMemo, useRef, useState } from 'react';
import type { PatientSeries, PatientSummary } from '@ehealth/types';
import { Link, useParams, useSearchParams } from 'react-router-dom';
import { addDays, dayKey, startOfDay } from '../data/dates';
import { isOutOfRange, MEASURE_ORDER, MEASURES, readingLevel } from '../data/ranges';
import { customRange, daysWithReadings, inRange, lastNDays, Range, statOf } from '../data/stats';
import { Reading } from '../data/types';
import { ApiClientError } from '../lib/api';
import { fetchPatientReport, hasLiveSeriesData, pickChartPoints } from '../lib/reports';
import { newId, useApp } from '../store/AppStore';
import { ChartSeries, LineChart } from '../ui/Charts';
import { Modal, useFeedback } from '../ui/Feedback';
import { Icon } from '../ui/Icon';
import { Avatar, Badge, Banner, Button, Card, Chip, Empty, Field, PageHeader, Segmented, StatusBadge, Tabs, Value } from '../ui/Kit';
import { ReadingModal } from '../ui/ReadingModal';

type Tab = 'overview' | 'readings' | 'notes';
type P = '7' | '30' | '90' | 'custom';
const PAGE = 15;
const SHOW_DEV_BANNER = import.meta.env.VITE_HIDE_DEV !== '1';

/** Patient report for the doctor (US-10, US-11, US-19, FR-17 via print). Admin may open it read-only for support. */
export function PatientPage() {
  const { id = '' } = useParams();
  const { i18n, user, token, userById, canView, readingsOf, state, dispatch } = useApp();
  const { toast } = useFeedback();
  const { t } = i18n;
  const [params, setParams] = useSearchParams();
  const tab = (params.get('tab') as Tab) || 'overview';
  const period = (params.get('p') as P) || '30';
  const today = dayKey(new Date());
  const [cFrom, setCFrom] = useState(dayKey(addDays(new Date(), -13)));
  const [cTo, setCTo] = useState(today);
  const [open, setOpen] = useState<Reading | null>(null);
  const [noteOpen, setNoteOpen] = useState(false);
  const [noteText, setNoteText] = useState('');
  const [noteErr, setNoteErr] = useState<string>();
  const [onlyFlagged, setOnlyFlagged] = useState(false);
  const [page, setPage] = useState(0);
  const noteRef = useRef<HTMLTextAreaElement>(null);

  const p = userById(id);
  const all = useMemo(() => (p ? readingsOf(p.id) : []), [p, readingsOf]);
  const range: Range = useMemo(() => {
    if (period === 'custom') {
      const a = new Date(cFrom), b = new Date(cTo);
      if (!isNaN(a.getTime()) && !isNaN(b.getTime())) return customRange(startOfDay(a), startOfDay(b));
    }
    return lastNDays(Number(period === 'custom' ? 30 : period));
  }, [period, cFrom, cTo]);
  const inPeriod = useMemo(() => inRange(all, range), [all, range]);
  const asc = useMemo(() => inPeriod.slice().reverse(), [inPeriod]);

  const allowed = Boolean(p && canView(id));
  const fields = useMemo(
    () => state.data.fields.filter((f) => f.active || inPeriod.some((r) => r.extra?.[f.id] != null)),
    [state.data.fields, inPeriod],
  );
  const seriesKeysKey = [...MEASURE_ORDER, ...fields.map((f) => f.id)].join(',');
  const apiDays = Math.min(365, Math.max(1, range.days));
  const apiFrom = period === 'custom' ? dayKey(range.from) : undefined;
  const apiTo = period === 'custom' ? dayKey(range.to) : undefined;
  const [apiSummary, setApiSummary] = useState<PatientSummary | null>(null);
  const [apiSeries, setApiSeries] = useState<Record<string, PatientSeries> | null>(null);
  const [apiError, setApiError] = useState<ApiClientError | null>(null);
  const [apiLoading, setApiLoading] = useState(false);
  const [retryTick, setRetryTick] = useState(0);

  useEffect(() => {
    if (!token || !allowed) {
      setApiSummary(null);
      setApiSeries(null);
      setApiError(null);
      setApiLoading(false);
      return;
    }
    const ctrl = new AbortController();
    const keys = seriesKeysKey ? seriesKeysKey.split(',') : [];
    const custom = apiFrom && apiTo ? { from: apiFrom, to: apiTo } : undefined;
    setApiLoading(true);
    setApiError(null);
    fetchPatientReport(id, keys, apiDays, token, ctrl.signal, custom)
      .then(({ summary, series }) => {
        setApiSummary(summary);
        setApiSeries(series);
        setApiLoading(false);
      })
      .catch((err: unknown) => {
        if (err instanceof DOMException && err.name === 'AbortError') return;
        setApiSummary(null);
        setApiSeries(null);
        setApiError(
          err instanceof ApiClientError
            ? err
            : new ApiClientError(0, 'unknown', 'errors.internal_error'),
        );
        setApiLoading(false);
      });
    return () => ctrl.abort();
  }, [token, allowed, id, apiDays, apiFrom, apiTo, seriesKeysKey, retryTick]);

  if (!p || !canView(id)) {
    return (
      <Empty icon="lock" title={t('notLinked')}>
        <Link className="btn btn-secondary" to={user?.role === 'admin' ? '/admin/readings' : '/patients'}>
          {t('backToPatients')}
        </Link>
      </Empty>
    );
  }

  const set = (k: string, v: string) => {
    const n = new URLSearchParams(params);
    n.set(k, v);
    setParams(n, { replace: true });
    setPage(0);
  };

  const team = state.data.links.filter((l) => l.patientId === p.id && l.status === 'active').map((l) => ({ l, u: userById(l.userId) }));
  const notes = state.data.notes.filter((n) => n.patientId === p.id).sort((a, b) => b.createdAt.localeCompare(a.createdAt));
  const isDoctor = user?.role === 'doctor';
  const from = range.from.getTime();
  const to = Math.min(range.to.getTime(), Date.now());
  const pts = (get: (r: Reading) => number | undefined) => asc.filter((r) => get(r) != null).map((r) => ({ t: new Date(r.takenAt).getTime(), v: get(r)!, id: r.id }));
  const seriesPts = (fieldKey: string, get: (r: Reading) => number | undefined) =>
    pickChartPoints(apiSeries, fieldKey, pts(get));
  const openById = (rid: string) => setOpen(all.find((r) => r.id === rid || r.takenAt === rid) ?? null);

  const charts: { key: string; title: string; unit: string; decimals?: number; series: ChartSeries[] }[] = [
    {
      key: 'bp', title: t('bp'), unit: 'mmHg',
      series: [
        { key: 'sys', label: t('m_systolic'), color: 'var(--series-1)', points: seriesPts('systolic', (r) => r.systolic), band: { min: MEASURES.systolic.normalMin, max: MEASURES.systolic.normalMax } },
        { key: 'dia', label: t('m_diastolic'), color: 'var(--series-2)', points: seriesPts('diastolic', (r) => r.diastolic), band: { min: MEASURES.diastolic.normalMin, max: MEASURES.diastolic.normalMax } },
      ],
    },
    { key: 'glu', title: t('m_glucose'), unit: 'mg/dL', series: [{ key: 'glu', label: t('m_glucose'), color: 'var(--series-1)', points: seriesPts('glucose', (r) => r.glucose), band: { min: MEASURES.glucose.normalMin, max: MEASURES.glucose.normalMax } }] },
    { key: 'pul', title: t('m_pulse'), unit: 'bpm', series: [{ key: 'pul', label: t('m_pulse'), color: 'var(--series-1)', points: seriesPts('pulse', (r) => r.pulse), band: { min: MEASURES.pulse.normalMin, max: MEASURES.pulse.normalMax } }] },
    ...fields
      .filter((f) => (apiSeries?.[f.id]?.points.length ?? 0) > 0 || inPeriod.some((r) => r.extra?.[f.id] != null))
      .map((f) => ({
        key: f.id, title: `${i18n.name(f)}${f.active ? '' : ' ' + t('archivedSuffix')}`, unit: f.unit, decimals: f.decimals,
        series: [{ key: f.id, label: i18n.name(f), color: 'var(--series-1)', points: seriesPts(f.id, (r) => r.extra?.[f.id]) }],
      })),
  ];

  const liveFields =
    apiSummary && apiSummary.fields.length > 0
      ? new Map(apiSummary.fields.map((f) => [f.fieldKey, f]))
      : null;

  const statRows = [
    ...MEASURE_ORDER.map((k) => {
      const live = liveFields?.get(k);
      return {
        key: k,
        label: t(`m_${k}`),
        unit: MEASURES[k].unit,
        dec: 0,
        s: live ? { min: live.min, max: live.max, avg: live.avg, count: live.count } : statOf(inPeriod, (r) => r[k]),
      };
    }),
    ...fields.map((f) => {
      const live = liveFields?.get(f.id);
      return {
        key: f.id,
        label: i18n.name(f),
        unit: f.unit,
        dec: f.decimals,
        s: live ? { min: live.min, max: live.max, avg: live.avg, count: live.count } : statOf(inPeriod, (r) => r.extra?.[f.id]),
      };
    }),
  ];

  const flagged = inPeriod.filter(isOutOfRange);
  const outOfRangeTotal = liveFields && apiSummary ? apiSummary.outOfRangeCount : flagged.length;
  const list = onlyFlagged ? flagged : inPeriod;
  const pages = Math.max(1, Math.ceil(list.length / PAGE));
  const pageRows = list.slice(page * PAGE, page * PAGE + PAGE);
  const last7 = Array.from({ length: 7 }, (_, i) => addDays(new Date(), i - 6));
  const days = new Set(all.map((r) => dayKey(r.takenAt)));
  const latest = all[0];

  const saveNote = () => {
    if (!noteText.trim()) {
      setNoteErr(t('errRequired'));
      noteRef.current?.focus();
      return;
    }
    dispatch({ type: 'addNote', note: { id: newId('n'), patientId: p.id, authorId: user!.id, text: noteText.trim(), createdAt: new Date().toISOString() } });
    setNoteText('');
    setNoteOpen(false);
    toast({ message: t('noteSaved') });
  };

  const periodControl = (
    <div className="toolbar no-print">
      <Segmented<P>
        label={t('period')}
        value={period}
        onChange={(v) => set('p', v)}
        options={[
          { value: '7', label: t('nDays', { n: 7 }) },
          { value: '30', label: t('nDays', { n: 30 }) },
          { value: '90', label: t('nDays', { n: 90 }) },
          { value: 'custom', label: t('custom') },
        ]}
      />
      {period === 'custom' ? (
        <div className="row-wrap">
          <label className="row small">
            {t('from')}
            <input className="input" type="date" value={cFrom} max={cTo} onChange={(e) => setCFrom(e.target.value)} style={{ width: 'auto' }} />
          </label>
          <label className="row small">
            {t('to')}
            <input className="input" type="date" value={cTo} min={cFrom} max={today} onChange={(e) => setCTo(e.target.value)} style={{ width: 'auto' }} />
          </label>
        </div>
      ) : null}
      <span className="muted small right">
        {i18n.date(range.from)} – {i18n.date(range.to)}
      </span>
    </div>
  );

  return (
    <>
      <div className="print-only">
        <h1>{t('reportFor', { name: i18n.name(p) })}</h1>
        <p className="muted">
          {t('generatedOn', { date: `${i18n.date(new Date())} ${i18n.time(new Date())}`, name: i18n.name(user ?? undefined) })} · {t('period')}: {i18n.date(range.from)} – {i18n.date(range.to)}
        </p>
      </div>

      <PageHeader
        crumbs={[user?.role === 'admin' ? { to: '/admin/readings', label: t('nav_readings') } : { to: '/patients', label: t('dashTitle') }]}
        title={
          <span className="row" style={{ gap: 'var(--s3)' }}>
            <Avatar name={i18n.name(p)} big />
            {i18n.name(p)}
          </span>
        }
        actions={
          <>
            <Button variant="secondary" icon="pdf" onClick={() => window.print()} title={t('exportHint')}>
              {t('exportPdf')}
            </Button>
            {isDoctor ? (
              <Button icon="note" onClick={() => setNoteOpen(true)}>
                {t('addNote')}
              </Button>
            ) : null}
          </>
        }
      />
      <div className="meta">
        <span>{t('years', { n: p.age ?? 0 })}</span>
        <span>{i18n.lang === 'km' ? p.conditionsKm : p.conditionsEn}</span>
        <span>
          <Icon name="phone" size={16} />
          {p.phone}
        </span>
        <span>
          <Icon name="patients" size={16} />
          {t('careTeam')}: {team.map(({ l, u }) => `${i18n.name(u)} (${i18n.role(l.relation)})`).join(', ') || t('none')}
        </span>
      </div>
      {user?.role === 'admin' ? <Banner kind="warning" icon="shield">{t('supportBanner')}</Banner> : null}

      <Tabs<Tab>
        label={i18n.name(p)}
        value={tab}
        onChange={(v) => set('tab', v)}
        tabs={[
          { value: 'overview', label: t('tab_overview') },
          { value: 'readings', label: t('tab_readings'), count: inPeriod.length },
          { value: 'notes', label: t('tab_notes'), count: notes.length },
        ]}
      />

      {tab === 'overview' ? (
        <div role="tabpanel" id="panel-overview" aria-labelledby="tab-overview" className="stack" style={{ gap: 'var(--s5)' }}>
          {periodControl}
          {apiError ? (
            <div className="no-print">
              <Banner kind="error" icon={apiError.status === 403 ? 'lock' : 'error'}>
                <div className="row-wrap" style={{ justifyContent: 'space-between' }}>
                  <span>{i18n.apiError(apiError.messageKey)}</span>
                  {apiError.status !== 403 ? (
                    <Button small variant="secondary" onClick={() => setRetryTick((n) => n + 1)}>
                      {t('retry')}
                    </Button>
                  ) : null}
                </div>
              </Banner>
            </div>
          ) : SHOW_DEV_BANNER && apiLoading ? (
            <div className="no-print">
              <Banner>{t('liveApiLoading')}</Banner>
            </div>
          ) : SHOW_DEV_BANNER && apiSummary ? (
            <div className="no-print">
              <Banner>
                {t('liveApiConnected', {
                  fields: apiSummary.fields.length,
                  missed: apiSummary.missedDays,
                  outOfRange: apiSummary.outOfRangeCount,
                })}
                {apiSummary.fields.length === 0 && !hasLiveSeriesData(apiSeries) ? ` ${t('liveApiDemoFallback')}` : ''}
              </Banner>
            </div>
          ) : null}
          <div className="grid-3">
            <Card>
              <div className="card-head">
                <h2>{t('summary')}</h2>
                <span className="small muted">
                  {t('daysRecorded', {
                    n: liveFields && apiSummary ? Math.max(0, apiDays - apiSummary.missedDays) : daysWithReadings(inPeriod),
                    total: range.days,
                  })}
                </span>
              </div>
              <div className="table-wrap">
                <table className="table stats">
                  <thead>
                    <tr>
                      <th scope="col">{t('measure')}</th>
                      <th scope="col" className="num">{t('min')}</th>
                      <th scope="col" className="num">{t('avg')}</th>
                      <th scope="col" className="num">{t('max')}</th>
                      <th scope="col" className="num">{t('count')}</th>
                    </tr>
                  </thead>
                  <tbody>
                    {statRows.map((r) => (
                      <tr key={r.key}>
                        <td>
                          <span className="strong">{r.label}</span> <span className="cell-sub">{r.unit}</span>
                        </td>
                        <td className="num">{i18n.num(r.s.min, r.dec)}</td>
                        <td className="num strong">{i18n.num(r.s.avg, r.dec)}</td>
                        <td className="num">{i18n.num(r.s.max, r.dec)}</td>
                        <td className="num muted">{i18n.num(r.s.count)}</td>
                      </tr>
                    ))}
                  </tbody>
                </table>
              </div>
              {outOfRangeTotal ? (
                <Badge kind="high" icon="alert">
                  {t('outOfRangeCount', { n: outOfRangeTotal })}
                </Badge>
              ) : (
                <StatusBadge level="normal" />
              )}
            </Card>
            <Card>
              <h2>{t('colLatest')}</h2>
              {latest ? (
                <button type="button" className="account-btn" onClick={() => setOpen(latest)} style={{ display: 'block' }}>
                  <div className="row">
                    <span className="small muted">
                      {i18n.dateRelative(latest.takenAt)} · {i18n.time(latest.takenAt)}
                    </span>
                    <span className="right" />
                    <StatusBadge level={readingLevel(latest)} />
                  </div>
                  <div style={{ fontSize: '1.75rem', fontWeight: 600 }} className="num">
                    <Value k="systolic" v={latest.systolic} />/<Value k="diastolic" v={latest.diastolic} /> <span className="small muted">mmHg</span>
                  </div>
                  <div className="num">
                    {t('m_pulse')} <Value k="pulse" v={latest.pulse} /> · {t('m_glucose')} <Value k="glucose" v={latest.glucose} /> <span className="small muted">mg/dL</span>
                  </div>
                </button>
              ) : (
                <p className="muted">{t('noData')}</p>
              )}
              <div className="stack-sm">
                <span className="small muted">{t('nDays', { n: 7 })}</span>
                <div className="dots" role="list" aria-label={t('nDays', { n: 7 })}>
                  {last7.map((d) => {
                    const on = days.has(dayKey(d));
                    return (
                      <span key={d.toISOString()} role="listitem" className={`dot ${on ? 'on' : 'off'}`} title={`${i18n.date(d)}: ${on ? t('recorded') : t('missed')}`} aria-label={`${i18n.date(d)}: ${on ? t('recorded') : t('missed')}`}>
                        {i18n.weekdayInitials[d.getDay()]}
                      </span>
                    );
                  })}
                </div>
              </div>
            </Card>
          </div>
          <div className="grid-2">
            {charts.map((c) => (
              <ChartCard key={`${c.key}-${from}-${to}`} title={c.title} unit={c.unit} series={c.series} decimals={c.decimals} from={from} to={to} onOpen={openById} />
            ))}
          </div>
          {notes.length ? (
            <Card className="print-only">
              <h2>{t('notes')}</h2>
              {notes.map((n) => (
                <div key={n.id} className="note">
                  <span className="small muted">
                    {i18n.name(userById(n.authorId))} · {i18n.date(n.createdAt)}
                  </span>
                  <p>{n.text}</p>
                </div>
              ))}
            </Card>
          ) : null}
        </div>
      ) : null}

      {tab === 'readings' ? (
        <div role="tabpanel" id="panel-readings" aria-labelledby="tab-readings" className="stack">
          {periodControl}
          <Card className="card-tight">
            <div className="toolbar" style={{ padding: 'var(--s3) var(--s4)' }}>
              <Chip pressed={onlyFlagged} onClick={() => { setOnlyFlagged(!onlyFlagged); setPage(0); }} icon="alert" count={i18n.num(flagged.length)}>
                {t('onlyFlagged')}
              </Chip>
              <span className="right small muted">{t('readingsCount', { n: list.length })}</span>
            </div>
            {!list.length ? (
              <Empty icon="readings" title={t('noData')} />
            ) : (
              <>
                <div className="table-wrap">
                  <table className="table responsive">
                    <caption className="sr-only">{t('tab_readings')}</caption>
                    <thead>
                      <tr>
                        <th scope="col">{t('date')}</th>
                        <th scope="col" className="num">{t('bp')} <span className="cell-sub">mmHg</span></th>
                        <th scope="col" className="num">{t('m_pulse')}</th>
                        <th scope="col" className="num">{t('m_glucose')} <span className="cell-sub">mg/dL</span></th>
                        {fields.map((f) => (
                          <th key={f.id} scope="col" className="num">{i18n.name(f)} <span className="cell-sub">{f.unit}</span></th>
                        ))}
                        <th scope="col">{t('status')}</th>
                        <th scope="col">{t('enteredBy')}</th>
                        <th scope="col">{t('note')}</th>
                      </tr>
                    </thead>
                    <tbody>
                      {pageRows.map((r) => (
                        <tr key={r.id} className="clickable" onClick={() => setOpen(r)}>
                          <td data-label={t('date')}>
                            <button type="button" className="sort-btn row-link" onClick={(e) => { e.stopPropagation(); setOpen(r); }}>
                              {i18n.dateRelative(r.takenAt)}
                            </button>
                            <div className="cell-sub">{i18n.time(r.takenAt)}</div>
                          </td>
                          <td data-label={t('bp')} className="num">
                            {r.systolic != null ? <><Value k="systolic" v={r.systolic} />/<Value k="diastolic" v={r.diastolic} /></> : '–'}
                          </td>
                          <td data-label={t('m_pulse')} className="num"><Value k="pulse" v={r.pulse} /></td>
                          <td data-label={t('m_glucose')} className="num"><Value k="glucose" v={r.glucose} /></td>
                          {fields.map((f) => (
                            <td key={f.id} data-label={i18n.name(f)} className="num">{r.extra?.[f.id] != null ? i18n.num(r.extra[f.id], f.decimals) : '–'}</td>
                          ))}
                          <td data-label={t('status')}><StatusBadge level={readingLevel(r)} /></td>
                          <td data-label={t('enteredBy')}>
                            <span className="row" style={{ gap: 4 }}>
                              <Icon name={r.method === 'ocr' ? 'camera' : 'keyboard'} size={16} title={t(`method_${r.method}`)} />
                              {i18n.name(userById(r.enteredBy))}
                            </span>
                          </td>
                          <td data-label={t('note')} className="small" style={{ maxWidth: '14rem' }}>{r.note ?? ''}</td>
                        </tr>
                      ))}
                    </tbody>
                  </table>
                </div>
                <div className="pager">
                  <span className="small muted">
                    {t('showingOf', { from: page * PAGE + 1, to: Math.min(list.length, page * PAGE + PAGE), total: list.length })}
                  </span>
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
        </div>
      ) : null}

      {tab === 'notes' ? (
        <div role="tabpanel" id="panel-notes" aria-labelledby="tab-notes" className="stack">
          <Card>
            <div className="card-head">
              <h2>{t('notes')}</h2>
              <Badge kind="info" icon="eye">{t('visibleTo')}</Badge>
              {isDoctor ? <Button icon="plus" onClick={() => setNoteOpen(true)}>{t('addNote')}</Button> : null}
            </div>
            {!notes.length ? <p className="muted">{t('noNotes')}</p> : null}
            {notes.map((n) => (
              <div key={n.id} className="note">
                <span className="small muted">
                  {i18n.name(userById(n.authorId))} · {i18n.date(n.createdAt)} · {i18n.time(n.createdAt)}
                </span>
                <p style={{ whiteSpace: 'pre-wrap' }}>{n.text}</p>
              </div>
            ))}
          </Card>
        </div>
      ) : null}

      <ReadingModal reading={open} onClose={() => setOpen(null)} />
      <Modal
        open={noteOpen}
        onClose={() => setNoteOpen(false)}
        title={`${t('addNote')} · ${i18n.name(p)}`}
        icon="note"
        footer={
          <>
            <Button variant="secondary" onClick={() => setNoteOpen(false)}>{t('cancel')}</Button>
            <Button icon="check" onClick={saveNote}>{t('save')}</Button>
          </>
        }
      >
        <Field label={t('note')} error={noteErr} hint={t('visibleTo')}>
          {(fp) => (
            <textarea
              {...fp}
              ref={noteRef}
              className="textarea"
              autoFocus
              value={noteText}
              placeholder={t('notePlaceholder')}
              maxLength={1000}
              onChange={(e) => { setNoteText(e.target.value); setNoteErr(undefined); }}
            />
          )}
        </Field>
      </Modal>
    </>
  );
}

function ChartCard({ title, unit, series, from, to, decimals = 0, onOpen }: { title: string; unit: string; series: ChartSeries[]; from: number; to: number; decimals?: number; onOpen: (id: string) => void }) {
  const { i18n } = useApp();
  const { t } = i18n;
  const [view, setView] = useState<'chart' | 'table'>('chart');
  const empty = series.every((s) => !s.points.length);
  return (
    <Card>
      <div className="card-head">
        <h3>
          {title} <span className="small muted" style={{ fontWeight: 400 }}>{unit}</span>
        </h3>
        {!empty ? (
          <span className="no-print">
            <Segmented label={title} value={view} onChange={setView} options={[{ value: 'chart', label: t('chartView') }, { value: 'table', label: t('tableView') }]} />
          </span>
        ) : null}
      </div>
      {empty ? (
        <p className="muted">{t('noData')}</p>
      ) : view === 'chart' ? (
        <LineChart title={title} series={series} from={from} to={to} decimals={decimals} onOpen={onOpen} />
      ) : (
        <div className="table-wrap" style={{ maxHeight: 260, overflowY: 'auto' }}>
          <table className="table stats">
            <thead>
              <tr>
                <th scope="col">{t('date')}</th>
                {series.map((s) => <th key={s.key} scope="col" className="num">{s.label}</th>)}
              </tr>
            </thead>
            <tbody>
              {series[0].points.slice().reverse().map((pt) => (
                <tr key={pt.id} className="clickable" onClick={() => onOpen(pt.id)}>
                  <td>{i18n.dateShort(new Date(pt.t))}</td>
                  {series.map((s) => (
                    <td key={s.key} className="num">{i18n.num(s.points.find((q) => q.id === pt.id)?.v, decimals)}</td>
                  ))}
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </Card>
  );
}
