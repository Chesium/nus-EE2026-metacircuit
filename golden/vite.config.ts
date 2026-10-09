import { defineConfig } from 'vitest/config';

export default defineConfig({
  root: '.',
  server: { port: 5173, strictPort: false },
  build: { outDir: 'dist', target: 'es2022' },
  test: {
    include: ['test/**/*.test.ts'],
    environment: 'node',
  },
});
