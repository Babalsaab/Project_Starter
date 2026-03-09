/**
 * Environment Auto-Detection for Vibecoded Orchestrator
 *
 * Automatically detects:
 *   1. Which AI coding tool is running (Claude Code, Cursor, Antigravity, etc.)
 *   2. Whether this is cloned into an existing project or standalone
 *   3. Project characteristics (language, framework, package manager)
 *
 * Runs on first invocation and caches results. Configures integrations
 * and adapts behavior based on the detected environment.
 */

import * as fs from "fs";
import * as path from "path";
import { execSync } from "child_process";

// ─── Types ───────────────────────────────────────────────────────────────────

export type AITool =
  | "claude-code"
  | "cursor"
  | "antigravity"
  | "windsurf"
  | "aider"
  | "opencode"
  | "gemini-cli"
  | "copilot"
  | "junie"
  | "unknown";

export type ProjectContext =
  | "standalone"      // Orchestrator is its own project
  | "cloned-into"     // Orchestrator was cloned/installed into an existing project
  | "monorepo-child"; // Inside a monorepo as a subdirectory

export interface DetectedFramework {
  name: string;
  version?: string;
  configFile: string;
}

export interface DetectedLanguage {
  name: string;
  percentage?: number; // rough % of codebase
}

export interface ProjectInfo {
  name?: string;
  version?: string;
  description?: string;
  packageManager: "npm" | "yarn" | "pnpm" | "bun" | "unknown";
  languages: DetectedLanguage[];
  frameworks: DetectedFramework[];
  hasTests: boolean;
  hasCI: boolean;
  hasDocs: boolean;
  rootPath: string;
}

export interface EnvironmentReport {
  aiTool: AITool;
  aiToolVersion?: string;
  projectContext: ProjectContext;
  projectInfo: ProjectInfo;
  orchestratorPath: string;
  timestamp: string;
  recommendations: string[];
}

// ─── Orchestrator Root Detection ─────────────────────────────────────────────

/** Find the orchestrator's own root (where package.json with "vibecoded-orchestrator" lives) */
function findOrchestratorRoot(): string {
  let dir = __dirname;
  for (let i = 0; i < 10; i++) {
    const pkgPath = path.join(dir, "package.json");
    if (fs.existsSync(pkgPath)) {
      try {
        const pkg = JSON.parse(fs.readFileSync(pkgPath, "utf-8"));
        if (pkg.name === "vibecoded-orchestrator") return dir;
      } catch { /* skip */ }
    }
    const parent = path.dirname(dir);
    if (parent === dir) break;
    dir = parent;
  }
  return process.cwd();
}

// ─── AI Tool Detection ───────────────────────────────────────────────────────

function commandExists(cmd: string): boolean {
  try {
    execSync(`which ${cmd} 2>/dev/null || where ${cmd} 2>NUL`, {
      stdio: "pipe",
      timeout: 3000,
    });
    return true;
  } catch {
    return false;
  }
}

function getCommandVersion(cmd: string): string | undefined {
  try {
    return execSync(`${cmd} --version 2>/dev/null`, {
      stdio: "pipe",
      timeout: 3000,
    })
      .toString()
      .trim()
      .split("\n")[0];
  } catch {
    return undefined;
  }
}

/**
 * Detect which AI coding tool is currently running.
 * Uses environment variables, process info, and filesystem markers.
 */
