import { useEffect, useMemo, useRef, useState } from 'react';
import { useApp } from '../store/AppStore';

export interface ChartPoint {
  t: number;
  v: number;
  id: string;
}
export interface ChartSeries {
  key: string;
  label: string;
  color: string;
  points: ChartPoint[]; // ascending time
  band?: { min: number; max: number };
}

function niceTicks(min: number, max: number, count = 4) {
  const span = max - min || 1;
  const step0 = span / count;
  const mag = Math.pow(10, Math.floor(Math.log10(step0)));
  const step = [1, 2, 5, 10].map((m) => m * mag).find((s) => s >= step0) ?? step0;
  const lo = Math.floor(min / step) * step;
  const hi = Math.ceil(max / step) * step;
  const ticks: number[] = [];
  for (let v = lo; v <= hi + step / 2; v += step) ticks.push(Math.round(v * 100) / 100);
  return { lo, hi, ticks };
}

function useWidth<T extends HTMLElement>() {
  const ref = useRef<T>(null);
  const [w, setW] = useState(0);
  useEffect(() => {
    if (!ref.current) return;
    const ro = new ResizeObserver((e) => setW(e[0].contentRect.width));
    ro.observe(ref.current);
    return () => ro.disconnect();
  }, []);
  return [ref, w] as const;
}

/**
 * Line chart: one y-axis, normal-range band, recessive grid, legend for 2+ series.
 * Hover (mouse) or ← → (keyboard, when focused) moves a crosshair; the tooltip names date and values.
 * Click/Enter opens the reading.
 */
