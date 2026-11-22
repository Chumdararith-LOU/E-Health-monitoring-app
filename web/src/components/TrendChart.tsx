// One metric per chart (BP counts as one), shaded green normal band with
// dashed edges, red diamonds for out-of-range points, hover/tap tooltip.
// Breaks the line on missed days. Pure SVG, no chart package.

import { useMemo, useRef, useState } from 'react';
import { dayStart } from '../data/mock';
import type { Format } from '../i18n/strings';

export interface ChartPoint {
  t: Date;
  v: number;
  flagged: boolean;
  line1: string;
  line2: string;
}

export interface ChartSeries {
  points: ChartPoint[];
  color: string;
  dashed?: boolean;
  marker?: 'circle' | 'square';
  width?: number;
}

interface Props {
  series: ChartSeries[];
  bands: { lo: number; hi: number }[];
  start: Date;
  end: Date;
  f: Format;
  label: string;
  width?: number;
  height?: number;
  yMin?: number;
  yMax?: number;
}

const DAY = 24 * 3600 * 1000;

function niceStep(range: number) {
  const raw = range <= 0 ? 1 : range / 4;
  const mag = Math.pow(10, Math.floor(Math.log10(raw)));
  const n = raw / mag;
  return (n <= 1 ? 1 : n <= 2 ? 2 : n <= 5 ? 5 : 10) * mag;
}

