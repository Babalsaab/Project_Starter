---
name: prd-analysis
description: "Use when analyzing PRDs, detecting requirement gaps, mapping dependencies, assessing risks, or prioritizing features in product requirement documents."
version: "1.0.0"
argument-hint: "[prd-file-path]"
compatible_agents:
  - product_manager
  - ux_researcher
  - marketing_strategist
  - information_architect
domain: "all"
priority: 15
user_invocable: true
---

# PRD Analysis Skill

When receiving a PRD or project requirement document, apply this structured analysis:

## Step 1: Gap Detection
Scan the PRD for:
- Missing success metrics (every feature needs a measurable KPI)
- Undefined edge cases (what happens when X fails?)
- Ambiguous requirements (terms like "fast", "secure", "modern" need quantification)
- Missing user flows (happy path is defined, but what about error/edge paths?)

## Step 2: Dependency Mapping
For each feature/requirement:
1. List all technical dependencies (APIs, services, data)
2. List all team dependencies (which other agents need to deliver first?)
3. Identify blocking vs non-blocking dependencies
4. Flag circular dependencies

## Step 3: Risk Assessment
Rate each requirement:
- **Complexity**: Low / Medium / High / Very High
- **Uncertainty**: Known / Some unknowns / Many unknowns
- **Dependencies**: None / Internal / External / Third-party

## Step 4: Output Enhancement
When producing outputs based on PRD analysis:
- Always reference the specific PRD section you're addressing
- Call out assumptions explicitly
- Flag items that need clarification with [NEEDS_CLARIFICATION] tag
- Suggest alternatives when requirements seem suboptimal

## Priority Framework
- P0: Must have for launch (blocks everything)
- P1: Should have for launch (degrades experience if missing)
- P2: Nice to have (can ship without)
- P3: Future consideration (explicit not-now items)
