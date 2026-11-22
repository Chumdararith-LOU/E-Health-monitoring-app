// Doctor triage dashboard (FR-12, US-12): one row per linked patient,
// flagged first (red), then missed days (amber), then normal (zebra).
// Phayuk owns this screen; data comes from Rith's summary later.

import { useMemo, useState } from 'react';
import { useApp } from '../state/AppState';
import { Crumbs, Header } from '../components/Header';
import { Icon } from '../components/Icon';
import { Alert, Badge, Empty, ErrorState, Loading, Pager } from '../components/ui';
import { PhotoModal } from '../components/PhotoModal';
import { readingsOf, triage, type TriageRow } from '../lib/stats';
import { navigate } from '../lib/router';
import type { Patient } from '../data/types';

const PAGE = 10;
type Sort = 'priority' | 'name' | 'latest';

export function DoctorDashboard() {
  const { t, f, lang, data, fields, simulate, setSimulate } = useApp();
  const [q, setQ] = useState('');
  const [flaggedOnly, setFlaggedOnly] = useState(false);
  const [missedOnly, setMissedOnly] = useState(false);
  const [sort, setSort] = useState<Sort>('priority');
  const [page, setPage] = useState(0);
  const [photo, setPhoto] = useState<{ patient: Patient; index: number } | null>(null);

  const now = new Date();
  const all = useMemo(() => triage(data.patients, data.readings, fields), [data.patients, data.readings, fields]);

  const rows = useMemo(() => {
    const needle = q.trim().toLowerCase().replace(/\s+/g, '');
    let list = all.filter((r) => {
      if (needle) {
        const hay = `${r.patient.name.km}${r.patient.name.en}${r.patient.phone}`.toLowerCase().replace(/\s+/g, '');
        if (!hay.includes(needle)) return false;
      }
      if (flaggedOnly && !r.flagged) return false;
      if (missedOnly && r.missed === 0) return false;
      return true;
    });
    list = [...list].sort((a, b) => {
      if (sort === 'name') return a.patient.name[lang].localeCompare(b.patient.name[lang], lang);
      if (sort === 'latest') return (b.latest?.time.getTime() ?? 0) - (a.latest?.time.getTime() ?? 0);
      return a.priority - b.priority || b.missed - a.missed || a.patient.name.en.localeCompare(b.patient.name.en);
    });
    return list;
  }, [all, q, flaggedOnly, missedOnly, sort, lang]);

  const pages = Math.max(1, Math.ceil(rows.length / PAGE));
  const cur = Math.min(page, pages - 1);
  const shown = rows.slice(cur * PAGE, cur * PAGE + PAGE);
  const flaggedN = all.filter((r) => r.flagged).length;
  const missedN = all.filter((r) => r.missed > 0).length;

  const when = (d: Date) => {
    const diff = Math.round((new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime() - new Date(d.getFullYear(), d.getMonth(), d.getDate()).getTime()) / 86400000);
    if (diff === 0) return `${t.today} ${f.time(d)}`;
    if (diff === 1) return `${t.yesterday} ${f.time(d)}`;
    return f.dayTime(d);
  };

  function resetFilters() {
    setQ('');
    setFlaggedOnly(false);
    setMissedOnly(false);
    setSort('priority');
    setPage(0);
  }

  function statusBadges(r: TriageRow) {
    const out = [];
    if (r.bp === 'high') out.push(<Badge key="bp" tone="crit">{t.bpHigh}</Badge>);
    if (r.bp === 'low') out.push(<Badge key="bpl" tone="crit">{t.bpLow}</Badge>);
    if (r.glu === 'high') out.push(<Badge key="glu" tone="crit">{t.gluHigh}</Badge>);
    if (r.glu === 'low') out.push(<Badge key="glul" tone="crit">{t.gluLow}</Badge>);
    if (r.missed === 1) out.push(<Badge key="m" tone="warn">{t.missedTodayBadge}</Badge>);
    if (r.missed > 1) out.push(<Badge key="m" tone="warn">{t.missedDays(f.n(r.missed))}</Badge>);
    if (!out.length) out.push(<Badge key="ok" tone="ok">{t.normal}</Badge>);
    return out;
  }

  let body;
  if (simulate === 'loading') body = <Loading />;
  else if (simulate === 'error') body = <ErrorState onRetry={() => setSimulate('none')} />;
  else if (simulate === 'empty') body = <Empty title={t.noPatients} hint={t.noPatientsHint} />;
  else if (rows.length === 0)
    body = (
      <Empty
        icon="search"
        title={t.noMatch}
        action={
          <button type="button" className="btn btn-gray" onClick={resetFilters}>
            <Icon name="reset" />
            {t.resetFilters}
          </button>
        }
      />
    );
  else
    body = (
      <section className="panel">
        <div className="tbl-scroll">
          <table className="dt num" style={{ minWidth: 900 }}>
            <caption className="sr-only">{t.dashTitle}</caption>
            <thead>
              <tr>
                <th style={{ width: 180 }}>{t.colStatus}</th>
                <th>{t.colPatient}</th>
                <th>{t.colLatest}</th>
                <th>{t.colAvg7}</th>
                <th style={{ width: 150 }}>{t.colAction}</th>
              </tr>
            </thead>
            <tbody>
              {shown.map((r) => {
                const l = r.latest;
                const cls = r.flagged ? 'r-crit' : r.missed > 0 ? 'r-warn' : '';
                const by = r.patient.caretaker ? t.caretakerIs(r.patient.caretaker.name[lang]) : t.selfRecorded;
                return (
                  <tr key={r.patient.id} className={cls}>
                    <td className="top">
                      <div className="stack">{statusBadges(r)}</div>
                    </td>
                    <td className="top">
                      <div style={{ fontWeight: 700, fontSize: 15 }}>{r.patient.name[lang]}</div>
                      <div className="cap">{f.n(r.patient.phone)}</div>
                      <div className="cap">{by}</div>
                    </td>
                    <td className="top">
                      {l ? (
                        <>
                          <div>
                            <b className={r.bp !== 'normal' ? 'hi' : undefined}>{f.n(`${l.systolic}/${l.diastolic}`)}</b> mmHg {r.bp === 'high' ? '▲' : r.bp === 'low' ? '▼' : ''}
                          </div>
                          <div>
                            <b className={r.glu !== 'normal' ? 'hi' : undefined}>{f.n(Math.round(l.glucose))}</b> mg/dL {r.glu === 'high' ? '▲' : r.glu === 'low' ? '▼' : ''} · {f.n(l.pulse)} bpm
                          </div>
                          <div className="cap row" style={{ gap: 6 }}>
                            {when(l.time)}
                            {l.photo && (
                              <button
                                type="button"
                                className="btn btn-gray btn-sm"
                                style={{ minHeight: 28, padding: '0 8px' }}
                                onClick={() => {
                                  const photos = readingsOf(data.readings, r.patient.id).filter((x) => x.photo);
                                  setPhoto({ patient: r.patient, index: Math.max(0, photos.findIndex((x) => x.id === l.id)) });
                                }}
                              >
                                <Icon name="camera" />
                                {t.viewPhoto}
                              </button>
                            )}
                          </div>
                        </>
                      ) : (
                        '—'
                      )}
                    </td>
                    <td className="top">
                      {r.avgSys !== undefined ? (
                        <>
                          <div>{f.n(`${Math.round(r.avgSys)}/${Math.round(r.avgDia!)}`)} mmHg</div>
                          <div>{f.n(Math.round(r.avgGlu!))} mg/dL</div>
                        </>
                      ) : (
                        '—'
                      )}
                    </td>
                    <td className="top">
                      <a className="btn btn-navy btn-sm" href={`#/doctor/patient/${r.patient.id}`}>
                        {t.openReport}
                      </a>
                    </td>
                  </tr>
                );
              })}
            </tbody>
          </table>
        </div>
        <div className="panel-foot">
          <span className="cap">{t.showingPatients(f.n(cur * PAGE + 1), f.n(cur * PAGE + shown.length), f.n(rows.length))}</span>
          <Pager page={cur} pages={pages} onPage={setPage} />
        </div>
      </section>
    );

  const photoList = photo ? readingsOf(data.readings, photo.patient.id).filter((x) => x.photo) : [];

  return (
    <>
      <Header active="dashboard" />
      <Crumbs
        items={[{ label: t.home, href: '#/doctor' }, { label: t.tabDashboard }]}
        right={
          simulate === 'empty' ? undefined : (
            <div className="row" style={{ gap: 6 }}>
              <span className="cap">{t.summary}</span>
              <Badge tone="crit">{t.flaggedN(f.n(flaggedN))}</Badge>
              <Badge tone="warn">{t.missedN(f.n(missedN))}</Badge>
              <Badge tone="gray">{t.allN(f.n(all.length))}</Badge>
            </div>
          )
        }
      />
      <main className="wrap page">
        <div>
          <h1 className="page-title">{t.dashTitle}</h1>
          <p className="cap">{t.dashSub(f.dayTime(now))}</p>
        </div>

        {simulate === 'offline' && (
          <Alert sev="warn" icon="wifiOff">
            {t.offlineAction}
          </Alert>
        )}

        {simulate !== 'empty' && (
          <section className="panel toolbar" aria-label={t.search}>
            <form
              className="row"
              style={{ flex: '1 1 360px', minWidth: 0, flexWrap: 'nowrap' }}
              onSubmit={(e) => {
                e.preventDefault();
                setPage(0);
              }}
            >
              <label className="sr-only" htmlFor="q">
                {t.search}
              </label>
              <input
                id="q"
                className="input"
                style={{ flex: 1 }}
                placeholder={t.searchPatients}
                value={q}
                onChange={(e) => {
                  setQ(e.target.value);
                  setPage(0);
                }}
              />
              <button type="submit" className="btn btn-gray">
                <Icon name="search" />
                {t.search}
              </button>
            </form>
            <label className="chk">
              <input
                type="checkbox"
                checked={flaggedOnly}
                onChange={(e) => {
                  setFlaggedOnly(e.target.checked);
                  setPage(0);
                }}
              />
              {t.flaggedOnly}
            </label>
            <label className="chk">
              <input
                type="checkbox"
                checked={missedOnly}
                onChange={(e) => {
                  setMissedOnly(e.target.checked);
                  setPage(0);
                }}
              />
              {t.missedToday}
            </label>
            <div className="row" style={{ gap: 6 }}>
              <label className="cap" htmlFor="sort" style={{ fontWeight: 600, color: 'var(--text)' }}>
                {t.sortBy}
              </label>
              <select id="sort" className="input" value={sort} onChange={(e) => setSort(e.target.value as Sort)}>
                <option value="priority">{t.sortPriority}</option>
                <option value="name">{t.sortName}</option>
                <option value="latest">{t.sortLatest}</option>
              </select>
            </div>
          </section>
        )}

        {body}

        <p className="cap">
          {f.n(t.normalNote)} {t.disclaimer}
        </p>
      </main>

      {photo && <PhotoModal patient={photo.patient} photos={photoList} index={photo.index} onIndex={(i) => setPhoto({ ...photo, index: i })} onClose={() => setPhoto(null)} />}
    </>
  );
}

export function goToPatient(id: string) {
  navigate(`/doctor/patient/${id}`);
}
