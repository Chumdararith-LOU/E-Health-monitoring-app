import { addDays, startOfDay } from './dates';
import { DataState, Link, Reading, User } from './types';

/**
 * Demo data (mirrors the "seed script" in the plan: 4 test patients, 90 days of readings,
 * one test user per role). Dates are generated relative to TODAY so the demo always looks fresh.
 * Deterministic random numbers → the same data on every reset.
 */
export const SEED_VERSION = 1;

function rng(seed: number) {
  let a = seed;
  return () => {
    a |= 0;
    a = (a + 0x6d2b79f5) | 0;
    let t = Math.imul(a ^ (a >>> 15), 1 | a);
    t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
    return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
  };
}

export const USERS: User[] = [
  {
    id: 'p1', role: 'patient', nameEn: 'Sok Chantha', nameKm: 'សុខ ចន្ថា', phone: '012 345 678', age: 64,
    conditionsEn: 'High blood pressure, type 2 diabetes', conditionsKm: 'លើសសម្ពាធឈាម ទឹកនោមផ្អែមប្រភេទទី២',
  },
  {
    id: 'p2', role: 'patient', nameEn: 'Keo Sreymom', nameKm: 'កែវ ស្រីមុំ', phone: '017 222 310', age: 78,
    conditionsEn: 'Type 2 diabetes', conditionsKm: 'ទឹកនោមផ្អែមប្រភេទទី២',
  },
  {
    id: 'p3', role: 'patient', nameEn: 'Chea Vuthy', nameKm: 'ជា វុទ្ធី', phone: '015 880 112', age: 59,
    conditionsEn: 'Type 2 diabetes', conditionsKm: 'ទឹកនោមផ្អែមប្រភេទទី២',
  },
  {
    id: 'p4', role: 'patient', nameEn: 'Meas Sophea', nameKm: 'មាស សុភា', phone: '010 456 901', age: 81,
    conditionsEn: 'High blood pressure', conditionsKm: 'លើសសម្ពាធឈាម',
  },
  {
    id: 'p5', role: 'patient', nameEn: 'Hem Sovann', nameKm: 'ហែម សុវណ្ណ', phone: '012 777 450', age: 70,
    conditionsEn: 'High blood pressure', conditionsKm: 'លើសសម្ពាធឈាម',
  },
  {
    id: 'p6', role: 'patient', nameEn: 'Nhem Bopha', nameKm: 'ញ៉ែម បុប្ផា', phone: '092 118 640', age: 66,
    conditionsEn: 'Type 2 diabetes', conditionsKm: 'ទឹកនោមផ្អែមប្រភេទទី២',
  },
  {
    id: 'p7', role: 'patient', nameEn: 'Ros Pisey', nameKm: 'រស់ ពិសី', phone: '097 303 221', age: 55,
    conditionsEn: 'Type 2 diabetes, high blood pressure', conditionsKm: 'ទឹកនោមផ្អែមប្រភេទទី២ លើសសម្ពាធឈាម',
  },
  {
    id: 'p8', role: 'patient', nameEn: 'Tep Sambath', nameKm: 'ទេព សម្បត្តិ', phone: '088 640 912', age: 73,
    conditionsEn: 'High blood pressure', conditionsKm: 'លើសសម្ពាធឈាម',
  },
  { id: 'c1', role: 'caretaker', nameEn: 'Dara Pich', nameKm: 'ពេជ្រ ដារ៉ា', phone: '011 765 432' },
  { id: 'f1', role: 'family', nameEn: 'Sok Sreyleak', nameKm: 'សុខ ស្រីលក្ខ', phone: '096 555 0101' },
  { id: 'd1', role: 'doctor', nameEn: 'Dr. Lim Bunthoeun', nameKm: 'វេជ្ជ. លឹម ប៊ុនធឿន', phone: '023 900 100' },
  { id: 'd2', role: 'doctor', nameEn: 'Dr. Ouk Malis', nameKm: 'វេជ្ជ. អ៊ុក ម៉ាលីស', phone: '023 900 200' },
  { id: 'c2', role: 'caretaker', nameEn: 'Chan Rotha', nameKm: 'ចាន់ រដ្ឋា', phone: '016 401 228' },
  { id: 'f2', role: 'family', nameEn: 'Hem Dalin', nameKm: 'ហែម ដាលីន', phone: '093 220 115' },
  { id: 'a1', role: 'admin', nameEn: 'System Admin', nameKm: 'អ្នកគ្រប់គ្រងប្រព័ន្ធ', phone: 'admin@ehealth.kh' },
];

/** The signed-in user for each demo role (dev login). */
export const DEMO_LOGINS = [
  { userId: 'd1', role: 'doctor' as const },
  { userId: 'd2', role: 'doctor' as const },
  { userId: 'a1', role: 'admin' as const },
];

