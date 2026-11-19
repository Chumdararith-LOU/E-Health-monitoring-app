import { defineConfig } from 'vitest/config';

export default defineConfig({
  test: {
    // Every test file gets its own fresh in-memory database
    env: { DB_FILE: ':memory:' },
  },
});
