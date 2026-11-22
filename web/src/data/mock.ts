// Hard-coded sample data, built relative to today so the portal always looks
// current. Replace these exports with API calls later.

import type { Bi, ClinicalNote, Patient, Reading, User, VitalField } from './types';

export const dayStart = (d: Date) => new Date(d.getFullYear(), d.getMonth(), d.getDate());
export const daysAgo = (n: number, base = new Date()) => new Date(base.getFullYear(), base.getMonth(), base.getDate() - n);
const at = (day: Date, h: number, m: number) => new Date(day.getFullYear(), day.getMonth(), day.getDate(), h, m);

/** Small deterministic random generator so the data is the same on every load. */
function rng(seed: number) {
  let s = seed >>> 0;
  return () => {
    s = (s * 1664525 + 1013904223) >>> 0;
    return s / 4294967296;
  };
}

// ---------- Field schema (core + Admin custom fields) ----------

export const CORE_FIELDS: VitalField[] = [
  { id: 'sys', name: { km: 'សម្ពាធឈាមលើ', en: 'Systolic' }, unit: 'mmHg', decimal: false, hardMin: 50, hardMax: 260, normalMin: 90, normalMax: 120, core: true, active: true },
  { id: 'dia', name: { km: 'សម្ពាធឈាមក្រោម', en: 'Diastolic' }, unit: 'mmHg', decimal: false, hardMin: 30, hardMax: 150, normalMin: 60, normalMax: 80, core: true, active: true },
  { id: 'pul', name: { km: 'ជីពចរ', en: 'Pulse' }, unit: 'bpm', decimal: false, hardMin: 30, hardMax: 220, normalMin: 60, normalMax: 100, core: true, active: true },
  { id: 'glu', name: { km: 'ជាតិស្ករ', en: 'Glucose' }, unit: 'mg/dL', decimal: false, hardMin: 20, hardMax: 600, normalMin: 70, normalMax: 125, core: true, active: true },
];

export const INITIAL_CUSTOM_FIELDS: VitalField[] = [
  { id: 'wt', name: { km: 'ទម្ងន់ខ្លួន', en: 'Body weight' }, unit: 'kg', decimal: true, hardMin: 20, hardMax: 250, normalMin: 45, normalMax: 85, core: false, active: true },
  { id: 'temp', name: { km: 'សីតុណ្ហភាពខ្លួន', en: 'Body temperature' }, unit: '°C', decimal: true, hardMin: 34, hardMax: 42, normalMin: 36.1, normalMax: 37.2, core: false, active: true },
  { id: 'spo2', name: { km: 'អុកស៊ីសែនក្នុងឈាម', en: 'Blood oxygen (SpO₂)' }, unit: '%', decimal: false, hardMin: 50, hardMax: 100, normalMin: 95, normalMax: 100, core: false, active: false },
];

// ---------- People ----------

const mey = { name: { km: 'ម៉ី', en: 'Mey' }, phone: '097 555 220' };
const nich = { name: { km: 'ស្រីនិច', en: 'Srey Nich' }, phone: '096 555 118' };
const sopheak = { name: { km: 'សុភ័ក្រ', en: 'Sopheak' }, phone: '098 555 731' };

interface Seed {
  id: string;
  name: Bi;
  sex: 'f' | 'm';
  age: number;
  phone: string;
  linked: number; // days ago
  caretaker?: { name: Bi; phone: string };
  family?: { name: Bi; phone: string };
  sys: number;
  dia: number;
  glu: number;
  pul: number;
  wt: number;
  missed: number; // consecutive days missed up to today (0 = recorded today)
  noToday?: boolean; // only today missing
  spike?: number; // day offset with a spike
}

