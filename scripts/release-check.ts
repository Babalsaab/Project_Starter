#!/usr/bin/env ts-node
/**
 * Release Check Script
 *
 * Pre-release verification checklist. Ensures the project is in a releasable
 * state before tagging a version.
 *
 * Usage: npx ts-node scripts/release-check.ts
 */

import * as fs from "fs";
import * as path from "path";
import { execSync } from "child_process";

// ─── Types ────────────────────────────────────────────────────────────────────

interface CheckResult {
  name: string;
  passed: boolean;
  detail: string;
}

// ─── Checks ───────────────────────────────────────────────────────────────────

function checkChangelog(): CheckResult {
  const changelogPath = path.join(__dirname, "../CHANGELOG.md");
  if (!fs.existsSync(changelogPath)) {
    return { name: "CHANGELOG.md exists", passed: false, detail: "File not found" };
  }
  const content = fs.readFileSync(changelogPath, "utf-8");
  const hasUnreleased = content.includes("## [Unreleased]");
  if (!hasUnreleased) {
    return { name: "CHANGELOG has [Unreleased]", passed: false, detail: "No [Unreleased] section found" };
  }
  // Check that there's content under Unreleased
  const unreleased = content.split("## [Unreleased]")[1]?.split("## [")[0] ?? "";
  const hasContent = unreleased.trim().length > 50;
  return {
    name: "CHANGELOG has unreleased content",
    passed: hasContent,
    detail: hasContent ? "Content present" : "Unreleased section appears empty",
  };
}

function checkPackageVersion(): CheckResult {
  const pkgPath = path.join(__dirname, "../package.json");
  const pkg = JSON.parse(fs.readFileSync(pkgPath, "utf-8"));
  const version = pkg.version || "0.0.0";
  const isValid = /^\d+\.\d+\.\d+(-[\w.]+)?$/.test(version);
  return {
    name: "package.json version is valid semver",
    passed: isValid,
    detail: `Version: ${version}`,
  };
}

function checkTypeScript(): CheckResult {
  try {
    execSync("npx tsc --noEmit -p tsconfig.orchestrator.json", { stdio: "pipe" });
    return { name: "TypeScript compiles clean", passed: true, detail: "No errors" };
  } catch (e: any) {
    const stderr = e.stderr?.toString() || "Compilation failed";
    const errorCount = (stderr.match(/error TS/g) || []).length;
    return {
      name: "TypeScript compiles clean",
      passed: false,
      detail: `${errorCount} error(s) found`,
    };
  }
}

function checkTests(): CheckResult {
  try {
    execSync("npx vitest run --reporter=json", { stdio: "pipe" });
    return { name: "All tests pass", passed: true, detail: "Tests passed" };
  } catch (e: any) {
    return { name: "All tests pass", passed: false, detail: "Test failures detected" };
  }
}

function checkGitStatus(): CheckResult {
  try {
    const status = execSync("git status --porcelain", { encoding: "utf-8" }).trim();
    const isClean = status.length === 0;
    return {
      name: "Git working directory is clean",
      passed: isClean,
      detail: isClean ? "No uncommitted changes" : `${status.split("\n").length} file(s) modified`,
    };
  } catch {
    return { name: "Git working directory is clean", passed: false, detail: "Not a git repo" };
  }
}

function checkSecurityAudit(): CheckResult {
  try {
    execSync("npm audit --audit-level=critical", { stdio: "pipe" });
    return { name: "No critical npm vulnerabilities", passed: true, detail: "Audit clean" };
  } catch {
    return {
      name: "No critical npm vulnerabilities",
      passed: false,
      detail: "Critical vulnerabilities found — run 'npm audit' for details",
    };
  }
}

function checkRequiredFiles(): CheckResult {
  const required = [
    "README.md",
    "CHANGELOG.md",
    "SECURITY.md",
    "AGENTS.md",
    "LICENSE",
    "package.json",
    "package-lock.json",
  ];
  const missing = required.filter(
    (f) => !fs.existsSync(path.join(__dirname, "..", f))
  );
  return {
    name: "Required files present",
    passed: missing.length === 0,
    detail: missing.length === 0 ? "All present" : `Missing: ${missing.join(", ")}`,
  };
}

function checkAgentValidation(): CheckResult {
  try {
    execSync("npx ts-node scripts/validate-agents.ts", { stdio: "pipe", cwd: path.join(__dirname, "..") });
    return { name: "Agent YAML validation", passed: true, detail: "All agents valid" };
  } catch {
    return { name: "Agent YAML validation", passed: false, detail: "Validation errors found" };
  }
}

// ─── Runner ───────────────────────────────────────────────────────────────────

function main(): void {
  console.log("🔍 Release Readiness Check\n");
  console.log("─".repeat(60));

  const checks: CheckResult[] = [
    checkRequiredFiles(),
    checkPackageVersion(),
    checkChangelog(),
    checkTypeScript(),
    checkTests(),
    checkGitStatus(),
    checkSecurityAudit(),
    checkAgentValidation(),
  ];

  let allPassed = true;
  for (const check of checks) {
    const icon = check.passed ? "✅" : "❌";
    console.log(`${icon} ${check.name}`);
    console.log(`   ${check.detail}`);
    if (!check.passed) allPassed = false;
  }

  console.log("\n" + "─".repeat(60));

  if (allPassed) {
    console.log("✅ All checks passed — ready to release!\n");
    console.log("Next steps:");
    console.log("  1. Update CHANGELOG.md — move [Unreleased] to version header");
    console.log("  2. Bump version: npm version <major|minor|patch>");
    console.log("  3. Push tag: git push --follow-tags");
    process.exit(0);
  } else {
    const failCount = checks.filter((c) => !c.passed).length;
    console.log(`❌ ${failCount} check(s) failed — fix before releasing.\n`);
    process.exit(1);
  }
}

main();