function detectAITool(): { tool: AITool; version?: string } {
  const home = process.env["HOME"] || process.env["USERPROFILE"] || "";

  // 1. Check environment variables set by specific tools
  if (process.env["CLAUDE_CODE"] || process.env["CLAUDE_CONTEXT"]) {
    return { tool: "claude-code", version: getCommandVersion("claude") };
  }

  if (process.env["CURSOR_SESSION"] || process.env["CURSOR_TRACE_ID"]) {
    return { tool: "cursor" };
  }

  if (process.env["ANTIGRAVITY_SESSION"] || process.env["ANTIGRAVITY_HOME"]) {
    return { tool: "antigravity", version: getCommandVersion("antigravity") };
  }

  if (process.env["WINDSURF_SESSION"] || process.env["CODEIUM_SESSION"]) {
    return { tool: "windsurf" };
  }

  if (process.env["AIDER_MODEL"] || process.env["AIDER_CHAT_HISTORY_FILE"]) {
    return { tool: "aider", version: getCommandVersion("aider") };
  }

  if (process.env["GEMINI_CLI"]) {
    return { tool: "gemini-cli", version: getCommandVersion("gemini") };
  }

  if (process.env["GITHUB_COPILOT_AGENT"] || process.env["COPILOT_AGENT_SESSION"]) {
    return { tool: "copilot" };
  }

  if (process.env["JUNIE_SESSION"]) {
    return { tool: "junie" };
  }

  // 2. Check parent process name (works when spawned by a tool)
  try {
    const ppid = process.ppid;
    if (ppid) {
      const parentCmd = execSync(`ps -p ${ppid} -o comm= 2>/dev/null`, {
        stdio: "pipe",
        timeout: 2000,
      })
        .toString()
        .trim()
        .toLowerCase();

      if (parentCmd.includes("claude")) return { tool: "claude-code" };
      if (parentCmd.includes("cursor")) return { tool: "cursor" };
      if (parentCmd.includes("antigravity")) return { tool: "antigravity" };
      if (parentCmd.includes("windsurf") || parentCmd.includes("codeium"))
        return { tool: "windsurf" };
      if (parentCmd.includes("aider")) return { tool: "aider" };
    }
  } catch { /* not available on all platforms */ }

  // 3. Check filesystem markers in project directory
  const cwd = process.cwd();

  if (
    fs.existsSync(path.join(cwd, ".claude")) ||
    fs.existsSync(path.join(home, ".claude"))
  ) {
    // Could be Claude Code — check if it's the active tool
    if (commandExists("claude")) {
      return { tool: "claude-code", version: getCommandVersion("claude") };
    }
  }

  if (
    fs.existsSync(path.join(cwd, ".cursor")) ||
    fs.existsSync(path.join(home, ".cursor"))
  ) {
    return { tool: "cursor" };
  }

  if (
    fs.existsSync(path.join(cwd, ".agent")) ||
    fs.existsSync(path.join(home, ".antigravity"))
  ) {
    return { tool: "antigravity" };
  }

  if (fs.existsSync(path.join(cwd, ".windsurfrules"))) {
    return { tool: "windsurf" };
  }

  if (fs.existsSync(path.join(cwd, ".aider.conf.yml"))) {
    return { tool: "aider" };
  }

  if (
    fs.existsSync(path.join(cwd, ".opencode")) ||
    fs.existsSync(path.join(home, ".config", "opencode"))
  ) {
    return { tool: "opencode" };
  }

  if (
    fs.existsSync(path.join(home, ".gemini")) ||
    commandExists("gemini")
  ) {
    return { tool: "gemini-cli" };
  }

  return { tool: "unknown" };
}

// ─── Project Context Detection ───────────────────────────────────────────────

/**
 * Determine if the orchestrator is standalone, cloned into a project, or in a monorepo.
 */
function detectProjectContext(orchestratorRoot: string): {
  context: ProjectContext;
  hostProjectRoot?: string;
} {
  const cwd = process.cwd();
  const cwdNormalized = path.resolve(cwd);
  const orchNormalized = path.resolve(orchestratorRoot);

  // If CWD is the orchestrator root → standalone
  if (cwdNormalized === orchNormalized) {
    // But check if parent has its own package.json (monorepo child)
    const parentPkg = path.join(path.dirname(orchNormalized), "package.json");
    if (fs.existsSync(parentPkg)) {
      try {
        const pkg = JSON.parse(fs.readFileSync(parentPkg, "utf-8"));
        if (pkg.workspaces || pkg.name) {
          return {
            context: "monorepo-child",
            hostProjectRoot: path.dirname(orchNormalized),
          };
        }
      } catch { /* skip */ }
    }
    return { context: "standalone" };
  }

  // If orchestrator is a subdirectory of CWD → cloned into existing project
  if (orchNormalized.startsWith(cwdNormalized)) {
    return { context: "cloned-into", hostProjectRoot: cwdNormalized };
  }

  // If CWD is inside the orchestrator → standalone (user cd'd into a subdir)
  if (cwdNormalized.startsWith(orchNormalized)) {
    return { context: "standalone" };
  }

  // Default: check if there's a host project above orchestrator
  const parentDir = path.dirname(orchNormalized);
  if (
    fs.existsSync(path.join(parentDir, "package.json")) ||
    fs.existsSync(path.join(parentDir, "Cargo.toml")) ||
    fs.existsSync(path.join(parentDir, "go.mod")) ||
    fs.existsSync(path.join(parentDir, "pyproject.toml")) ||
    fs.existsSync(path.join(parentDir, "pom.xml"))
  ) {
    return { context: "cloned-into", hostProjectRoot: parentDir };
  }

  return { context: "standalone" };
}