const SEEDS: Seed[] = [
  { id: 'sokha', name: { km: 'សុខា ដារា', en: 'Sokha Dara' }, sex: 'f', age: 67, phone: '012 555 891', linked: 50, caretaker: mey, family: { name: { km: 'ពិសិដ្ឋ (កូនស្រី)', en: 'Piseth (daughter)' }, phone: '088 555 417' }, sys: 135, dia: 86, glu: 115, pul: 75, wt: 62.4, missed: 0 },
  { id: 'ravy', name: { km: 'ចាន់ រ៉ាវី', en: 'Chan Ravy' }, sex: 'f', age: 58, phone: '017 555 442', linked: 38, sys: 121, dia: 78, glu: 190, pul: 72, wt: 70.2, missed: 0, spike: 0 },
  { id: 'pisey', name: { km: 'សុខ ពិសី', en: 'Sok Pisey' }, sex: 'f', age: 71, phone: '015 555 318', linked: 36, sys: 150, dia: 93, glu: 112, pul: 80, wt: 55.8, missed: 0 },
  { id: 'kim', name: { km: 'មាស គឹម', en: 'Meas Kim' }, sex: 'm', age: 74, phone: '092 555 103', linked: 47, caretaker: mey, sys: 128, dia: 80, glu: 105, pul: 70, wt: 58.1, missed: 2 },
  { id: 'bora', name: { km: 'ហេង បូរ៉ា', en: 'Heng Bora' }, sex: 'm', age: 63, phone: '010 555 774', linked: 44, sys: 119, dia: 77, glu: 110, pul: 74, wt: 68.0, missed: 1 },
  { id: 'sophal', name: { km: 'លឹម សុផល', en: 'Lim Sophal' }, sex: 'm', age: 60, phone: '011 555 229', linked: 40, sys: 115, dia: 74, glu: 97, pul: 68, wt: 66.5, missed: 0 },
  { id: 'chantha', name: { km: 'កែវ ចន្ថា', en: 'Keo Chantha' }, sex: 'f', age: 69, phone: '016 555 905', linked: 33, caretaker: nich, sys: 113, dia: 74, glu: 103, pul: 71, wt: 52.3, missed: 0 },
  { id: 'sreymom', name: { km: 'ញ៉ែម ស្រីមុំ', en: 'Nhem Sreymom' }, sex: 'f', age: 55, phone: '093 555 610', linked: 30, sys: 116, dia: 75, glu: 100, pul: 69, wt: 57.9, missed: 0 },
  { id: 'vanna', name: { km: 'អ៊ុក វណ្ណា', en: 'Ouk Vanna' }, sex: 'm', age: 66, phone: '012 555 377', linked: 29, sys: 117, dia: 76, glu: 106, pul: 73, wt: 71.4, missed: 0 },
  { id: 'darap', name: { km: 'ប្រាក់ ដារ៉ា', en: 'Prak Dara' }, sex: 'm', age: 72, phone: '070 555 482', linked: 27, caretaker: sopheak, sys: 115, dia: 74, glu: 96, pul: 66, wt: 60.2, missed: 0 },
  { id: 'kunthea', name: { km: 'សេង គន្ធា', en: 'Seng Kunthea' }, sex: 'f', age: 61, phone: '089 555 266', linked: 25, sys: 114, dia: 73, glu: 99, pul: 70, wt: 54.6, missed: 0 },
  { id: 'rithy', name: { km: 'ទូច រិទ្ធី', en: 'Touch Rithy' }, sex: 'm', age: 59, phone: '085 555 902', linked: 24, sys: 118, dia: 77, glu: 108, pul: 75, wt: 74.8, missed: 0 },
  { id: 'malis', name: { km: 'ឈឹម ម៉ាលីស', en: 'Chhim Malis' }, sex: 'f', age: 64, phone: '081 555 334', linked: 22, sys: 112, dia: 72, glu: 101, pul: 72, wt: 50.9, missed: 0 },
  { id: 'samnang', name: { km: 'យឹម សំណាង', en: 'Yim Samnang' }, sex: 'm', age: 68, phone: '078 555 619', linked: 20, sys: 116, dia: 75, glu: 104, pul: 67, wt: 63.3, missed: 0 },
  { id: 'channa', name: { km: 'ពៅ ចាន់ណា', en: 'Pov Channa' }, sex: 'f', age: 57, phone: '077 555 145', linked: 18, sys: 113, dia: 73, glu: 98, pul: 70, wt: 56.0, missed: 0 },
  { id: 'vuthy', name: { km: 'ជា វុទ្ធី', en: 'Chea Vuthy' }, sex: 'm', age: 70, phone: '069 555 803', linked: 15, sys: 117, dia: 76, glu: 102, pul: 71, wt: 65.7, missed: 0 },
  { id: 'sreyleak', name: { km: 'ម៉ៅ ស្រីល័ក្ខ', en: 'Mao Sreyleak' }, sex: 'f', age: 62, phone: '067 555 470', linked: 12, sys: 114, dia: 74, glu: 100, pul: 69, wt: 53.4, missed: 0 },
  { id: 'sambath', name: { km: 'គង់ សម្បត្តិ', en: 'Kong Sambath' }, sex: 'm', age: 65, phone: '066 555 238', linked: 10, sys: 118, dia: 76, glu: 103, pul: 72, wt: 69.1, missed: 0 },
];

