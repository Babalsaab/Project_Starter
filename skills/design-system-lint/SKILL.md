---
name: design-system-lint
description: "Use when validating design system tokens, checking spacing scales, auditing color palettes, reviewing typography, or ensuring component usage consistency."
version: "1.0.0"
argument-hint: "[component-file]"
compatible_agents:
  - design_systems_engineer
  - design_engineer
  - web_frontend_engineer
  - ui_designer
  - ux_designer
  - interaction_designer
  - cross_platform_engineer
  - ios_engineer
  - android_engineer
domain:
  - "tech/frontend"
  - "tech/design"
  - "tech/mobile"
priority: 10
user_invocable: true
---

```skill
# Design System Lint

When building or reviewing UI components, enforce design system consistency:

## Design Token Usage

### Spacing
- Use only design system spacing tokens (e.g., Tailwind's spacing scale)
- Allowed values: 0, 0.5, 1, 1.5, 2, 2.5, 3, 3.5, 4, 5, 6, 7, 8, 9, 10, 11, 12, 14, 16, 20, 24, 28, 32, 36, 40, 44, 48, 52, 56, 60, 64, 72, 80, 96
- ❌ Never use arbitrary values: `p-[13px]`, `mt-[7px]`
- ❌ Never use inline styles for spacing: `style={{ margin: '13px' }}`
- ✅ Use token values: `p-4`, `mt-2`, `gap-6`

### Colors
- Use only palette colors from the design system
- Reference semantic color tokens, not raw hex/RGB values
- ❌ `text-[#1a73e8]`, `bg-[rgb(26,115,232)]`
- ✅ `text-primary`, `bg-accent`, `text-muted-foreground`
- Dark mode: always pair `bg-*` with `dark:bg-*` or use CSS variables

### Typography
- Use defined type scale only (no arbitrary font sizes)
- ❌ `text-[15px]`, `font-size: 0.9375rem`
- ✅ `text-sm`, `text-base`, `text-lg`, `text-xl`
- Font weight: use semantic names (`font-normal`, `font-medium`, `font-bold`)
- Line height: use token values (`leading-tight`, `leading-normal`, `leading-relaxed`)

### Border Radius
- Use consistent radius tokens
- ✅ `rounded-sm`, `rounded-md`, `rounded-lg`, `rounded-full`
- ❌ `rounded-[5px]`, `border-radius: 5px`

### Shadows
- Use predefined shadow tokens
- ✅ `shadow-sm`, `shadow-md`, `shadow-lg`
- ❌ `shadow-[0_2px_4px_rgba(0,0,0,0.1)]`

## Component Patterns

### Composition Rules
- Use shadcn/ui components as base building blocks
- Don't recreate existing components (Button, Input, Dialog, etc.)
- Compose complex UI from primitive components
- Each component should have a single, clear responsibility

### Consistency Checks
- Same action = same component (all primary actions use `<Button>`)
- Consistent icon sizes within context (16px in nav, 20px in actions, 24px in heroes)
- Uniform loading states (use `<Skeleton>` patterns consistently)
- Standard empty states (icon + title + description + action)

### Responsive Patterns
- Mobile-first approach (base styles, then `sm:`, `md:`, `lg:`, `xl:`)
- Consistent breakpoint usage across pages
- Touch targets ≥ 44×44px on mobile
- Consistent grid systems (no mixing grid approaches)

## Component API Standards

### Props
- Use descriptive prop names matching design system vocabulary
- Variant props: `variant="primary" | "secondary" | "ghost" | "destructive"`
- Size props: `size="sm" | "md" | "lg"`
- Boolean props: `disabled`, `loading`, `fullWidth` (not `isDisabled`)
- Always provide defaults for optional props

### Slots & Children
- Use `children` for primary content
- Use named slots for structured content: `header`, `footer`, `icon`
- Avoid deeply nested render props — prefer composition

## Output Format

```
## Design System Lint Report

### Compliance: [PASS | WARNINGS | VIOLATIONS]

### Token Violations
| # | Type | File | Line | Violation | Recommended |
|---|------|------|------|-----------|-------------|
| 1 | Spacing | Button.tsx | 12 | p-[13px] | p-3 or p-4 |
| 2 | Color | Card.tsx | 8 | text-[#333] | text-foreground |

### Component Consistency
| Pattern | Expected | Actual | Status |
|---------|----------|--------|--------|
| Primary actions | <Button> | <div onClick> | ❌ |
| Loading states | <Skeleton> | Custom spinner | ⚠️ |

### Summary
- Token violations: N
- Component issues: N
- Responsive issues: N

### Recommendations
1. ...
```
```
