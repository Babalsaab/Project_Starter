---
name: antigravity-skill-creator
description: Use when creating skills compatible with AntiGravity agent environment, or when building cross-platform skills that work in both Claude Code and AntiGravity/.agent/ setups.
allowed-tools: Read, Write, Edit, Glob, Grep, Bash(ls *), Bash(mkdir *)
---

# AntiGravity Skill Creator

Creates skills compatible with the AntiGravity agent environment (`.agent/skills/`) following the Agent Skills open standard. Skills created here also work with Gemini CLI, Cursor, Windsurf, and other agents supporting the standard.

## When to Use

- Building a skill for AntiGravity or `.agent/skills/` format
- Creating cross-platform skills (Claude Code + AntiGravity + others)
- Converting existing skills to the Agent Skills open standard

## Folder Structure

Every skill must follow this hierarchy:

```
<skill-name>/
  SKILL.md          # Required: Main logic and instructions (<500 lines)
  scripts/          # Optional: Helper scripts (validation, API calls)
  examples/         # Optional: Reference implementations
  resources/        # Optional: Templates, checklists, assets
```

## YAML Frontmatter Standards

```yaml
---
name: gerund-form-name        # e.g., "testing-code", "managing-databases"
description: Third person.    # Include specific trigger keywords. Max 1024 chars.
allowed-tools: Read, Write    # Comma-separated tool restrictions
---
```

Rules:
- **name**: Gerund form, max 64 chars, lowercase + numbers + hyphens only
- **description**: Written in third person with specific triggers/keywords
- No "claude" or "anthropic" in the name

## Writing Principles (The "Claude Way")

1. **Conciseness** — Assume the agent is smart. Don't explain basics. Focus on unique logic.
2. **Progressive Disclosure** — Keep SKILL.md under 500 lines. Link to secondary files only one level deep.
3. **Forward Slashes** — Always use `/` for paths, never `\`.
4. **Degrees of Freedom**:
   - **Bullet Points** — High-freedom tasks (heuristics, guidelines)
   - **Code Blocks** — Medium-freedom (templates, schemas)
   - **Specific Bash Commands** — Low-freedom (fragile operations that must be exact)

## Workflow & Feedback Loops

For complex tasks, include:

1. **Checklists** — Markdown checklist the agent copies and updates to track state
2. **Validation Loops** — Plan-Validate-Execute pattern (check config BEFORE applying changes)
3. **Error Handling** — Scripts are "black boxes" — tell agent to run `--help` if unsure

## Cross-Platform Skill Creation

To create a skill that works in BOTH Claude Code and AntiGravity:

### Step 1: Build the AntiGravity version
```
.agent/skills/<name>/
  SKILL.md
  scripts/
  resources/
```

### Step 2: Symlink or copy to Claude Code
```
.claude/skills/<name>/
  SKILL.md      # Same file, Claude Code frontmatter is a superset
```

### Step 3: Add Orchestrator integration (optional)
```
skills/<name>/
  config.yaml   # Orchestrator-specific: compatible_agents, domain, priority
  SKILL.md      # Same content
```

### Frontmatter Compatibility

| Field | Claude Code | AntiGravity | Both |
|-------|------------|-------------|------|
| `name` | Yes | Yes | Yes |
| `description` | Yes | Yes | Yes |
| `allowed-tools` | Yes | Yes | Yes |
| `context: fork` | Yes | No | Claude only |
| `model` | Yes | No | Claude only |
| `hooks` | Yes | No | Claude only |

## Skill Template

When creating a new skill, use this template:

```markdown
---
name: [gerund-name]
description: [3rd-person description with trigger keywords]
allowed-tools: [tools needed]
---

# [Skill Title]

## When to Use This Skill
- [Trigger scenario 1]
- [Trigger scenario 2]

## Workflow
1. [Step with clear instruction]
2. [Step with validation]
3. [Step with output]

## Instructions
[Specific logic, code snippets, or rules]

## Checklist
- [ ] [Verification item 1]
- [ ] [Verification item 2]

## Resources
- [Link to scripts/ or resources/ if applicable]
```

## Output Convention

When generating a skill, output:
1. The full directory structure
2. Complete SKILL.md content
3. Any supporting files (scripts, resources, examples)
4. Installation instructions for the target platform

## Notes

- Test both `/skill-name` invocation and natural language triggering
- Verify skills don't exceed the character budget (2% of context window)
- For skills with side effects (API calls, file generation), set `disable-model-invocation: true`
