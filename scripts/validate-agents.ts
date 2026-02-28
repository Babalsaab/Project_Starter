#!/usr/bin/env ts-node
/**
 * validate-agents.ts — "npm run validate"
 *
 * Validates every agent YAML in agents/pool/ and agents/chiefs/:
 * 1. Required fields present (id, title, domain, system_prompt, etc.)
 * 2. Field types correct (arrays, strings, numbers)
 * 3. Unique agent IDs (no duplicate)
 * 4. reports_to references valid chiefs
 * 5. Cross-references: expected_inputs from other agents' expected_outputs
 * 6. Persona files exist for mapped agents
 * 7. Mentor references resolve in config/mentors.yaml
 * 8. Token cap within sane bounds
 *
 * Exit code 0 = all OK, 1 = errors found.
 * Inspired by OpenClaw's validate-* scripts.
 */

import * as fs from "fs";
import * as path from "path";
import * as yaml from "js-yaml";

// ─── Types ────────────────────────────────────────────────────────────────────

interface AgentYaml {
  id?: string;
  title?: string;
  domain?: string;
  tier?: string;
  reports_to?: string | null;
  responsibilities?: string[];
  expected_inputs?: string[];
  expected_outputs?: string[];
  token_cap?: number;
  system_prompt?: string;
  mentors?: {
    primary?: string[];
    secondary?: string[];
  };
  mentor_lens?: string;
  delegates_to?: string[];
  [key: string]: unknown;
}

interface ValidationError {
  file: string;
  agentId: string;
  severity: "error" | "warning";
  message: string;
}

// ─── Config ───────────────────────────────────────────────────────────────────

const ROOT = path.resolve(__dirname, "..");
const POOL_DIRS = [
  path.join(ROOT, "agents/pool/tech"),
  path.join(ROOT, "agents/pool/marketing"),
];
const CHIEFS_DIR = path.join(ROOT, "agents/chiefs");
const PERSONAS_DIR = path.join(ROOT, "agents/personas");
const MENTORS_PATH = path.join(ROOT, "config/mentors.yaml");

const VALID_CHIEFS = ["CEO", "CTO", "CMO", "COO"];
const REQUIRED_FIELDS_POOL = ["id", "title", "domain", "system_prompt"];
const REQUIRED_FIELDS_CHIEF = ["id", "title", "domain", "system_prompt"];
const TOKEN_CAP_MIN = 100;
const TOKEN_CAP_MAX = 32_000;

// ─── Helpers ──────────────────────────────────────────────────────────────────

function loadYamlFiles(dir: string): Array<{ filepath: string; data: AgentYaml }> {
  if (!fs.existsSync(dir)) return [];
  return fs
    .readdirSync(dir)
    .filter((f) => f.endsWith(".yaml") || f.endsWith(".yml"))
    .map((f) => {
      const filepath = path.join(dir, f);
      try {
        const data = yaml.load(fs.readFileSync(filepath, "utf-8")) as AgentYaml;
        return { filepath, data };
      } catch (e) {
        return {
          filepath,
          data: { _parseError: (e as Error).message } as unknown as AgentYaml,
        };
      }
    });
}

function getPersonaFiles(): Set<string> {
  if (!fs.existsSync(PERSONAS_DIR)) return new Set();
  return new Set(
    fs
      .readdirSync(PERSONAS_DIR)
      .filter((f) => f.endsWith(".md"))
      .map((f) => f.replace(/\.md$/, "").toLowerCase())
  );
}

function loadMentorNames(): Set<string> {
  if (!fs.existsSync(MENTORS_PATH)) return new Set();
  try {
    const raw = yaml.load(fs.readFileSync(MENTORS_PATH, "utf-8")) as any;
    if (!raw?.mentors) return new Set();
    const names = new Set<string>();
    for (const key of Object.keys(raw.mentors)) {
      const mentor = raw.mentors[key];
      if (mentor?.name) names.add(mentor.name);
      names.add(key);
    }
    return names;
  } catch {
    return new Set();
  }
}

// ─── Validation Engine ───────────────────────────────────────────────────────