// ─── Project Info Scanner ────────────────────────────────────────────────────

function detectPackageManager(projectRoot: string): ProjectInfo["packageManager"] {
  if (fs.existsSync(path.join(projectRoot, "bun.lockb")) ||
      fs.existsSync(path.join(projectRoot, "bun.lock")))
    return "bun";
  if (fs.existsSync(path.join(projectRoot, "pnpm-lock.yaml")))
    return "pnpm";
  if (fs.existsSync(path.join(projectRoot, "yarn.lock")))
    return "yarn";
  if (fs.existsSync(path.join(projectRoot, "package-lock.json")))
    return "npm";
  if (fs.existsSync(path.join(projectRoot, "package.json")))
    return "npm";
  return "unknown";
}

function detectLanguages(projectRoot: string): DetectedLanguage[] {
  const langs: DetectedLanguage[] = [];
  const checks: Array<{
    name: string;
    markers: string[];
  }> = [
    { name: "TypeScript", markers: ["tsconfig.json", "tsconfig.*.json"] },
    { name: "JavaScript", markers: ["package.json", "jsconfig.json"] },
    { name: "Python", markers: ["pyproject.toml", "setup.py", "requirements.txt", "Pipfile"] },
    { name: "Rust", markers: ["Cargo.toml"] },
    { name: "Go", markers: ["go.mod"] },
    { name: "Java", markers: ["pom.xml", "build.gradle", "build.gradle.kts"] },
    { name: "Ruby", markers: ["Gemfile"] },
    { name: "PHP", markers: ["composer.json"] },
    { name: "Swift", markers: ["Package.swift", "*.xcodeproj"] },
    { name: "Kotlin", markers: ["build.gradle.kts"] },
    { name: "C#", markers: ["*.csproj", "*.sln"] },
  ];

  for (const check of checks) {
    for (const marker of check.markers) {
      if (marker.includes("*")) {
        // Glob-like check — just check if any matching file exists
        try {
          const dir = fs.readdirSync(projectRoot);
          const pattern = marker.replace("*", "");
          if (dir.some((f) => f.endsWith(pattern))) {
            langs.push({ name: check.name });
            break;
          }
        } catch { /* skip */ }
      } else if (fs.existsSync(path.join(projectRoot, marker))) {
        langs.push({ name: check.name });
        break;
      }
    }
  }

  return langs;
}

function detectFrameworks(projectRoot: string): DetectedFramework[] {
  const frameworks: DetectedFramework[] = [];
  const pkgPath = path.join(projectRoot, "package.json");

  if (fs.existsSync(pkgPath)) {
    try {
      const pkg = JSON.parse(fs.readFileSync(pkgPath, "utf-8"));
      const allDeps = {
        ...(pkg.dependencies || {}),
        ...(pkg.devDependencies || {}),
      };

      const frameworkChecks: Array<{
        name: string;
        dep: string;
        configFiles: string[];
      }> = [
        { name: "Next.js", dep: "next", configFiles: ["next.config.js", "next.config.mjs", "next.config.ts"] },
        { name: "React", dep: "react", configFiles: [] },
        { name: "Vue", dep: "vue", configFiles: ["vue.config.js", "nuxt.config.ts"] },
        { name: "Angular", dep: "@angular/core", configFiles: ["angular.json"] },
        { name: "Svelte", dep: "svelte", configFiles: ["svelte.config.js"] },
        { name: "Express", dep: "express", configFiles: [] },
        { name: "Fastify", dep: "fastify", configFiles: [] },
        { name: "NestJS", dep: "@nestjs/core", configFiles: ["nest-cli.json"] },
        { name: "Prisma", dep: "@prisma/client", configFiles: ["prisma/schema.prisma"] },
        { name: "Tailwind CSS", dep: "tailwindcss", configFiles: ["tailwind.config.ts", "tailwind.config.js"] },
        { name: "Vite", dep: "vite", configFiles: ["vite.config.ts", "vite.config.js"] },
        { name: "Storybook", dep: "storybook", configFiles: [".storybook/main.ts", ".storybook/main.js"] },
        { name: "Playwright", dep: "@playwright/test", configFiles: ["playwright.config.ts"] },
        { name: "Vitest", dep: "vitest", configFiles: ["vitest.config.ts"] },
      ];

      for (const check of frameworkChecks) {
        if (allDeps[check.dep]) {
          const configFile =
            check.configFiles.find((f) =>
              fs.existsSync(path.join(projectRoot, f))
            ) || check.dep;
          frameworks.push({
            name: check.name,
            version: allDeps[check.dep],
            configFile,
          });
        }
      }
    } catch { /* skip */ }
  }

  // Non-JS frameworks
  const otherChecks: Array<{ name: string; marker: string }> = [
    { name: "Django", marker: "manage.py" },
    { name: "Flask", marker: "app.py" },
    { name: "Rails", marker: "Gemfile" },
    { name: "Spring Boot", marker: "src/main/java" },
    { name: "Laravel", marker: "artisan" },
  ];

  for (const check of otherChecks) {
    if (fs.existsSync(path.join(projectRoot, check.marker))) {
      frameworks.push({ name: check.name, configFile: check.marker });
    }
  }

  return frameworks;
}

