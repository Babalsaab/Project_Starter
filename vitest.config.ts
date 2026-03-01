import { defineConfig } from 'vitest/config';
import path from 'path';

export default defineConfig({
  test: {
    // ─── Test Discovery ─────────────────────────────────────────────────
    include: [
      'orchestrator/**/*.test.ts',
      'scripts/**/*.test.ts',
      'skills/**/*.test.ts',
    ],
    exclude: ['node_modules', 'dist', '.next', 'runs'],

    // ─── Environment ────────────────────────────────────────────────────
    environment: 'node',
    globals: true,

    // ─── Parallelization ────────────────────────────────────────────────
    pool: 'forks',
    poolOptions: {
      forks: {
        minForks: 1,
        maxForks: process.env.CI ? 2 : undefined, // auto-detect locally
      },
    },

    // ─── Coverage (V8 provider) ─────────────────────────────────────────
    coverage: {
      enabled: false, // enable via --coverage flag or test:coverage script
      provider: 'v8',
      reporter: ['text', 'text-summary', 'lcov', 'json-summary', 'html'],
      reportsDirectory: './coverage',
      include: ['orchestrator/**/*.ts', 'skills/**/*.ts', 'src/**/*.ts'],
      exclude: [
        'orchestrator/**/*.test.ts',
        'orchestrator/executor.ts.bak',
        'orchestrator/index.ts',
        'orchestrator/cil-cli.ts',
        'skills/**/*.test.ts',
        'src/**/*.test.ts',
        'src/**/*.spec.ts',
        '**/*.d.ts',
      ],
      thresholds: {
        lines: 50,
        branches: 45,
        functions: 50,
        statements: 50,
      },
    },

    // ─── Timeouts ───────────────────────────────────────────────────────
    testTimeout: 15000,
    hookTimeout: 10000,

    // ─── Reporter ───────────────────────────────────────────────────────
    reporter: process.env.CI ? ['verbose', 'junit'] : ['verbose'],
    outputFile: process.env.CI
      ? { junit: './test-results/junit.xml' }
      : undefined,
  },

  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
});