export const DOCTOR_NAME: Bi = { km: 'វេជ្ជ. វណ្ណាក់', en: 'Dr. Vannak' };
export const ADMIN_NAME: Bi = { km: 'ប៊ុន រតនា', en: 'Bun Rathana' };

// Sokha's last 30 days match the design canvas exactly (index 29 = today).
const SOKHA = {
  sys: [118, 128, 121, 130, 126, null, 132, 129, 135, 127, 131, 140, 133, 128, null, 136, 142, 138, 134, 145, 139, 150, 141, 143, 162, null, 130, 120, 138, 134],
  dia: [74, 80, 76, 82, 79, null, 84, 81, 86, 78, 83, 90, 85, 80, null, 86, 92, 88, 84, 94, 89, 96, 90, 91, 98, null, 82, 78, 86, 84],
  pul: [72, 74, 70, 76, 73, null, 75, 71, 78, 74, 72, 80, 76, 73, null, 77, 79, 75, 74, 84, 76, 78, 75, 76, 82, null, 75, 72, 74, 76],
  glu: [98, 104, 92, 110, 101, null, 115, 106, 120, 99, 108, 130, 112, 104, null, 118, 126, 114, 109, 140, 121, 135, 117, 124, 185, null, 109, 98, 112, 104],
  wt: [62.0, 62.1, 61.8, 62.2, 62.0, null, 62.3, 62.1, 62.4, 62.2, 62.3, 62.6, 62.4, 62.2, null, 62.5, 62.7, 62.5, 62.4, 62.8, 62.6, 63.0, 62.7, 62.6, 62.9, null, 62.5, 62.3, 62.4, 62.5],
};

function buildPatients(today: Date): Patient[] {
  return SEEDS.map((s) => ({
    id: s.id,
    name: s.name,
    sex: s.sex,
    age: s.age,
    phone: s.phone,
    linkedSince: daysAgo(s.linked, today),
    caretaker: s.caretaker,
    family: s.family,
    devices: { km: 'ម៉ាស៊ីនវាស់សម្ពាធឈាមដៃ · ម៉ាស៊ីនវាស់ជាតិស្ករ', en: 'Arm BP monitor · glucose meter' },
  }));
}

