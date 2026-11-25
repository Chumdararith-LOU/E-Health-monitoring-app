// Readings module SQLite schema (custom fields, readings, flexible reading values, morning reminders).
// Foreign keys to `users` are imported only via accounts' public `index.ts`.
// Initial scaffold for local end-to-end testing; Seyla can evolve columns/routes as needed.

import { index, integer, primaryKey, real, sqliteTable, text } from 'drizzle-orm/sqlite-core';
import { newId } from '../../shared/ids';
import { users } from '../accounts';

const nowIso = () => new Date().toISOString();

export const customFields = sqliteTable('custom_fields', {
  id: text('id').primaryKey(), // stable field key: systolic, diastolic, pulse, glucose, weight, ...
  nameEn: text('name_en').notNull(),
  nameKm: text('name_km').notNull(),
  unit: text('unit').notNull(),
  decimals: integer('decimals').notNull().default(0),
  minValue: real('min_value').notNull(),
  maxValue: real('max_value').notNull(),
  normalMin: real('normal_min'),
  normalMax: real('normal_max'),
  builtIn: integer('built_in', { mode: 'boolean' }).notNull().default(false),
  active: integer('active', { mode: 'boolean' }).notNull().default(true),
  createdAt: text('created_at').notNull().$defaultFn(nowIso),
});

export const readings = sqliteTable(
  'readings',
  {
    id: text('id').primaryKey().$defaultFn(newId),
    patientId: text('patient_id')
      .notNull()
      .references(() => users.id, { onDelete: 'cascade' }),
    enteredBy: text('entered_by')
      .notNull()
      .references(() => users.id, { onDelete: 'restrict' }),
    measuredAt: text('measured_at').notNull(),
    method: text('method', { enum: ['manual', 'ocr'] }).notNull().default('manual'),
    note: text('note'),
    photoUri: text('photo_uri'),
    createdAt: text('created_at').notNull().$defaultFn(nowIso),
    updatedAt: text('updated_at'),
  },
  (t) => [index('readings_patient_measured_idx').on(t.patientId, t.measuredAt)],
);

export const readingValues = sqliteTable(
  'reading_values',
  {
    readingId: text('reading_id')
      .notNull()
      .references(() => readings.id, { onDelete: 'cascade' }),
    fieldKey: text('field_key')
      .notNull()
      .references(() => customFields.id, { onDelete: 'restrict' }),
    value: real('value').notNull(),
  },
  (t) => [
    primaryKey({ columns: [t.readingId, t.fieldKey] }),
    index('reading_values_field_key_idx').on(t.fieldKey),
  ],
);

export const reminders = sqliteTable('reminders', {
  patientId: text('patient_id')
    .primaryKey()
    .references(() => users.id, { onDelete: 'cascade' }),
  enabled: integer('enabled', { mode: 'boolean' }).notNull().default(true),
  minutesAfterMidnight: integer('minutes_after_midnight').notNull().default(6 * 60 + 30),
  updatedAt: text('updated_at').notNull().$defaultFn(nowIso),
});
