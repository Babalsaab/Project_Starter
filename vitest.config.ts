import { defineConfig } from "vitest/config";
import path from "path";

export default defineConfig({
  test: {
    // ─── Test Discovery ─────────────────────────────────────────────────
    include: [
      "orchestrator/**/*.test.ts",
      "scripts/**/*.test.ts",
      "skills/**/*.test.ts",
    ],
    exclude: ["node_modules", "dist", ".next", "runs"],

    // ─── Environment ────────────────────────────────────────────────────
    environment: "node",
    globals: true,

    // ─── Coverage (V8 provider) ─────────────────────────────────────────
    coverage: {
      provider: "v8",
      reporter: ["text", "text-summary", "lcov", "json-summary"],
      reportsDirectory: "./coverage",
      include: [
        "orchestrator/**/*.ts",
        "skills/**/*.ts",
      ],
      exclude: [
        "orchestrator/**/*.test.ts",
        "orchestrator/executor.ts.bak",
        "skills/**/*.test.ts",
        "**/*.d.ts",
      ],
      // ── Thresholds matching OpenClaw's 70% standard ──
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
    reporter: ["verbose"],
  },

  resolve: {
    alias: {
      "@": path.resolve(__dirname, "./src"),
    },
  },
});