interface Profile {
  id: string;
  sys: number; dia: number; pulse: number; glu: number;
  sysSd: number; gluSd: number;
  skip: number; // chance to miss a day
  enteredBy: string[];
  weight?: number;
  skipLastDays?: number;
  skipToday?: boolean;
  trend?: number; // systolic drift per 30 days (negative = improving)
}

const PROFILES: Profile[] = [
  // Patient demo account: improving BP, not yet recorded today (so Home shows "Record now")
  { id: 'p1', sys: 128, dia: 77, pulse: 76, glu: 110, sysSd: 6, gluSd: 12, skip: 0.06, enteredBy: ['p1'], weight: 68.5, skipToday: true, trend: -5 },
  // Elderly, caretaker records; occasional low glucose; recorded today
  { id: 'p2', sys: 114, dia: 72, pulse: 72, glu: 98, sysSd: 5, gluSd: 10, skip: 0.04, enteredBy: ['c1'] },
  // Missed the last 3 days → dashboard "missed" flag
  { id: 'p3', sys: 120, dia: 78, pulse: 80, glu: 158, sysSd: 6, gluSd: 25, skip: 0.15, enteredBy: ['p3'], weight: 74, skipLastDays: 3 },
  // Rising BP → dashboard "high" flag
  { id: 'p4', sys: 148, dia: 90, pulse: 70, glu: 110, sysSd: 9, gluSd: 12, skip: 0.08, enteredBy: ['c1'], trend: 8 },
  { id: 'p5', sys: 118, dia: 74, pulse: 68, glu: 96, sysSd: 5, gluSd: 8, skip: 0.03, enteredBy: ['c2'] },
  { id: 'p6', sys: 112, dia: 70, pulse: 78, glu: 104, sysSd: 5, gluSd: 9, skip: 0.05, enteredBy: ['p6'], weight: 59 },
  { id: 'p7', sys: 122, dia: 78, pulse: 82, glu: 112, sysSd: 5, gluSd: 10, skip: 0.04, enteredBy: ['p7'], skipToday: true },
  { id: 'p8', sys: 116, dia: 72, pulse: 64, glu: 92, sysSd: 6, gluSd: 7, skip: 0.2, enteredBy: ['p8'], skipLastDays: 2 },
];

const NOTES_EN = ['Felt dizzy', 'After a short walk', 'Forgot medicine yesterday', 'Slept badly'];
const NOTES_KM = ['មានវិលមុខ', 'ក្រោយដើរលេងបន្តិច', 'ភ្លេចលេបថ្នាំម្សិលមិញ', 'គេងមិនលក់ស្រួល'];

function gauss(r: () => number) {
  // Box–Muller
  const u = Math.max(r(), 1e-9);
  const v = r();
  return Math.sqrt(-2 * Math.log(u)) * Math.cos(2 * Math.PI * v);
}

function makeReadings(now: Date): Reading[] {
  const out: Reading[] = [];
  const today = startOfDay(now);
  PROFILES.forEach((p, pi) => {
    const r = rng(1000 + pi * 77);
    for (let back = 89; back >= 0; back--) {
      const day = addDays(today, -back);
      if (back === 0 && p.skipToday) continue;
      if (p.skipLastDays && back < p.skipLastDays) continue;
      if (back > 0 && r() < p.skip) continue;
      const progress = (89 - back) / 30; // months elapsed
      const drift = (p.trend ?? 0) * progress - (p.trend ?? 0) * 1.5;
      const sys = Math.round(p.sys + drift + gauss(r) * p.sysSd);
      const dia = Math.round(p.dia + drift * 0.5 + gauss(r) * (p.sysSd * 0.6));
      const pulse = Math.round(p.pulse + gauss(r) * 6);
      let glu = Math.round(p.glu + gauss(r) * p.gluSd);
      if (p.id === 'p2' && r() < 0.05) glu = 62 + Math.round(r() * 5);
      const t = new Date(day);
      t.setHours(6, Math.round(r() * 120), 0, 0); // 6:00–8:00
      if (back === 0 && t > now) t.setTime(now.getTime() - 5 * 60000);
      const extra: Record<string, number> = {};
      if (p.id === 'p2' && back > 45 && back % 3 === 0) extra.temp = Math.round((36.6 + gauss(r) * 0.3) * 10) / 10; // archived field, old data
      if (p.weight && back % 7 === 0) extra.weight = Math.round((p.weight + gauss(r) * 0.6 - progress * 0.3) * 10) / 10;
      const noteIdx = r() < 0.07 ? Math.floor(r() * NOTES_EN.length) : -1;
      const enteredBy = p.enteredBy[0];
      out.push({
        id: `seed-${p.id}-${back}`,
        patientId: p.id,
        takenAt: t.toISOString(),
        systolic: Math.max(80, sys),
        diastolic: Math.max(45, Math.min(dia, sys - 20)),
        pulse,
        glucose: Math.max(45, glu),
        extra,
        enteredBy,
        method: r() < 0.55 ? 'ocr' : 'manual',
        note: noteIdx >= 0 ? (pi % 2 === 0 ? NOTES_KM[noteIdx] : NOTES_EN[noteIdx]) : undefined,
      });
    }
  });
  return out;
}