function validate(): ValidationError[] {
  const errors: ValidationError[] = [];
  const allAgents = new Map<string, string>(); // id → filepath
  const allOutputs = new Set<string>(); // all expected_outputs across agents
  const personaFiles = getPersonaFiles();
  const mentorNames = loadMentorNames();

  // Load all files
  const chiefFiles = loadYamlFiles(CHIEFS_DIR);
  const poolFiles: Array<{ filepath: string; data: AgentYaml }> = [];
  for (const dir of POOL_DIRS) {
    poolFiles.push(...loadYamlFiles(dir));
  }
  const allFiles = [...chiefFiles, ...poolFiles];

  // Pass 1: Structural validation
  for (const { filepath, data } of allFiles) {
    const relPath = path.relative(ROOT, filepath);
    const agentId = data.id || path.basename(filepath, path.extname(filepath));
    const isChief = filepath.startsWith(CHIEFS_DIR);

    // Parse error
    if ((data as any)._parseError) {
      errors.push({
        file: relPath,
        agentId,
        severity: "error",
        message: `YAML parse error: ${(data as any)._parseError}`,
      });
      continue;
    }

    // Check required fields
    const requiredFields = isChief ? REQUIRED_FIELDS_CHIEF : REQUIRED_FIELDS_POOL;
    for (const field of requiredFields) {
      if (!data[field]) {
        errors.push({
          file: relPath,
          agentId,
          severity: "error",
          message: `Missing required field: ${field}`,
        });
      }
    }

    // Pool agents need expected_inputs and expected_outputs
    if (!isChief) {
      if (!data.expected_inputs || !Array.isArray(data.expected_inputs)) {
        errors.push({
          file: relPath,
          agentId,
          severity: "warning",
          message: `Missing or invalid expected_inputs (should be string[])`,
        });
      }
      if (!data.expected_outputs || !Array.isArray(data.expected_outputs)) {
        errors.push({
          file: relPath,
          agentId,
          severity: "warning",
          message: `Missing or invalid expected_outputs (should be string[])`,
        });
      } else {
        for (const o of data.expected_outputs) allOutputs.add(o);
      }
    }

    // Duplicate ID check
    if (data.id) {
      if (allAgents.has(data.id)) {
        errors.push({
          file: relPath,
          agentId,
          severity: "error",
          message: `Duplicate agent ID "${data.id}" (also in ${allAgents.get(data.id)})`,
        });
      } else {
        allAgents.set(data.id, relPath);
      }
    }

    // reports_to validation
    if (!isChief && data.reports_to) {
      if (!VALID_CHIEFS.includes(data.reports_to)) {
        errors.push({
          file: relPath,
          agentId,
          severity: "error",
          message: `Invalid reports_to "${data.reports_to}". Must be one of: ${VALID_CHIEFS.join(", ")}`,
        });
      }
    }

    // Token cap bounds
    if (data.token_cap !== undefined) {
      if (typeof data.token_cap !== "number") {
        errors.push({
          file: relPath,
          agentId,
          severity: "error",
          message: `token_cap must be a number, got ${typeof data.token_cap}`,
        });
      } else if (data.token_cap < TOKEN_CAP_MIN || data.token_cap > TOKEN_CAP_MAX) {
        errors.push({
          file: relPath,
          agentId,
          severity: "warning",
          message: `token_cap ${data.token_cap} outside recommended range [${TOKEN_CAP_MIN}–${TOKEN_CAP_MAX}]`,
        });
      }
    } else if (!isChief) {
      errors.push({
        file: relPath,
        agentId,
        severity: "warning",
        message: `Missing token_cap — will use default`,
      });
    }

    // Responsibilities should be an array
    if (data.responsibilities && !Array.isArray(data.responsibilities)) {
      errors.push({
        file: relPath,
        agentId,
        severity: "error",
        message: `responsibilities must be an array`,
      });
    }

    // System prompt length check
    if (data.system_prompt) {
      const promptLen = data.system_prompt.length;
      if (promptLen < 20) {
        errors.push({
          file: relPath,
          agentId,
          severity: "warning",
          message: `system_prompt is very short (${promptLen} chars) — may not provide enough context`,
        });
      }
      if (promptLen > 8000) {
        errors.push({
          file: relPath,
          agentId,
          severity: "warning",
          message: `system_prompt is very long (${promptLen} chars) — consider trimming to save tokens`,
        });
      }
    }

    // Mentor validation
    if (data.mentors) {
      const allMentorRefs = [
        ...(data.mentors.primary || []),
        ...(data.mentors.secondary || []),
      ];
      for (const mentorName of allMentorRefs) {
        const key = mentorName
          .toLowerCase()
          .replace(/[^a-z0-9]+/g, "_")
          .replace(/^_|_$/g, "");
        if (mentorNames.size > 0 && !mentorNames.has(mentorName) && !mentorNames.has(key)) {
          errors.push({
            file: relPath,
            agentId,
            severity: "warning",
            message: `Mentor "${mentorName}" not found in config/mentors.yaml`,
          });
        }
      }
    }
  }

  // Pass 2: Cross-reference validation (inputs match some agent's outputs)
  const WELL_KNOWN_INPUTS = new Set([
    "product_spec",
    "prd",
    "project_profile",
    "discovery_answers",
    "budget",
    "brand_guidelines",
    "target_audience",
    "product_requirements",
    "marketing_strategy",
    "design_system",
    "tech_stack",
  ]);

  for (const { filepath, data } of poolFiles) {
    const relPath = path.relative(ROOT, filepath);
    const agentId = data.id || path.basename(filepath, path.extname(filepath));
    if (!data.expected_inputs || (data as any)._parseError) continue;

    for (const input of data.expected_inputs) {
      if (!allOutputs.has(input) && !WELL_KNOWN_INPUTS.has(input)) {
        errors.push({
          file: relPath,
          agentId,
          severity: "warning",
          message: `expected_input "${input}" is not produced by any agent's expected_outputs`,
        });
      }
    }
  }

  // Pass 3: Persona file existence check (using CLAUDE.md mapping)
  const PERSONA_AGENT_MAP: Record<string, string[]> = {
    "sarah-chen-ux-ui-designer": ["ux_designer", "ui_designer"],
    "marcus-rodriguez-backend": ["backend_engineer", "api_designer"],
    "jordan-park-frontend": ["web_frontend_engineer", "design_engineer"],
    "rachel-thompson-security": ["security_engineer"],
    "alex-kim-devops": ["devops_engineer", "release_engineer"],
    "anna-kim-accessibility": ["accessibility_engineer"],
    "carlos-martinez-performance-fixed": ["frontend_performance_engineer"],
  };

  for (const [personaFile, agentIds] of Object.entries(PERSONA_AGENT_MAP)) {
    if (!personaFiles.has(personaFile)) {
      for (const agentId of agentIds) {
        if (allAgents.has(agentId)) {
          errors.push({
            file: `agents/personas/${personaFile}.md`,
            agentId,
            severity: "warning",
            message: `Persona file missing for agent "${agentId}"`,
          });
        }
      }
    }
  }

  return errors;
}

