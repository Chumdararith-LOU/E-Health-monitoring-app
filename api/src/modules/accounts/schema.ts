// Accounts module SQLite schema (users, care-team links, invite codes, doctor notes).
// Initial scaffold for local end-to-end testing; Phayuk can evolve columns/routes as needed.

import { index, integer, sqliteTable, text, uniqueIndex } from 'drizzle-orm/sqlite-core';
import { newId } from '../../shared/ids';

const nowIso = () => new Date().toISOString();

export const users = sqliteTable(
  'users',
  {
    id: text('id').primaryKey().$defaultFn(newId),
    role: text('role', { enum: ['patient', 'caretaker', 'family', 'doctor', 'admin'] }).notNull(),
    nameEn: text('name_en').notNull(),
    nameKm: text('name_km').notNull(),
    phone: text('phone').unique(),
    email: text('email').unique(),
    passwordHash: text('password_hash').notNull(),
    age: integer('age'),
    conditionsEn: text('conditions_en'),
    conditionsKm: text('conditions_km'),
    createdAt: text('created_at').notNull().$defaultFn(nowIso),
  },
  (t) => [index('users_role_idx').on(t.role)],
);

export const patientLinks = sqliteTable(
  'patient_links',
  {
    id: text('id').primaryKey().$defaultFn(newId),
    patientId: text('patient_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    userId: text('user_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    relation: text('relation', { enum: ['doctor', 'caretaker', 'family'] }).notNull(),
    status: text('status', { enum: ['active', 'pending', 'revoked'] }).notNull().default('pending'),
    initiatedByPatient: integer('initiated_by_patient', { mode: 'boolean' }).notNull().default(false),
    createdAt: text('created_at').notNull().$defaultFn(nowIso),
  },
  (t) => [
    uniqueIndex('patient_links_patient_user_uidx').on(t.patientId, t.userId),
    index('patient_links_user_status_idx').on(t.userId, t.status),
  ],
);

export const inviteCodes = sqliteTable(
  'invite_codes',
  {
    code: text('code').primaryKey(),
    patientId: text('patient_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    relation: text('relation', { enum: ['doctor', 'caretaker', 'family'] }).notNull(),
    expiresAt: text('expires_at').notNull(),
    usedAt: text('used_at'),
    createdAt: text('created_at').notNull().$defaultFn(nowIso),
  },
  (t) => [index('invite_codes_patient_idx').on(t.patientId)],
);

export const doctorNotes = sqliteTable(
  'doctor_notes',
  {
    id: text('id').primaryKey().$defaultFn(newId),
    patientId: text('patient_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    authorId: text('author_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    text: text('text').notNull(),
    createdAt: text('created_at').notNull().$defaultFn(nowIso),
  },
  (t) => [index('doctor_notes_patient_created_idx').on(t.patientId, t.createdAt)],
);