function scanProjectInfo(projectRoot: string): ProjectInfo {
  let name: string | undefined;
  let version: string | undefined;
  let description: string | undefined;

  const pkgPath = path.join(projectRoot, "package.json");
  if (fs.existsSync(pkgPath)) {
    try {
      const pkg = JSON.parse(fs.readFileSync(pkgPath, "utf-8"));
      name = pkg.name;
      version = pkg.version;
      description = pkg.description;
    } catch { /* skip */ }
  }

  return {
    name,
    version,
    description,
    packageManager: detectPackageManager(projectRoot),
    languages: detectLanguages(projectRoot),
    frameworks: detectFrameworks(projectRoot),
    hasTests:
      fs.existsSync(path.join(projectRoot, "__tests__")) ||
      fs.existsSync(path.join(projectRoot, "tests")) ||
      fs.existsSync(path.join(projectRoot, "test")) ||
      fs.existsSync(path.join(projectRoot, "spec")) ||
      fs.existsSync(path.join(projectRoot, "vitest.config.ts")) ||
      fs.existsSync(path.join(projectRoot, "jest.config.ts")),
    hasCI:
      fs.existsSync(path.join(projectRoot, ".github", "workflows")) ||
      fs.existsSync(path.join(projectRoot, ".gitlab-ci.yml")) ||
      fs.existsSync(path.join(projectRoot, "Jenkinsfile")) ||
      fs.existsSync(path.join(projectRoot, ".circleci")),
    hasDocs:
      fs.existsSync(path.join(projectRoot, "docs")) ||
      fs.existsSync(path.join(projectRoot, "documentation")),
    rootPath: projectRoot,
  };
}

// ─── Recommendations Engine ─────────────────────────────────────────────────

