# CLAUDE.md — Vibecoded Orchestrator Instructions for Claude Code

## What Is This Repo?

This is the Vibecoded Orchestrator — a unified multi-agent system structured like a real IT company.
It has 74 specialist agents (46 tech + 28 marketing) coordinated by a CEO orchestrator,
with CMO and CTO chiefs managing their respective teams, guided by a **Mentors Layer**
of 30 world-class influences spanning ancient strategy to modern AI. It includes a comprehensive
PRD generation system with 35+ templates, 81 expert personas, a CTO Codebase Evaluation Suite
(495 parameters, 21 categories), cross-tool compatibility (7+ AI coding tools), auto-update
from 4 upstream registries, enhanced memory with vector embeddings, multi-model provider support
(Anthropic, OpenAI, Gemini, Bedrock), and a production-ready Next.js 15 web app (TaskFlow)
— all in one project with a single `npm install`.

## MCP Tools Available

You have an MCP server called **"orchestrator"** v2.0 with **44 tools**. Use these instead of manually reading YAML/markdown files:

**Agent System (4 tools):**

- `list_agents` — Browse/search all 74 agents by domain, chief, or keyword
- `get_agent` — Load full agent config (system prompt, inputs/outputs, mentors)
- `invoke_agent` — Adopt a specialist's identity (loads agent + persona + mentors + skills)
- `suggest_agents` — Get agent recommendations based on file path or task description

**Personas & Mentors (4 tools):**

- `list_personas` / `get_persona` — Browse and load 78 expert professional profiles
- `list_mentors` — See all 30 world-class mentors and their philosophies
- `mentor_review` — Apply a mentor's review lens to code, designs, or decisions

**Skills & Quality (4 tools):**

- `list_skills` / `get_skill` — Load quality checklists (security audit, code quality, accessibility, etc.)
- `check_skill_applicability` — Find which skills apply to a given agent or domain
- `create_claude_skill` — Generate native Claude Code skills (`.claude/skills/`) with proper frontmatter

**PRD Templates (3 tools):**

- `list_prd_templates` / `get_prd_template` — Browse and load 35+ PRD templates
- `generate_prd_outline` — Create a pre-filled PRD from template + project details

**Sessions & Pipelines (4 tools):**

- `list_sessions` / `get_session` / `get_artifact` / `pipeline_status` — Manage orchestrator sessions

**Structured Memory with Semantic Search (9 tools):**

- `memory_read` / `memory_write` — Read/write structured facts (auto-categorized by section, type, tags)
- `memory_search` — Hybrid BM25 + TF-IDF semantic search across all facts
- `memory_update` / `memory_delete` — Modify or remove facts
- `memory_stats` — Get memory analytics (sections, types, top tags)
- `memory_related` — Find knowledge graph connections between facts
- `memory_migrate` — Import existing MEMORY.md into structured store
- `memory_session_start` — Track facts created during a work session

**Workflow Engine (8 tools):**

- `list_workflows` / `get_workflow` — Browse YAML workflow definitions
- `run_workflow` — Start executing a deterministic pipeline with agent assignments
- `workflow_complete_step` — Mark a step done and advance the workflow
- `workflow_approve` — Approve steps at approval gates
- `workflow_resume` — Resume interrupted workflows with resume tokens
- `workflow_status` — Check execution progress
- `list_workflow_executions` — See all running/completed workflows

**Self-Extending Skills (4 tools):**

- `discover_skills` — Browse 8 curated registries with 100+ external skills
- `install_skill` — Install skills from Anthropic, marketing, design, dev workflow registries
- `create_skill` — Generate new custom skills from templates
- `skill_status` — View all installed skills (bundled + external)

**CTO Evaluation Suite (4 tools):**

- `run_evaluation` — Run 495-parameter codebase evaluation (quick/standard/enhanced modes)
- `get_evaluation` — Get latest evaluation results (summary, full, or per-category view)
- `list_evaluations` — List evaluation history with scores and trends
- `compare_evaluations` — Compare two evaluation runs for progress tracking

### How to Use

1. **For any coding task:** Run `suggest_agents` with the file path to find the right specialist
2. **To adopt a specialist:** Run `invoke_agent` with the agent ID — it returns the full context
3. **After completing work:** Run `mentor_review` to apply quality review lenses
4. **Before committing:** Run `get_skill` with "code-quality" or "security-audit" to apply checklists
5. **For new projects:** Run `list_prd_templates` then `generate_prd_outline` to scaffold a PRD

