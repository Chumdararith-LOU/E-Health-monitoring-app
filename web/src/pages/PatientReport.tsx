// Doctor patient report (US-10, US-11, US-19): 70 / 30 layout.
// Main: period tabs, Min/Avg/Max (schema-driven, includes active custom
// fields), one chart per metric, reading log with photo check.
// Sidebar: patient summary, clinic PDF (print), clinical notes + post note.

import { useEffect, useMemo, useState } from 'react';
import type { PatientSummary } from '@ehealth/types';
import { useApp } from '../state/AppState';
import { Crumbs, Header, SHOW_DEV_STRIP } from '../components/Header';
import { apiErrorText } from '../i18n/strings';
import { ApiClientError, apiGetPatientSummary } from '../lib/api';
import { Icon } from '../components/Icon';
import { Alert, Badge, Empty, ErrorState, Loading, Pager, Panel, Segmented } from '../components/ui';
import { LegendBand, LegendDiamond, LegendLine, TrendChart, type ChartPoint } from '../components/TrendChart';
import { PhotoModal } from '../components/PhotoModal';
import { byField, fmtValue, inRange, readingFlags, readingsOf, sameDay, statFor, statusOf, valueOf } from '../lib/stats';
import { dayStart, daysAgo } from '../data/mock';
import type { Reading, VitalField } from '../data/types';

type Period = '7' | '30' | '90' | 'custom';
const LOG_PAGE = 10;

