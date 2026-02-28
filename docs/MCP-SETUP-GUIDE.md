# MCP Server Setup Guide

Complete guide for first-time setup, adding new tools, adding new IDEs, and extending the Vibecoded Orchestrator MCP server.

---

## Table of Contents

1. [First-Time Setup](#1-first-time-setup)
2. [Verifying It Works](#2-verifying-it-works)
3. [IDE-Specific Configuration](#3-ide-specific-configuration)
4. [Adding a New IDE / AI Coder](#4-adding-a-new-ide--ai-coder)
5. [Adding a New MCP Tool](#5-adding-a-new-mcp-tool)
6. [Adding a New Loader (Data Source)](#6-adding-a-new-loader-data-source)
7. [Extending Existing Tools](#7-extending-existing-tools)
8. [Architecture Overview](#8-architecture-overview)
9. [Troubleshooting](#9-troubleshooting)

---

## 1. First-Time Setup

### Prerequisites

- Node.js >= 18
- npm >= 9
- The Vibecoded Orchestrator repo cloned locally

### Install & Build

```bash
# From the project root
cd mcp-server
npm install
npm run build
```

This compiles TypeScript from `mcp-server/src/` into `mcp-server/build/`.

Or from the project root using the shortcut scripts:

```bash
npm run mcp:install
npm run mcp:build
```

### What Gets Built

```
mcp-server/
  build/           # Compiled JavaScript (auto-generated)
    index.js       # Entry point
    tools/         # Tool handlers
    lib/           # Shared loaders
  src/             # TypeScript source
    index.ts       # Server entry point
    tools/         # Tool modules (agents, mentors, skills, etc.)
    lib/           # Data loaders (YAML, markdown, config)
  package.json     # Dependencies
  tsconfig.json    # TypeScript config
```

### Configure Your IDE

The project ships with config files for all major AI coders. If you've just cloned, they're already in place:

| IDE | Config File | Location |
|-----|------------|----------|
| Claude Code | `.claude/settings.local.json` | Project root |
| Cursor | `.cursor/mcp.json` | Project root |
| VS Code / Copilot | `.vscode/mcp.json` | Project root |
| Windsurf | `.windsurfrules` + manual MCP config | Project root |
| AntiGravity | `.antigravityrules` + `.agent/skills/` + MCP settings UI | Project root + user config |

After building, restart your IDE or reload the window. The MCP server should auto-connect.

---

## 2. Verifying It Works

### Quick CLI Test

From the project root, send an MCP initialize + tools/list request:

```bash
printf '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}\n{"jsonrpc":"2.0","method":"notifications/initialized"}\n{"jsonrpc":"2.0","id":2,"method":"tools/list","params":{}}\n' | node mcp-server/build/index.js
```

You should see a JSON response listing 40 tools.

### In Claude Code

Open the project and ask:

> "List all available agents"

Claude Code should call `list_agents` via MCP and return a formatted list of 66+ agents.

### In Cursor

Open the project. In Composer or Chat, type:

> "What agents can help me with this file?"

Cursor should use `suggest_agents` via MCP.

### Expected Tools (40 total)

| Category | Tools | Count |
|----------|-------|-------|
| Agents | `list_agents`, `get_agent`, `invoke_agent`, `suggest_agents` | 4 |
| Personas | `list_personas`, `get_persona` | 2 |
| Mentors | `list_mentors`, `mentor_review` | 2 |
| Skills & Quality | `list_skills`, `get_skill`, `check_skill_applicability`, `create_claude_skill` | 4 |
| PRD | `list_prd_templates`, `get_prd_template`, `generate_prd_outline` | 3 |
| Sessions | `list_sessions`, `get_session`, `get_artifact`, `pipeline_status` | 4 |
| Structured Memory | `memory_read`, `memory_write`, `memory_search`, `memory_update`, `memory_delete`, `memory_stats`, `memory_related`, `memory_migrate`, `memory_session_start` | 9 |
| Workflow Engine | `list_workflows`, `get_workflow`, `run_workflow`, `workflow_complete_step`, `workflow_approve`, `workflow_resume`, `workflow_status`, `list_workflow_executions` | 8 |
| Self-Extending Skills | `discover_skills`, `install_skill`, `create_skill`, `skill_status` | 4 |

---

## 3. IDE-Specific Configuration

### Claude Code

**Config:** `.claude/settings.local.json`

```json
{
  "mcpServers": {
    "orchestrator": {
      "command": "node",
      "args": ["mcp-server/build/index.js"]
    }
  }
}
```

Claude Code auto-detects this file when you open the project. The MCP server connects via stdio.

**Instruction file:** `CLAUDE.md` — contains MCP tool reference and workflow guide.

### Cursor

**MCP Config:** `.cursor/mcp.json`

```json
{
  "mcpServers": {
    "orchestrator": {
      "command": "node",
      "args": ["mcp-server/build/index.js"]
    }
  }
}
```

**Rule files:**
- `.cursorrules` — root-level rules with MCP tool reference
- `.cursor/rules/agent-invocation.mdc` — context-aware agent suggestions per file type
- `.cursor/rules/mentor-review.mdc` — mentor review trigger guide
- `.cursor/rules/skills.mdc` — skill application guide

### VS Code / GitHub Copilot

**MCP Config:** `.vscode/mcp.json`

```json
{
  "servers": {
    "orchestrator": {
      "type": "stdio",
      "command": "node",
      "args": ["mcp-server/build/index.js"]
    }
  }
}
```

Note: VS Code uses `"servers"` (not `"mcpServers"`) and requires the `"type": "stdio"` field.

**Instruction file:** `.github/copilot-instructions.md`

### Windsurf

**Instruction file:** `.windsurfrules` — full rules with MCP tool reference.

**MCP Config:** Windsurf reads MCP config from its global settings or workspace config. Add the server in Windsurf's settings UI:

- **Name:** `orchestrator`
- **Command:** `node`
- **Args:** `mcp-server/build/index.js`
- **Transport:** stdio

Or, if Windsurf supports a file-based config (check their current docs), create a config similar to Cursor's format.

### AntiGravity

**Instruction file:** `.antigravityrules` — full rules with MCP tool reference and agent orchestration protocol.

**Skills:** `.agent/skills/` — 3 AntiGravity-native skills (cross-platform compatible with Claude Code):

| Skill | Invocation | Purpose |
|-------|-----------|---------|
| `skill-builder` | `/skill-builder` | Create new skills interactively |
| `image-gen` | `/image-gen` | AI image generation via Kie.ai |
| `antigravity-skill-creator` | `/antigravity-skill-creator` | Cross-platform skill creation |

**MCP Config:** AntiGravity reads MCP config from its settings UI or `~/.gemini/settings.json`. Add the server in AntiGravity's Settings > MCP Servers:

- **Name:** `orchestrator`
- **Command:** `node`
- **Args:** `<absolute-path-to-project>/mcp-server/build/index.js`
- **Transport:** stdio

**Important:** Use the **absolute path** to `mcp-server/build/index.js` in AntiGravity's config since it stores MCP config at the user level, not per-project.

**Quick Setup for AntiGravity:**

```bash
# 1. Clone and set up the project
git clone <repo-url> && cd vibecoded-orchestrator
./start.sh --setup

# 2. The script will print the absolute path to the MCP server.
#    Copy it and add to AntiGravity Settings > MCP Servers.

# 3. Open the project in AntiGravity. It will auto-detect:
#    - .antigravityrules (instruction file)
#    - .agent/skills/ (native skills)
#    - MCP server (40 tools via the config you added)
```

---

## 4. Adding a New IDE / AI Coder

To add support for a new AI coding tool (like Aider, Continue, Cody, etc.):

### Step 1: Create the MCP Configuration

Find out how the IDE discovers MCP servers. Most use one of these patterns:

**Pattern A: JSON config file** (Claude Code, Cursor, VS Code)

Create the appropriate config file. Examples:

```json
// For IDEs using "mcpServers" key (Claude Code, Cursor pattern):
{
  "mcpServers": {
    "orchestrator": {
      "command": "node",
      "args": ["mcp-server/build/index.js"]
    }
  }
}
```

```json
// For IDEs using "servers" key (VS Code pattern):
{
  "servers": {
    "orchestrator": {
      "type": "stdio",
      "command": "node",
      "args": ["mcp-server/build/index.js"]
    }
  }
}
```

Common config file locations by convention:

| Pattern | Example IDEs |
|---------|-------------|
| `.claude/settings.local.json` | Claude Code |
| `.cursor/mcp.json` | Cursor |
| `.vscode/mcp.json` | VS Code, Copilot |
| `~/.config/<ide>/mcp.json` | Global config (some IDEs) |
| IDE settings UI | Windsurf, Antigravity, others |

**Pattern B: IDE settings UI**

Some IDEs don't read config files — you configure MCP servers through their settings panel:

1. Open IDE settings
2. Find "MCP" or "Model Context Protocol" section
3. Add server:
   - **Name:** `orchestrator`
   - **Command:** `node`
   - **Arguments:** `mcp-server/build/index.js`
   - **Working directory:** (project root)
   - **Transport:** `stdio`

### Step 2: Create an Instruction / Rules File

Most AI coders auto-load instruction files from the project root. Create one for your IDE:

| IDE | Expected File |
|-----|--------------|
| Antigravity | Check docs — likely `.antigravityrules` or `AGENTS.md` |
| Aider | `.aider.conf.yml` or conventions file |
| Continue | `.continuerules` or custom config |
| Cody | `.cody/instructions.md` or similar |
| Generic | `AGENTS.md` (emerging standard) |

Use the existing `.windsurfrules` as a template — it has the complete MCP tool reference, role determination logic, and quality standards.

### Step 3: Add to Documentation

Update this file with the new IDE's configuration details.

### Example: Adding Antigravity Support

```bash
# 1. Create rules file (copy from windsurfrules as base)
cp .windsurfrules .antigravityrules

# 2. Edit the header to reference Antigravity
# Change "Windsurf Rules" to "Antigravity Rules"

# 3. Create MCP config (check Antigravity docs for exact format)
# If it uses Cursor-style config:
cp .cursor/mcp.json .antigravity/mcp.json

# 4. Rebuild if you changed any TypeScript
cd mcp-server && npm run build
```

---

## 5. Adding a New MCP Tool

The MCP server is modular — each tool category has its own file in `mcp-server/src/tools/`.

### Step 1: Decide Where the Tool Belongs

| If your tool relates to... | Add it to... |
|---------------------------|-------------|
| Agent discovery/invocation | `src/tools/agents.ts` |
| Persona loading | `src/tools/personas.ts` |
| Mentor reviews | `src/tools/mentors.ts` |
| Quality skills/checklists | `src/tools/skills.ts` |
| PRD templates/generation | `src/tools/prd.ts` |
| Orchestrator sessions | `src/tools/sessions.ts` |
| Structured memory/semantic search | `src/tools/memory.ts` |
| Workflow pipelines | `src/tools/workflows.ts` |
| External skill discovery/install | `src/tools/skill-discovery.ts` |
| **Something entirely new** | Create a new file (see below) |

### Step 2a: Add a Tool to an Existing Module

Open the relevant tool file and add a new `server.tool()` call:

```typescript
// In mcp-server/src/tools/agents.ts (or whichever module)

server.tool(
  "my_new_tool",                    // Tool name (snake_case)
  "Description of what it does",     // Shown to AI coders
  {
    // Input parameters using Zod schema
    param1: z.string().describe("What this parameter is for"),
    param2: z.number().optional().describe("Optional numeric param"),
  },
  async ({ param1, param2 }) => {
    // Your tool logic here
    const result = doSomething(param1, param2);

    return {
      content: [
        {
          type: "text" as const,
          text: result,  // Markdown-formatted string
        },
      ],
    };
  }
);
```

### Step 2b: Create a New Tool Module

For an entirely new tool category:

**1. Create the tool file:**

```typescript
// mcp-server/src/tools/my-feature.ts

import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";

export function registerMyFeatureTools(server: McpServer): void {
  server.tool(
    "my_feature_list",
    "List all available items for my feature",
    {
      filter: z.string().optional().describe("Optional filter"),
    },
    async ({ filter }) => {
      // Implementation
      return {
        content: [{ type: "text" as const, text: "Result here" }],
      };
    }
  );

  server.tool(
    "my_feature_get",
    "Get details for a specific item",
    {
      id: z.string().describe("Item ID"),
    },
    async ({ id }) => {
      // Implementation
      return {
        content: [{ type: "text" as const, text: "Details here" }],
      };
    }
  );
}
```

**2. Register it in `mcp-server/src/index.ts`:**

```typescript
import { registerMyFeatureTools } from "./tools/my-feature.js";

// Add alongside existing registrations:
registerMyFeatureTools(server);
```

**3. Rebuild:**

```bash
cd mcp-server && npm run build
```

### Step 3: Tool Design Guidelines

- **Tool names:** Use `snake_case`. Prefix with category (e.g., `agent_`, `mentor_`, `skill_`).
- **Descriptions:** Be specific — this is what AI coders see when deciding which tool to call.
- **Parameters:** Use Zod schemas. Always add `.describe()` to every parameter.
- **Return format:** Always return `{ content: [{ type: "text", text: "..." }] }`.
- **Output:** Use markdown formatting — headers, lists, code blocks, tables. AI coders render this.
- **Token efficiency:** Keep responses concise. Truncate large outputs (>3000 chars) with a note.
- **Error handling:** Return helpful error messages, not empty results. Suggest alternatives.

---

## 6. Adding a New Loader (Data Source)

Loaders live in `mcp-server/src/lib/` and handle reading data from the filesystem.

### Existing Loaders

| File | What It Loads | Source |
|------|-------------|--------|
| `agent-loader.ts` | 66+ agent YAML configs | `agents/pool/`, `agents/chiefs/` |
| `persona-loader.ts` | 70 persona markdown profiles | `agents/personas/` |
| `mentor-loader.ts` | 15 mentor definitions | `config/mentors.yaml` |
| `skill-loader.ts` | 10 skill configs + SKILL.md | `skills/*/config.yaml` |
| `template-loader.ts` | 35+ PRD templates | `config/prd-templates/` |
| `memory-store.ts` | Structured facts with semantic search | `memory/memory-store.json` |
| `tfidf-engine.ts` | BM25 + TF-IDF search engine | In-memory (serialized with memory store) |
| `workflow-engine.ts` | YAML workflow definitions + execution state | `config/workflows/`, `runs/workflows/` |

### Creating a New Loader

```typescript
// mcp-server/src/lib/my-loader.ts

import { readFileSync, readdirSync, existsSync } from "fs";
import { join } from "path";

// Root is 3 levels up from lib/ → src/ → mcp-server/ → project root
const ROOT = join(import.meta.dirname, "..", "..", "..");
const MY_DATA_DIR = join(ROOT, "path", "to", "data");

// Define your data type
export interface MyDataItem {
  id: string;
  name: string;
  // ... other fields
}

// Cache for performance (loaded once, reused across tool calls)
let cache: MyDataItem[] | null = null;

export function loadAll(): MyDataItem[] {
  if (cache) return cache;
  if (!existsSync(MY_DATA_DIR)) return [];

  cache = readdirSync(MY_DATA_DIR)
    .filter((f) => f.endsWith(".yaml"))
    .map((f) => {
      const content = readFileSync(join(MY_DATA_DIR, f), "utf-8");
      // Parse and return
      return JSON.parse(content) as MyDataItem;
    });

  return cache;
}

export function getById(id: string): MyDataItem | undefined {
  return loadAll().find((item) => item.id === id);
}
```

### Loader Design Guidelines

- Use `import.meta.dirname` (not `__dirname`) — the server uses ES modules.
- Cache data in module-level variables — the server stays running between tool calls.
- Always check `existsSync()` before reading files.
- Use `js-yaml` for YAML files (already a dependency).
- Return `null` or `undefined` for missing items, not exceptions.

---

## 7. Extending Existing Tools

### Adding Parameters to a Tool

Find the tool's `server.tool()` call and add to the Zod schema:

```typescript
// Before:
server.tool("list_agents", "...", {
  domain: z.string().optional(),
}, async ({ domain }) => { ... });

// After — added "sort_by" parameter:
server.tool("list_agents", "...", {
  domain: z.string().optional(),
  sort_by: z.enum(["name", "domain", "priority"]).optional().describe("Sort results"),
}, async ({ domain, sort_by }) => { ... });
```

### Adding a New Agent Domain

Agents are auto-discovered from the filesystem. Just drop a YAML file in the right directory:

```bash
# Tech agent
agents/pool/tech/my_new_agent.yaml

# Marketing agent
agents/pool/marketing/my_new_agent.yaml
```

The MCP server picks it up automatically (restart the server or IDE to refresh the cache).

### Adding a New Orchestrator Skill

Orchestrator skills live in `skills/` and are discoverable via MCP tools (`list_skills`, `get_skill`).

1. Create `skills/my-skill/config.yaml`:
```yaml
id: my-skill
name: "My Skill"
description: "What this skill does"
version: "1.0.0"
compatible_agents:
  - backend_engineer
  - qa_engineer
compatible_domains:
  - "tech/"
required_inputs: []
provides_outputs:
  - my_skill_report
priority: 10
enabled: true
```

2. Create `skills/my-skill/SKILL.md`:
```markdown
---
name: my-skill
description: "Use when reviewing [X], checking [Y], or generating [Z] reports."
version: "1.0.0"
argument-hint: "[file-or-directory]"
compatible_agents:
  - backend_engineer
  - qa_engineer
domain: "tech/"
priority: 10
user_invocable: true
---

# My Skill

When applying this skill, follow these steps:

## Step 1: ...
## Step 2: ...

## Output Format
...
```

**Frontmatter tips:**
- `name`: Use lowercase hyphenated format matching the directory name (e.g., `my-skill`)
- `description`: Write as "Use when..." for better auto-detection by AI coders
- `argument-hint`: Shows in `/command` autocomplete menus (e.g., `[file-path]`, `[pr-number]`)
- **Do NOT use `allowed-tools`** in orchestrator skills — it's only supported in `.claude/skills/`

The MCP server's `list_skills` and `get_skill` tools discover it automatically.

### Adding a Claude Code Native Skill

Claude Code skills live in `.claude/skills/` and are invocable as `/slash-commands` directly in the IDE.

**Option A: Via MCP tool (recommended)**

Use the `create_claude_skill` MCP tool — it generates the SKILL.md with proper frontmatter automatically.

**Option B: Manually**

Create `.claude/skills/my-skill/SKILL.md`:
```markdown
---
name: my-skill
description: Use when someone asks to [action]. Analyzes [X] and produces [Y].
allowed-tools: Read, Grep, Glob, Bash(npm test *)
argument-hint: [file-path]
---

# My Skill

## When to Use
Use when someone asks to [action]. Analyzes [X] and produces [Y].

## Workflow

1. First step of the workflow
2. Second step
3. Third step

## Output Format

Description of expected output format.

## Notes

- Edge case or constraint
- Things the skill should NOT do
```

**Claude Code skill frontmatter fields:**

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Lowercase, hyphens. Becomes the `/slash-command` |
| `description` | Yes | "Use when..." trigger description for auto-detection |
| `allowed-tools` | No | Tools allowed without prompts (e.g., `Read, Grep, Bash(git *)`) |
| `argument-hint` | No | Autocomplete hint (e.g., `[file-path]`) |
| `disable-model-invocation` | No | `true` = manual `/command` only, no auto-detection |
| `context` | No | `fork` = runs in isolated subagent context |

**Option C: Use the `/skill-builder` slash command**

Run `/skill-builder` in Claude Code for a guided discovery interview that creates the skill for you.

### Dual Skill System Summary

| Aspect | Orchestrator Skills (`skills/`) | Claude Code Skills (`.claude/skills/`) |
|--------|-------------------------------|---------------------------------------|
| Location | `skills/<name>/` | `.claude/skills/<name>/` |
| Discovery | MCP tools (`list_skills`, `get_skill`) | `/slash-commands` in IDE |
| Config | `config.yaml` + `SKILL.md` | `SKILL.md` only (with frontmatter) |
| `allowed-tools` | **Not supported** | Supported |
| `context: fork` | Not supported | Supported |
| Use case | Agent pipeline quality gates | Interactive developer workflows |

### Adding a New Mentor

Edit `config/mentors.yaml` and add a new entry under the `mentors:` key:

```yaml
  my_mentor:
    name: "Mentor Name"
    domain_focus: "Area of Expertise"
    quote: "Their signature philosophy."
    principles:
      - "First principle"
      - "Second principle"
    influences_domains:
      - "tech/frontend"
    influences_agents:
      - web_frontend_engineer
    review_lens: "The key question this mentor asks when reviewing work?"
```

The MCP `list_mentors` and `mentor_review` tools pick it up automatically.

---

## 8. Architecture Overview

```
AI Coder (Claude Code / Cursor / Windsurf / Copilot)
    │
    │ stdio (JSON-RPC)
    ▼
┌─────────────────────────────────────────────────────────┐
│  MCP Server  (mcp-server/build/index.js)  — 40 tools   │
│                                                         │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌──────────────┐  │
│  │ agents  │ │personas │ │ mentors │ │  workflows   │  │
│  │ 4 tools │ │ 2 tools │ │ 2 tools │ │   8 tools    │  │
│  └────┬────┘ └────┬────┘ └────┬────┘ └──────┬───────┘  │
│       │           │           │              │          │
│  ┌────┴────┐ ┌────┴────┐ ┌────┴────┐ ┌──────┴───────┐  │
│  │ skills  │ │   prd   │ │sessions │ │   skill-     │  │
│  │ 4 tools │ │ 3 tools │ │ 4 tools │ │  discovery   │  │
│  └────┬────┘ └────┬────┘ └────┬────┘ │   4 tools    │  │
│       │           │           │      └──────┬───────┘  │
│  ┌────┴───────────┴───────────┴─────────────┴───┐      │
│  │     structured memory (9 tools)              │      │
│  │     TF-IDF + BM25 semantic search            │      │
│  └──────────────────┬───────────────────────────┘      │
│                     │                                   │
│  ─────────── Shared Loaders (lib/) ──────────────      │
│  agent-loader  │ persona-loader │ mentor-loader        │
│  skill-loader  │ template-loader                       │
│  memory-store  │ tfidf-engine   │ workflow-engine       │
│                                                         │
│  ─────────── Live Dashboard ─────────────────────      │
│  SSE event stream (/api/orchestrator/events)           │
│  event-emitter.ts (in-process pub/sub)                 │
└─────────────────────┼───────────────────────────────────┘
                      │
                      ▼  (filesystem reads/writes)
┌─────────────────────────────────────────────────────────┐
│  Project Filesystem                                     │
│                                                         │
│  agents/pool/tech/       (38 YAML files)                │
│  agents/pool/marketing/  (28 YAML files)                │
│  agents/chiefs/          (4 YAML files)                 │
│  agents/personas/        (70 markdown files)            │
│  config/mentors.yaml     (15 mentors)                   │
│  config/prd-templates/   (35+ templates)                │
│  config/workflows/       (YAML workflow definitions)    │
│  skills/                 (10 orchestrator skill dirs)   │
│  .claude/skills/         (3 Claude Code native skills)  │
│  config/project-sessions/(session state)                │
│  runs/artifacts/         (agent outputs)                │
│  runs/workflows/         (workflow execution state)     │
│  memory/memory-store.json(structured facts + TF-IDF)    │
└─────────────────────────────────────────────────────────┘
```

### Key Design Principles

1. **Filesystem as database** — No external database. Agents, personas, mentors, skills, templates, workflows, and memory are all files. The MCP server reads them on demand.

2. **Caching** — Loaders cache data in memory after first read. Restart the server to pick up new files.

3. **Stdio transport** — The MCP server communicates via stdin/stdout JSON-RPC. This is the standard for local MCP servers and works with all major AI coders.

4. **Modular tools** — Each tool category is a separate file (9 modules, 40 tools). Adding new tools doesn't affect existing ones.

5. **Token efficiency** — Tools return concise, markdown-formatted text. Large outputs are truncated with a note.

6. **Dual skill system** — Orchestrator skills (`skills/`) are discoverable via MCP tools. Claude Code native skills (`.claude/skills/`) are invocable as `/slash-commands` directly in the IDE.

7. **Semantic search** — The memory system uses a pure-TypeScript TF-IDF + BM25 hybrid engine for relevance-ranked retrieval — no external dependencies.

8. **Workflow engine** — YAML-defined pipelines with sequential/parallel steps, approval gates, and resume tokens. Execution state persists across restarts.

---

## 9. Troubleshooting

### MCP server not connecting

```bash
# Test manually:
echo '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{"protocolVersion":"2024-11-05","capabilities":{},"clientInfo":{"name":"test","version":"1.0"}}}' | node mcp-server/build/index.js
```

If you see a JSON response with `"serverInfo"`, the server works. The issue is IDE config.

### "Cannot find module" errors

```bash
# Rebuild:
cd mcp-server && npm run build
```

### Tools not showing up

1. Check the IDE's MCP server logs (most IDEs have an MCP debug panel)
2. Verify the config file is in the right location
3. Restart the IDE after config changes

### New agents/skills/mentors not appearing

The server caches data on first load. Restart your IDE (or the MCP server process) to refresh.

### Wrong number of agents listed

Verify YAML files are valid:
```bash
npm run validate
```

### Memory not persisting

Check that `memory/` directory exists and is writable:
```bash
ls -la memory/
ls -la memory/daily/
```

### Workflows not executing

```bash
# Check workflow definitions exist
ls config/workflows/

# Verify execution state directory exists
ls runs/workflows/
```

If `runs/workflows/` doesn't exist, create it — the engine writes execution state there.

If a workflow is stuck on an approval step, use `workflow_approve` with the execution ID.

If a workflow failed mid-execution, use `workflow_resume` with the execution ID and resume token from `workflow_status`.

### Semantic memory search returning poor results

The TF-IDF + BM25 engine builds its index from stored facts. If results are irrelevant:

1. Check that facts exist: use `memory_stats` to see fact count and category breakdown
2. Add more specific facts with clear categories and tags via `memory_write`
3. Use `memory_related` with a fact ID to test the relatedness scoring

The search index is rebuilt automatically when facts are added. No manual reindexing needed.

### Claude Code skills not appearing as /commands

1. Verify the skill directory exists: `.claude/skills/<name>/SKILL.md`
2. Check the frontmatter has `name` and `description` fields
3. If `disable-model-invocation: true` is set, the skill won't auto-detect — you must type `/<name>` manually
4. Restart Claude Code after adding new skills

### `create_claude_skill` MCP tool errors

If the tool returns "Skill already exists", edit the existing SKILL.md directly instead:
```bash
ls .claude/skills/
```

### Skill discovery returning empty results

The `discover_skills` tool searches 8 curated registries. If results are empty:
1. Check your filter — use `category` or `keyword`, not both
2. Run without filters first to see all available external skills
3. Network issues won't cause errors — the registries are built-in metadata, not live API calls

### Build errors after adding a new tool

```bash
cd mcp-server && npx tsc --noEmit  # Type-check without building
```

Common issues:
- Missing `.js` extension in imports (required for NodeNext module resolution)
- Forgot to add `as const` to `type: "text"` in return values
- Missing Zod import (`import { z } from "zod"` — re-exported by MCP SDK)
