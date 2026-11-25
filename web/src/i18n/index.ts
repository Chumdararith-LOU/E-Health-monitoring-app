import { Lang, Numerals, User } from '../data/types';
import { en, StringKey } from './en';
import { km } from './km';

const DICTS = { en, km };

/** Translations for API error messageKeys (api/src/shared/errors.ts + network errors). */
export const API_ERRORS: Record<Lang, Record<string, string>> = {
  km: {
    'errors.bad_request': 'សំណើមិនត្រឹមត្រូវទេ។ សូមពិនិត្យព័ត៌មានម្តងទៀត។',
    'errors.validation_failed': 'ទិន្នន័យដែលបានបញ្ចូលមិនត្រឹមត្រូវទេ។',
    'errors.unauthorized': 'សម័យប្រើប្រាស់ផុតកំណត់ ឬមិនទាន់ចូលគណនី។ សូមចូលម្តងទៀត។',
    'errors.forbidden': 'អ្នកមិនមានសិទ្ធិមើលទិន្នន័យនេះទេ។',
    'errors.not_found': 'រកមិនឃើញទិន្នន័យដែលបានស្នើសុំទេ។',
    'errors.conflict': 'ទិន្នន័យនេះមានរួចហើយ។',
    'errors.db_unavailable': 'ប្រព័ន្ធទិន្នន័យមិនអាចភ្ជាប់បានជាបណ្តោះអាសន្ន។ សូមព្យាយាមម្តងទៀត។',
    'errors.internal_error': 'មានបញ្ហាបច្ចេកទេសនៅម៉ាស៊ីនមេ។ សូមព្យាយាមម្តងទៀត។',
    'errors.network': 'មិនអាចភ្ជាប់ទៅម៉ាស៊ីនមេបានទេ។ សូមពិនិត្យការតភ្ជាប់អ៊ីនធឺណិត។',
  },
  en: {
    'errors.bad_request': 'Invalid request. Please check your input and try again.',
    'errors.validation_failed': 'Some fields are invalid. Please check and try again.',
    'errors.unauthorized': 'Session expired or not signed in. Please sign in again.',
    'errors.forbidden': 'You do not have permission to view this data.',
    'errors.not_found': 'The requested record was not found.',
    'errors.conflict': 'This record already exists.',
    'errors.db_unavailable': 'Database is temporarily unavailable. Please try again.',
    'errors.internal_error': 'Something went wrong on the server. Please try again.',
    'errors.network': 'Could not reach the server. Please check your connection.',
  },
};

export function apiErrorText(lang: Lang, messageKey: string): string {
  return API_ERRORS[lang][messageKey] ?? API_ERRORS[lang]['errors.internal_error'];
}

const KHMER_DIGITS = ['០', '១', '២', '៣', '៤', '៥', '៦', '៧', '៨', '៩'];
const MONTHS_KM = ['មករា', 'កុម្ភៈ', 'មីនា', 'មេសា', 'ឧសភា', 'មិថុនា', 'កក្កដា', 'សីហា', 'កញ្ញា', 'តុលា', 'វិច្ឆិកា', 'ធ្នូ'];
const MONTHS_EN = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const DAYS_KM = ['អាទិត្យ', 'ច័ន្ទ', 'អង្គារ', 'ពុធ', 'ព្រហស្បតិ៍', 'សុក្រ', 'សៅរ៍'];
const DAYS_EN = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'];

export function toKhmerDigits(s: string) {
  return s.replace(/[0-9]/g, (d) => KHMER_DIGITS[Number(d)]);
}

/** Converts Khmer digits typed on a Khmer keyboard back to plain digits (stored values are always plain numbers, NFR-02). */
export function fromKhmerDigits(s: string) {
  return s.replace(/[០-៩]/g, (d) => String(KHMER_DIGITS.indexOf(d)));
}