## Claude Code Skills (Slash Commands)

This project has native Claude Code skills in `.claude/skills/`. Use `/skill-name` to invoke:

| Skill               | Command                      | Description                                           |
| ------------------- | ---------------------------- | ----------------------------------------------------- |
| Skill Builder       | `/skill-builder`             | Create and audit skills following best practices      |
| Image Generation    | `/image-gen`                 | Generate AI images via Kie.ai API with JSON prompting |
| AntiGravity Creator | `/antigravity-skill-creator` | Create cross-platform AntiGravity-compatible skills   |

**Orchestrator Quality Skills** (14 skills in `skills/`): code-quality, security-audit, accessibility-check, api-contract-validation, deploy-checklist, design-system-lint, performance-budget, prd-analysis, pr-review, pr-lifecycle, penetration-test-report, cloud-security-audit, compliance-control-check, cto-evaluation. Use via MCP `get_skill` tool.

## When You're Asked to Start a Project

1. Check if a session exists: `config/project-sessions/`
2. If no session → run the Discovery Agent flow (orchestrator/index.ts)
3. If a session exists → read session.yaml and the PRD, then begin task execution

## When You're Acting as an Agent

```
Step 1: Read the agent's YAML from agents/pool/<domain>/<id>.yaml
Step 2: Read the matching persona from agents/personas/ (if available) for deeper context
Step 3: Read mentors from the YAML — inject mentor quotes and principles into your thinking
Step 4: Adopt the system_prompt from the YAML as your persona
Step 5: Accept only the inputs listed in expected_inputs
Step 6: Apply mentor_lens questions as a final quality check on your output
Step 7: Produce only the outputs listed in expected_outputs
Step 8: Write files to runs/artifacts/<project-id>/
Step 9: Return a short summary (≤150 tokens) to the orchestrator
```

## When You're Acting as CEO/Orchestrator

```
Step 1: Read config/globals.yaml
Step 2: Read config/orchestrator-schema.yaml
Step 3: Read the project PRD at runs/prds/<project-id>-prd.md
Step 4: Read config/project-sessions/<project-id>/session.yaml
Step 5: Generate a YAML task_plan
Step 6: Execute each task sequentially or in parallel (per the plan)
Step 7: Pass only minimal context to each specialist agent
Step 8: Compress outputs between steps
```

## Directory Reference

