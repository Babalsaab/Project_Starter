# CLAUDE.md — Vibecoded Orchestrator Instructions for Claude Code

## What Is This Repo?

This is the Vibecoded Orchestrator — a unified multi-agent system structured like a real IT company.
It has 66 specialist agents (38 tech + 28 marketing) coordinated by a CEO orchestrator,
with CMO and CTO chiefs managing their respective teams, guided by a **Mentors Layer**
of 15 world-class influences. It includes a comprehensive PRD generation system with
35+ templates, 70 expert personas, and a production-ready Next.js 15 web app (TaskFlow)
— all in one project with a single `npm install`.

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

| Path | Purpose |
|------|---------|
| **Web App (TaskFlow)** | |
| `src/app/` | Next.js 15 App Router pages (home, auth, dashboard, PRD tools) |
| `src/components/` | React components (auth, dashboard, layout, shadcn/ui) |
| `src/lib/` | Prisma client, utilities |
| `prisma/` | Database schema and migrations (SQLite dev / PostgreSQL prod) |
| `auth.ts` | NextAuth.js 5 configuration |
| **Agent System** | |
| `agents/chiefs/` | CEO, CMO, CTO, COO definitions |
| `agents/pool/tech/` | 38 tech specialist agents (incl. 6 operations/utility agents) |
| `agents/pool/marketing/` | 28 marketing specialist agents |
| `agents/personas/` | 70 expert persona docs (enrich agent prompts) |
| **Configuration** | |
| `config/globals.yaml` | Global brand, voice, token policy |
| `config/mentors.yaml` | 15 world-class mentors layer (influences agent decisions) |
| `config/orchestrator-schema.yaml` | Runtime schema for each run |
| `config/project-sessions/<id>/` | Per-project config and session state |
| `config/prd-templates/core/` | 29 core domain PRD templates |
| `config/prd-templates/specialized/` | 4 specialized PRD templates (AI/ML, DevOps, etc.) |
| `config/prd-templates/companion/` | Design + Tasks companion templates |
| `config/registries/` | Agent and MCP tool registries |
| **Orchestrator** | |
| `orchestrator/index.ts` | Main entry point (CLI) |
| `orchestrator/discovery.ts` | Discovery Agent interview logic |
| `orchestrator/prd-generator.ts` | PRD generation and agent selection |
| `orchestrator/agent-configurator.ts` | Session creation and agent loading |
| `orchestrator/executor.ts` | Agent execution engine (Claude API + artifact pipeline) |
| **Orchestrator Dashboard (Web)** | |
| `src/app/orchestrator/page.tsx` | Dashboard hub — sessions list, stats, CLI reference |
| `src/app/orchestrator/[id]/page.tsx` | Session detail — pipeline view, PRD, artifacts |
| `src/app/orchestrator/agents/page.tsx` | Agent registry — browse all 66 agents + personas |
| **Orchestrator API Routes** | |
| `src/app/api/orchestrator/sessions/route.ts` | GET all sessions with progress |
| `src/app/api/orchestrator/sessions/[id]/route.ts` | GET details / POST trigger execution |
| `src/app/api/orchestrator/artifacts/[id]/route.ts` | GET artifact content by project |
| `src/app/api/orchestrator/agents/route.ts` | GET full agent registry |
| **Outputs** | |
| `runs/prds/` | Generated Master PRDs |
| `runs/artifacts/<id>/` | Agent-produced outputs |
| `runs/generated-prds/` | Full PRD suite outputs |
| `runs/logs/` | Execution logs |
| **Reference** | |
| `implementations/` | AI agent playbooks (shadcn, design, components) |
| `scripts/` | PRD generation and project setup scripts |
| `docs/` | Workflow guides, API docs, GEKB reference |
| `.github/` | CI/CD workflows, issue templates |
| **Config Files (root)** | |
| `tsconfig.json` | Next.js TypeScript config |
| `tsconfig.orchestrator.json` | Orchestrator CLI TypeScript config |
| `next.config.js` | Next.js configuration |
| `tailwind.config.ts` | Tailwind CSS configuration |
| `components.json` | shadcn/ui component paths |

## Token Efficiency Rules

- Pass summaries (≤150 tokens) between agents, not full content
- Store full outputs as files; pass file paths
- Only send each agent the sections of the PRD it needs
- Respect the token_cap field in each agent's YAML

## Adding New Agents

Drop a YAML file in `agents/pool/tech/` or `agents/pool/marketing/` following this structure:

```yaml
id: "my_new_agent"
title: "My New Agent"
domain: "tech/frontend"   # or marketing/email etc.
reports_to: "CTO"         # or CMO
responsibilities:
  - "..."
expected_inputs: ["product_spec"]
expected_outputs: ["my_output"]
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

| Persona | Maps to Agent(s) |
|---------|-----------------|
| Sarah Chen (UX/UI) | `ux_designer`, `ui_designer` |
| Marcus Rodriguez (Backend) | `backend_engineer`, `api_designer` |
| Jordan Park (Frontend) | `web_frontend_engineer`, `design_engineer` |
| Rachel Thompson (Security) | `security_engineer` |
| Alex Kim (DevOps) | `devops_engineer`, `release_engineer` |
| Anna Kim (Accessibility) | `accessibility_engineer` |
| Carlos Martinez (Performance) | `frontend_performance_engineer` |
| David Chen (Analytics) | `product_analyst`, `experimentation_engineer` |
| Diana Patel (Integration) | `api_designer`, `data_engineer` |
| Emily Watson (Product) | `product_manager` |
| Jennifer Wu (QA) | `qa_engineer`, `test_automation_engineer` |
| Lisa Morgan (Content) | `content_strategist`, `editorial_writer` |
| Maria Santos (Database) | `database_engineer` |
| Thomas Clark (Mobile) | `ios_engineer`, `android_engineer`, `cross_platform_engineer` |
| Ryan Zhao (3D Design) | `3d_designer` |
| Priya Kapoor (Accessibility) | `accessibility_engineer` |
| Kenji Tanaka (Android) | `android_engineer` |
| Aisha Patel (API Design) | `api_designer` |
| Natasha Volkov (Art Direction) | `art_director` |
| Sofia Navarro (Cross-Platform) | `cross_platform_engineer` |
| Daniel Okafor (Data Engineering) | `data_engineer` |
| Liam Chen (Design Engineering) | `design_engineer` |
| Elena Petrova (Design Systems) | `design_systems_engineer` |
| Maya Washington (Experimentation) | `experimentation_engineer` |
| Nina Rossi (Information Architecture) | `information_architect` |
| Yuki Matsuda (Interaction Design) | `interaction_designer` |
| Kai Nakamura (iOS) | `ios_engineer` |
| Amara Osei (ML Engineering) | `ml_engineer` |
| Sven Eriksson (Motion Design) | `motion_designer` |
| Victor Andrade (Product Management) | `product_manager` |
| Hannah Johansson (Prototyping) | `prototype_engineer` |
| Grace Kim (QA Engineering) | `qa_engineer` |
| Omar Hassan (Release Engineering) | `release_engineer` |
| James Mitchell (Technical Writing) | `technical_writer` |
| Derek Okonkwo (Test Automation) | `test_automation_engineer` |
| Mia Chen-Ramirez (UX Design) | `ux_designer` |
| Alex Petrov (UX Research) | `ux_researcher` |
| Raj Krishnamurthy (WebGL) | `webgl_engineer` |
| Tanya Brooks (Affiliate Marketing) | `affiliate_manager` |
| Kevin Park (ASO) | `aso_specialist` |
| Zara Okafor-Williams (Brand Strategy) | `brand_strategist` |
| Jade Moreno (Community) | `community_manager` |
| Marcus Chen (CRM Automation) | `crm_automation_specialist` |
| Samantha Liu (CRO) | `cro_specialist` |
| Danielle Foster (Email Copy) | `email_copywriter` |
| Arjun Mehta (Email Design) | `email_designer` |
| Rachel Goldstein (Email Platform) | `email_platform_builder` |
| Natalie Rivera (Email Strategy) | `email_strategist` |
| Tyler Nguyen (Growth Marketing) | `growth_marketer` |
| Camille Dubois (Influencer Management) | `influencer_manager` |
| Wei Zhang (Marketing Analytics) | `marketing_analytics` |
| Jordan Blake (Marketing Copy) | `marketing_copywriter` |
| Isabella Santos (Marketing Design) | `marketing_designer` |
| David Okonjo (Marketing Strategy) | `marketing_strategist` |
| Lauren Torres (Media Buying) | `media_buyer` |
| Priya Sharma (Partnerships) | `partnership_manager` |
| Eric Chang (Performance Marketing) | `performance_marketer` |
| Nina Kowalski (Push Messaging) | `push_messaging_specialist` |
| Ryan Patel (SEM/PPC) | `sem_specialist` |
| Anika Johansson (SEO) | `seo_specialist` |
| Amara Johnson (Social Media) | `social_media_marketer` |
| Marco Valentino (Social Video) | `social_video_creator` |
| Sophie Laurent (UX Writing) | `ux_writer` |
| Andre Williams (Video Production) | `video_producer` |
| Elena Vasquez (Process Feedback) | `feedback_agent` |
| Nathan Okafor (Error Logging) | `error_logging_agent` |
| Clara Fitzgerald (Environment Mgmt) | `environment_checker_agent` |
| Tomás Herrera (Dependency Tracking) | `dependency_tracker_agent` |
| Ingrid Holm (Directory Housekeeping) | `directory_housekeeping_agent` |
| Mateo Rivera (Deployment Readiness) | `deployment_readiness_agent` |

## Running the Project

```bash
npm install                     # install all dependencies (one command)
npm run dev                     # start the TaskFlow web app (Next.js, port 1000)
npm run orchestrator            # start discovery → PRD → agent config → execute flow
npm run orchestrator:list       # list all project sessions
npm run list-agents             # see all available agents
npm run generate:master-prd     # generate a master PRD from template
npm run generate:all-prds       # generate complete PRD suite (35+ docs)
npm run db:push                 # push Prisma schema to database
npm run db:studio               # open Prisma Studio GUI
```

## Execution Engine

The executor (`orchestrator/executor.ts`) runs agents against Claude API:

1. Loads session + selected agents from `config/project-sessions/<id>/`
2. Generates a phased execution plan (9 phases: planning → design → build → test → deploy)
3. Iterates steps respecting dependencies — calls Claude with each agent's `system_prompt`
4. Saves outputs to `runs/artifacts/<id>/<agent>-output.md` + `manifest.json`
5. Falls back to structured placeholder when no `ANTHROPIC_API_KEY` is set

Set `ANTHROPIC_API_KEY` in `.env.local` for real Claude API calls.

## Web Dashboard

Visit `http://localhost:1000/orchestrator` to see:
- **Dashboard** — all sessions, progress stats, CLI reference
- **Session Detail** (`/orchestrator/<id>`) — pipeline view, PRD, artifact viewer
- **Agent Registry** (`/orchestrator/agents`) — browse all 64 agents + 14 personas

The dashboard auto-polls for updates during execution and lets you trigger runs via the UI.