function generateRecommendations(
  aiTool: AITool,
  context: ProjectContext,
  projectInfo: ProjectInfo,
  orchestratorRoot: string
): string[] {
  const recs: string[] = [];

  // Tool-specific recommendations
  switch (aiTool) {
    case "cursor":
      if (!fs.existsSync(path.join(projectInfo.rootPath, ".cursor", "rules"))) {
        recs.push(
          "Run `npm run convert:cursor` to generate Cursor rule files for all 74 agents"
        );
      }
      break;
    case "antigravity":
      if (!fs.existsSync(path.join(projectInfo.rootPath, ".agent"))) {
        recs.push(
          "Run `npm run convert -- --format antigravity` to generate .agent/ skill files"
        );
      }
      break;
    case "gemini-cli":
      recs.push(
        "Run `npm run convert:gemini` to generate Gemini CLI extension files"
      );
      break;
    case "windsurf":
      if (!fs.existsSync(path.join(projectInfo.rootPath, ".windsurfrules"))) {
        recs.push(
          "Run `npm run convert -- --format windsurf` to generate .windsurfrules"
        );
      }
      break;
    case "aider":
      if (!fs.existsSync(path.join(projectInfo.rootPath, "CONVENTIONS.md"))) {
        recs.push(
          "Run `npm run convert -- --format aider` to generate CONVENTIONS.md for Aider"
        );
      }
      break;
    case "claude-code":
      // Already native — just ensure MCP server is configured
      recs.push(
        "Ensure MCP server is registered: check .claude/mcp.json for orchestrator tools"
      );
      break;
  }

  // Context-specific recommendations
  if (context === "cloned-into") {
    recs.push(
      "Detected existing project — orchestrator will adapt agents to your project's stack"
    );
    if (projectInfo.frameworks.length > 0) {
      const stacks = projectInfo.frameworks.map((f) => f.name).join(", ");
      recs.push(
        `Detected frameworks: ${stacks} — relevant specialist agents will be prioritized`
      );
    }
    recs.push(
      "Run `npm run orchestrator` to start a discovery session tailored to your existing project"
    );
  } else if (context === "standalone") {
    recs.push(
      "Standalone mode — run `npm run orchestrator` to start a new project from scratch"
    );
  } else if (context === "monorepo-child") {
    recs.push(
      "Monorepo detected — orchestrator will scope to this workspace package"
    );
  }

  // Missing infrastructure recommendations
  if (!projectInfo.hasTests) {
    recs.push(
      "No test directory detected — consider running the QA Engineer agent to set up testing"
    );
  }
  if (!projectInfo.hasCI) {
    recs.push(
      "No CI/CD detected — consider running the DevOps Engineer agent to set up pipelines"
    );
  }

  return recs;
}

// ─── Auto-Configure Integrations ─────────────────────────────────────────────

/**
 * Auto-configure the detected tool's integration files if they don't exist.
 * Only runs the conversion for the detected tool, not all 7.
 */
function autoConfigureForTool(
  aiTool: AITool,
  orchestratorRoot: string,
  projectRoot: string
): boolean {
  if (aiTool === "unknown" || aiTool === "claude-code") return false;

  const formatMap: Partial<Record<AITool, string>> = {
    cursor: "cursor",
    antigravity: "antigravity",
    windsurf: "windsurf",
    aider: "aider",
    opencode: "opencode",
    "gemini-cli": "gemini-cli",
  };

  const format = formatMap[aiTool];
  if (!format) return false;

  const convertScript = path.join(orchestratorRoot, "scripts", "convert.sh");
  if (!fs.existsSync(convertScript)) return false;

  // Check if integration files already exist
  const integrationDir = path.join(orchestratorRoot, "integrations", format);
  if (fs.existsSync(integrationDir)) {
    const files = fs.readdirSync(integrationDir);
    if (files.length > 10) return false; // Already converted
  }

  try {
    console.log(`  ⚙ Auto-configuring integrations for ${aiTool}...`);
    execSync(`bash "${convertScript}" --format ${format}`, {
      cwd: orchestratorRoot,
      stdio: "pipe",
      timeout: 30000,
    });
    console.log(`  ✓ ${aiTool} integration files generated`);
    return true;
  } catch {
    console.warn(`  ⚠ Could not auto-generate ${aiTool} integration files`);
    return false;
  }
}

// ─── Cache ───────────────────────────────────────────────────────────────────

const CACHE_FILE = ".env-detect-cache.json";
const CACHE_TTL_MS = 24 * 60 * 60 * 1000; // 24 hours

function loadCache(orchestratorRoot: string): EnvironmentReport | null {
  const cachePath = path.join(orchestratorRoot, "runs", CACHE_FILE);
  if (!fs.existsSync(cachePath)) return null;

  try {
    const data = JSON.parse(fs.readFileSync(cachePath, "utf-8"));
    const age = Date.now() - new Date(data.timestamp).getTime();
    if (age < CACHE_TTL_MS) return data as EnvironmentReport;
  } catch { /* stale or corrupt */ }

  return null;
}

function saveCache(
  orchestratorRoot: string,
  report: EnvironmentReport
): void {
  const runsDir = path.join(orchestratorRoot, "runs");
  if (!fs.existsSync(runsDir)) fs.mkdirSync(runsDir, { recursive: true });

  const cachePath = path.join(runsDir, CACHE_FILE);
  fs.writeFileSync(cachePath, JSON.stringify(report, null, 2));
}

