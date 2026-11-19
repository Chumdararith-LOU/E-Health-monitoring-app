import { defineConfig } from 'tsup';

export default defineConfig({
  entry: ['src/server.ts'],
  format: ['esm'],
  target: 'node24',
  // @ehealth/types ships TypeScript source, so bundle it instead of importing it at runtime
  noExternal: ['@ehealth/types'],
});
