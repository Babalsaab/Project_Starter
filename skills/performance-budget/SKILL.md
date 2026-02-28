---
name: performance-budget
description: "Use when checking performance budgets, auditing bundle sizes, reviewing Core Web Vitals targets, or enforcing runtime performance constraints."
version: "1.0.0"
argument-hint: "[file-or-build-output]"
compatible_agents:
  - frontend_performance_engineer
  - web_frontend_engineer
  - design_engineer
  - devops_engineer
  - cross_platform_engineer
domain:
  - "tech/frontend"
  - "tech/performance"
  - "tech/devops"
priority: 11
user_invocable: true
---

```skill
# Performance Budget Enforcement

When building or reviewing frontend code, enforce these performance constraints:

## Bundle Size Budgets

| Asset Type | Budget | Compressed |
|-----------|--------|------------|
| Total JS (initial) | ≤ 300 KB | ≤ 100 KB gzip |
| Total CSS (initial) | ≤ 80 KB | ≤ 25 KB gzip |
| Largest JS chunk | ≤ 150 KB | ≤ 50 KB gzip |
| Individual images | ≤ 200 KB | — |
| Total page weight | ≤ 1.5 MB | ≤ 500 KB gzip |
| Third-party JS | ≤ 100 KB | ≤ 35 KB gzip |

## Core Web Vitals Targets

| Metric | Good | Needs Improvement | Poor |
|--------|------|-------------------|------|
| **LCP** (Largest Contentful Paint) | ≤ 2.5s | ≤ 4.0s | > 4.0s |
| **INP** (Interaction to Next Paint) | ≤ 200ms | ≤ 500ms | > 500ms |
| **CLS** (Cumulative Layout Shift) | ≤ 0.1 | ≤ 0.25 | > 0.25 |
| **TTFB** (Time to First Byte) | ≤ 800ms | ≤ 1.8s | > 1.8s |
| **FCP** (First Contentful Paint) | ≤ 1.8s | ≤ 3.0s | > 3.0s |

Target: **ALL metrics in "Good" range**.

## Code-Level Rules

### JavaScript
- Use dynamic `import()` for routes and heavy components
- Tree-shake: import specific functions, not entire libraries
- Avoid synchronous `require()` in client bundles
- Debounce scroll/resize handlers (≥ 100ms)
- Use `requestAnimationFrame` for visual updates
- Prefer CSS animations over JS-driven animations

### Images & Media
- Use `next/image` (or equivalent) for automatic optimization
- Serve WebP/AVIF with fallbacks
- Set explicit `width` and `height` to prevent CLS
- Lazy load below-the-fold images (`loading="lazy"`)
- Use responsive `srcSet` for different viewport sizes

### CSS
- Purge unused CSS in production builds
- Avoid `@import` chains (use a single entry point)
- Minimize use of `!important`
- Prefer `transform` and `opacity` for animations (compositor-only)
- Use `content-visibility: auto` for off-screen content

### Data Fetching
- Fetch only required fields (no over-fetching)
- Implement pagination/infinite scroll for lists
- Cache API responses (stale-while-revalidate)
- Prefetch critical navigation targets
- Use streaming/suspense for non-blocking rendering

### Fonts
- Self-host fonts (`next/font` or manual)
- Use `font-display: swap` to prevent FOIT
- Subset fonts to required character ranges
- Limit to ≤ 2 font families, ≤ 4 weights total

## Output Format

```
## Performance Budget Report

### Status: [PASS | WARNING | FAIL]

### Bundle Analysis
| Asset | Size | Budget | Status |
|-------|------|--------|--------|
| main.js | 85 KB | 150 KB | ✅ PASS |
| vendor.js | 165 KB | 150 KB | ❌ OVER (+15 KB) |

### Core Web Vitals (estimated)
| Metric | Estimated | Target | Status |
|--------|-----------|--------|--------|
| LCP | ~2.1s | ≤ 2.5s | ✅ |
| INP | ~180ms | ≤ 200ms | ✅ |
| CLS | ~0.05 | ≤ 0.1 | ✅ |

### Optimization Opportunities
1. [High Impact] ...
2. [Medium Impact] ...
3. [Low Impact] ...
```
```