export function LineChart({ series, from, to, height = 240, decimals = 0, onOpen, title }: { series: ChartSeries[]; from: number; to: number; height?: number; decimals?: number; onOpen?: (id: string) => void; title: string }) {
  const { i18n } = useApp();
  const [wrapRef, width] = useWidth<HTMLDivElement>();
  const [selIdx, setSelIdx] = useState<number | null>(null);
  const padL = 44, padR = 16, padT = 12, padB = 30;
  const plotW = Math.max(1, width - padL - padR);
  const plotH = height - padT - padB;

  const { lo, hi, ticks } = useMemo(() => {
    const vals: number[] = [];
    series.forEach((s) => {
      s.points.forEach((p) => vals.push(p.v));
      if (s.band) vals.push(s.band.min, s.band.max);
    });
    return vals.length ? niceTicks(Math.min(...vals), Math.max(...vals)) : niceTicks(0, 100);
  }, [series]);

  const times = useMemo(() => Array.from(new Set(series.flatMap((s) => s.points.map((p) => p.t)))).sort((a, b) => a - b), [series]);
  const x = (t: number) => padL + ((t - from) / Math.max(1, to - from)) * plotW;
  const y = (v: number) => padT + (1 - (v - lo) / Math.max(1e-6, hi - lo)) * plotH;

  const nearest = (px: number) => {
    let best = 0, bestD = Infinity;
    times.forEach((t, i) => {
      const d = Math.abs(x(t) - px);
      if (d < bestD) { bestD = d; best = i; }
    });
    return best;
  };

  const sel = selIdx != null ? times[selIdx] : null;
  const selPts = sel == null ? [] : series.map((s) => ({ s, p: s.points.find((p) => p.t === sel) })).filter((v) => v.p);
  const mid = from + (to - from) / 2;
  const tipLeft = sel != null ? Math.min(Math.max(x(sel) + 12, 0), width - 170) : 0;

  const summary = series
    .map((s) => {
      const v = s.points.map((p) => p.v);
      return v.length ? `${s.label}: ${i18n.t('min')} ${i18n.num(Math.min(...v), decimals)}, ${i18n.t('max')} ${i18n.num(Math.max(...v), decimals)}` : `${s.label}: ${i18n.t('noData')}`;
    })
    .join('. ');

  return (
    <div className="stack-sm">
      <div className="legend" aria-hidden>
        {series.length > 1
          ? series.map((s) => (
              <span key={s.key}>
                <i className="swatch" style={{ background: s.color }} />
                {s.label}
              </span>
            ))
          : null}
        {series.some((s) => s.band) ? (
          <span>
            <i className="swatch-band" />
            {i18n.t('normalRange')}
          </span>
        ) : null}
      </div>
      <div
        ref={wrapRef}
        className="chart"
        style={{ height }}
        tabIndex={0}
        role="img"
        aria-label={`${title}. ${summary}. ${i18n.t('chartHint')}`}
        onMouseMove={(e) => {
          const r = e.currentTarget.getBoundingClientRect();
          if (times.length) setSelIdx(nearest(e.clientX - r.left));
        }}
        onMouseLeave={() => setSelIdx(null)}
        onClick={() => {
          if (sel != null && selPts[0]?.p && onOpen) onOpen(selPts[0].p.id);
        }}
        onKeyDown={(e) => {
          if (!times.length) return;
          if (e.key === 'ArrowRight' || e.key === 'ArrowLeft') {
            e.preventDefault();
            const cur = selIdx ?? (e.key === 'ArrowRight' ? -1 : times.length);
            setSelIdx(Math.min(times.length - 1, Math.max(0, cur + (e.key === 'ArrowRight' ? 1 : -1))));
          } else if ((e.key === 'Enter' || e.key === ' ') && selPts[0]?.p && onOpen) {
            e.preventDefault();
            onOpen(selPts[0].p.id);
          } else if (e.key === 'Escape') setSelIdx(null);
        }}
        onBlur={() => setSelIdx(null)}
      >
        {width > 0 ? (
          <svg width={width} height={height} style={{ cursor: onOpen ? 'pointer' : 'default' }}>
            {series.map((s) =>
              s.band ? (
                <g key={`b-${s.key}`} className="band">
                  <rect x={padL} width={plotW} y={y(Math.min(hi, s.band.max))} height={Math.max(0, y(Math.max(lo, s.band.min)) - y(Math.min(hi, s.band.max)))} fill="var(--band)" />
                  <line x1={padL} x2={padL + plotW} y1={y(s.band.max)} y2={y(s.band.max)} stroke="var(--border-strong)" strokeDasharray="4 4" />
                  <line x1={padL} x2={padL + plotW} y1={y(s.band.min)} y2={y(s.band.min)} stroke="var(--border-strong)" strokeDasharray="4 4" />
                </g>
              ) : null,
            )}
            {ticks.map((tv) => (
              <g key={`t-${tv}`}>
                <line x1={padL} x2={padL + plotW} y1={y(tv)} y2={y(tv)} stroke="var(--grid)" />
                <text x={padL - 8} y={y(tv) + 4} fontSize="12" fill="var(--axis)" textAnchor="end">
                  {i18n.num(tv)}
                </text>
              </g>
            ))}
            {[from, mid, to].map((tv, i) => (
              <text key={`x-${i}`} x={x(tv)} y={height - 8} fontSize="12" fill="var(--axis)" textAnchor={i === 0 ? 'start' : i === 2 ? 'end' : 'middle'}>
                {i18n.dateShort(new Date(tv))}
              </text>
            ))}
            {series.map((s) => {
              if (!s.points.length) return null;
              const d = s.points.map((p, i) => `${i ? 'L' : 'M'}${x(p.t).toFixed(1)},${y(p.v).toFixed(1)}`).join(' ');
              return (
                <g key={`l-${s.key}`}>
                  <path d={d} fill="none" stroke={s.color} strokeWidth={2} strokeLinejoin="round" strokeLinecap="round" />
                  {s.points.length <= 45
                    ? s.points.map((p) => <circle key={p.id} cx={x(p.t)} cy={y(p.v)} r={3.5} fill={s.color} stroke="var(--surface)" strokeWidth={1.5} />)
                    : null}
                </g>
              );
            })}
            {sel != null ? (
              <g>
                <line x1={x(sel)} x2={x(sel)} y1={padT} y2={padT + plotH} stroke="var(--text)" />
                {selPts.map(({ s, p }) => (
                  <circle key={`s-${s.key}`} cx={x(p!.t)} cy={y(p!.v)} r={6} fill={s.color} stroke="var(--surface)" strokeWidth={2} />
                ))}
              </g>
            ) : null}
          </svg>
        ) : null}
        {sel != null && selPts.length ? (
          <div className="tooltip" style={{ left: tipLeft, top: 4 }} aria-live="polite">
            <div className="t-date">
              {i18n.date(new Date(sel))} · {i18n.time(new Date(sel))}
            </div>
            {selPts.map(({ s, p }) => (
              <div key={s.key} className="row">
                <i className="swatch" style={{ background: s.color }} />
                <span>{s.label}:</span>
                <strong className="num">{i18n.num(p!.v, decimals)}</strong>
              </div>
            ))}
          </div>
        ) : null}
      </div>
    </div>
  );
}

export function Sparkline({ values, width = 120, height = 32, label }: { values: number[]; width?: number; height?: number; label?: string }) {
  if (values.length < 2) return <span className="muted">–</span>;
  const min = Math.min(...values), max = Math.max(...values), span = max - min || 1;
  const px = (i: number) => 3 + (i / (values.length - 1)) * (width - 6);
  const py = (v: number) => 3 + (1 - (v - min) / span) * (height - 6);
  const d = values.map((v, i) => `${i ? 'L' : 'M'}${px(i).toFixed(1)},${py(v).toFixed(1)}`).join(' ');
  return (
    <svg width={width} height={height} role={label ? 'img' : undefined} aria-label={label} aria-hidden={label ? undefined : true}>
      <path d={d} fill="none" stroke="var(--series-1)" strokeWidth={2} strokeLinecap="round" strokeLinejoin="round" />
      <circle cx={px(values.length - 1)} cy={py(values[values.length - 1])} r={3} fill="var(--series-1)" />
    </svg>
  );
}
