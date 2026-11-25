import type { I18n } from '../i18n';
import { fromKhmerDigits } from '../i18n';
import { levelOf, MEASURES } from './ranges';
import { CustomField, MeasureKey } from './types';

export type Vals = Record<string, string>;

export function parseNum(s: string | undefined): number | undefined | 'nan' {
  if (s == null) return undefined;
  const x = fromKhmerDigits(s).trim().replace(',', '.');
  if (!x) return undefined;
  const n = Number(x);
  return Number.isFinite(n) ? n : 'nan';
}

/**
 * Same rules as the mobile entry form (FR-06): safe limits block, normal ranges only warn.
 * Kept in one place so web and mobile behave the same.
 */
export function validateReading(vals: Vals, fields: CustomField[], i18n: I18n) {
  const { t } = i18n;
  const errors: Record<string, string> = {};
  const warnings: Record<string, string> = {};
  const out: Partial<Record<MeasureKey, number>> = {};
  const extra: Record<string, number> = {};

  (['systolic', 'diastolic', 'pulse', 'glucose'] as MeasureKey[]).forEach((k) => {
    const m = MEASURES[k];
    const n = parseNum(vals[k]);
    if (n == null) return;
    if (n === 'nan' || n < m.safeMin || n > m.safeMax || !Number.isInteger(n)) {
      errors[k] = t('errRange', { min: m.safeMin, max: m.safeMax });
      return;
    }
    out[k] = n;
    const lvl = levelOf(k, n);
    if (lvl && lvl !== 'normal') warnings[k] = t('outsideNormal', { min: m.normalMin, max: m.normalMax });
  });

  fields.forEach((f) => {
    const n = parseNum(vals[f.id]);
    if (n == null) return;
    if (n === 'nan' || n < f.min || n > f.max) errors[f.id] = t('errRange', { min: f.min, max: f.max });
    else extra[f.id] = Math.round(n * 10 ** f.decimals) / 10 ** f.decimals;
  });

  const hasSys = (vals.systolic ?? '').trim() !== '';
  const hasDia = (vals.diastolic ?? '').trim() !== '';
  if (hasSys !== hasDia) errors[hasSys ? 'diastolic' : 'systolic'] = t('errBpPair');
  if (out.systolic != null && out.diastolic != null && out.systolic <= out.diastolic) errors.diastolic = t('errSysDia');

  let form: string | undefined;
  if (!hasSys && !hasDia && (vals.glucose ?? '').trim() === '' && !errors.glucose) form = t('errEmpty');
  return { errors, warnings, out, extra, form, ok: !Object.keys(errors).length && !form };
}