function buildReadings(today: Date): Reading[] {
  const out: Reading[] = [];
  SEEDS.forEach((s, si) => {
    const r = rng(1000 + si * 77);
    for (let off = Math.min(s.linked, 89); off >= 0; off--) {
      const day = daysAgo(off, today);
      const roll = r();
      const roll2 = r();
      const roll3 = r();
      let sys: number;
      let dia: number;
      let pul: number;
      let glu: number;
      let wt: number;

      if (s.id === 'sokha' && off <= 29) {
        const i = 29 - off;
        if (SOKHA.sys[i] === null) continue;
        sys = SOKHA.sys[i]!;
        dia = SOKHA.dia[i]!;
        pul = SOKHA.pul[i]!;
        glu = SOKHA.glu[i]!;
        wt = SOKHA.wt[i]!;
      } else {
        if (off < s.missed) continue;
        if (off > 0 && roll < 0.06) continue; // occasional missed day
        sys = Math.round(s.sys + (roll2 - 0.5) * 16);
        dia = Math.round(s.dia + (roll3 - 0.5) * 10);
        pul = Math.round(s.pul + (roll - 0.5) * 10);
        glu = Math.round(s.glu + (roll2 - 0.4) * 30);
        wt = Math.round((s.wt + (roll3 - 0.5) * 0.8) * 10) / 10;
        if (s.spike !== undefined && off === s.spike) {
          glu = 240;
          sys = 124;
          dia = 80;
        }
      }
      const methodRoll = (roll * 7 + roll3) % 1;
      const method = methodRoll < 0.78 ? 'ocr' : methodRoll < 0.93 ? 'manual' : 'ocrEdited';
      const author = s.caretaker && roll2 < 0.4 ? 'caretaker' : 'self';
      const minute = Math.floor(roll3 * 55);
      const time = s.id === 'sokha' && off === 0 ? at(day, 7, 12) : at(day, roll < 0.5 ? 6 : 7, minute);
      out.push({
        id: `${s.id}-${off}`,
        patientId: s.id,
        time,
        systolic: sys,
        diastolic: dia,
        pulse: pul,
        glucose: glu,
        extra: { wt, temp: Math.round((36.4 + roll * 0.7) * 10) / 10 },
        author: s.id === 'sokha' && off === 0 ? 'self' : author,
        method: s.id === 'sokha' && off === 5 ? 'ocr' : method,
        photo: method !== 'manual',
        note:
          s.id === 'sokha' && off === 5
            ? { km: 'វិលមុខបន្តិចពេលព្រឹក', en: 'Slightly dizzy in the morning' }
            : undefined,
      });
    }
  });
  return out;
}

function buildNotes(today: Date): ClinicalNote[] {
  return [
    {
      id: 'n1',
      patientId: 'sokha',
      time: at(daysAgo(1, today), 16, 40),
      author: DOCTOR_NAME,
      text: {
        km: 'សម្ពាធឈាមខ្ពស់បន្តិចក្នុងសប្តាហ៍នេះ។ សូមកាត់បន្ថយអំបិលនៅពេលអាហារពេលល្ងាច ហើយវាស់មុនពេលលេបថ្នាំពេលព្រឹក។',
        en: 'Blood pressure is slightly high this week. Please reduce salt at dinner and measure before your morning medication.',
      },
    },
    {
      id: 'n2',
      patientId: 'sokha',
      time: at(daysAgo(15, today), 10, 15),
      author: DOCTOR_NAME,
      text: { km: 'ជាតិស្ករល្អ។ បន្តវាស់រៀងរាល់ព្រឹក មុនពេលញ៉ាំអាហារ។', en: 'Glucose looks good. Keep measuring every morning before eating.' },
    },
    {
      id: 'n3',
      patientId: 'sokha',
      time: at(daysAgo(29, today), 9, 30),
      author: DOCTOR_NAME,
      text: {
        km: 'ចាប់ផ្តើមតាមដាន។ សូមកត់ត្រារៀងរាល់ព្រឹក ទាំងសម្ពាធឈាម និងជាតិស្ករ។',
        en: 'Monitoring started. Please record both blood pressure and glucose every morning.',
      },
    },
    {
      id: 'n4',
      patientId: 'ravy',
      time: at(daysAgo(3, today), 11, 5),
      author: DOCTOR_NAME,
      text: { km: 'សូមវាស់ជាតិស្ករមុនញ៉ាំអាហារពេលព្រឹក ហើយមកពិនិត្យនៅសប្តាហ៍ក្រោយ។', en: 'Please measure glucose before breakfast and come for a check-up next week.' },
    },
  ];
}