| Path                                               | Purpose                                                                                                        |
| -------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| **Web App (TaskFlow)**                             |                                                                                                                |
| `src/app/`                                         | Next.js 15 App Router pages (home, auth, dashboard, PRD tools)                                                 |
| `src/components/`                                  | React components (auth, dashboard, layout, shadcn/ui)                                                          |
| `src/lib/`                                         | Prisma client, utilities                                                                                       |
| `prisma/`                                          | Database schema and migrations (SQLite dev / PostgreSQL prod)                                                  |
| `auth.ts`                                          | NextAuth.js 5 configuration                                                                                    |
| **Skills (Claude Code)**                           |                                                                                                                |
| `.claude/skills/skill-builder/`                    | Meta-skill for creating and auditing skills                                                                    |
| `.claude/skills/image-gen/`                        | AI image generation via Kie.ai API                                                                             |
| `.claude/skills/antigravity-skill-creator/`        | Cross-platform skill creation                                                                                  |
| **Skills (Orchestrator)**                          |                                                                                                                |
| `skills/`                                          | 14 quality gate skills (code-quality, security-audit, cto-evaluation, etc.)                                    |
| `skills/external/`                                 | Skills installed from external registries                                                                      |
| **Agent System**                                   |                                                                                                                |
| `agents/chiefs/`                                   | CEO, CMO, CTO, COO definitions                                                                                 |
| `agents/pool/tech/`                                | 46 tech specialist agents (incl. 6 operations/utility agents)                                                  |
| `agents/pool/marketing/`                           | 28 marketing specialist agents                                                                                 |
| `agents/personas/`                                 | 78 expert persona docs (enrich agent prompts)                                                                  |
| **Configuration**                                  |                                                                                                                |
| `config/globals.yaml`                              | Global brand, voice, token policy                                                                              |
| `config/mentors.yaml`                              | 30 world-class mentors layer (ancient to modern, influences agent decisions)                                    |
| `config/orchestrator-schema.yaml`                  | Runtime schema for each run                                                                                    |
| `config/project-sessions/<id>/`                    | Per-project config and session state                                                                           |
| `config/prd-templates/core/`                       | 29 core domain PRD templates                                                                                   |
| `config/prd-templates/specialized/`                | 4 specialized PRD templates (AI/ML, DevOps, etc.)                                                              |
| `config/prd-templates/companion/`                  | Design + Tasks companion templates                                                                             |
| `config/registries/`                               | Agent, MCP tool, and upstream sync registries                                                                  |
| **Cross-Tool Compatibility**                       |                                                                                                                |
| `integrations/`                                    | Auto-generated agent files for 7 AI tools (Claude Code, Cursor, Aider, etc.)                                  |
| `.claude-plugin/marketplace.json`                  | Claude Code plugin marketplace registry                                                                        |
| `scripts/convert.sh`                               | Convert agents to 7 tool formats                                                                               |
| `scripts/install.sh`                               | Interactive installer for AI tools                                                                             |
| `scripts/validate-skills.sh`                       | Validate skills against agentskills.io spec                                                                    |
| `scripts/lint-agents.sh`                           | Validate agent YAML structure                                                                                  |
| `scripts/sync-upstream.sh`                         | Sync skills from 4 upstream registries                                                                         |
| `scripts/update.sh`                                | User-facing update script with version checking                                                                |
| **Orchestrator**                                   |                                                                                                                |
| `orchestrator/index.ts`                            | Main entry point (CLI) with env detection + notification hooks                                                 |
| `orchestrator/env-detect.ts`                       | Auto-detects AI tool (Claude Code/Cursor/etc.), project context, stack                                         |
| `orchestrator/notifications.ts`                    | Slack/Discord/Telegram webhook notifications for pipeline events                                               |
| `orchestrator/discovery.ts`                        | Discovery Agent interview logic                                                                                |
| `orchestrator/prd-generator.ts`                    | PRD generation and agent selection                                                                             |
| `orchestrator/agent-configurator.ts`               | Session creation and agent loading                                                                             |
| `orchestrator/executor.ts`                         | Agent execution engine (Claude API + artifact pipeline)                                                        |
| **Orchestrator Dashboard (Web)**                   |                                                                                                                |
| `src/app/orchestrator/page.tsx`                    | Dashboard hub — sessions list, stats, CLI reference                                                            |
| `src/app/orchestrator/[id]/page.tsx`               | Session detail — pipeline view, PRD, artifacts                                                                 |
| `src/app/orchestrator/agents/page.tsx`             | Agent registry — browse all 74 agents + personas                                                               |
| `src/app/orchestrator/live/page.tsx`               | Live agent dashboard — SSE streaming with Framer Motion                                                        |
| **Orchestrator API Routes**                        |                                                                                                                |
| `src/app/api/orchestrator/sessions/route.ts`       | GET all sessions with progress                                                                                 |
| `src/app/api/orchestrator/sessions/[id]/route.ts`  | GET details / POST trigger execution                                                                           |
| `src/app/api/orchestrator/artifacts/[id]/route.ts` | GET artifact content by project                                                                                |
| `src/app/api/orchestrator/agents/route.ts`         | GET full agent registry                                                                                        |
| `src/app/api/orchestrator/events/route.ts`         | SSE endpoint for live agent activity streaming                                                                 |
| **MCP Server**                                     |                                                                                                                |
| `mcp-server/src/index.ts`                          | MCP server entry point (44 tools, stdio transport)                                                             |
| `mcp-server/src/tools/`                            | Tool modules: agents, personas, mentors, skills, prd, sessions, memory, workflows, skill-discovery, evaluation |
| `mcp-server/src/lib/`                              | Shared loaders, TF-IDF, vector store, embedding providers, enhanced memory, workflow engine                    |
| **LLM Providers**                                  |                                                                                                                |
| `orchestrator/providers/openai.ts`                 | OpenAI provider (GPT-4o, o1)                                                                                   |
| `orchestrator/providers/gemini.ts`                 | Google Gemini provider (2.5-pro, 2.0-flash)                                                                    |
| `orchestrator/providers/bedrock.ts`                | AWS Bedrock provider (Claude, Llama, Mistral via SigV4)                                                        |
| **CTO Evaluation Suite**                           |                                                                                                                |
| `tools/cto-evaluation/`                            | 495-parameter codebase evaluation engine (21 categories, 24 analyzers)                                         |
| `tools/cto-evaluation/scripts/`                    | 21 category evaluation scripts + orchestration                                                                 |
| `tools/cto-evaluation/config/`                     | Evaluation weights, patterns, and scoring thresholds                                                           |
| **Workflows**                                      |                                                                                                                |
| `config/workflows/`                                | YAML workflow definitions (feature-build, code-review, marketing-launch, cto-evaluation)                       |
| `runs/workflows/`                                  | Persisted workflow execution state                                                                             |
| **Memory**                                         |                                                                                                                |
| `memory/MEMORY.md`                                 | Long-term curated project facts                                                                                |
| `memory/memory-store.json`                         | Structured memory store with semantic search index                                                             |
| `memory/daily/`                                    | Daily working logs                                                                                             |
| **Outputs**                                        |                                                                                                                |
| `runs/prds/`                                       | Generated Master PRDs                                                                                          |
| `runs/artifacts/<id>/`                             | Agent-produced outputs                                                                                         |
| `runs/generated-prds/`                             | Full PRD suite outputs                                                                                         |
| `runs/logs/`                                       | Execution logs                                                                                                 |
| **Reference**                                      |                                                                                                                |
| `docs/playbooks/`                                  | AI agent playbooks (shadcn, design, components)                                                                |
| `scripts/`                                         | PRD generation and project setup scripts                                                                       |
| `docs/`                                            | Workflow guides, API docs, GEKB reference, setup & deployment guides                                           |
| `.github/`                                         | CI/CD workflows, issue templates                                                                               |
| **Config Files (root)**                            |                                                                                                                |
| `tsconfig.json`                                    | Next.js TypeScript config                                                                                      |
| `tsconfig.orchestrator.json`                       | Orchestrator CLI TypeScript config                                                                             |
| `next.config.js`                                   | Next.js configuration                                                                                          |
| `tailwind.config.ts`                               | Tailwind CSS configuration                                                                                     |
| `components.json`                                  | shadcn/ui component paths                                                                                      |

