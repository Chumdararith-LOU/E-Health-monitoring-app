// Readings & custom fields REST routes (US-04, US-05, US-06, US-16).
// Every patient route runs requireAuth + requirePatientAccess; admin field writes run requireRole('admin').

import type { AuthUser, CustomFieldDto, ReadingDto } from '@ehealth/types';
import { and, desc, eq, inArray, sql } from 'drizzle-orm';
import { type Request, Router } from 'express';
import { z } from 'zod';
import { requirePatientAccess } from '../../shared/access';
import { requireAuth, requireRole } from '../../shared/auth';
import { type Db, getDb } from '../../shared/db';
import { badRequest, conflict, forbidden, notFound } from '../../shared/errors';
import { newId } from '../../shared/ids';
import { validate } from '../../shared/validate';
import { customFields, readings, readingValues } from './schema';

export const readingsRouter = Router();

function dbOf(req: Request): Db {
  const getter = req.app.locals.getDb as (() => Db) | undefined;
  return (getter ?? getDb)();
}

function canWriteReading(user: AuthUser, patientId: string): boolean {
  if (user.role === 'admin') return true;
  if (user.role === 'patient') return user.id === patientId;
  return user.role === 'caretaker';
}

function canModifyReading(user: AuthUser, patientId: string, enteredBy: string): boolean {
  if (user.role === 'admin') return true;
  if (user.role === 'patient') return user.id === patientId;
  return user.role === 'caretaker' && enteredBy === user.id;
}

const isoDateRegex = /^\d{4}-\d{2}-\d{2}$/;

function phnomPenhDay(iso: string): string {
  return new Intl.DateTimeFormat('en-CA', {
    timeZone: 'Asia/Phnom_Penh',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
  }).format(new Date(iso));
}

function hydrateReadings(db: Db, rows: (typeof readings.$inferSelect)[]): ReadingDto[] {
  if (rows.length === 0) return [];
  const ids = rows.map((r) => r.id);
  const valRows = db
    .select({
      readingId: readingValues.readingId,
      fieldKey: readingValues.fieldKey,
      value: readingValues.value,
    })
    .from(readingValues)
    .where(inArray(readingValues.readingId, ids))
    .all();

  const byId = new Map<string, Record<string, number>>();
  for (const v of valRows) {
    let rec = byId.get(v.readingId);
    if (!rec) {
      rec = {};
      byId.set(v.readingId, rec);
    }
    rec[v.fieldKey] = v.value;
  }

  return rows.map((r) => ({
    id: r.id,
    patientId: r.patientId,
    enteredBy: r.enteredBy,
    measuredAt: r.measuredAt,
    method: r.method,
    note: r.note,
    photoUri: r.photoUri,
    values: byId.get(r.id) ?? {},
    createdAt: r.createdAt,
    updatedAt: r.updatedAt,
  }));
}

function validateReadingValues(
  db: Db,
  values: Record<string, number>,
  allowArchivedKeys: ReadonlySet<string> = new Set(),
): void {
  const keys = Object.keys(values);
  if (keys.length === 0) {
    throw badRequest('validation_failed', 'errors.validation_failed');
  }

  const fieldRows = db.select().from(customFields).where(inArray(customFields.id, keys)).all();
  const fieldMap = new Map(fieldRows.map((f) => [f.id, f]));

  for (const key of keys) {
    const field = fieldMap.get(key);
    if (!field || (!field.active && !allowArchivedKeys.has(key))) {
      throw badRequest('validation_failed', 'errors.validation_failed');
    }
    const v = values[key];
    if (!Number.isFinite(v) || v < field.minValue || v > field.maxValue) {
      throw badRequest('validation_failed', 'errors.validation_failed');
    }
  }

  const hasSys = Object.prototype.hasOwnProperty.call(values, 'systolic');
  const hasDia = Object.prototype.hasOwnProperty.call(values, 'diastolic');
  if (hasSys !== hasDia) {
    throw badRequest('validation_failed', 'errors.validation_failed');
  }
  if (hasSys && hasDia && values.systolic <= values.diastolic) {
    throw badRequest('validation_failed', 'errors.validation_failed');
  }
}

