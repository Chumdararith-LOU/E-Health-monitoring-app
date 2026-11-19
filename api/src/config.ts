import { existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { z } from 'zod';

// api/.env sits one level above both src/ and dist/
const envFile = fileURLToPath(new URL('../.env', import.meta.url));
if (existsSync(envFile)) process.loadEnvFile(envFile);

const DEV_JWT_SECRET = 'dev-only-jwt-secret-not-for-production';

const schema = z
  .object({
    PORT: z.coerce.number().int().positive().default(3000),
    NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
    DB_FILE: z.string().min(1).default('./data/ehealth.db'),
    JWT_SECRET: z.string().min(1).optional(),
    DEV_LOGIN: z.stringbool().optional(),
    CORS_ORIGIN: z.string().min(1).default('http://localhost:5173'),
  })
  .superRefine((env, ctx) => {
    if (env.NODE_ENV === 'production' && !env.JWT_SECRET) {
      ctx.addIssue({ code: 'custom', path: ['JWT_SECRET'], message: 'required in production' });
    }
  })
  .transform((env) => ({
    ...env,
    JWT_SECRET: env.JWT_SECRET ?? DEV_JWT_SECRET,
    DEV_LOGIN:
      env.NODE_ENV === 'production' ? false : (env.DEV_LOGIN ?? env.NODE_ENV === 'development'),
  }));

const parsed = schema.safeParse(process.env);
if (!parsed.success) {
  console.error(`Invalid environment:\n${z.prettifyError(parsed.error)}`);
  process.exit(1);
}

export const config = parsed.data;
export type Config = typeof config;