function buildUsers(today: Date): User[] {
  const u = (id: string, km: string, en: string, contact: string, role: User['role'], created: number, active = true): User => ({
    id,
    name: { km, en },
    contact,
    role,
    active,
    created: daysAgo(created, today),
  });
  const list: User[] = [
    u('u-sokha', 'សុខា ដារា', 'Sokha Dara', '012 555 891', 'patient', 50),
    u('u-mey', 'ម៉ី', 'Mey', '097 555 220', 'caretaker', 47),
    u('u-piseth', 'ពិសិដ្ឋ', 'Piseth', '088 555 417', 'family', 9),
    u('u-vannak', 'វេជ្ជ. វណ្ណាក់', 'Dr. Vannak', 'vannak@clinic.kh', 'doctor', 51),
    u('u-sophea', 'វេជ្ជ. សុភា', 'Dr. Sophea', 'sophea@clinic.kh', 'doctor', 1),
    u('u-bora', 'ហេង បូរ៉ា', 'Heng Bora', '010 555 774', 'patient', 44),
    u('u-kim', 'មាស គឹម', 'Meas Kim', '092 555 103', 'patient', 47),
    u('u-ravy', 'ចាន់ រ៉ាវី', 'Chan Ravy', '017 555 442', 'patient', 38),
    u('u-pisey', 'សុខ ពិសី', 'Sok Pisey', '015 555 318', 'patient', 36, false),
    u('u-rathana', 'ប៊ុន រតនា', 'Bun Rathana', 'rathana@ehealth.kh', 'admin', 51),
  ];
  // Remaining patients, caretakers and family members (total 42 accounts).
  SEEDS.slice(5).forEach((s, i) => list.push(u(`u-${s.id}`, s.name.km, s.name.en, s.phone, 'patient', s.linked + (i % 3))));
  list.push(u('u-nich', 'ស្រីនិច', 'Srey Nich', '096 555 118', 'caretaker', 33));
  list.push(u('u-sopheak', 'សុភ័ក្រ', 'Sopheak', '098 555 731', 'caretaker', 27));
  const fam: [string, string, string][] = [
    ['ដារ៉ា', 'Dara', '071 555 902'],
    ['សុភី', 'Sophy', '086 555 213'],
    ['វិចិត្រ', 'Vichet', '095 555 640'],
    ['ចន្ទា', 'Chanda', '092 555 871'],
    ['រក្សា', 'Raksa', '087 555 452'],
    ['ពិសី', 'Pisey', '090 555 318'],
    ['មករា', 'Makara', '061 555 207'],
    ['លីដា', 'Lida', '015 555 664'],
    ['សុធា', 'Sotheara', '010 555 935'],
    ['ណារី', 'Nary', '096 555 382'],
    ['ផល្លា', 'Phalla', '097 555 519'],
  ];
  fam.forEach(([km, en, phone], i) => list.push(u(`u-f${i}`, km, en, phone, 'family', 5 + i * 3)));
  return list;
}

export function buildSampleData(now = new Date()) {
  const today = dayStart(now);
  return {
    patients: buildPatients(today),
    readings: buildReadings(today),
    notes: buildNotes(today),
    users: buildUsers(today),
    customFields: INITIAL_CUSTOM_FIELDS.map((f) => ({ ...f })),
  };
}

/** Demo sign-in accounts (also shown on the login page). */
export const DEMO_ACCOUNTS = [
  { id: '012 555 001', password: '1234', userId: 'u-vannak', role: 'doctor' as const, name: DOCTOR_NAME },
  { id: 'admin@ehealth.kh', password: '1234', userId: 'u-rathana', role: 'admin' as const, name: ADMIN_NAME },
];