function listFieldsWithUsage(db: Db, includeArchived: boolean): CustomFieldDto[] {
  const rows = includeArchived
    ? db.select().from(customFields).all()
    : db.select().from(customFields).where(eq(customFields.active, true)).all();

  const counts = db
    .select({
      fieldKey: readingValues.fieldKey,
      n: sql<number>`count(*)`,
    })
    .from(readingValues)
    .groupBy(readingValues.fieldKey)
    .all();
  const countMap = new Map(counts.map((c) => [c.fieldKey, Number(c.n)]));

  return rows.map((f) => ({
    id: f.id,
    nameEn: f.nameEn,
    nameKm: f.nameKm,
    unit: f.unit,
    decimals: f.decimals,
    minValue: f.minValue,
    maxValue: f.maxValue,
    normalMin: f.normalMin,
    normalMax: f.normalMax,
    builtIn: f.builtIn,
    active: f.active,
    usedCount: countMap.get(f.id) ?? 0,
  }));
}

function slugifyFieldId(nameEn: string): string {
  return nameEn
    .trim()
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '_')
    .replace(/^_+|_+$/g, '')
    .slice(0, 48);
}

// ---------- Readings CRUD ----------

const listReadingsQuery = z.object({
  from: z.string().regex(isoDateRegex).optional(),
  to: z.string().regex(isoDateRegex).optional(),
  limit: z.coerce.number().int().min(1).max(500).default(100),
});

readingsRouter.get(
  '/patients/:patientId/readings',
  requireAuth,
  requirePatientAccess(),
  validate({ query: listReadingsQuery }),
  (req, res) => {
    const db = dbOf(req);
    const patientId = req.params.patientId as string;
    const { from, to, limit } = req.query as unknown as z.infer<typeof listReadingsQuery>;

    if (from && to && from > to) {
      throw badRequest('validation_failed', 'errors.validation_failed');
    }

    const allRows = db
      .select()
      .from(readings)
      .where(eq(readings.patientId, patientId))
      .orderBy(desc(readings.measuredAt))
      .all();

    const filtered = allRows.filter((r) => {
      const day = phnomPenhDay(r.measuredAt);
      if (from && day < from) return false;
      if (to && day > to) return false;
      return true;
    });

    res.json({ readings: hydrateReadings(db, filtered.slice(0, limit)) });
  },
);

const createReadingBody = z.object({
  measuredAt: z.string().datetime({ offset: true }).optional(),
  method: z.enum(['manual', 'ocr']).default('manual'),
  note: z.string().max(1000).nullable().optional(),
  photoUri: z.string().max(500).nullable().optional(),
  values: z.record(z.string().min(1).max(64), z.number().finite()),
});

readingsRouter.post(
  '/patients/:patientId/readings',
  requireAuth,
  requirePatientAccess(),
  validate({ body: createReadingBody }),
  (req, res) => {
    const user = req.user!;
    const patientId = req.params.patientId as string;
    if (!canWriteReading(user, patientId)) {
      throw forbidden();
    }

    const db = dbOf(req);
    const body = req.body as z.infer<typeof createReadingBody>;
    validateReadingValues(db, body.values);

    const id = newId();
    const now = new Date().toISOString();
    const measuredAt = body.measuredAt ?? now;

    db.transaction((tx) => {
      tx.insert(readings)
        .values({
          id,
          patientId,
          enteredBy: user.id,
          measuredAt,
          method: body.method,
          note: body.note ?? null,
          photoUri: body.photoUri ?? null,
          createdAt: now,
        })
        .run();

      tx.insert(readingValues)
        .values(
          Object.entries(body.values).map(([fieldKey, value]) => ({
            readingId: id,
            fieldKey,
            value,
          })),
        )
        .run();
    });

    const created = db.select().from(readings).where(eq(readings.id, id)).get()!;
    res.status(201).json(hydrateReadings(db, [created])[0]);
  },
);

