// Idempotent development seed for accounts (users, patient links, invite code, sample notes).
// Safe to run multiple times via `.onConflictDoNothing()`.

import type { Db } from '../../shared/db';
import { devUsers } from '../../shared/dev/dev-users';
import { hashPasswordSync } from './password';
import { doctorNotes, inviteCodes, patientLinks, users } from './schema';

// Every demo user signs in with the password "123456".
// Databases seeded before this change keep the old placeholder hash: run db:reset.
const DEMO_PASSWORD_HASH = hashPasswordSync('123456');

const SEED_USERS: (typeof users.$inferInsert)[] = [
  // Fixed dev-login users (match api/src/shared/dev/dev-users.ts and Bruno requests)
  {
    id: devUsers.patient.id,
    role: 'patient',
    nameEn: devUsers.patient.name,
    nameKm: 'សុខ តារា',
    phone: '012000001',
    passwordHash: DEMO_PASSWORD_HASH,
    age: 62,
    conditionsEn: 'High blood pressure, type 2 diabetes',
    conditionsKm: 'លើសសម្ពាធឈាម ទឹកនោមផ្អែមប្រភេទទី២',
  },
  {
    id: devUsers.caretaker.id,
    role: 'caretaker',
    nameEn: devUsers.caretaker.name,
    nameKm: 'ចាន់ សុភា',
    phone: '012000002',
    passwordHash: DEMO_PASSWORD_HASH,
  },
  {
    id: devUsers.family.id,
    role: 'family',
    nameEn: devUsers.family.name,
    nameKm: 'សុខ វណ្ណា',
    phone: '012000003',
    passwordHash: DEMO_PASSWORD_HASH,
  },
  {
    id: devUsers.doctor.id,
    role: 'doctor',
    nameEn: devUsers.doctor.name,
    nameKm: 'វេជ្ជ. កែវ រតនា',
    phone: '012000004',
    passwordHash: DEMO_PASSWORD_HASH,
  },
  {
    id: devUsers.admin.id,
    role: 'admin',
    nameEn: devUsers.admin.name,
    nameKm: 'អ្នកគ្រប់គ្រង',
    email: 'dev-admin@ehealth.kh',
    passwordHash: DEMO_PASSWORD_HASH,
  },

  // Web & mobile demo patients & staff (match web/src/data/seed.ts and mobile/lib/data/seed.dart)
  {
    id: 'p1',
    role: 'patient',
    nameEn: 'Sok Chantha',
    nameKm: 'សុខ ចន្ថា',
    phone: '012 345 678',
    passwordHash: DEMO_PASSWORD_HASH,
    age: 64,
    conditionsEn: 'High blood pressure, type 2 diabetes',
    conditionsKm: 'លើសសម្ពាធឈាម ទឹកនោមផ្អែមប្រភេទទី២',
  },
  {
    id: 'p2',
    role: 'patient',
    nameEn: 'Keo Sreymom',
    nameKm: 'កែវ ស្រីមុំ',
    phone: '017 222 310',
    passwordHash: DEMO_PASSWORD_HASH,
    age: 78,
    conditionsEn: 'Type 2 diabetes',
    conditionsKm: 'ទឹកនោមផ្អែមប្រភេទទី២',
  },
  {
    id: 'p3',
    role: 'patient',
    nameEn: 'Chea Vuthy',
    nameKm: 'ជា វុទ្ធី',
    phone: '015 880 112',
    passwordHash: DEMO_PASSWORD_HASH,
    age: 59,
    conditionsEn: 'Type 2 diabetes',
    conditionsKm: 'ទឹកនោមផ្អែមប្រភេទទី២',
  },
  {
    id: 'p4',
    role: 'patient',
    nameEn: 'Meas Sophea',
    nameKm: 'មាស សុភា',
    phone: '010 456 901',
    passwordHash: DEMO_PASSWORD_HASH,
    age: 81,
    conditionsEn: 'High blood pressure',
    conditionsKm: 'លើសសម្ពាធឈាម',
  },
  {
    id: 'p5',
    role: 'patient',
    nameEn: 'Hem Sovann',
    nameKm: 'ហែម សុវណ្ណ',
    phone: '012 777 450',
    passwordHash: DEMO_PASSWORD_HASH,
    age: 70,
    conditionsEn: 'High blood pressure',
    conditionsKm: 'លើសសម្ពាធឈាម',
  },
  {
    id: 'p6',
    role: 'patient',
    nameEn: 'Nhem Bopha',
    nameKm: 'ញ៉ែម បុប្ផា',
    phone: '092 118 640',
    passwordHash: DEMO_PASSWORD_HASH,
    age: 66,
    conditionsEn: 'Type 2 diabetes',
    conditionsKm: 'ទឹកនោមផ្អែមប្រភេទទី២',
  },
  {
    id: 'p7',
    role: 'patient',
    nameEn: 'Ros Pisey',
    nameKm: 'រស់ ពិសី',
    phone: '097 303 221',
    passwordHash: DEMO_PASSWORD_HASH,
    age: 55,
    conditionsEn: 'Type 2 diabetes, high blood pressure',
    conditionsKm: 'ទឹកនោមផ្អែមប្រភេទទី២ លើសសម្ពាធឈាម',
  },
  {
    id: 'p8',
    role: 'patient',
    nameEn: 'Tep Sambath',
    nameKm: 'ទេព សម្បត្តិ',
    phone: '088 640 912',
    passwordHash: DEMO_PASSWORD_HASH,
    age: 73,
    conditionsEn: 'High blood pressure',
    conditionsKm: 'លើសសម្ពាធឈាម',
  },
  {
    id: 'c1',
    role: 'caretaker',
    nameEn: 'Dara Pich',
    nameKm: 'ពេជ្រ ដារ៉ា',
    phone: '011 765 432',
    passwordHash: DEMO_PASSWORD_HASH,
  },
  {
    id: 'f1',
    role: 'family',
    nameEn: 'Sok Sreyleak',
    nameKm: 'សុខ ស្រីលក្ខ',
    phone: '096 555 0101',
    passwordHash: DEMO_PASSWORD_HASH,
  },
  {
    id: 'd1',
    role: 'doctor',
    nameEn: 'Dr. Lim Bunthoeun',
    nameKm: 'វេជ្ជ. លឹម ប៊ុនធឿន',
    phone: '023 900 100',
    passwordHash: DEMO_PASSWORD_HASH,
  },
  {
    id: 'd2',
    role: 'doctor',
    nameEn: 'Dr. Ouk Malis',
    nameKm: 'វេជ្ជ. អ៊ុក ម៉ាលីស',
    phone: '023 900 200',
    passwordHash: DEMO_PASSWORD_HASH,
  },
  {
    id: 'a1',
    role: 'admin',
    nameEn: 'System Admin',
    nameKm: 'អ្នកគ្រប់គ្រងប្រព័ន្ធ',
    email: 'admin@ehealth.kh',
    passwordHash: DEMO_PASSWORD_HASH,
  },
];