export interface I18n {
  lang: Lang;
  numerals: Numerals;
  t: (key: StringKey, params?: Record<string, string | number>) => string;
  num: (n: number | undefined, decimals?: number) => string;
  digits: (s: string) => string;
  date: (d: Date | string) => string; // Wed 25 Nov 2026
  dateShort: (d: Date | string) => string; // 25 Nov
  dateRelative: (d: Date | string) => string; // Today / Yesterday / 25 Nov
  time: (d: Date | string) => string; // 6:45 AM
  timeOfMinutes: (m: number) => string;
  dayName: (d: Date | string) => string;
  monthYear: (d: Date) => string;
  weekdayInitials: string[];
  name: (u?: { nameEn: string; nameKm: string }) => string;
  role: (r: User['role']) => string;
  apiError: (messageKey: string) => string;
}

export function makeI18n(lang: Lang, numerals: Numerals): I18n {
  const dict = DICTS[lang];
  const digits = (s: string) => (numerals === 'khmer' ? toKhmerDigits(s) : s);
  const num = (n: number | undefined, decimals = 0) => (n == null || Number.isNaN(n) ? '–' : digits(n.toFixed(decimals)));
  const toDate = (d: Date | string) => (typeof d === 'string' ? new Date(d) : d);
  const months = lang === 'km' ? MONTHS_KM : MONTHS_EN;
  const days = lang === 'km' ? DAYS_KM : DAYS_EN;

  const t: I18n['t'] = (key, params) => {
    let s: string = dict[key] ?? en[key] ?? String(key);
    if (params) {
      for (const [k, v] of Object.entries(params)) {
        s = s.split(`{${k}}`).join(typeof v === 'number' ? num(v) : v);
      }
    }
    return s;
  };

  const timeOfMinutes = (mins: number) => {
    const h = Math.floor(mins / 60);
    const m = `${mins % 60}`.padStart(2, '0');
    if (lang === 'km') {
      const part = h < 12 ? 'ព្រឹក' : h < 17 ? 'រសៀល' : 'ល្ងាច';
      const h12 = h % 12 === 0 ? 12 : h % 12;
      return digits(`${h12}:${m}`) + ' ' + part;
    }
    const h12 = h % 12 === 0 ? 12 : h % 12;
    return digits(`${h12}:${m}`) + (h < 12 ? ' AM' : ' PM');
  };

  const dateShort = (d: Date | string) => {
    const x = toDate(d);
    return digits(`${x.getDate()}`) + ' ' + months[x.getMonth()];
  };

  return {
    lang,
    numerals,
    t,
    num,
    digits,
    date: (d) => {
      const x = toDate(d);
      return `${days[x.getDay()]} ${digits(String(x.getDate()))} ${months[x.getMonth()]} ${digits(String(x.getFullYear()))}`;
    },
    dateShort,
    dateRelative: (d) => {
      const x = toDate(d);
      const now = new Date();
      const y = new Date(now);
      y.setDate(now.getDate() - 1);
      if (x.toDateString() === now.toDateString()) return t('today');
      if (x.toDateString() === y.toDateString()) return t('yesterday');
      return `${days[x.getDay()]} ${dateShort(x)}`;
    },
    time: (d) => {
      const x = toDate(d);
      return timeOfMinutes(x.getHours() * 60 + x.getMinutes());
    },
    timeOfMinutes,
    dayName: (d) => days[toDate(d).getDay()],
    monthYear: (d) => `${lang === 'km' ? MONTHS_KM[d.getMonth()] : MONTHS_EN[d.getMonth()]} ${digits(String(d.getFullYear()))}`,
    weekdayInitials: lang === 'km' ? ['អា', 'ច', 'អ', 'ពុ', 'ព្រ', 'សុ', 'ស'] : ['S', 'M', 'T', 'W', 'T', 'F', 'S'],
    name: (u) => (u ? (lang === 'km' ? u.nameKm : u.nameEn) : ''),
    role: (r) => t(`role_${r}` as StringKey),
    apiError: (messageKey) => apiErrorText(lang, messageKey),
  };
}
