#!/usr/bin/env ts-node
/**
 * check-ts-max-loc.ts — Enforce maximum lines-of-code per TypeScript file.
 *
 * Inspired by OpenClaw's scripts/check-ts-max-loc.ts.
 * Scans all .ts/.tsx files (excluding node_modules, dist, .next, generated)
 * and reports any that exceed the configured threshold.
 *
 * Usage:
 *   npx ts-node scripts/check-ts-max-loc.ts [--max 600] [--fix-hint]
 *
 * Exit code 0 = all OK, 1 = files over limit found.
 */

import * as fs from "fs";
import * as path from "path";

// ─── Config ───────────────────────────────────────────────────────────────────

const DEFAULT_MAX_LOC = 600;

const IGNORE_DIRS = new Set([
  "node_modules",
  ".next",
  "dist",
  "build",
  ".git",
  "prisma/migrations",
  "runs",
]);

const IGNORE_PATTERNS = [
  /\.d\.ts$/, // Type declaration files
  /\.generated\./,
  /\.min\./,
];

// ─── Helpers ──────────────────────────────────────────────────────────────────

function walkDir(dir: string, results: string[] = []): string[] {
  const entries = fs.readdirSync(dir, { withFileTypes: true });
  for (const entry of entries) {
    const fullPath = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (IGNORE_DIRS.has(entry.name)) continue;
      // Also skip nested ignored paths
      const relative = path.relative(process.cwd(), fullPath);
      if (
        [...IGNORE_DIRS].some((d) => relative.startsWith(d))
      )
        continue;
      walkDir(fullPath, results);
    } else if (
      entry.isFile() &&
      (entry.name.endsWith(".ts") || entry.name.endsWith(".tsx"))
    ) {
      const shouldIgnore = IGNORE_PATTERNS.some((p) => p.test(entry.name));
      if (!shouldIgnore) {
        results.push(fullPath);
      }
    }
  }
  return results;
}

function countLines(filePath: string): {
  total: number;
  code: number;
  blank: number;
  comment: number;
} {
  const content = fs.readFileSync(filePath, "utf-8");
  const lines = content.split("\n");
  let code = 0;
  let blank = 0;
  let comment = 0;
  let inBlockComment = false;

  for (const line of lines) {
    const trimmed = line.trim();

    if (inBlockComment) {
      comment++;
      if (trimmed.includes("*/")) {
        inBlockComment = false;
      }
      continue;
    }

    if (trimmed === "") {
      blank++;
    } else if (trimmed.startsWith("/*")) {
      comment++;
      if (!trimmed.includes("*/")) {
        inBlockComment = true;
      }
    } else if (trimmed.startsWith("//")) {
      comment++;
    } else {
      code++;
    }
  }

  return { total: lines.length, code, blank, comment };
}

function suggestSplitting(filePath: string, loc: number, maxLoc: number): string {
  const rel = path.relative(process.cwd(), filePath);
  const excess = loc - maxLoc;
  const suggestions = [
    `  📄 ${rel}: ${loc} lines (${excess} over limit)`,
    `     → Consider splitting into smaller modules:`,
  ];

  // Try to identify major sections
  const content = fs.readFileSync(filePath, "utf-8");
  const sectionHeaders = content
    .split("\n")
    .map((line, i) => ({ line: line.trim(), num: i + 1 }))
    .filter(
      (l) =>
        l.line.startsWith("// ─") ||
        l.line.startsWith("// ═") ||
        l.line.match(/^\/\/ [A-Z][A-Z ]+$/) ||
        l.line.match(/^export (class|function|interface|type|enum) \w+/)
    );

  if (sectionHeaders.length > 2) {
    suggestions.push(`     Detected ${sectionHeaders.length} major sections:`);
    for (const header of sectionHeaders.slice(0, 8)) {
      suggestions.push(`       L${header.num}: ${header.line.substring(0, 70)}`);
    }
    if (sectionHeaders.length > 8) {
      suggestions.push(`       ... and ${sectionHeaders.length - 8} more`);
    }
  }

  return suggestions.join("\n");
}

// ─── Main ─────────────────────────────────────────────────────────────────────

function main(): void {
  const args = process.argv.slice(2);
  let maxLoc = DEFAULT_MAX_LOC;
  let showFixHint = false;

  for (let i = 0; i < args.length; i++) {
    if (args[i] === "--max" && args[i + 1]) {
      maxLoc = parseInt(args[i + 1]!, 10);
      i++;
    } else if (args[i] === "--fix-hint") {
      showFixHint = true;
    }
  }

  console.log(`🔍 Checking TypeScript files for max ${maxLoc} LOC...\n`);

  const root = process.cwd();
  const files = walkDir(root);
  const overLimit: Array<{
    file: string;
    stats: { total: number; code: number; blank: number; comment: number };
  }> = [];
  let totalFiles = 0;
  let totalLines = 0;

  for (const file of files) {
    totalFiles++;
    const stats = countLines(file);
    totalLines += stats.total;

    if (stats.total > maxLoc) {
      overLimit.push({ file, stats });
    }
  }

  // Sort by line count desc
  overLimit.sort((a, b) => b.stats.total - a.stats.total);

  if (overLimit.length > 0) {
    console.log(`❌ ${overLimit.length} file(s) exceed ${maxLoc} lines:\n`);
    for (const { file, stats } of overLimit) {
      if (showFixHint) {
        console.log(suggestSplitting(file, stats.total, maxLoc));
      } else {
        const rel = path.relative(root, file);
        console.log(
          `  ❌ ${rel}: ${stats.total} lines (code: ${stats.code}, comments: ${stats.comment}, blank: ${stats.blank})`
        );
      }
    }
    console.log();
  }

  // Summary
  console.log("─".repeat(60));
  console.log(`Scanned: ${totalFiles} files, ${totalLines.toLocaleString()} total lines`);
  console.log(`Limit: ${maxLoc} LOC per file`);
  console.log(`Over limit: ${overLimit.length} file(s)`);

  if (overLimit.length > 0) {
    if (!showFixHint) {
      console.log(`\nRun with --fix-hint for splitting suggestions.`);
    }
    console.log();
    process.exit(1);
  } else {
    console.log(`\n✅ All files within limit!\n`);
    process.exit(0);
  }
}

main();
