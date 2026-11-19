import request from 'supertest';
import { describe, expect, it } from 'vitest';
import { createApp } from './app';

const app = createApp();

describe('app', () => {
  it('GET /api/v1/health returns 200', async () => {
    const res = await request(app).get('/api/v1/health');
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ ok: true, name: 'ehealth-api', env: 'test' });
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
});
