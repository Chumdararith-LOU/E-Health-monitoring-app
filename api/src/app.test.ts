import { mkdtempSync, rmSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import request from 'supertest';
import { describe, expect, it, vi } from 'vitest';
import { createApp } from './app';
import { config } from './config';
import { createDb } from './shared/db';

// The app's database is in-memory here (see vitest.config.ts)
const app = createApp();

describe('app', () => {
  it('GET /api/v1/health returns 200', async () => {
    const res = await request(app).get('/api/v1/health');
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ ok: true, name: 'ehealth-api', env: 'test', db: 'ok' });
  });

  it('GET /api/v1/health returns 503 when the database fails', async () => {
    const closed = createDb(':memory:');
    closed.$client.close();
    const errorLog = vi.spyOn(console, 'error').mockImplementation(() => {});
    const res = await request(createApp(() => closed)).get('/api/v1/health');
    errorLog.mockRestore();
    expect(res.status).toBe(503);
    expect(res.body).toEqual({
      error: { code: 'db_unavailable', messageKey: 'errors.db_unavailable' },
    });
  });

  it('GET /api/v1/reports/ping returns 200', async () => {
    const res = await request(app).get('/api/v1/reports/ping');
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ module: 'reports', ok: true });
  });

  it('unknown route returns 404 in the ApiError shape', async () => {
    const res = await request(app).get('/api/v1/nope');
    expect(res.status).toBe(404);
    expect(res.body).toEqual({ error: { code: 'not_found', messageKey: 'errors.not_found' } });
  });

  it('serves built web portal from WEB_DIST_DIR while keeping /api/* as JSON 404', async () => {
    const dir = mkdtempSync(join(tmpdir(), 'ehealth-web-dist-'));
    const prev = config.WEB_DIST_DIR;
    try {
      writeFileSync(join(dir, 'index.html'), '<!doctype html><html><body>E-Health Web</body></html>');
      config.WEB_DIST_DIR = dir;
      const deployedApp = createApp();

      const home = await request(deployedApp).get('/');
      expect(home.status).toBe(200);
      expect(home.text).toContain('E-Health Web');

      const missingApi = await request(deployedApp).get('/api/v1/nope');
      expect(missingApi.status).toBe(404);
      expect(missingApi.body).toEqual({ error: { code: 'not_found', messageKey: 'errors.not_found' } });
    } finally {
      config.WEB_DIST_DIR = prev;
      rmSync(dir, { recursive: true, force: true });
    }
  });
});
