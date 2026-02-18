# readme_copilot.md — Self-Executing Integration Guide for Claude Code

> **To Claude Code:** This file is your instruction set. Read it fully before doing anything.
> Then execute each phase in order. Do not ask the user for steps — infer from context and act.

---

## What You Are Working With

You have been given the **Vibecoded Orchestrator** — a complete multi-agent AI system that acts
like a structured IT company. It contains:

- 66 specialist agents (38 tech + 28 marketing) in `agents/pool/`
- 4 chief agents (CEO, CMO, CTO, COO) in `agents/chiefs/`
- 70 expert personas in `agents/personas/`
- 15 world-class mentor influences in `config/mentors.yaml`
- 35+ PRD templates in `config/prd-templates/`
- A full orchestrator CLI in `orchestrator/`
- A Next.js 15 web dashboard in `src/`

Your job is to **integrate this system with the user's existing project** and make it fully operational.

---

## Phase 0 — Orientation (do this first, silently)

Before anything else, read these files to understand the full system:

1. `CLAUDE.md` — master instructions for the orchestrator
2. `config/globals.yaml` — global defaults, token policy, provider config
3. `config/orchestrator-schema.yaml` — runtime schema
4. `config/mentors.yaml` — mentor layer (15 influences injected into agent thinking)
5. `agents/chiefs/ceo.yaml` — orchestrator persona
6. `package.json` — available scripts

**Then scan the user's existing project** (the directory they pointed you to, or the current working
directory if this file is inside it). Look for:
- Their tech stack (`package.json`, `requirements.txt`, `go.mod`, etc.)
- Their existing folder structure (`src/`, `app/`, `pages/`, `components/`, etc.)
- Any existing `.env` or `.env.local` files
- Any existing `README.md` or docs
- Their main entry point and build command

Do not report findings yet. Use them to inform Phase 1.

---

## Phase 1 — Environment Setup

### 1.1 Install dependencies
```bash
npm install
```

### 1.2 Check for `.env.local`
If `.env.local` does not exist, copy from `.env.example`:
```bash
cp .env.example .env.local
```

### 1.3 Set the Anthropic API key
Check if `ANTHROPIC_API_KEY` in `.env.local` is a real key (starts with `sk-ant-` and is not a placeholder).

- If **real key exists** → proceed, agents will run in full Claude API mode
- If **no key / placeholder** → tell the user exactly this:
  > "Add your Anthropic API key to `.env.local` as `ANTHROPIC_API_KEY=sk-ant-...` — without it,
  > agents run in placeholder mode and produce template text instead of real output."
  > Then continue with setup anyway so everything else is ready.

### 1.4 Push the database schema
```bash
npm run db:push
```

### 1.5 Verify the install
```bash
npm run list-agents
```
This should list all 66 agents. If it fails, read the error and fix it before proceeding.

---

## Phase 2 — Project Discovery

You need to understand the user's existing project before deploying agents against it.

### 2.1 Scan the existing project

Read the following from the user's project root (wherever they pointed you):
- Main `package.json` or equivalent — extract: framework, dependencies, scripts
- `src/` or `app/` structure — identify pages, components, API routes
- Any existing `README.md` — extract: purpose, features, current state
- Any `.env` or `.env.local` — note what services are connected (do NOT read secrets)

### 2.2 Build a project context summary

Create the file `runs/artifacts/active-project/context-snapshot.md` with this structure:

```markdown
# Active Project Context Snapshot
Generated: <date>

## Tech Stack
- Framework: <detected>
- Language: <detected>
- Database: <detected>
- Auth: <detected>
- Styling: <detected>

## Current State
- What exists: <list of main features/pages/routes found>
- What's incomplete: <list of obvious gaps, missing pages, TODOs found in code>
- Build command: <detected>
- Dev command: <detected>

## Integration Points
- Where Vibecoded agents should focus: <inferred from gaps>
- Highest-impact improvements available: <top 5 inferred>
```

### 2.3 Create a project session

Create `config/project-sessions/active/session.yaml`:

```yaml
project_id: "active"
project_name: "<inferred from package.json or README>"
project_type: "<web_app | mobile_app | saas | ecommerce — infer from stack>"
status: "ready"
created_at: "<today's date>"
context_snapshot: "runs/artifacts/active-project/context-snapshot.md"

objective:
  primary_goal: "Improve and complete the existing project using specialist agents"
  secondary_goals:
    - "Fill identified gaps"
    - "Improve code quality, security, and performance"
    - "Generate missing documentation"

selected_agents: []  # Will be populated in Phase 3
```

---

## Phase 3 — Agent Selection & Deployment

Based on the gaps and stack identified in Phase 2, select the most relevant agents.

### 3.1 Agent selection logic

Read each relevant agent YAML from `agents/pool/tech/` and `agents/pool/marketing/`.
Select agents whose `expected_inputs` match what you have and whose `expected_outputs`
match what the project needs.

**Priority order for a typical half-built project:**