const updateReadingBody = z
  .object({
    measuredAt: z.string().datetime({ offset: true }).optional(),
    note: z.string().max(1000).nullable().optional(),
    values: z.record(z.string().min(1).max(64), z.number().finite()).optional(),
  })
  .refine((b) => b.measuredAt !== undefined || b.note !== undefined || b.values !== undefined, {
    message: 'at least one field must be updated',
  });

readingsRouter.put(
  '/patients/:patientId/readings/:readingId',
  requireAuth,
  requirePatientAccess(),
  validate({ body: updateReadingBody }),
  (req, res) => {
    const db = dbOf(req);
    const patientId = req.params.patientId as string;
    const readingId = req.params.readingId as string;

    const existing = db
      .select()
      .from(readings)
      .where(and(eq(readings.id, readingId), eq(readings.patientId, patientId)))
      .get();
    if (!existing) throw notFound();

    if (!canModifyReading(req.user!, patientId, existing.enteredBy)) {
      throw forbidden();
    }

    const body = req.body as z.infer<typeof updateReadingBody>;
    if (body.values !== undefined) {
      const existingKeys = new Set(
        db
          .select({ fieldKey: readingValues.fieldKey })
          .from(readingValues)
          .where(eq(readingValues.readingId, readingId))
          .all()
          .map((r) => r.fieldKey),
      );
      validateReadingValues(db, body.values, existingKeys);
    }

    const now = new Date().toISOString();
    db.transaction((tx) => {
      tx.update(readings)
        .set({
          measuredAt: body.measuredAt ?? existing.measuredAt,
          note: body.note === undefined ? existing.note : body.note,
          updatedAt: now,
        })
        .where(eq(readings.id, readingId))
        .run();

      if (body.values !== undefined) {
        tx.delete(readingValues).where(eq(readingValues.readingId, readingId)).run();
        tx.insert(readingValues)
          .values(
            Object.entries(body.values).map(([fieldKey, value]) => ({
              readingId,
              fieldKey,
              value,
            })),
          )
          .run();
      }
    });

    const updated = db.select().from(readings).where(eq(readings.id, readingId)).get()!;
    res.json(hydrateReadings(db, [updated])[0]);
  },
);

readingsRouter.delete(
  '/patients/:patientId/readings/:readingId',
  requireAuth,
  requirePatientAccess(),
  (req, res) => {
    const db = dbOf(req);
    const patientId = req.params.patientId as string;
    const readingId = req.params.readingId as string;

    const existing = db
      .select()
      .from(readings)
      .where(and(eq(readings.id, readingId), eq(readings.patientId, patientId)))
      .get();
    if (!existing) throw notFound();

    if (!canModifyReading(req.user!, patientId, existing.enteredBy)) {
      throw forbidden();
    }

    db.delete(readings).where(eq(readings.id, readingId)).run();
    res.status(204).end();
  },
);

// ---------- Custom Fields CRUD (US-16) ----------

const listFieldsQuery = z.object({
  includeArchived: z
    .enum(['true', 'false'])
    .optional()
    .transform((v) => v === 'true'),
});

readingsRouter.get('/fields', requireAuth, validate({ query: listFieldsQuery }), (req, res) => {
  const { includeArchived } = req.query as unknown as z.infer<typeof listFieldsQuery>;
  res.json({ fields: listFieldsWithUsage(dbOf(req), Boolean(includeArchived)) });
});

const createFieldBody = z
  .object({
    id: z
      .string()
      .trim()
      .regex(/^[a-z][a-z0-9_]{1,47}$/)
      .optional(),
    nameEn: z.string().trim().min(1).max(80),
    nameKm: z.string().trim().min(1).max(80),
    unit: z.string().trim().min(1).max(24),
    decimals: z.number().int().min(0).max(2).default(0),
    minValue: z.number().finite(),
    maxValue: z.number().finite(),
    normalMin: z.number().finite().nullable().optional(),
    normalMax: z.number().finite().nullable().optional(),
  })
  .refine((b) => b.minValue < b.maxValue, { message: 'minValue must be smaller than maxValue' })
  .refine(
    (b) => b.normalMin == null || b.normalMax == null || b.normalMin < b.normalMax,
    { message: 'normalMin must be smaller than normalMax' },
  );

