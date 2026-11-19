import { existsSync } from 'node:fs';
import { defineConfig } from 'drizzle-kit';

// drizzle-kit runs from api/, so paths here are relative to api/
if (existsSync('.env')) process.loadEnvFile('.env');

export default defineConfig({
  dialect: 'sqlite',
  schema: './src/modules/*/schema.ts',
  out: './drizzle',
  dbCredentials: { url: process.env.DB_FILE ?? './data/ehealth.db' },
});
