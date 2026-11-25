import { describe, expect, it } from 'vitest';
import { en } from './en';
import { API_ERRORS, fromKhmerDigits, makeI18n, toKhmerDigits } from './index';
import { km } from './km';
import { accountsEn, accountsKm } from './modules/accounts';
import { ocrEn, ocrKm } from './modules/ocr';
import { readingsEn, readingsKm } from './modules/readings';
import { reportsEn, reportsKm } from './modules/reports';
import { sharedEn, sharedKm } from './modules/shared';

const MODULES = [
  { name: 'shared', km: sharedKm, en: sharedEn },
  { name: 'accounts', km: accountsKm, en: accountsEn },
  { name: 'readings', km: readingsKm, en: readingsEn },
  { name: 'ocr', km: ocrKm, en: ocrEn },
  { name: 'reports', km: reportsKm, en: reportsEn },
] as const;

describe('web i18n', () => {
  it('has identical Khmer and English keys in every module', () => {
    for (const mod of MODULES) {
      expect(Object.keys(mod.km).sort(), `${mod.name} keys`).toEqual(Object.keys(mod.en).sort());
    }
    expect(Object.keys(km).sort()).toEqual(Object.keys(en).sort());
  });

  it('has no duplicate keys across modules', () => {
    const seen = new Map<string, string>();
    for (const mod of MODULES) {
      for (const key of Object.keys(mod.km)) {
        expect(seen.has(key), `duplicate key "${key}" in ${mod.name} and ${seen.get(key)}`).toBe(false);
        seen.set(key, mod.name);
      }
    }
    expect(seen.size).toBe(Object.keys(km).length);
  });

  it('has non-empty translations for every key', () => {
    for (const [key, value] of Object.entries(km)) {
      expect(value.trim().length, `km.${key}`).toBeGreaterThan(0);
    }
    for (const [key, value] of Object.entries(en)) {
      expect(value.trim().length, `en.${key}`).toBeGreaterThan(0);
    }
  });

  it('has matching API error keys in Khmer and English', () => {
    expect(Object.keys(API_ERRORS.km).sort()).toEqual(Object.keys(API_ERRORS.en).sort());
  });

  it('converts Khmer and Western numerals round-trip', () => {
    expect(toKhmerDigits('120/80')).toBe('១២០/៨០');
    expect(fromKhmerDigits('១២០/៨០')).toBe('120/80');
  });

  it('interpolates parameters and respects numeral setting', () => {
    const kmI18n = makeI18n('km', 'khmer');
    expect(kmI18n.t('nDays', { n: 7 })).toBe('៧ ថ្ងៃ');
    const enI18n = makeI18n('en', 'western');
    expect(enI18n.t('nDays', { n: 7 })).toBe('7 days');
  });
});
