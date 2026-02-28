---
name: accessibility-check
description: "Use when checking WCAG 2.1 AA compliance, auditing semantic HTML, validating ARIA attributes, testing color contrast, or reviewing keyboard navigation and screen reader support."
version: "1.0.0"
argument-hint: "[component-or-page-file]"
compatible_agents:
  - accessibility_engineer
  - web_frontend_engineer
  - ux_designer
  - ui_designer
  - design_engineer
  - design_systems_engineer
  - interaction_designer
  - ios_engineer
  - android_engineer
  - cross_platform_engineer
domain:
  - "tech/frontend"
  - "tech/design"
  - "tech/mobile"
priority: 12
user_invocable: true
---

```skill
# Accessibility Compliance Check

When producing or reviewing UI code, apply WCAG 2.1 AA compliance checks:

## Semantic HTML

- Use correct heading hierarchy (h1 → h2 → h3, no skipping)
- Use `<nav>`, `<main>`, `<aside>`, `<footer>`, `<header>` landmarks
- Use `<button>` for actions, `<a>` for navigation (never divs)
- Use `<ul>/<ol>` for lists, `<table>` for tabular data
- Every `<img>` must have `alt` text (decorative images: `alt=""`)
- Every `<form>` input must have an associated `<label>`

## ARIA Attributes

- Use ARIA only when native HTML semantics are insufficient
- Required: `aria-label` or `aria-labelledby` on interactive elements without visible text
- Required: `aria-expanded` on expandable controls (accordions, dropdowns)
- Required: `aria-live` regions for dynamic content updates
- Never use `aria-hidden="true"` on focusable elements
- `role` attributes must match expected interaction pattern

## Color & Contrast

- Text contrast ratio ≥ 4.5:1 (AA normal text)
- Large text (18px+ or 14px+ bold) contrast ratio ≥ 3:1
- UI component boundaries contrast ratio ≥ 3:1
- Never convey information through color alone (add icons, text, patterns)
- Ensure focus indicators are visible (minimum 3:1 contrast against background)

## Keyboard Navigation

- All interactive elements must be reachable via Tab
- Logical tab order following visual layout
- Escape key closes modals/popups and returns focus
- Arrow keys for related controls (tabs, menus, radio groups)
- No keyboard traps — users must be able to leave any component
- Skip-to-content link at top of page

## Screen Reader Compatibility

- Dynamic content changes announced via `aria-live`
- Loading states communicated (e.g., `aria-busy`)
- Error messages associated with inputs via `aria-describedby`
- Modal dialogs trap focus and announce opening
- Page title updates on route changes (SPA)

## Motion & Animation

- Respect `prefers-reduced-motion` media query
- No auto-playing animations without pause control
- Flashing content must not exceed 3 flashes per second

## Output Format

```
## Accessibility Audit Report

### Compliance Level: [AAA | AA | A | Non-Compliant]

### Findings
| # | WCAG Criterion | Level | Status | Element | Issue | Fix |
|---|----------------|-------|--------|---------|-------|-----|
| 1 | 1.1.1 Non-text Content | A | FAIL | img.hero | Missing alt | Add descriptive alt text |

### Summary
- Pass: N criteria
- Fail: N criteria
- Not Applicable: N criteria

### Priority Fixes
1. [Critical] ...
2. [Important] ...
3. [Enhancement] ...
```
```
