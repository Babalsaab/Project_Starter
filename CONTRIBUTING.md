# Contributing to Vibecoded Orchestrator

Thank you for your interest! This guide covers how to contribute agents, skills, personas, mentors, and code.

## Quick Start
1. Fork the repository
2. Create a feature branch (`git checkout -b feat/my-agent`)
3. Make your changes following the templates below
4. Run validation (`npm run validate && bash scripts/lint-agents.sh && bash scripts/validate-skills.sh`)
5. Submit a Pull Request

## Adding a New Agent

Drop a YAML file in `agents/pool/tech/` or `agents/pool/marketing/`:

```yaml
id: 'my_agent_id'
title: 'My Agent Title'
domain: 'tech/frontend'  # or marketing/email, etc.
reports_to: 'CTO'  # or CMO
responsibilities:
  - 'Primary responsibility 1'
  - 'Primary responsibility 2'
expected_inputs: ['product_spec', 'design_system']
expected_outputs: ['implementation', 'tests']
token_cap: 2000
mentors:
  primary: ['steve_jobs']
  secondary: ['jony_ive']
mentor_lens:
  - 'Does this meet quality standards?'
system_prompt: |
  You are a [role]. Given [inputs], produce [outputs].
  Be specific. Stay within token_cap.
```

**Requirements:**
- `id` must be unique, snake_case
- `domain` must follow `category/subcategory` format
- `system_prompt` must be >50 words
- `token_cap` must be set (typically 2000-4000)
- Must map to at least one mentor

## Adding a New Persona

Drop a markdown file in `agents/personas/` named `firstname-lastname-role.md`:

```markdown
# Firstname Lastname — Role Title

## Professional Identity
Current role, specializations, industry recognition...

## Background & Career Journey
Education, career progression, pivotal projects...

## Core Philosophy
- Principle 1
- Principle 2
...

## Technical Expertise & Tool Mastery
Languages, frameworks, platforms, tools...

## Methodology
Discovery → Execution → Review process...

## Collaboration Style
How they work with other teams...
```

## Adding a New Skill

Create a directory in `skills/` with a `SKILL.md` file:

```yaml
---
name: my-skill-name
description: What the skill does and when to use it. Max 1024 chars.
metadata:
  version: "1.0.0"
  author: "Your Name"
---

# Skill Instructions

Detailed instructions for the agent...
```

Also create `config.yaml` in the skill directory:
```yaml
id: my-skill-name
name: "My Skill"
description: "..."
version: "1.0.0"
compatible_agents: [agent_id_1, agent_id_2]
compatible_domains: ["tech/"]
priority: 10
enabled: true
```

**Requirements:**
- `name` must match directory name
- `name` must be lowercase with hyphens only, max 64 chars
- `description` must be <1024 chars
- Must include when to use AND when not to use

## Adding a New Mentor

Add to `config/mentors.yaml` under the `mentors:` key:

```yaml
  mentor_key:
    name: "Full Name"
    domain_focus: "Areas of expertise..."
    quote: "Famous quote..."
    principles:
      - "Principle 1"
      # ... (12 principles)
    influences_domains:
      - "tech/design"
    influences_agents:
      - agent_id
    review_lens: |
      1. Review question 1?
      2. Review question 2?
      3. Review question 3?
      4. Review question 4?
      5. Review question 5?
```

Also update `domain_mentor_map` and optionally `review_passes`.

## Code Contributions

### Setup
```bash
npm install          # Install all dependencies
npm run dev          # Start web app (port 1000)
npm run test         # Run tests
npm run lint         # Run linter
npm run type-check   # TypeScript check
```

### Conventions
- TypeScript strict mode
- ESLint + Prettier enforced via husky pre-commit
- Conventional commits (feat:, fix:, chore:, docs:)
- Tests required for orchestrator/ and mcp-server/ changes
- Max 300 lines per TypeScript file

### Testing
```bash
npm run test                    # All tests
npm run test:orchestrator       # Orchestrator tests only
npm run test:e2e                # E2E tests
bash scripts/lint-agents.sh     # Validate agents
bash scripts/validate-skills.sh # Validate skills
```

## Pull Request Process
1. Fill out the PR template completely
2. Ensure all checks pass (lint, type-check, tests, agent/skill validation)
3. Link any related issues
4. Request review from a maintainer
5. Address review feedback promptly

## Code of Conduct
Be respectful, constructive, and inclusive. We welcome contributors of all backgrounds and experience levels.

## License
By contributing, you agree that your contributions will be licensed under the project's license.