## Token Efficiency Rules

- Pass summaries (≤150 tokens) between agents, not full content
- Store full outputs as files; pass file paths
- Only send each agent the sections of the PRD it needs
- Respect the token_cap field in each agent's YAML

## Adding New Agents

Drop a YAML file in `agents/pool/tech/` or `agents/pool/marketing/` following this structure:

```yaml
id: 'my_new_agent'
title: 'My New Agent'
domain: 'tech/frontend' # or marketing/email etc.
reports_to: 'CTO' # or CMO
responsibilities:
  - '...'
expected_inputs: ['product_spec']
expected_outputs: ['my_output']
token_cap: 2000
system_prompt: |
  You are a [role]. Given [inputs], produce [outputs].
  Be specific. Stay within token_cap.
```

## Adding New Personas

Drop a markdown file in `agents/personas/` following the naming pattern: `firstname-lastname-role.md`.
Each persona should include: professional profile, background, philosophy, tool stack, methodology.
These enrich agent system prompts with deep domain expertise.

## Persona ↔ Agent Mapping

| Persona                                | Maps to Agent(s)                                              |
| -------------------------------------- | ------------------------------------------------------------- |
| Sarah Chen (UX/UI)                     | `ux_designer`, `ui_designer`                                  |
| Marcus Rodriguez (Backend)             | `backend_engineer`, `api_designer`                            |
| Jordan Park (Frontend)                 | `web_frontend_engineer`, `design_engineer`                    |
| Rachel Thompson (Security)             | `security_engineer`                                           |
| Kai Blackwell (Penetration Testing)    | `penetration_tester`                                          |
| Priya Mehta (Cloud Security)           | `cloud_security_engineer`                                     |
| Jordan Lee (DevSecOps)                 | `devsecops_engineer`                                          |
| Amara Diallo (SOC Analysis)            | `soc_analyst`                                                 |
| Elena Foster (Compliance/GRC)          | `compliance_engineer`                                         |
| Felix Nakamura (IAM)                   | `iam_engineer`                                                |
| Zoe Bergmann (AI Security)             | `ai_security_engineer`                                        |
| David Morrison (Technical Auditor)     | `technical_auditor`                                           |
| Alex Kim (DevOps)                      | `devops_engineer`, `release_engineer`                         |
| Anna Kim (Accessibility)               | `accessibility_engineer`                                      |
| Carlos Martinez (Performance)          | `frontend_performance_engineer`                               |
| David Chen (Analytics)                 | `product_analyst`, `experimentation_engineer`                 |
| Diana Patel (Integration)              | `api_designer`, `data_engineer`                               |
| Emily Watson (Product)                 | `product_manager`                                             |
| Jennifer Wu (QA)                       | `qa_engineer`, `test_automation_engineer`                     |
| Lisa Morgan (Content)                  | `content_strategist`, `editorial_writer`                      |
| Maria Santos (Database)                | `database_engineer`                                           |
| Thomas Clark (Mobile)                  | `ios_engineer`, `android_engineer`, `cross_platform_engineer` |
| Ryan Zhao (3D Design)                  | `3d_designer`                                                 |
| Priya Kapoor (Accessibility)           | `accessibility_engineer`                                      |
| Kenji Tanaka (Android)                 | `android_engineer`                                            |
| Aisha Patel (API Design)               | `api_designer`                                                |
| Natasha Volkov (Art Direction)         | `art_director`                                                |
| Sofia Navarro (Cross-Platform)         | `cross_platform_engineer`                                     |
| Daniel Okafor (Data Engineering)       | `data_engineer`                                               |
| Liam Chen (Design Engineering)         | `design_engineer`                                             |
| Elena Petrova (Design Systems)         | `design_systems_engineer`                                     |
| Maya Washington (Experimentation)      | `experimentation_engineer`                                    |
| Nina Rossi (Information Architecture)  | `information_architect`                                       |
| Yuki Matsuda (Interaction Design)      | `interaction_designer`                                        |
| Kai Nakamura (iOS)                     | `ios_engineer`                                                |
| Amara Osei (ML Engineering)            | `ml_engineer`                                                 |
| Sven Eriksson (Motion Design)          | `motion_designer`                                             |
| Victor Andrade (Product Management)    | `product_manager`                                             |
| Hannah Johansson (Prototyping)         | `prototype_engineer`                                          |
| Grace Kim (QA Engineering)             | `qa_engineer`                                                 |
| Omar Hassan (Release Engineering)      | `release_engineer`                                            |
| James Mitchell (Technical Writing)     | `technical_writer`                                            |
| Derek Okonkwo (Test Automation)        | `test_automation_engineer`                                    |
| Mia Chen-Ramirez (UX Design)           | `ux_designer`                                                 |
| Alex Petrov (UX Research)              | `ux_researcher`                                               |
| Raj Krishnamurthy (WebGL)              | `webgl_engineer`                                              |
| Tanya Brooks (Affiliate Marketing)     | `affiliate_manager`                                           |
| Kevin Park (ASO)                       | `aso_specialist`                                              |
| Zara Okafor-Williams (Brand Strategy)  | `brand_strategist`                                            |
| Jade Moreno (Community)                | `community_manager`                                           |
| Marcus Chen (CRM Automation)           | `crm_automation_specialist`                                   |
| Samantha Liu (CRO)                     | `cro_specialist`                                              |
| Danielle Foster (Email Copy)           | `email_copywriter`                                            |
| Arjun Mehta (Email Design)             | `email_designer`                                              |
| Rachel Goldstein (Email Platform)      | `email_platform_builder`                                      |
| Natalie Rivera (Email Strategy)        | `email_strategist`                                            |
| Tyler Nguyen (Growth Marketing)        | `growth_marketer`                                             |
| Camille Dubois (Influencer Management) | `influencer_manager`                                          |
| Wei Zhang (Marketing Analytics)        | `marketing_analytics`                                         |
| Jordan Blake (Marketing Copy)          | `marketing_copywriter`                                        |
| Isabella Santos (Marketing Design)     | `marketing_designer`                                          |
| David Okonjo (Marketing Strategy)      | `marketing_strategist`                                        |
| Lauren Torres (Media Buying)           | `media_buyer`                                                 |
| Priya Sharma (Partnerships)            | `partnership_manager`                                         |
| Eric Chang (Performance Marketing)     | `performance_marketer`                                        |
| Nina Kowalski (Push Messaging)         | `push_messaging_specialist`                                   |
| Ryan Patel (SEM/PPC)                   | `sem_specialist`                                              |
| Anika Johansson (SEO)                  | `seo_specialist`                                              |
| Amara Johnson (Social Media)           | `social_media_marketer`                                       |
| Marco Valentino (Social Video)         | `social_video_creator`                                        |
| Sophie Laurent (UX Writing)            | `ux_writer`                                                   |
| Andre Williams (Video Production)      | `video_producer`                                              |
| Elena Vasquez (Process Feedback)       | `feedback_agent`                                              |
| Nathan Okafor (Error Logging)          | `error_logging_agent`                                         |
| Clara Fitzgerald (Environment Mgmt)    | `environment_checker_agent`                                   |
| Tomás Herrera (Dependency Tracking)    | `dependency_tracker_agent`                                    |
| Ingrid Holm (Directory Housekeeping)   | `directory_housekeeping_agent`                                |
| Mateo Rivera (Deployment Readiness)    | `deployment_readiness_agent`                                  |