| Priority | Agent ID | Why |
|----------|----------|-----|
| 1 | `feedback_agent` | Assess what's done and what's missing |
| 2 | `security_engineer` | Audit existing code for vulnerabilities |
| 3 | `qa_engineer` | Generate missing tests |
| 4 | `frontend_performance_engineer` | Find and fix perf bottlenecks |
| 5 | `ux_researcher` | Audit existing UX flows |
| 6 | `technical_writer` | Generate missing docs |
| 7 | `deployment_readiness_agent` | Pre-launch checklist |
| 8 | `error_logging_agent` | Set up proper error tracking |

Add or replace based on the specific gaps you found in Phase 2.

### 3.2 Run agents

For each selected agent, follow the exact protocol from `CLAUDE.md`:

```
Step 1: Read agents/pool/<domain>/<id>.yaml
Step 2: Read agents/personas/<matching-persona>.md (if exists — check CLAUDE.md persona mapping)
Step 3: Read the mentor references listed in the agent YAML
Step 4: Adopt the system_prompt as your active persona
Step 5: Feed it the context from runs/artifacts/active-project/context-snapshot.md
Step 6: Apply the agent's mentor_lens questions as a quality check
Step 7: Produce only the agent's expected_outputs
Step 8: Write output to runs/artifacts/active-project/<agent-id>-output.md
Step 9: Update session.yaml with the agent's status and output path
```

### 3.3 Token efficiency rules (follow strictly)

- Pass only summaries (≤150 tokens) between agents — never full content
- Reference file paths, not file contents, when chaining agents
- Respect each agent's `token_cap` field
- Compress outputs aggressively between phases

---

## Phase 4 — Apply Improvements

After agents produce their outputs in `runs/artifacts/active-project/`, apply the recommendations:

### 4.1 For each agent output file:
1. Read `runs/artifacts/active-project/<agent-id>-output.md`
2. Identify actionable changes (code, config, structure)
3. Apply them directly to the user's project files
4. Do not apply speculation — only apply concrete, specific recommendations

### 4.2 Priority of application:
1. **Security fixes** — apply immediately, no questions asked
2. **Bug fixes** — apply immediately
3. **Missing tests** — create test files
4. **Performance improvements** — apply if non-breaking
5. **Documentation** — create/update README, inline docs
6. **UX improvements** — apply if purely additive

### 4.3 For each applied change:
- Note what was changed and why in `runs/artifacts/active-project/changes-log.md`
- Keep changes minimal and focused — do not refactor code that wasn't flagged

---

## Phase 5 — PRD Generation (optional but powerful)

If the user wants a full specification suite for their project:

```bash
npm run generate:all-prds
```

Or for a targeted PRD:
```bash
npm run generate:master-prd
```

The PRDs land in `runs/prds/` and `runs/generated-prds/`.
Use these as long-term project specs — feed them to agents for future work.

---

## Phase 6 — Web Dashboard

Start the orchestrator dashboard so the user can monitor everything visually:

```bash
npm run dev
```

Then tell the user:
> "Open http://localhost:1000/orchestrator to see all sessions, agent outputs, and pipeline status.
> Your active session is at http://localhost:1000/orchestrator/active"

---

## Phase 7 — Ongoing Usage (tell the user this)

Once setup is complete, explain to the user how to use this going forward:

### To improve a specific part of the project:
> "Tell me to 'act as [agent-id]' — e.g. 'act as the security_engineer and audit my auth flow'.
> I will read that agent's YAML, adopt its persona, and produce expert-level output for that domain."

### To run a full orchestrated improvement cycle:
```bash
npm run orchestrator
```

### To see all available agents:
```bash
npm run list-agents
```

### To add this system's CLAUDE.md to your own project root:
Copy `CLAUDE.md` to your project root — Claude Code will read it automatically in every session
and know how to operate all 66 agents on your codebase without re-explaining.

### Using with GitHub Copilot:
Agent outputs in `runs/artifacts/` are plain markdown. Open them in VS Code alongside your code
— Copilot reads open files as context and will autocomplete inline with the agent's recommendations.

---

## Mentor Layer Reference

Every agent in this system is influenced by 15 world-class mentors defined in `config/mentors.yaml`.
When acting as any agent, you should read the mentor references in that agent's YAML and apply their
principles as a quality filter on your output. This is what separates generic AI suggestions from
genuinely expert-level recommendations.

---

## Key File Paths Reference

| What | Where |
|------|-------|
| All agent definitions | `agents/pool/tech/` and `agents/pool/marketing/` |
| Expert personas | `agents/personas/` |
| Mentor influences | `config/mentors.yaml` |
| Global config | `config/globals.yaml` |
| Active session | `config/project-sessions/active/session.yaml` |
| Agent outputs | `runs/artifacts/active-project/` |
| PRD templates | `config/prd-templates/core/` |
| Generated PRDs | `runs/prds/` |
| Web dashboard | `src/app/orchestrator/` |
| Orchestrator CLI | `orchestrator/index.ts` |

---

## Done

When all phases are complete, give the user a summary with:
1. What was found in their existing project (gaps, strengths)
2. Which agents were run and what they produced
3. What changes were applied directly
4. What files to look at next (`runs/artifacts/active-project/`)
5. One-line reminder: "Say 'act as [agent-id]' anytime to invoke a specialist."