export function PatientReport({ patientId }: { patientId: string }) {
  const { t, f, lang, session, data, fields, simulate, setSimulate, addNote } = useApp();
  const [period, setPeriod] = useState<Period>('30');
  const today = dayStart(new Date());
  const [from, setFrom] = useState(f.iso(daysAgo(13, today)));
  const [to, setTo] = useState(f.iso(today));
  const [logPage, setLogPage] = useState(0);
  const [photoIdx, setPhotoIdx] = useState<number | null>(null);
  const [note, setNote] = useState('');
  const [posted, setPosted] = useState(false);

  const patient = data.patients.find((p) => p.id === patientId);
  const all = useMemo(() => readingsOf(data.readings, patientId), [data.readings, patientId]);

  const { start, end } = useMemo(() => {
    if (period === 'custom') {
      const a = from ? new Date(`${from}T00:00:00`) : daysAgo(13, today);
      const b = to ? new Date(`${to}T00:00:00`) : today;
      return a <= b ? { start: a, end: b } : { start: b, end: a };
    }
    return { start: daysAgo(Number(period) - 1, today), end: today };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [period, from, to]);

  const rs = useMemo(() => inRange(all, start, end), [all, start, end]);
  const active = fields.filter((x) => x.active);
  const photos = all.filter((r) => r.photo);
  const totalDays = Math.round((end.getTime() - start.getTime()) / 86400000) + 1;
  const periodLabel = period === 'custom' ? `${f.day(start)} – ${f.day(end)}` : t.days(f.n(period));

  const dayKeys = new Set(rs.map((r) => dayStart(r.time).getTime()));
  let missed = 0;
  for (let i = 0; i < totalDays; i++) {
    const d = new Date(start.getFullYear(), start.getMonth(), start.getDate() + i);
    if (sameDay(d, today)) continue;
    if (!dayKeys.has(d.getTime())) missed++;
  }
  const flaggedDays = new Set(rs.filter((r) => readingFlags(fields, r).any).map((r) => dayStart(r.time).getTime())).size;

  const [apiSummary, setApiSummary] = useState<PatientSummary | null>(null);
  const [apiError, setApiError] = useState<ApiClientError | null>(null);
  const [apiLoading, setApiLoading] = useState(false);
  const [retryTick, setRetryTick] = useState(0);

  const apiDays = Math.min(365, Math.max(1, totalDays));
  const token = session?.token;
  const hasPatient = Boolean(patient);

  useEffect(() => {
    if (!token || !hasPatient || simulate !== 'none') {
      setApiSummary(null);
      setApiError(null);
      setApiLoading(false);
      return;
    }
    const ctrl = new AbortController();
    setApiLoading(true);
    setApiError(null);
    apiGetPatientSummary(patientId, apiDays, token, ctrl.signal)
      .then((res) => {
        setApiSummary(res);
        setApiLoading(false);
      })
      .catch((err: unknown) => {
        if (err instanceof DOMException && err.name === 'AbortError') return;
        setApiSummary(null);
        setApiError(
          err instanceof ApiClientError
            ? err
            : new ApiClientError(0, 'unknown', 'errors.internal_error'),
        );
        setApiLoading(false);
      });
    return () => ctrl.abort();
  }, [token, hasPatient, patientId, apiDays, simulate, retryTick]);

  if (!patient) {
    return (
      <>
        <Header active="reports" />
        <main className="wrap page">
          <Empty icon="user" title={t.patientNotFound} action={<a className="btn btn-navy" href="#/doctor">{t.backToDash}</a>} />
        </main>
      </>
    );
  }

  const name = patient.name[lang];
  const latest = all[0];
  const latestFlags = latest ? readingFlags(fields, latest) : undefined;

  // ---------- Charts ----------
  const oldestFirst = [...rs].reverse();
  const pts = (fid: string, field: VitalField, line2: (r: Reading) => string): ChartPoint[] =>
    oldestFirst
      .filter((r) => valueOf(r, fid) !== undefined)
      .map((r) => {
        const v = valueOf(r, fid)!;
        return { t: r.time, v, flagged: statusOf(field, v) !== 'normal', line1: f.dayTime(r.time), line2: line2(r) };
      });
  const sysF = byField(fields, 'sys');
  const diaF = byField(fields, 'dia');
  const bpLine = (r: Reading) => f.n(`${r.systolic}/${r.diastolic} mmHg`);

  // ---------- Log (day by day, newest first) ----------
  const logItems: ({ kind: 'r'; r: Reading } | { kind: 'm'; d: Date })[] = [];
  for (let i = 0; i < totalDays; i++) {
    const d = new Date(end.getFullYear(), end.getMonth(), end.getDate() - i);
    const day = rs.filter((r) => sameDay(r.time, d));
    if (day.length) day.forEach((r) => logItems.push({ kind: 'r', r }));
    else if (!sameDay(d, today) && d >= dayStart(patient.linkedSince)) logItems.push({ kind: 'm', d });
  }
  const logPages = Math.max(1, Math.ceil(logItems.length / LOG_PAGE));
  const lp = Math.min(logPage, logPages - 1);
  const logShown = logItems.slice(lp * LOG_PAGE, lp * LOG_PAGE + LOG_PAGE);
  const customFields = active.filter((x) => !x.core);

  const offline = simulate === 'offline';

  let main;
  if (simulate === 'revoked' || apiError?.status === 403) {
    main = (
      <Alert sev="info" icon="lock" action={<a className="btn btn-navy" href="#/doctor">{t.backToDash}</a>}>
        {t.accessRevoked}
      </Alert>
    );
  } else if (simulate === 'loading' || apiLoading) {
    main = <Loading />;
  } else if (simulate === 'error' || apiError) {
    main = (
      <ErrorState
        message={apiError ? apiErrorText(lang, apiError.messageKey) : undefined}
        onRetry={() => (apiError ? setRetryTick((n) => n + 1) : setSimulate('none'))}
      />
    );
  } else {
    main = (
      <div className="split">
        <div className="split-main">
          <div className="row between no-print">
            <Segmented
              label={t.period}
              value={period}
              onChange={(p) => {
                setPeriod(p);
                setLogPage(0);
              }}
              options={[
                { value: '7', label: t.days(f.n(7)) },
                { value: '30', label: t.days(f.n(30)) },
                { value: '90', label: t.days(f.n(90)) },
                { value: 'custom', label: t.custom },
              ]}
            />
            {period === 'custom' ? (
              <div className="row">
                <label className="cap" htmlFor="from" style={{ fontWeight: 600, color: 'var(--text)' }}>
                  {t.from}
                </label>
                <input id="from" type="date" className="input" value={from} max={f.iso(today)} onChange={(e) => setFrom(e.target.value)} />
                <label className="cap" htmlFor="to" style={{ fontWeight: 600, color: 'var(--text)' }}>
                  {t.to}
                </label>
                <input id="to" type="date" className="input" value={to} max={f.iso(today)} onChange={(e) => setTo(e.target.value)} />
              </div>
            ) : (
              <span className="cap" style={{ fontWeight: 600, color: 'var(--text)' }}>
                {f.dayY(start)} – {f.dayY(end)}
              </span>
            )}
          </div>

          {SHOW_DEV_STRIP && apiSummary && (
            <Alert sev="info">
              Live API <code>GET /patients/{apiSummary.patientId}/summary?days={apiDays}</code> →{' '}
              {apiSummary.fields.length} fields · {apiSummary.missedDays} missed days · {apiSummary.outOfRangeCount} out of range
              {apiSummary.fields.length === 0 ? ' (mock charts shown until readings module is wired)' : ''}
            </Alert>
          )}

          {rs.length === 0 ? (
            <Empty icon="info" title={t.noReadings} />
          ) : (
            <>
              <Panel
                title={t.summaryOf(periodLabel)}
                bodyClass=""
                right={
                  <div className="row" style={{ gap: 6 }}>
                    <Badge tone="gray" icon={null}>
                      {t.readingsN(f.n(rs.length))}
                    </Badge>
                    <Badge tone="warn">{t.missedDays(f.n(missed))}</Badge>
                    <Badge tone="crit">{t.flaggedDaysN(f.n(flaggedDays))}</Badge>
                  </div>
                }
              >
                <div className="tbl-scroll">
                  <table className="dt num" style={{ minWidth: 620 }}>
                    <thead>
                      <tr>
                        <th>{t.colMeasure}</th>
                        <th className="r">{t.colMin}</th>
                        <th className="r">{t.colAvg}</th>
                        <th className="r">{t.colMax}</th>
                        <th className="r">{t.colNormal}</th>
                        <th>{t.colFlagged}</th>
                      </tr>
                    </thead>
                    <tbody>
                      {active.map((fd) => {
                        const s = statFor(rs, fd);
                        if (!s) return null;
                        const high = s.max > fd.normalMax;
                        const low = s.min < fd.normalMin;
                        return (
                          <tr key={fd.id}>
                            <td>
                              <b>{fd.name[lang]}</b> <span className="cap">({fd.unit})</span> {!fd.core && <Badge tone="gray" icon={null}>{t.extraField}</Badge>}
                            </td>
                            <td className={`r ${low ? 'hi' : ''}`}>
                              {f.n(fmtValue(fd, s.min))}
                              {low ? ' ▼' : ''}
                            </td>
                            <td className="r">{f.n(fmtValue(fd, s.avg))}</td>
                            <td className={`r ${high ? 'hi' : ''}`}>
                              {f.n(fmtValue(fd, s.max))}
                              {high ? ' ▲' : ''}
                            </td>
                            <td className="r cap">{f.n(`${fmtValue(fd, fd.normalMin)}–${fmtValue(fd, fd.normalMax)}`)}</td>
                            <td>{s.flagged > 0 ? <Badge tone="crit">{t.times(f.n(s.flagged))}</Badge> : <span className="cap">{f.n(0)}</span>}</td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
              </Panel>

              <Panel title={t.bp} right={<span className="cap">mmHg</span>}>
                <TrendChart
                  f={f}
                  label={`${t.bp} · ${periodLabel}`}
                  start={start}
                  end={end}
                  bands={[
                    { lo: sysF.normalMin, hi: sysF.normalMax },
                    { lo: diaF.normalMin, hi: diaF.normalMax },
                  ]}
                  series={[
                    { points: pts('dia', diaF, bpLine), color: '#4A5568', dashed: true, marker: 'square', width: 1.6 },
                    { points: pts('sys', sysF, bpLine), color: '#1B4369', width: 2.2 },
                  ]}
                />
                <div className="legend" style={{ marginTop: 8 }}>
                  <LegendLine color="#1B4369">{t.systolic}</LegendLine>
                  <LegendLine color="#4A5568" dashed square>
                    {t.diastolic}
                  </LegendLine>
                  <LegendDiamond>{t.outOfRange}</LegendDiamond>
                  <LegendBand>{t.normalRange}</LegendBand>
                  <span className="no-print">{t.hoverHint}</span>
                </div>
              </Panel>

              <div className="cards2">
                {[byField(fields, 'glu'), byField(fields, 'pul'), ...customFields].map((fd) => {
                  const p = pts(fd.id, fd, (r) => f.n(`${fmtValue(fd, valueOf(r, fd.id)!)} ${fd.unit}`));
                  if (!p.length) return null;
                  const title = fd.id === 'glu' ? t.glucose : fd.id === 'pul' ? t.pulse : fd.name[lang];
                  return (
                    <Panel key={fd.id} title={title} right={fd.core ? <span className="cap">{fd.unit}</span> : <Badge tone="gray" icon={null}>{t.extraField}</Badge>}>
                      <TrendChart f={f} label={`${title} · ${periodLabel}`} start={start} end={end} width={380} height={220} bands={[{ lo: fd.normalMin, hi: fd.normalMax }]} series={[{ points: p, color: '#1B4369' }]} />
                      <div className="legend" style={{ marginTop: 6 }}>
                        <LegendDiamond>{t.outOfRange}</LegendDiamond>
                        <LegendBand>{`${t.normalRange} ${f.n(`${fmtValue(fd, fd.normalMin)}–${fmtValue(fd, fd.normalMax)}`)}`}</LegendBand>
                      </div>
                    </Panel>
                  );
                })}
              </div>

              <Panel title={t.logTitle} bodyClass="" right={<span className="cap">{t.rowsOf(f.n(lp * LOG_PAGE + 1), f.n(lp * LOG_PAGE + logShown.length), f.n(logItems.length))}</span>}>
                <div className="tbl-scroll">
                  <table className="dt num" style={{ minWidth: 780 }}>
                    <thead>
                      <tr>
                        <th>{t.colDate}</th>
                        <th>{t.bp}</th>
                        <th className="r">{t.pulse}</th>
                        <th className="r">{t.glucose}</th>
                        {customFields.map((cf) => (
                          <th key={cf.id} className="r">
                            {cf.name[lang]}
                          </th>
                        ))}
                        <th>{t.colSource}</th>
                        <th>{t.colNote}</th>
                        <th className="no-print">{t.colPhoto}</th>
                      </tr>
                    </thead>
                    <tbody>
                      {logShown.map((it) => {
                        if (it.kind === 'm')
                          return (
                            <tr key={`m-${it.d.getTime()}`} className="r-warn">
                              <td>
                                <b>{f.day(it.d)}</b>
                              </td>
                              <td colSpan={6 + customFields.length}>
                                <Badge tone="warn">{t.missedRow}</Badge>
                              </td>
                            </tr>
                          );
                        const r = it.r;
                        const fl = readingFlags(fields, r);
                        const by = r.author === 'caretaker' && patient.caretaker ? patient.caretaker.name[lang] : patient.name[lang].split(' ')[0];
                        return (
                          <tr key={r.id}>
                            <td>
                              <b>{f.day(r.time)}</b> <span className="cap">{f.time(r.time)}</span>
                            </td>
                            <td className={fl.bp !== 'normal' ? 'hi' : undefined}>
                              {f.n(`${r.systolic}/${r.diastolic}`)}
                              {fl.bp === 'high' ? ' ▲' : fl.bp === 'low' ? ' ▼' : ''}
                            </td>
                            <td className={`r ${fl.pul !== 'normal' ? 'hi' : ''}`}>{f.n(r.pulse)}</td>
                            <td className={`r ${fl.glu !== 'normal' ? 'hi' : ''}`}>
                              {f.n(Math.round(r.glucose))}
                              {fl.glu === 'high' ? ' ▲' : fl.glu === 'low' ? ' ▼' : ''}
                            </td>
                            {customFields.map((cf) => (
                              <td key={cf.id} className="r">
                                {r.extra[cf.id] !== undefined ? f.n(fmtValue(cf, r.extra[cf.id])) : '—'}
                              </td>
                            ))}
                            <td>
                              <Badge tone={r.method === 'manual' ? 'info' : r.method === 'ocrEdited' ? 'warn' : 'gray'} icon={null}>
                                {r.method === 'manual' ? t.manual : r.method === 'ocrEdited' ? t.ocrEdited : 'OCR'}
                              </Badge>{' '}
                              <span className="cap">{by}</span>
                            </td>
                            <td className="cap">{r.note ? r.note[lang] : '—'}</td>
                            <td className="no-print">
                              {r.photo ? (
                                <button type="button" className="btn btn-gray btn-sm" onClick={() => setPhotoIdx(Math.max(0, photos.findIndex((x) => x.id === r.id)))}>
                                  <Icon name="camera" />
                                  {t.viewPhoto}
                                </button>
                              ) : (
                                <span className="cap">—</span>
                              )}
                            </td>
                          </tr>
                        );
                      })}
                    </tbody>
                  </table>
                </div>
                <div className="panel-foot no-print" style={{ justifyContent: 'flex-end' }}>
                  <Pager page={lp} pages={logPages} onPage={setLogPage} />
                </div>
              </Panel>
            </>
          )}
        </div>

        <aside className="split-side">
          <Panel title={t.patientInfo}>
            <div style={{ display: 'flex', flexDirection: 'column', gap: 10 }}>
              <div className="row" style={{ gap: 12, flexWrap: 'nowrap' }}>
                <span style={{ display: 'flex', width: 48, height: 48, flex: 'none', alignItems: 'center', justifyContent: 'center', border: '1px solid var(--border)', borderRadius: 4, background: 'var(--panel-h)', color: 'var(--navy)' }}>
                  <Icon name="user" size={26} />
                </span>
                <div>
                  <b style={{ fontSize: 16 }}>{name}</b>
                  <div className="cap">
                    {patient.sex === 'f' ? t.sexF : t.sexM} · {t.ageN(f.n(patient.age))}
                  </div>
                </div>
              </div>
              <dl className="num" style={{ margin: 0, display: 'grid', gridTemplateColumns: 'auto 1fr', gap: '4px 12px', fontSize: 13 }}>
                <dt className="cap">{t.phone}</dt>
                <dd style={{ margin: 0 }}>{f.n(patient.phone)}</dd>
                <dt className="cap">{t.linkedSince}</dt>
                <dd style={{ margin: 0 }}>{f.dayY(patient.linkedSince)}</dd>
                {patient.caretaker && (
                  <>
                    <dt className="cap">{t.caretaker}</dt>
                    <dd style={{ margin: 0 }}>
                      {patient.caretaker.name[lang]} · {f.n(patient.caretaker.phone)}
                    </dd>
                  </>
                )}
                {patient.family && (
                  <>
                    <dt className="cap">{t.family}</dt>
                    <dd style={{ margin: 0 }}>{patient.family.name[lang]}</dd>
                  </>
                )}
                <dt className="cap">{t.devices}</dt>
                <dd style={{ margin: 0 }}>{patient.devices[lang]}</dd>
              </dl>
              <button type="button" className="btn btn-gray btn-block no-print" onClick={() => window.print()} disabled={rs.length === 0}>
                <Icon name="download" />
                {t.downloadPdf}
              </button>
              <p className="cap no-print">{t.pdfHint}</p>
            </div>
          </Panel>

          <Panel className="memo" icon="note" title={t.notesTitle} bodyClass="">
            {data.notes.filter((n) => n.patientId === patient.id).length === 0 && <p className="cap" style={{ padding: '10px 14px' }}>{t.noNotes}</p>}
            {data.notes
              .filter((n) => n.patientId === patient.id)
              .sort((a, b) => b.time.getTime() - a.time.getTime())
              .map((n) => (
                <article key={n.id} style={{ padding: '10px 14px', borderBottom: '1px solid #E8DFA8' }}>
                  <div className="cap num" style={{ fontWeight: 600 }}>
                    {f.dayY(n.time)} · {f.time(n.time)} · {n.author[lang]}
                  </div>
                  <p>{n.text[lang]}</p>
                </article>
              ))}
            <form
              className="no-print"
              style={{ padding: '12px 14px', display: 'flex', flexDirection: 'column', gap: 8 }}
              onSubmit={(e) => {
                e.preventDefault();
                if (!note.trim() || offline) return;
                addNote(patient.id, note.trim());
                setNote('');
                setPosted(true);
              }}
            >
              {posted && <Alert sev="ok">{t.notePosted}</Alert>}
              {offline && (
                <Alert sev="warn" icon="wifiOff">
                  {t.offlineAction}
                </Alert>
              )}
              <label htmlFor="note" style={{ fontWeight: 600 }}>
                {t.newNote}
              </label>
              <textarea
                id="note"
                className="input"
                rows={4}
                maxLength={500}
                placeholder={t.notePlaceholder}
                value={note}
                onChange={(e) => {
                  setNote(e.target.value);
                  setPosted(false);
                }}
              />
              <p className="cap">{t.noteHint}</p>
              <button type="submit" className="btn btn-navy btn-block" disabled={!note.trim() || offline}>
                <Icon name="send" />
                {t.postNote}
              </button>
            </form>
          </Panel>

          <p className="cap">{f.n(t.normalNote)}</p>
        </aside>
      </div>
    );
  }

  return (
    <>
      <Header active="reports" reportHref={`#/doctor/patient/${patient.id}`} />
      <Crumbs
        items={[
          { label: t.home, href: '#/doctor' },
          { label: t.tabDashboard, href: '#/doctor' },
          { label: t.patientLabel(name), href: `#/doctor/patient/${patient.id}` },
          { label: t.reportOf(periodLabel) },
        ]}
      />
      <main className="wrap page">
        <div className="row between">
          <div className="row" style={{ gap: 10 }}>
            <h1 className="page-title">{simulate === 'revoked' ? '—' : name}</h1>
            {simulate !== 'revoked' && latestFlags?.bp === 'high' && <Badge tone="crit">{t.bpHigh}</Badge>}
            {simulate !== 'revoked' && latestFlags?.glu === 'high' && <Badge tone="crit">{t.gluHigh}</Badge>}
          </div>
          <a className="btn btn-gray no-print" href="#/doctor">
            <Icon name="chevLeft" />
            {t.backToDash}
          </a>
        </div>
        <p className="print-only cap">
          {name} · {f.n(patient.phone)} · {f.dayY(start)} – {f.dayY(end)} · {t.disclaimer}
        </p>
        {offline && simulate === 'offline' && (
          <Alert sev="warn" icon="wifiOff">
            {t.offlineAction}
          </Alert>
        )}
        {main}
      </main>
      {photoIdx !== null && simulate !== 'revoked' && <PhotoModal patient={patient} photos={photos} index={photoIdx} onIndex={setPhotoIdx} onClose={() => setPhotoIdx(null)} />}
    </>
  );
}
