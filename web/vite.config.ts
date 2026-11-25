import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';

export default defineConfig({
  plugins: [react()],
  // Relative paths so the built site also works from a sub-folder or file share.
  base: './',
  server: { port: 5173, host: true, open: true },
});
