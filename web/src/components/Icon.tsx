// Inline stroke icons (no icon package). Decorative by default.

const PATHS: Record<string, string> = {
  alert: 'M12 2a10 10 0 1 0 0 20a10 10 0 1 0 0-20M12 8v4M12 16h.01',
  clock: 'M12 2a10 10 0 1 0 0 20a10 10 0 1 0 0-20M12 6v6l4 2',
  check: 'M20 6L9 17l-5-5',
  checkCircle: 'M22 11.08V12a10 10 0 1 1-5.93-9.14M22 4L12 14.01l-3-3',
  x: 'M18 6L6 18M6 6l12 12',
  xCircle: 'M12 2a10 10 0 1 0 0 20a10 10 0 1 0 0-20M15 9l-6 6M9 9l6 6',
  info: 'M12 2a10 10 0 1 0 0 20a10 10 0 1 0 0-20M12 16v-4M12 8h.01',
  search: 'M11 3a8 8 0 1 0 0 16a8 8 0 1 0 0-16M21 21l-4.35-4.35',
  chevLeft: 'M15 18l-6-6 6-6',
  chevRight: 'M9 18l6-6-6-6',
  chevDown: 'M6 9l6 6 6-6',
  camera: 'M23 19a2 2 0 0 1-2 2H3a2 2 0 0 1-2-2V8a2 2 0 0 1 2-2h4l2-3h6l2 3h4a2 2 0 0 1 2 2zM12 9a4 4 0 1 0 0 8a4 4 0 1 0 0-8',
  download: 'M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4M7 10l5 5 5-5M12 15V3',
  send: 'M22 2L11 13M22 2l-7 20-4-9-9-4z',
  note: 'M14 2H6a2 2 0 0 0-2 2v16a2 2 0 0 0 2 2h12a2 2 0 0 0 2-2V8zM14 2v6h6M16 13H8M16 17H8',
  user: 'M20 21v-2a4 4 0 0 0-4-4H8a4 4 0 0 0-4 4v2M12 3a4 4 0 1 0 0 8a4 4 0 1 0 0-8',
  users: 'M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2M9 3a4 4 0 1 0 0 8a4 4 0 1 0 0-8M23 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75',
  logout: 'M9 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h4M16 17l5-5-5-5M21 12H9',
  login: 'M15 3h4a2 2 0 0 1 2 2v14a2 2 0 0 1-2 2h-4M10 17l5-5-5-5M15 12H3',
  eye: 'M1 12s4-8 11-8 11 8 11 8-4 8-11 8-11-8-11-8zM12 9a3 3 0 1 0 0 6a3 3 0 1 0 0-6',
  refresh: 'M23 4v6h-6M20.49 15a9 9 0 1 1-2.12-9.36L23 10',
  reset: 'M1 4v6h6M3.51 15a9 9 0 1 0 2.13-9.36L1 10',
  wifiOff: 'M1 1l22 22M16.72 11.06A10.94 10.94 0 0 1 19 12.55M5 12.55a10.94 10.94 0 0 1 5.17-2.39M10.71 5.05A16 16 0 0 1 22.58 9M1.42 9a15.91 15.91 0 0 1 4.7-2.88M8.53 16.11a6 6 0 0 1 6.95 0M12 20h.01',
  lock: 'M5 11h14v11H5zM7 11V7a5 5 0 0 1 10 0v4',
  plus: 'M12 5v14M5 12h14',
  pulse: 'M22 12h-4l-3 9L9 3l-3 9H2',
  sliders: 'M4 21v-7M4 10V3M12 21v-9M12 8V3M20 21v-5M20 12V3M1 14h6M9 8h6M17 16h6',
};

export function Icon({ name, size = 16, label, strokeWidth = 2, className }: { name: keyof typeof PATHS | string; size?: number; label?: string; strokeWidth?: number; className?: string }) {
  const d = PATHS[name] ?? PATHS.info;
  return (
    <svg
      viewBox="0 0 24 24"
      width={size}
      height={size}
      className={className ? `ico ${className}` : 'ico'}
      fill="none"
      stroke="currentColor"
      strokeWidth={strokeWidth}
      strokeLinecap="round"
      strokeLinejoin="round"
      role={label ? 'img' : undefined}
      aria-label={label}
      aria-hidden={label ? undefined : true}
    >
      <path d={d} />
    </svg>
  );
}

export function Emblem() {
  return (
    <span className="emblem" aria-hidden="true">
      <svg viewBox="0 0 24 24" width="18" height="18" fill="none" stroke="#C62828" strokeWidth="3.5" strokeLinecap="square">
        <path d="M12 4v16M4 12h16" />
      </svg>
    </span>
  );
}