## Running the Project

```bash
npm install                     # install all dependencies (one command)
npm run dev                     # start the TaskFlow web app (Next.js, port 1000)
npm run orchestrator            # start discovery → PRD → agent config → execute flow
npm run orchestrator:list       # list all project sessions
npm run list-agents             # see all available agents
npm run evaluate                # run CTO codebase evaluation (interactive)
npm run evaluate:quick          # quick evaluation of current directory
npm run generate:master-prd     # generate a master PRD from template
npm run generate:all-prds       # generate complete PRD suite (35+ docs)
npm run db:push                 # push Prisma schema to database
npm run db:studio               # open Prisma Studio GUI

# Cross-Tool Compatibility
npm run convert                 # convert agents to all 7 tool formats
npm run convert:cursor          # convert for Cursor only
npm run convert:gemini          # convert for Gemini CLI only
npm run install:tools           # interactive installer for AI tools

# Quality & Validation
npm run lint:agents             # validate all 74 agent YAMLs
npm run lint:skills             # validate skills against agentskills.io spec

# Auto-Update & Sync
npm run sync:upstream           # sync skills from 4 upstream registries
npm run update                  # check for updates and apply
npm run update:check            # check for updates (dry run)
npm run update:sync             # sync upstream only
```

## Environment Auto-Detection