// ─── Public API ──────────────────────────────────────────────────────────────

/**
 * Run full environment detection. Results are cached for 24 hours.
 * Pass `force: true` to bypass the cache.
 */
export async function detectEnvironment(options?: {
  force?: boolean;
  silent?: boolean;
  autoConfig?: boolean;
}): Promise<EnvironmentReport> {
  const orchestratorRoot = findOrchestratorRoot();

  // Check cache first
  if (!options?.force) {
    const cached = loadCache(orchestratorRoot);
    if (cached) return cached;
  }

  // Detect AI tool
  const { tool: aiTool, version: aiToolVersion } = detectAITool();

  // Detect project context
  const { context: projectContext, hostProjectRoot } =
    detectProjectContext(orchestratorRoot);

  // Scan the appropriate project root
  const scanRoot =
    projectContext === "cloned-into" && hostProjectRoot
      ? hostProjectRoot
      : orchestratorRoot;

  const projectInfo = scanProjectInfo(scanRoot);

  // Generate recommendations
  const recommendations = generateRecommendations(
    aiTool,
    projectContext,
    projectInfo,
    orchestratorRoot
  );

  const report: EnvironmentReport = {
    aiTool,
    aiToolVersion,
    projectContext,
    projectInfo,
    orchestratorPath: orchestratorRoot,
    timestamp: new Date().toISOString(),
    recommendations,
  };

  // Auto-configure integrations for detected tool
  if (options?.autoConfig !== false) {
    autoConfigureForTool(aiTool, orchestratorRoot, scanRoot);
  }

  // Print summary unless silent
  if (!options?.silent) {
    printDetectionSummary(report);
  }

  // Cache results
  saveCache(orchestratorRoot, report);

  return report;
}

/**
 * Print a concise summary of the detected environment.
 */
function printDetectionSummary(report: EnvironmentReport): void {
  const toolNames: Record<AITool, string> = {
    "claude-code": "Claude Code",
    cursor: "Cursor",
    antigravity: "AntiGravity",
    windsurf: "Windsurf",
    aider: "Aider",
    opencode: "OpenCode",
    "gemini-cli": "Gemini CLI",
    copilot: "GitHub Copilot",
    junie: "JetBrains Junie",
    unknown: "Unknown",
  };

  const contextLabels: Record<ProjectContext, string> = {
    standalone: "Standalone orchestrator project",
    "cloned-into": "Cloned into existing project",
    "monorepo-child": "Monorepo workspace child",
  };

  console.log(`  🔍 Environment Detection`);
  console.log(
    `     AI Tool:  ${toolNames[report.aiTool]}${report.aiToolVersion ? ` (${report.aiToolVersion})` : ""}`
  );
  console.log(`     Context:  ${contextLabels[report.projectContext]}`);

  if (report.projectInfo.name) {
    console.log(`     Project:  ${report.projectInfo.name}${report.projectInfo.version ? ` v${report.projectInfo.version}` : ""}`);
  }

  if (report.projectInfo.languages.length > 0) {
    console.log(
      `     Stack:    ${report.projectInfo.languages.map((l) => l.name).join(", ")}`
    );
  }

  if (report.projectInfo.frameworks.length > 0) {
    console.log(
      `     Frameworks: ${report.projectInfo.frameworks.map((f) => f.name).join(", ")}`
    );
  }

  console.log(
    `     Pkg Mgr: ${report.projectInfo.packageManager}`
  );

  if (report.recommendations.length > 0) {
    console.log(`\n  💡 Recommendations:`);
    for (const rec of report.recommendations.slice(0, 5)) {
      console.log(`     • ${rec}`);
    }
  }

  console.log("");
}

/**
 * Get a previously cached detection result, or run detection if none exists.
 */
export async function getEnvironment(): Promise<EnvironmentReport> {
  return detectEnvironment({ silent: true, autoConfig: false });
}

/**
 * Quick check — returns just the AI tool name without full scan.
 */
export function detectAIToolQuick(): AITool {
  return detectAITool().tool;
}

/**
 * Quick check — returns project context without full scan.
 */
export function detectProjectContextQuick(): ProjectContext {
  const orchestratorRoot = findOrchestratorRoot();
  return detectProjectContext(orchestratorRoot).context;
}