export function makeSeed(now = new Date()): DataState {
  const iso = (daysAgo: number) => addDays(now, -daysAgo).toISOString();
  const links: Link[] = [
    // Patient demo account p1
    { id: 'l1', patientId: 'p1', userId: 'd1', relation: 'doctor', status: 'active', initiatedBy: 'patient', createdAt: iso(120) },
    { id: 'l2', patientId: 'p1', userId: 'f1', relation: 'family', status: 'active', initiatedBy: 'patient', createdAt: iso(100) },
    { id: 'l3', patientId: 'p1', userId: 'd2', relation: 'doctor', status: 'pending', initiatedBy: 'other', createdAt: iso(1) }, // waiting for p1's approval
    // Caretaker c1 records for p2 and p4
    { id: 'l4', patientId: 'p2', userId: 'c1', relation: 'caretaker', status: 'active', initiatedBy: 'patient', createdAt: iso(200) },
    { id: 'l5', patientId: 'p4', userId: 'c1', relation: 'caretaker', status: 'active', initiatedBy: 'patient', createdAt: iso(150) },
    // Family f1 follows p1 and p2
    { id: 'l6', patientId: 'p2', userId: 'f1', relation: 'family', status: 'active', initiatedBy: 'patient', createdAt: iso(180) },
    // Doctor d1 follows everyone
    { id: 'l7', patientId: 'p2', userId: 'd1', relation: 'doctor', status: 'active', initiatedBy: 'patient', createdAt: iso(300) },
    { id: 'l8', patientId: 'p3', userId: 'd1', relation: 'doctor', status: 'active', initiatedBy: 'patient', createdAt: iso(90) },
    { id: 'l9', patientId: 'p4', userId: 'd1', relation: 'doctor', status: 'active', initiatedBy: 'patient', createdAt: iso(60) },
    { id: 'l10', patientId: 'p5', userId: 'd1', relation: 'doctor', status: 'active', initiatedBy: 'patient', createdAt: iso(45) },
    { id: 'l11', patientId: 'p6', userId: 'd1', relation: 'doctor', status: 'active', initiatedBy: 'patient', createdAt: iso(80) },
    { id: 'l12', patientId: 'p7', userId: 'd1', relation: 'doctor', status: 'active', initiatedBy: 'patient', createdAt: iso(33) },
    { id: 'l13', patientId: 'p8', userId: 'd1', relation: 'doctor', status: 'active', initiatedBy: 'patient', createdAt: iso(20) },
    { id: 'l14', patientId: 'p5', userId: 'c2', relation: 'caretaker', status: 'active', initiatedBy: 'patient', createdAt: iso(44) },
    { id: 'l15', patientId: 'p5', userId: 'f2', relation: 'family', status: 'active', initiatedBy: 'patient', createdAt: iso(40) },
    { id: 'l16', patientId: 'p6', userId: 'd2', relation: 'doctor', status: 'active', initiatedBy: 'patient', createdAt: iso(70) },
    { id: 'l17', patientId: 'p7', userId: 'd2', relation: 'doctor', status: 'active', initiatedBy: 'patient', createdAt: iso(25) },
    { id: 'l18', patientId: 'p8', userId: 'd2', relation: 'doctor', status: 'pending', initiatedBy: 'other', createdAt: iso(1) },
  ];
  return {
    version: SEED_VERSION,
    users: USERS,
    links,
    readings: makeReadings(now),
    fields: [
      // Added by the admin on the web (FR-15) — appears automatically in the entry form, history and reports
      { id: 'weight', nameEn: 'Weight', nameKm: 'ទម្ងន់', unit: 'kg', decimals: 1, min: 2, max: 300, active: true, createdAt: iso(120) },
      { id: 'temp', nameEn: 'Body temperature', nameKm: 'សីតុណ្ហភាពរាងកាយ', unit: '°C', decimals: 1, min: 30, max: 45, active: false, createdAt: iso(200) },
    ],
    notes: [
      { id: 'n1', patientId: 'p1', authorId: 'd1', createdAt: iso(6), text: 'Blood pressure is improving. Keep taking amlodipine every morning and walk 30 minutes a day.' },
      { id: 'n2', patientId: 'p4', authorId: 'd1', createdAt: iso(3), text: 'BP trending up. Please come to the clinic this week.' },
    ],
  };
}
