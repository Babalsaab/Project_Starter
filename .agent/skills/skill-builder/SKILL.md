---
name: skill-builder
description: Use when creating new skills, optimizing existing skills, or auditing skill quality. Guides skill development for Claude Code, AntiGravity, and the Vibecoded Orchestrator agent-skill architecture.
allowed-tools: Read, Write, Edit, Glob, Grep
---

## What This Skill Does

Guides the creation and optimization of skills for **Claude Code** (`.claude/skills/`), **AntiGravity** (`.agent/skills/`), and the **Vibecoded Orchestrator** (`skills/`). Use this whenever:

- Building a new skill from scratch
- Optimizing or auditing an existing skill
- Creating cross-platform skills (works in all AI coders)
- Troubleshooting a skill that isn't working correctly

## Quick Start: Skill Types in This Project

| System | Location | Format | Used By |
|--------|----------|--------|---------|
| **Claude Code Skills** | `.claude/skills/<name>/SKILL.md` | YAML frontmatter + markdown | Claude Code `/slash-commands` |
| **AntiGravity Skills** | `.agent/skills/<name>/SKILL.md` | YAML frontmatter + markdown | AntiGravity `/slash-commands` |
| **Orchestrator Skills** | `skills/<name>/SKILL.md` + `config.yaml` | YAML config + SKILL.md | MCP server `get_skill`, `list_skills` |

## Mode 1: Build a New Skill

Run the **Discovery Interview** first. Do NOT start writing files until discovery is complete.

### Discovery Interview (6 Rounds)

**Round 1: Goal & Name**
- What does this skill do? What problem does it solve?
- What should we call it? (lowercase, hyphens, max 64 chars)
- Which system? Claude Code / AntiGravity / Orchestrator / All?

**Round 2: Trigger**
- What would someone say to trigger this? (2-3 natural language phrases)
- Should it be user-only (`/slash-command`), auto-invocable, or both?
- Does it accept arguments? If so, what?

**Round 3: Step-by-Step Process**
- Walk through exactly what happens from trigger to output
- For each step: Does the agent do it directly, or delegate?
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
Summarize back to the user before building.

### Build Phase

**Step 1: Write the frontmatter**
```yaml
---
name: [gerund-name]
description: [3rd person, includes trigger keywords]
allowed-tools: [comma-separated tool list]
---
```

**Step 2: Write the content**
1. **When to Use** — Trigger scenarios
2. **Workflow** — Numbered steps with exact instructions
3. **Output format** — Templates or examples
4. **Notes** — Edge cases, constraints, what NOT to do

**Step 3: Place the file**
- AntiGravity: `.agent/skills/<name>/SKILL.md`
- Claude Code: `.claude/skills/<name>/SKILL.md`
- Orchestrator: `skills/<name>/SKILL.md` + `config.yaml`
- Cross-platform: Create in `.agent/skills/` and copy to `.claude/skills/`

**Step 4: Test** — Invoke via `/skill-name` and via natural language

## Mode 2: Audit an Existing Skill

### Checklist
- [ ] `name` matches directory name
- [ ] `description` uses natural trigger keywords
- [ ] `allowed-tools` set if tool access should be restricted
- [ ] Under 500 lines
- [ ] Clear step-by-step workflow
- [ ] Output format specified
- [ ] All file paths documented
- [ ] No vague instructions
- [ ] Scripts have correct paths
- [ ] API keys in env vars, never hardcoded

## Frontmatter Compatibility

| Field | Claude Code | AntiGravity | Orchestrator |
|-------|------------|-------------|-------------|
| `name` | Yes | Yes | Yes |
| `description` | Yes | Yes | Yes |
| `allowed-tools` | Yes | Yes | No |
| `argument-hint` | Yes | Yes | Yes |
| `context: fork` | Yes | No | No |
| `disable-model-invocation` | Yes | No | No |

## Notes

- Always read an existing skill before optimizing it
- Check for similar skills that could be extended instead
- Keep SKILL.md under 500 lines — move reference docs to supporting files
- Use forward slashes `/` for paths, never `\`