export function TrendChart({ series, bands, start, end, f, label, width = 760, height = 230, yMin, yMax }: Props) {
  const ref = useRef<SVGSVGElement>(null);
  const [sel, setSel] = useState<{ s: number; p: number } | null>(null);

  const L = 46;
  const R = width - 12;
  const T = 14;
  const B = height - 34;
  const s0 = dayStart(start).getTime();
  const total = Math.max(1, Math.round((dayStart(end).getTime() - s0) / DAY));

  const axis = useMemo(() => {
    let lo = Infinity;
    let hi = -Infinity;
    for (const b of bands) {
      lo = Math.min(lo, b.lo);
      hi = Math.max(hi, b.hi);
    }
    for (const s of series) for (const p of s.points) {
      lo = Math.min(lo, p.v);
      hi = Math.max(hi, p.v);
    }
    if (!isFinite(lo)) {
      lo = 0;
      hi = 100;
    }
    const step = niceStep(hi - lo);
    const min = yMin ?? Math.max(0, Math.floor((lo - step * 0.5) / step) * step);
    const max = yMax ?? Math.ceil((hi + step * 0.5) / step) * step;
    const ticks: number[] = [];
    for (let v = min; v <= max + 1e-9; v += step) ticks.push(Math.round(v * 10) / 10);
    return { min, max, ticks, step };
  }, [series, bands, yMin, yMax]);

  const x = (t: Date) => L + ((dayStart(t).getTime() - s0) / DAY / total) * (R - L);
  const y = (v: number) => B - ((Math.min(Math.max(v, axis.min), axis.max) - axis.min) / (axis.max - axis.min)) * (B - T);

  const xLabels = useMemo(() => {
    const idx: number[] = [];
    if (total <= 7) for (let i = 0; i <= total; i++) idx.push(i);
    else for (let i = 0; i < 5; i++) idx.push(Math.round((i * total) / 4));
    let lastMonth = -1;
    return idx.map((i) => {
      const d = new Date(s0 + i * DAY + 12 * 3600 * 1000);
      const showMonth = total > 7 && d.getMonth() !== lastMonth;
      lastMonth = d.getMonth();
      return { d, text: showMonth ? f.day(d) : f.n(d.getDate()) };
    });
  }, [s0, total, f]);

  const paths = series.map((s) => {
    let d = '';
    let prev: Date | null = null;
    for (const p of s.points) {
      const gap = prev ? (dayStart(p.t).getTime() - dayStart(prev).getTime()) / DAY : 99;
      d += `${prev && gap <= 1.5 ? 'L' : 'M'}${x(p.t).toFixed(1)} ${y(p.v).toFixed(1)} `;
      prev = p.t;
    }
    return d;
  });

  const dense = (series[0]?.points.length ?? 0) > 40;
  const r = dense ? 2.4 : 3.4;

  function pick(clientX: number, clientY: number) {
    const el = ref.current;
    if (!el) return;
    const box = el.getBoundingClientRect();
    const vx = ((clientX - box.left) / box.width) * width;
    const vy = ((clientY - box.top) / box.height) * height;
    let best = Infinity;
    let hit: { s: number; p: number } | null = null;
    series.forEach((s, si) =>
      s.points.forEach((p, pi) => {
        const dx = x(p.t) - vx;
        const dy = y(p.v) - vy;
        const dist = dx * dx + dy * dy * 0.25;
        if (Math.abs(dx) < 24 && dist < best) {
          best = dist;
          hit = { s: si, p: pi };
        }
      }),
    );
    setSel(hit);
  }

  const selPt = sel ? series[sel.s]?.points[sel.p] : undefined;
  const tipW = selPt ? Math.max(selPt.line1.length * 6.6, selPt.line2.length * 8) + 20 : 0;
  const tipX = selPt ? (x(selPt.t) > (L + R) / 2 ? x(selPt.t) - tipW - 10 : x(selPt.t) + 10) : 0;
  const tipY = selPt ? Math.max(T, Math.min(y(selPt.v) - 50, B - 46)) : 0;

  return (
    <div className="chart">
      <svg
        ref={ref}
        viewBox={`0 0 ${width} ${height}`}
        role="img"
        aria-label={label}
        onMouseMove={(e) => pick(e.clientX, e.clientY)}
        onMouseLeave={() => setSel(null)}
        onClick={(e) => pick(e.clientX, e.clientY)}
        style={{ fontFamily: 'var(--font)', cursor: 'crosshair' }}
      >
        {bands.map((b, i) => (
          <g key={i}>
            <rect x={L} y={y(b.hi)} width={R - L} height={Math.max(0, y(b.lo) - y(b.hi))} fill="#E8F5E9" />
            <line x1={L} x2={R} y1={y(b.hi)} y2={y(b.hi)} stroke="#2E7D32" strokeDasharray="4 3" />
            <line x1={L} x2={R} y1={y(b.lo)} y2={y(b.lo)} stroke="#2E7D32" strokeDasharray="4 3" />
          </g>
        ))}
        {axis.ticks.map((tk) => (
          <g key={tk}>
            <line x1={L} x2={R} y1={y(tk)} y2={y(tk)} stroke="#D5DCE3" />
            <text x={L - 6} y={y(tk) + 4} fontSize="12" textAnchor="end" fill="#4A5568">
              {f.n(axis.step < 1 ? tk.toFixed(1) : Math.round(tk))}
            </text>
          </g>
        ))}
        {xLabels.map((xl, i) => (
          <text key={i} x={x(xl.d)} y={height - 12} fontSize="12" fill="#4A5568" textAnchor={i === 0 ? 'start' : i === xLabels.length - 1 ? 'end' : 'middle'}>
            {xl.text}
          </text>
        ))}
        {series.map((s, si) => (
          <path key={si} d={paths[si]} fill="none" stroke={s.color} strokeWidth={s.width ?? 2} strokeDasharray={s.dashed ? '5 3' : undefined} strokeLinejoin="round" />
        ))}
        {series.map((s, si) =>
          s.points.map((p, pi) => {
            const cx = x(p.t);
            const cy = y(p.v);
            if (p.flagged) {
              const d = dense ? 4 : 5.5;
              return <path key={`${si}-${pi}`} d={`M${cx} ${cy - d}L${cx + d} ${cy}L${cx} ${cy + d}L${cx - d} ${cy}Z`} fill="#C62828" stroke="#fff" strokeWidth="1" />;
            }
            if (s.marker === 'square') return <rect key={`${si}-${pi}`} x={cx - r} y={cy - r} width={r * 2} height={r * 2} fill="#fff" stroke={s.color} strokeWidth="1.6" />;
            return <circle key={`${si}-${pi}`} cx={cx} cy={cy} r={r} fill={s.color} />;
          }),
        )}
        {selPt && (
          <g pointerEvents="none">
            <line x1={x(selPt.t)} x2={x(selPt.t)} y1={T} y2={B} stroke="#4A5568" strokeDasharray="3 3" />
            <circle cx={x(selPt.t)} cy={y(selPt.v)} r="7" fill="none" stroke="#1A202C" strokeWidth="2" />
            <rect x={tipX} y={tipY} width={tipW} height={44} rx="3" fill="#fff" stroke="#4A5568" />
            <text x={tipX + 10} y={tipY + 17} fontSize="11.5" fill="#4A5568">
              {selPt.line1}
            </text>
            <text x={tipX + 10} y={tipY + 35} fontSize="13" fontWeight="700" fill="#1A202C">
              {selPt.line2}
            </text>
          </g>
        )}
      </svg>
    </div>
  );
}

export function LegendLine({ color, dashed, square, children }: { color: string; dashed?: boolean; square?: boolean; children: string }) {
  return (
    <span>
      <svg width="22" height="10" aria-hidden="true">
        <line x1="0" y1="5" x2="22" y2="5" stroke={color} strokeWidth="2" strokeDasharray={dashed ? '5 3' : undefined} />
        {square ? <rect x="8" y="2" width="6" height="6" fill="#fff" stroke={color} strokeWidth="1.5" /> : <circle cx="11" cy="5" r="3" fill={color} />}
      </svg>
      {children}
    </span>
  );
}

export function LegendDiamond({ children }: { children: string }) {
  return (
    <span>
      <svg width="12" height="12" aria-hidden="true">
        <path d="M6 0.5L11.5 6L6 11.5L0.5 6Z" fill="#C62828" />
      </svg>
      {children}
    </span>
  );
}

export function LegendBand({ children }: { children: string }) {
  return (
    <span>
      <span style={{ display: 'inline-block', width: 18, height: 10, background: '#E8F5E9', border: '1px dashed #2E7D32' }} />
      {children}
    </span>
  );
}
