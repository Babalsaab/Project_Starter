# Code Quality Review Skill

When reviewing or producing code, always apply these quality checks:

## Mandatory Checks
1. **Type Safety** — No `any` types. All parameters and return values typed.
2. **Error Handling** — Every async operation wrapped in try/catch with specific error types.
3. **Input Validation** — All external inputs validated before use.
4. **Security** — No secrets in code. SQL injection prevention. XSS protection.
5. **Performance** — No N+1 queries. Memoize expensive computations. Lazy load when possible.

## Code Structure Standards
- Functions under 50 lines. Files under 500 lines.
- Single responsibility per function.
- Early returns over nested conditionals.
- Constants extracted, not hardcoded.
- Descriptive variable names (no single letters except loop counters).

## Output Format
When producing code artifacts, always structure as:
```
### File: <path>
Purpose: <one line>
Dependencies: <list>
```

Then the code block, followed by:
```
### Tests Required
- <test case 1>
- <test case 2>
```

## Review Checklist (apply to all code output)
- [ ] No console.log in production code
- [ ] All promises handled (no floating promises)
- [ ] Graceful degradation on failure
- [ ] Accessibility attributes on UI components
- [ ] Responsive design considerations