// ─── Main ─────────────────────────────────────────────────────────────────────

function main(): void {
  console.log("🔍 Validating agent definitions...\n");

  const errors = validate();
  const errorCount = errors.filter((e) => e.severity === "error").length;
  const warningCount = errors.filter((e) => e.severity === "warning").length;

  // Group by file
  const grouped = new Map<string, ValidationError[]>();
  for (const err of errors) {
    const existing = grouped.get(err.file) || [];
    existing.push(err);
    grouped.set(err.file, existing);
  }

  for (const [file, fileErrors] of grouped) {
    console.log(`📄 ${file}`);
    for (const err of fileErrors) {
      const icon = err.severity === "error" ? "  ❌" : "  ⚠️ ";
      console.log(`${icon} ${err.message}`);
    }
    console.log();
  }

  console.log("─".repeat(60));
  console.log(`Total: ${errors.length} issues (${errorCount} errors, ${warningCount} warnings)`);
  console.log();

  if (errorCount > 0) {
    console.log("❌ Validation FAILED — fix errors before proceeding.\n");
    process.exit(1);
  } else if (warningCount > 0) {
    console.log("⚠️  Validation passed with warnings.\n");
    process.exit(0);
  } else {
    console.log("✅ All agent definitions valid!\n");
    process.exit(0);
  }
}

main();