readingsRouter.post(
  '/fields',
  requireAuth,
  requireRole('admin'),
  validate({ body: createFieldBody }),
  (req, res) => {
    const db = dbOf(req);
    const body = req.body as z.infer<typeof createFieldBody>;
    const id = body.id ?? slugifyFieldId(body.nameEn);
    if (!id) throw badRequest('validation_failed', 'errors.validation_failed');

    const exists = db.select({ id: customFields.id }).from(customFields).where(eq(customFields.id, id)).get();
    if (exists) throw conflict();

    db.insert(customFields)
      .values({
        id,
        nameEn: body.nameEn,
        nameKm: body.nameKm,
        unit: body.unit,
        decimals: body.decimals,
        minValue: body.minValue,
        maxValue: body.maxValue,
        normalMin: body.normalMin ?? null,
        normalMax: body.normalMax ?? null,
        builtIn: false,
        active: true,
      })
      .run();

    const created = listFieldsWithUsage(db, true).find((f) => f.id === id)!;
    res.status(201).json(created);
  },
);

const updateFieldBody = z.object({
  nameEn: z.string().trim().min(1).max(80).optional(),
  nameKm: z.string().trim().min(1).max(80).optional(),
  unit: z.string().trim().min(1).max(24).optional(),
  decimals: z.number().int().min(0).max(2).optional(),
  minValue: z.number().finite().optional(),
  maxValue: z.number().finite().optional(),
  normalMin: z.number().finite().nullable().optional(),
  normalMax: z.number().finite().nullable().optional(),
  active: z.boolean().optional(),
});

readingsRouter.put(
  '/fields/:fieldId',
  requireAuth,
  requireRole('admin'),
  validate({ body: updateFieldBody }),
  (req, res) => {
    const db = dbOf(req);
    const fieldId = req.params.fieldId as string;
    const existing = db.select().from(customFields).where(eq(customFields.id, fieldId)).get();
    if (!existing) throw notFound();

    const body = req.body as z.infer<typeof updateFieldBody>;
    if (existing.builtIn && body.active === false) {
      throw badRequest('cannot_archive_builtin', 'errors.bad_request');
    }

    const nextMin = body.minValue ?? existing.minValue;
    const nextMax = body.maxValue ?? existing.maxValue;
    if (nextMin >= nextMax) {
      throw badRequest('validation_failed', 'errors.validation_failed');
    }

    const used = db
      .select({ n: sql<number>`count(*)` })
      .from(readingValues)
      .where(eq(readingValues.fieldKey, fieldId))
      .get();
    const usedCount = Number(used?.n ?? 0);
    if (
      usedCount > 0 &&
      ((body.unit !== undefined && body.unit !== existing.unit) ||
        (body.decimals !== undefined && body.decimals !== existing.decimals))
    ) {
      throw conflict('field_in_use', 'errors.conflict');
    }

    db.update(customFields)
      .set({
        nameEn: body.nameEn ?? existing.nameEn,
        nameKm: body.nameKm ?? existing.nameKm,
        unit: body.unit ?? existing.unit,
        decimals: body.decimals ?? existing.decimals,
        minValue: nextMin,
        maxValue: nextMax,
        normalMin: body.normalMin === undefined ? existing.normalMin : body.normalMin,
        normalMax: body.normalMax === undefined ? existing.normalMax : body.normalMax,
        active: body.active ?? existing.active,
      })
      .where(eq(customFields.id, fieldId))
      .run();

    const updated = listFieldsWithUsage(db, true).find((f) => f.id === fieldId)!;
    res.json(updated);
  },
);
