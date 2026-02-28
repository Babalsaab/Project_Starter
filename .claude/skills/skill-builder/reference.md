---
source: https://code.claude.com/docs/en/skills
---

# Skill Builder Reference

Complete technical reference for Claude Code skills. Covers all frontmatter fields, advanced patterns, argument passing, troubleshooting, and how skills fit into your project.

## Understanding CLAUDE.md vs Skills

| | CLAUDE.md | Skill |
|---|---|---|
| **When loaded** | Every conversation, always | Only when invoked (via `/name` or auto-detection) |
| **What it's for** | Project-wide rules, conventions, context | Specific task workflows, specialized procedures |
| **Size concern** | Always in context, so keep it focused | Only loaded when needed, but keep under 500 lines |

**Rule of thumb:** If Claude should *always* know it, put it in CLAUDE.md. If Claude should only know it when doing a specific task, make it a skill.

## Frontmatter Field Reference

| Field | Required | Type | Default | Description |
|-------|----------|------|---------|-------------|
| `name` | No | string | directory name | Display name and `/slash-command`. Lowercase letters, numbers, hyphens only. Max 64 chars. |
| `description` | Recommended | string | first paragraph | What the skill does and when to use it. Claude uses this for auto-invocation. |
| `argument-hint` | No | string | none | Autocomplete hint. Shown in `/` menu. Examples: `[issue-number]`, `[filename]` |
| `disable-model-invocation` | No | boolean | `false` | When `true`, only the user can invoke the skill. |
| `user-invocable` | No | boolean | `true` | When `false`, hides from `/` menu. Only Claude can invoke. |
| `allowed-tools` | No | string (CSV) | all tools | Tools available without permission prompts. |
| `model` | No | string | inherit | Model: `sonnet`, `opus`, `haiku`, or omit to inherit. |
| `context` | No | string | none | Set to `fork` to run in isolated subagent. |
| `agent` | No | string | `general-purpose` | Subagent type when `context: fork`. Options: `Explore`, `Plan`, `general-purpose`. |
| `hooks` | No | object | none | Lifecycle hooks scoped to this skill. |

## Invocation Control Matrix

| Frontmatter | User can invoke? | Claude can invoke? |
|-------------|------------------|--------------------|
| (default) | Yes | Yes |
| `disable-model-invocation: true` | Yes | No |
| `user-invocable: false` | No | Yes |

## String Substitutions

| Variable | Description | Example |
|----------|-------------|---------|
| `$ARGUMENTS` | All arguments passed | `/fix-issue 123` -> `123` |
| `$ARGUMENTS[N]` | Specific argument (0-based) | `$ARGUMENTS[0]` = first arg |
| `$N` | Shorthand for `$ARGUMENTS[N]` | `$0` = first arg |
| `${CLAUDE_SESSION_ID}` | Current session ID | Useful for logs |

## Skill File Locations

| Location | Path | Applies to | Priority |
|----------|------|------------|----------|
| Personal | `~/.claude/skills/<name>/SKILL.md` | All your projects | High |
| Project | `.claude/skills/<name>/SKILL.md` | This project only | Medium |
| Plugin | `<plugin>/skills/<name>/SKILL.md` | Where plugin enabled | Lowest |

## allowed-tools Syntax

```yaml
# Read-only skill
allowed-tools: Read, Grep, Glob

# Specific commands only
allowed-tools: Bash(git status), Bash(git diff), Read

# Pattern matching
allowed-tools: Bash(python scripts/*), Read, Write
```

## Advanced Patterns

### Dynamic Context Injection

The `` !`command` `` syntax runs shell commands BEFORE skill content is sent to Claude:

```yaml
---
name: pr-summary
context: fork
agent: Explore
allowed-tools: Bash(gh *)
---

## PR context
- PR diff: !`gh pr diff`
- Changed files: !`gh pr diff --name-only`

Summarize this pull request...
```

### Running Skills in a Subagent (context: fork)

**When to use:** Self-contained tasks, verbose output, tool restrictions needed.
**When NOT to use:** Guidelines without concrete task, needs conversation history.

Agent options: `Explore` (Haiku, read-only), `Plan` (inherit, read-only), `general-purpose` (inherit, all tools).

### Hooks in Skills

```yaml
---
name: safe-editor
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate-command.sh"
  PostToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: command
          command: "./scripts/run-linter.sh"
---
```

### Extended Thinking (Ultrathink)

Include the word `ultrathink` anywhere in skill content to activate extended thinking.

## Troubleshooting

- **Skill not triggering:** Check description keywords, verify with "What skills are available?", try `/skill-name` directly
- **Triggers too often:** Make description more specific, add `disable-model-invocation: true`
- **Subagent returns nothing:** Needs actionable prompt, not just guidelines
- **Arguments not substituting:** Verify `$ARGUMENTS`/`$N` appears in content
- **Character budget exceeded:** Keep descriptions concise, check `/context`, override with `SLASH_COMMAND_TOOL_CHAR_BUDGET` env var