const DEMO_PATIENT_IDS = ['p1', 'p2', 'p3', 'p4', 'p5', 'p6', 'p7', 'p8'] as const;

export function seedAccounts(db: Db): void {
  // Demo users count as verified, so the demo needs no email step.
  const verifiedAt = new Date().toISOString();
  db.insert(users)
    .values(SEED_USERS.map((u) => ({ ...u, emailVerifiedAt: verifiedAt })))
    .onConflictDoNothing()
    .run();

  const links: (typeof patientLinks.$inferInsert)[] = [
    // Dev login users linked to dev patient
    {
      id: 'link-dev-doctor-patient',
      patientId: devUsers.patient.id,
      userId: devUsers.doctor.id,
      relation: 'doctor',
      status: 'active',
      initiatedByPatient: true,
    },
    {
      id: 'link-dev-caretaker-patient',
      patientId: devUsers.patient.id,
      userId: devUsers.caretaker.id,
      relation: 'caretaker',
      status: 'active',
      initiatedByPatient: true,
    },
    {
      id: 'link-dev-family-patient',
      patientId: devUsers.patient.id,
      userId: devUsers.family.id,
      relation: 'family',
      status: 'active',
      initiatedByPatient: true,
    },
    // Dev login doctor/caretaker/family also linked to demo patients so web & mobile dev-login flows work live
    ...DEMO_PATIENT_IDS.map((pid) => ({
      id: `link-dev-doctor-${pid}`,
      patientId: pid,
      userId: devUsers.doctor.id,
      relation: 'doctor' as const,
      status: 'active' as const,
      initiatedByPatient: true,
    })),
    {
      id: 'link-dev-caretaker-p1',
      patientId: 'p1',
      userId: devUsers.caretaker.id,
      relation: 'caretaker',
      status: 'active',
      initiatedByPatient: true,
    },
    {
      id: 'link-dev-caretaker-p2',
      patientId: 'p2',
      userId: devUsers.caretaker.id,
      relation: 'caretaker',
      status: 'active',
      initiatedByPatient: true,
    },
    {
      id: 'link-dev-family-p1',
      patientId: 'p1',
      userId: devUsers.family.id,
      relation: 'family',
      status: 'active',
      initiatedByPatient: true,
    },
    // Demo staff links (mirroring frontend demo seed)
    ...DEMO_PATIENT_IDS.map((pid) => ({
      id: `link-d1-${pid}`,
      patientId: pid,
      userId: 'd1',
      relation: 'doctor' as const,
      status: 'active' as const,
      initiatedByPatient: true,
    })),
    {
      id: 'link-d2-p1-pending',
      patientId: 'p1',
      userId: 'd2',
      relation: 'doctor',
      status: 'pending',
      initiatedByPatient: false,
    },
    {
      id: 'link-c1-p2',
      patientId: 'p2',
      userId: 'c1',
      relation: 'caretaker',
      status: 'active',
      initiatedByPatient: true,
    },
    {
      id: 'link-c1-p4',
      patientId: 'p4',
      userId: 'c1',
      relation: 'caretaker',
      status: 'active',
      initiatedByPatient: true,
    },
    {
      id: 'link-f1-p1',
      patientId: 'p1',
      userId: 'f1',
      relation: 'family',
      status: 'active',
      initiatedByPatient: true,
    },
  ];

  db.insert(patientLinks).values(links).onConflictDoNothing().run();

  const tomorrow = new Date(Date.now() + 24 * 60 * 60 * 1000).toISOString();
  db.insert(inviteCodes)
    .values({
      code: '246810',
      patientId: 'p1',
      relation: 'family',
      expiresAt: tomorrow,
    })
    .onConflictDoNothing()
    .run();

  db.insert(doctorNotes)
    .values([
      {
        id: 'note-p1-1',
        patientId: 'p1',
        authorId: 'd1',
        text: 'Morning blood pressure is trending down nicely. Keep taking medicine before breakfast.',
      },
      {
        id: 'note-p4-1',
        patientId: 'p4',
        authorId: 'd1',
        text: 'Systolic readings are consistently above 140 mmHg. Please schedule a follow-up visit.',
      },
    ])
    .onConflictDoNothing()
    .run();
}