On first run, the orchestrator automatically detects:

1. **AI Coding Tool** — Claude Code, Cursor, AntiGravity, Windsurf, Aider, OpenCode, Gemini CLI, Copilot, Junie
2. **Project Context** — standalone, cloned into an existing project, or monorepo child
3. **Stack & Frameworks** — languages, frameworks, package manager, tests, CI/CD presence

Based on detection:
- If cloned into a project → adapts agents to the host project's stack
- If standalone → runs normal discovery flow
- Auto-generates integration files for the detected AI tool (e.g., `.cursor/rules/` for Cursor)
- Results are cached for 24 hours in `runs/.env-detect-cache.json`

## Notifications

Pipeline events can be sent to Slack, Discord, and Telegram. Set webhook URLs in `.env.local`:

```bash
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/T.../B.../...
DISCORD_WEBHOOK_URL=https://discord.com/api/webhooks/.../...
TELEGRAM_BOT_TOKEN=123456:ABC-DEF...
TELEGRAM_CHAT_ID=-100...
```

Notification levels (set in `config/globals.yaml`):
- `all` — every agent start/complete, phase changes, errors
- `phases` — phase transitions, quality gates, errors (default)
- `errors` — only errors and warnings
- `summary` — only pipeline start/complete

## Execution Engine

The executor (`orchestrator/executor.ts`) runs agents against Claude API:

1. Loads session + selected agents from `config/project-sessions/<id>/`
2. Generates a phased execution plan (9 phases: planning → design → build → test → deploy)
3. Iterates steps respecting dependencies — calls Claude with each agent's `system_prompt`
4. Saves outputs to `runs/artifacts/<id>/<agent>-output.md` + `manifest.json`
5. Falls back to structured placeholder when no `ANTHROPIC_API_KEY` is set
6. Sends notifications to configured channels at phase transitions and on errors

Set `ANTHROPIC_API_KEY` in `.env.local` for real Claude API calls.

## Web Dashboard

Visit `http://localhost:1000/orchestrator` to see:

- **Dashboard** — all sessions, progress stats, CLI reference
- **Session Detail** (`/orchestrator/<id>`) — pipeline view, PRD, artifact viewer
- **Agent Registry** (`/orchestrator/agents`) — browse all 74 agents + 78 personas

The dashboard auto-polls for updates during execution and lets you trigger runs via the UI.
