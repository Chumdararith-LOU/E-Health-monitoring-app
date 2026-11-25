import { useMemo, useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { isSameDay } from '../data/dates';
import { inRange, lastNDays, summarize } from '../data/stats';
import { fromKhmerDigits } from '../i18n';
import { useApp } from '../store/AppStore';
import { Sparkline } from '../ui/Charts';
import { Icon } from '../ui/Icon';
import { Badge, Banner, Card, Chip, Empty, PageHeader, StatusBadge, Value } from '../ui/Kit';

type Filter = 'all' | 'attention' | 'notToday';
type SortKey = 'attention' | 'name' | 'latest';

/** FR-12 / US-12: linked patients with latest reading, 7-day average and flags; patients who need attention first. */
export function DashboardPage() {
  const { i18n, patients, readingsOf } = useApp();
  const { t } = i18n;
  const nav = useNavigate();
  const [q, setQ] = useState('');
  const [filter, setFilter] = useState<Filter>('all');
  const [sort, setSort] = useState<{ key: SortKey; dir: 1 | -1 }>({ key: 'attention', dir: -1 });

  const rows = useMemo(
    () =>
      patients.map((p) => {
        const rs = readingsOf(p.id);
        const s = summarize(rs);
        const two = inRange(rs, lastNDays(14)).slice().reverse();
        return { p, s, today: rs.find((r) => isSameDay(r.takenAt, new Date())), trend: two.map((r) => r.systolic).filter((v): v is number => v != null) };
      }),
    [patients, readingsOf],
  );

  const counts = {
    all: rows.length,
    attention: rows.filter((r) => r.s.attentionScore > 0).length,
    notToday: rows.filter((r) => !r.today).length,
  };
  const out7 = rows.reduce((a, r) => a + r.s.outOfRange7, 0);
  const missed7 = rows.reduce((a, r) => a + r.s.missed7, 0);

  const query = fromKhmerDigits(q).trim().toLowerCase();
  const visible = rows
    .filter((r) => (filter === 'attention' ? r.s.attentionScore > 0 : filter === 'notToday' ? !r.today : true))
    .filter((r) => !query || [r.p.nameEn, r.p.nameKm, r.p.phone.replace(/\s/g, '')].some((s) => s.toLowerCase().includes(query.replace(/\s/g, '')) || s.toLowerCase().includes(query)))
    .sort((a, b) => {
      const d = sort.dir;
      if (sort.key === 'name') return d * i18n.name(a.p).localeCompare(i18n.name(b.p));
      if (sort.key === 'latest') return d * (a.s.latest?.takenAt ?? '').localeCompare(b.s.latest?.takenAt ?? '');
      return d * (a.s.attentionScore - b.s.attentionScore) || i18n.name(a.p).localeCompare(i18n.name(b.p));
    });

  const sortHeader = (key: SortKey, label: string) => {
    const active = sort.key === key;
    return (
      <th scope="col" aria-sort={active ? (sort.dir === 1 ? 'ascending' : 'descending') : 'none'}>
        <button type="button" className="sort-btn" onClick={() => setSort({ key, dir: active ? ((-sort.dir) as 1 | -1) : key === 'name' ? 1 : -1 })} title={t('sortBy', { col: label })}>
          {label}
          <Icon name={active ? (sort.dir === 1 ? 'sortUp' : 'sortDown') : 'sort'} size={16} />
        </button>
      </th>
    );
  };

  return (
    <>
      <PageHeader title={t('dashTitle')} subtitle={t('dashSubtitle', { date: i18n.date(new Date()) })} />

      <div className="kpis" role="list">
        <div className={`kpi${counts.attention ? ' alert' : ''}`} role="listitem">
          <span className="kpi-label">
            <Icon name="alert" size={18} />
            {t('kpiAttention')}
          </span>
          <span className="kpi-value">{i18n.num(counts.attention)}</span>
        </div>
        <div className="kpi" role="listitem">
          <span className="kpi-label">
            <Icon name="checkCircle" size={18} />
            {t('kpiRecordedToday')}
          </span>
          <span className="kpi-value">{t('kpiOf', { n: rows.length - counts.notToday, total: rows.length })}</span>
        </div>
        <div className="kpi" role="listitem">
          <span className="kpi-label">
            <Icon name="highCircle" size={18} />
            {t('kpiOutOfRange7')}
          </span>
          <span className="kpi-value">{i18n.num(out7)}</span>
        </div>
        <div className="kpi" role="listitem">
          <span className="kpi-label">
            <Icon name="missed" size={18} />
            {t('kpiMissed7')}
          </span>
          <span className="kpi-value">{i18n.num(missed7)}</span>
        </div>
      </div>

      <Card className="card-tight">
        <div className="toolbar" style={{ padding: 'var(--s4)' }}>
          <div className="search">
            <Icon name="search" />
            <input className="input" type="search" placeholder={t('searchPatients')} aria-label={t('searchPatients')} value={q} onChange={(e) => setQ(e.target.value)} />
          </div>
          <div className="row-wrap" role="group" aria-label={t('colFlags')}>
            <Chip pressed={filter === 'all'} onClick={() => setFilter('all')} count={i18n.num(counts.all)}>
              {t('all')}
            </Chip>
            <Chip pressed={filter === 'attention'} onClick={() => setFilter('attention')} count={i18n.num(counts.attention)} icon="alert">
              {t('filterAttention')}
            </Chip>
            <Chip pressed={filter === 'notToday'} onClick={() => setFilter('notToday')} count={i18n.num(counts.notToday)} icon="clockAlert">
              {t('filterNotToday')}
            </Chip>
          </div>
        </div>
        {!rows.length ? (
          <Empty icon="patients" title={t('noPatients')} />
        ) : !visible.length ? (
          <Empty icon="search" title={t('noMatch')}>
            <button
              type="button"
              className="btn btn-secondary btn-sm"
              onClick={() => {
                setQ('');
                setFilter('all');
              }}
            >
              {t('clearFilters')}
            </button>
          </Empty>
        ) : (
          <div className="table-wrap">
            <table className="table responsive">
              <caption className="sr-only">{t('dashTitle')}</caption>
              <thead>
                <tr>
                  {sortHeader('name', t('colPatient'))}
                  <th scope="col">{t('colToday')}</th>
                  {sortHeader('latest', t('colLatest'))}
                  <th scope="col">{t('colAvg7')}</th>
                  <th scope="col">{t('colTrend')}</th>
                  {sortHeader('attention', t('colFlags'))}
                  <th scope="col">
                    <span className="sr-only">{t('actions')}</span>
                  </th>
                </tr>
              </thead>
              <tbody>
                {visible.map(({ p, s, today, trend }) => (
                  <tr key={p.id} className="clickable" onClick={() => nav(`/patients/${p.id}`)}>
                    <td data-label={t('colPatient')}>
                      <Link className="row-link" to={`/patients/${p.id}`} onClick={(e) => e.stopPropagation()}>
                        {i18n.name(p)}
                      </Link>
                      <div className="cell-sub">
                        {t('years', { n: p.age ?? 0 })} · {i18n.lang === 'km' ? p.conditionsKm : p.conditionsEn}
                      </div>
                    </td>
                    <td data-label={t('colToday')}>
                      {today ? (
                        <Badge kind="normal" icon="check">
                          {i18n.time(today.takenAt)}
                        </Badge>
                      ) : (
                        <Badge kind="low" icon="clockAlert">
                          {t('notYet')}
                        </Badge>
                      )}
                    </td>
                    <td data-label={t('colLatest')}>
                      {s.latest ? (
                        <>
                          <div className="num">
                            <Value k="systolic" v={s.latest.systolic} />/<Value k="diastolic" v={s.latest.diastolic} /> <span className="cell-sub">mmHg</span>
                          </div>
                          <div className="num">
                            <Value k="glucose" v={s.latest.glucose} /> <span className="cell-sub">mg/dL</span>
                          </div>
                          <div className="cell-sub">
                            {i18n.dateRelative(s.latest.takenAt)} · {i18n.time(s.latest.takenAt)}
                          </div>
                        </>
                      ) : (
                        <span className="muted">{t('noData')}</span>
                      )}
                    </td>
                    <td data-label={t('colAvg7')} className="num">
                      {s.avg7.systolic != null ? (
                        <>
                          {i18n.num(s.avg7.systolic)}/{i18n.num(s.avg7.diastolic)} · {i18n.num(s.avg7.glucose)}
                        </>
                      ) : (
                        '–'
                      )}
                    </td>
                    <td data-label={t('colTrend')} className="hide-sm">
                      <Sparkline values={trend} label={`${t('colTrend')}: ${trend.map((v) => i18n.num(v)).join(', ')}`} />
                    </td>
                    <td data-label={t('colFlags')}>
                      <div className="row-wrap" style={{ gap: 4 }}>
                        {s.latestLevel && s.latestLevel !== 'normal' ? <StatusBadge level={s.latestLevel} /> : null}
                        {s.outOfRange7 > 0 ? (
                          <Badge kind="high" icon="alert">
                            {t('outOfRangeN', { n: s.outOfRange7 })}
                          </Badge>
                        ) : null}
                        {s.missed7 > 0 ? (
                          <Badge kind="neutral" icon="missed">
                            {t('missedDays', { n: s.missed7 })}
                          </Badge>
                        ) : null}
                        {s.attentionScore === 0 && !s.outOfRange7 && !s.missed7 ? <StatusBadge level="normal" /> : null}
                      </div>
                    </td>
                    <td className="hide-sm" style={{ width: 40 }}>
                      <Icon name="chevronRight" />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </Card>
      <Banner icon="info">{t('attentionHint')}</Banner>
    </>
  );
}
