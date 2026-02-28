---
name: skill-builder
description: Use when creating new skills, optimizing existing skills, or auditing skill quality. Guides skill development following Claude Code official best practices and the Vibecoded Orchestrator's agent-skill architecture.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(ls *), Bash(mkdir *)
---

## What This Skill Does

Guides the creation and optimization of skills for both **Claude Code** (`.claude/skills/`) and the **Vibecoded Orchestrator** (`skills/`). Use this whenever:

- Building a new skill from scratch
- Optimizing or auditing an existing skill
- Deciding on advanced features (subagent execution, hooks, dynamic context, etc.)
- Troubleshooting a skill that isn't working correctly

For the complete technical reference on all frontmatter fields, advanced patterns, and troubleshooting, see [reference.md](reference.md).

## Quick Start: Skill Types in This Project

This project has **two skill systems**:

| System | Location | Format | Used By |
|--------|----------|--------|---------|
| **Claude Code Skills** | `.claude/skills/<name>/SKILL.md` | YAML frontmatter + markdown | Claude Code native `/slash-commands` |
| **Orchestrator Skills** | `skills/<name>/SKILL.md` + `config.yaml` | YAML config + SKILL.md with frontmatter | MCP server `get_skill`, `list_skills` tools |

**When to use which:**
- **Claude Code skill** — For interactive tasks invoked by `/command` or auto-detected by Claude. Runs in the AI coder session.
- **Orchestrator skill** — For quality gates applied during pipeline execution. Used by agents via the MCP server.

## Mode 1: Build a New Skill

Run the **Discovery Interview** first. Do NOT start writing files until discovery is complete.

### Discovery Interview

Ask questions using AskUserQuestion, one round at a time.

**Round 1: Goal & Name**
- What does this skill do? What problem does it solve?
- What should we call it? (lowercase, hyphens, max 64 chars)
- Which system? Claude Code skill (`.claude/skills/`) or Orchestrator skill (`skills/`)?

**Round 2: Trigger**
- What would someone say to trigger this? (2-3 natural language phrases)
- Should it be user-only (`/slash-command`), Claude-auto-invocable, or both?
- Does it accept arguments? If so, what?

**Round 3: Step-by-Step Process**
- Walk through exactly what happens from trigger to output
- For each step: Does Claude do it directly, or delegate?
- Conversational (back-and-forth) or fire-and-forget?

**Round 4: Inputs, Outputs & Dependencies**
- What inputs does the skill need?
- What does it produce? Where do outputs go?
- External APIs, scripts, or tools needed?
- Which orchestrator agents is this compatible with?

**Round 5: Guardrails & Edge Cases**
- What could go wrong? Common failure modes?
- What should this skill NOT do?
- Cost concerns? (API calls, image generation, etc.)

**Round 6: Confirmation**
Summarize understanding back to the user:

```
## Skill Summary: [name]

**Goal:** [one sentence]
**System:** Claude Code / Orchestrator / Both
**Trigger:** `/name` + [natural language phrases]
**Arguments:** [what it accepts, or "none"]

**Process:**
1. [step]
2. [step]

**Inputs:** [what it reads/needs]
**Outputs:** [what it produces + where]
**Compatible Agents:** [agent IDs if orchestrator skill]
**Guardrails:** [what can go wrong, what to avoid]
```

### Build Phase

**Step 1: Choose the target system**

For **Claude Code skills** (`.claude/skills/<name>/SKILL.md`):
```yaml
---
name: [gerund-name]
description: [3rd person, includes trigger keywords]
allowed-tools: [comma-separated tool list]
---
```

For **Orchestrator skills** (`skills/<name>/`), create both files:
- `config.yaml` — id, name, description, version, domain, priority, compatible_agents
- `SKILL.md` — YAML frontmatter + checklist content

**Step 2: Write the content**
1. **Context** — Files to read, APIs to call
2. **Step-by-step workflow** — Numbered steps with exact instructions
3. **Output format** — Templates or examples
4. **Notes** — Edge cases, constraints, what NOT to do

**Step 3: Add supporting files (if needed)**
- Keep SKILL.md under 500 lines
- Move detailed reference to supporting files
- Reference them from SKILL.md

**Step 4: Test**
- Natural language invocation
- Direct `/skill-name` invocation
- Edge cases with missing/unusual input

## Mode 2: Audit an Existing Skill

### Frontmatter Audit
- [ ] `name` matches directory name
- [ ] `description` uses natural trigger keywords
- [ ] `allowed-tools` set if tool access should be restricted
- [ ] `context: fork` used if self-contained
- [ ] No unnecessary fields

### Content Audit
- [ ] Under 500 lines
- [ ] Clear step-by-step workflow
- [ ] Output format specified
- [ ] All file paths documented
- [ ] No vague instructions

### Integration Audit
- [ ] Documented in CLAUDE.md
- [ ] Supporting files referenced (not orphaned)
- [ ] Scripts have correct paths
- [ ] API keys in env vars, never hardcoded

### Quality Audit
- [ ] A beginner could follow the instructions
- [ ] Instructions are actionable, not abstract
- [ ] Doesn't duplicate CLAUDE.md content
- [ ] Output paths follow convention

## Important Notes

- Always read an existing skill before optimizing it
- Check for similar skills that could be extended instead
- For advanced patterns (subagent execution, hooks, permissions), see [reference.md](reference.md)
