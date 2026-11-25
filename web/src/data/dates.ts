export const DAY_MS = 24 * 60 * 60 * 1000;

export function startOfDay(d: Date) {
  const x = new Date(d);
  x.setHours(0, 0, 0, 0);
  return x;
}

export function addDays(d: Date, n: number) {
  const x = new Date(d);
  x.setDate(x.getDate() + n);
  return x;
}

/** Local calendar key YYYY-MM-DD */
export function dayKey(d: Date | string) {
  const x = typeof d === 'string' ? new Date(d) : d;
  const m = `${x.getMonth() + 1}`.padStart(2, '0');
  const day = `${x.getDate()}`.padStart(2, '0');
  return `${x.getFullYear()}-${m}-${day}`;
}

export function isSameDay(a: Date | string, b: Date | string) {
  return dayKey(a) === dayKey(b);
}

export function daysBetween(a: Date, b: Date) {
  return Math.round((startOfDay(b).getTime() - startOfDay(a).getTime()) / DAY_MS);
}

/** "Morning" for FR-05 duplicate check: before 12:00 local time. */
export function isMorning(d: Date | string) {
  const x = typeof d === 'string' ? new Date(d) : d;
  return x.getHours() < 12;
}
