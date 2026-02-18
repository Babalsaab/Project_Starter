# Vibecoded Skills Best Practices

This file defines cross-cutting best practices you can later reuse when creating detailed skill/agent markdown files.

---

## 1. Marketing Functions – Best Practices (for Digital Products)

1. Anchor all marketing work in a clearly defined ICP (ideal customer profile) and keep it updated as you learn.
2. Always translate high-level business goals (revenue, retention, awareness) into measurable marketing KPIs.
3. Use a simple, consistent messaging framework (problem → insight → solution → proof → CTA) across channels.
4. Maintain a single source of truth for positioning, value propositions, and brand voice guidelines.
5. Validate positioning with real customer language from calls, surveys, and reviews before scaling campaigns.
6. Start with a narrow beachhead segment and expand only after you have strong traction and messaging fit.
7. Run regular win/loss and churn analyses to refine product marketing narratives.
8. Map the entire customer journey (awareness → consideration → conversion → activation → retention → advocacy).
9. Design campaigns to move people one stage at a time along that journey, not to “do everything at once”.
10. Use simple experiments (A/B tests, holdout groups) to test big assumptions before heavy budget commits.
11. Maintain a prioritized marketing roadmap that balances quick wins with long-term brand-building.
12. Always define success upfront for each initiative (metric, baseline, target, time window).
13. Prefer a few well-instrumented channels over many weakly-managed ones.
14. In performance marketing, separate campaigns by intent level (brand, prospecting, retargeting, retention).
15. Continuously refresh creative and audiences in paid campaigns to avoid fatigue and rising CPAs.
16. Structure SEM accounts around themes and intents, not just keywords or brand names.
17. Align ad copy, landing page, and offer tightly for each keyword/ad group (message match).
18. Invest early in technical SEO foundations (site speed, mobile friendliness, crawlability, schema markup).
19. Build topic clusters (pillar pages + supporting content) for SEO instead of chasing isolated keywords.
20. Treat content as a library, not a timeline: focus on evergreen assets you can update over time.
21. Use a content brief for every substantial piece (audience, goal, angle, outline, SEO requirements).
22. Keep one unified editorial calendar across blog, email, and social so stories reinforce each other.
23. Maintain consistent brand voice while adapting tone slightly per channel and audience segment.
24. Use UX writing principles in product copy: clear, concise, context-aware, and action-oriented.
25. Always test subject lines, headlines, and CTAs—they have outsized impact on performance.
26. Create modular content (snippets, quotes, visuals) that can be reused across channels.
27. Anchor video and social concepts in clear hooks that resonate with specific audience pains or desires.
28. For influencer partnerships, prioritize audience-product fit and authenticity over follower count.
29. Make affiliate and referral programs dead simple to understand, track, and share.
30. Treat app store optimization (ASO) like SEO: continuous keyword, creative, and review optimization.
31. Use lifecycle campaigns (welcome, activation, upgrade, win-back, reactivation) rather than random blasts.
32. Trigger lifecycle messages on meaningful behavioral events, not arbitrary time delays.
33. Segment CRM audiences meaningfully (new, active, power users, at-risk, churned) and tailor messaging.
34. Design onboarding emails and in-app messages to drive one primary activation milestone.
35. For community management, start small, set clear norms, and show up consistently as a real person/brand.
36. Reward and spotlight power users, early adopters, and advocates publicly.
37. Use marketing automation to augment human judgment, not fully replace it—keep humans in review loops.
38. Regularly audit automation flows to remove outdated, conflicting, or excessive messages.
39. Practice progressive profiling: ask for more information over time as value increases.
40. Invest in good attribution basics (UTMs, consistent naming, channel mapping) before complex models.
41. Use cohort-based retention and revenue analyses to evaluate true impact of marketing activities.
42. Build simple dashboards that highlight a few key metrics per channel, not dozens of vanity metrics.
43. Run regular post-mortems for big campaigns (what worked, what didn’t, what we’re changing next time).
44. Document learnings in a lightweight experiment log so new team members and agents inherit knowledge.
45. Keep creative and data disciplines working closely together; avoid siloed decisions.
46. Align product and marketing roadmaps so launches are supported by coherent go-to-market plans.
47. Design “marketing inside the product” (empty states, tooltips, prompts) as seriously as external campaigns.
48. Ensure all marketing complies with legal, privacy, and platform policies from the start.
49. Localize more than language when going into new markets—adapt offers, channels, and social proof.
50. Periodically step back from optimization to revisit fundamentals: who we serve, why we win, and what must change.

---

## 2. Tech Functions – Best Practices (for Apps / Websites)

1. Start with a clear product vision and problem statement before choosing stacks or patterns.
2. Capture requirements in concise artifacts (PRD, user stories, use cases) that are easy to maintain.
3. Prioritize user value and outcomes over feature volume; ship small slices end-to-end.
4. Involve UX and engineering early in problem discovery, not just solution implementation.
5. Use low-fidelity sketches and wireframes to explore many options before committing to hi-fi designs.
6. Maintain a design system (tokens, components, patterns) to keep UIs consistent and scalable.
7. Design information architecture around user mental models and key jobs-to-be-done.
8. Keep interaction design predictable and responsive; avoid cleverness that hurts usability.
9. Treat accessibility as a first-class requirement (semantic HTML, keyboard navigation, ARIA, contrast).
10. Optimize for perceived performance (skeletons, preload, sensible loading states) as well as raw speed.
11. Choose front-end frameworks and libraries that match team skills and project complexity.
12. Keep front-end architecture modular: shared components, clear boundaries, minimal cross-coupling.
13. Avoid premature micro-frontends; start simple and evolve only when complexity demands it.
14. Use API contracts (OpenAPI, GraphQL schemas) as living agreements between front-end and back-end.
15. Keep back-end services cohesive around business capabilities, not arbitrary technical layers.
16. Normalize where necessary but design database schemas around access patterns and scalability needs.
17. Prefer idempotent, well-versioned APIs that are safe to retry and evolve.
18. Implement strong observability (logs, metrics, traces) from the first meaningful release.
19. Automate testing at multiple levels: unit, integration, end-to-end, and contract tests where appropriate.
20. Use CI/CD pipelines to enforce basic quality gates (build, tests, linting) on every change.
21. Keep deployment workflows boring and repeatable; avoid manual, one-off scripts.
22. Implement feature flags to decouple deployment from release and support gradual rollouts.
23. Design for graceful degradation and failure modes; assume dependencies will sometimes break.
24. Continuously monitor performance and error rates, not just functional correctness.
25. Treat security as part of design: input validation, least-privilege access, secret management.
26. Regularly patch dependencies and use tools to detect known vulnerabilities.
27. Protect user data with appropriate encryption in transit and at rest, plus clear data retention rules.
28. Document APIs, architecture decisions, and key workflows in short, discoverable docs.
29. Keep developer experience high: fast local setup, good test feedback loops, clear contribution guidelines.
30. Use code reviews to share knowledge and improve quality, not as gatekeeping bottlenecks.
31. Aim for simple, readable code over clever abstractions; optimize for future maintainers.
32. Refactor opportunistically alongside feature work rather than big-bang rewrites.
33. Keep environments (dev, staging, prod) as similar as possible to reduce surprises.
34. Use realistic but anonymized or synthetic data in non-production environments.
35. Track and control tech debt explicitly; include remediation items in your backlog.
36. Design analytics events with intention; avoid random event sprawl without a tracking plan.
37. Ensure analytics and product metrics are validated against reality (sanity checks, reconciliations).
38. Provide runtime feature telemetry to understand how features are actually used.
39. In mobile, manage app size, offline behavior, and upgrade paths thoughtfully.
40. For cross-platform apps, clearly define shared vs platform-specific layers.
41. Standardize error handling, user-facing error messages, and logging across the stack.
42. Use rate limiting, backpressure, and circuit-breaking patterns for resilience under load.
43. Plan for backup, restore, and disaster recovery; test these processes periodically.
44. Prefer configuration over hard-coded values to support multiple projects from the same codebase.
45. Separate project-specific configuration (branding, features) from core platform logic.
46. Build reusable modules where it truly makes sense (auth, billing, notifications, analytics).
47. Maintain compatibility and migration paths when schema or API changes are unavoidable.
48. Keep infrastructure definitions in code (IaC) for reproducibility and review.
49. Align technical decisions with business constraints: budget, team size, timelines, and risk appetite.
50. Regularly review architecture and operations to prune unused services, tools, and complexity.

---

## 3. Orchestrator & Multi‑Agent Org – Best Practices

1. Give the Chief Orchestrator a single, unambiguous responsibility: plan, route, and supervise work across agents.
2. Keep the user-facing interface limited to the orchestrator; prevent specialists from directly negotiating with users.
3. Separate concerns between chiefs (CMO/CTO) and specialists; chiefs handle strategy, specialists handle execution.
4. Represent projects explicitly via a `project_profile` that includes goals, audience, channels, and constraints.
5. Maintain global configuration for brand, voice, legal, and token policies shared across projects.
6. Always create or update a Master PRD or equivalent spec before large multi-agent executions.
7. Use a task graph (DAG) representation with clear dependencies, owners, and expected outputs.
8. Start with simple orchestration patterns (sequential, supervisor-worker) before experimenting with complex ones.
9. Prefer deterministic routing rules (based on domain, project_type, task_label) over fully emergent behavior.
10. Define clear contracts for each agent: inputs, outputs, responsibilities, and failure modes.
11. Keep agent prompts short and role-specific; avoid putting global context into every agent call.
12. Use shared memory and artifact references to pass context instead of copying large texts between agents.
13. Implement summarization layers to compress outputs while retaining essential information.
14. Limit the number of agents involved in a single run to what is truly needed.
15. Set explicit token budgets and max steps per run; enforce them in orchestration logic.
16. Distinguish between planning and execution phases; allow planning-only runs for inspection.
17. Log all decisions made by the orchestrator (routing, retries, stop conditions) for debugging and learning.
18. Use structured logs and IDs (run_id, task_id, agent_id) so you can trace end-to-end flows.
19. Implement basic health checks and timeouts for agents; handle slow or failing agents gracefully.
20. Provide default fallbacks when a specialist agent is missing or fails (e.g., generic writer instead of niche writer).
21. Version agent definitions and prompts so you can roll back problematic changes.
22. Keep agents stateless across runs; store state in explicit project/run contexts instead.
23. Allow agents to suggest follow-up tasks, but let the orchestrator decide whether to add them to the plan.
24. Periodically review and prune unused agents to reduce maintenance overhead.
25. Group agents into domains (marketing, tech, ops) and route via chiefs where appropriate.
26. Make it easy to add new agents by following a standard interface and registration mechanism.
27. Keep orchestration logic separate from agent implementations to avoid tight coupling.
28. Validate critical outputs (code, copy, configs) via additional checker agents or tools.
29. For code-generation tasks, run formatters, linters, and tests automatically after agent outputs.
30. For marketing tasks, run brand/safety checks before publishing or scheduling.
31. Allow human-in-the-loop review points for high-impact steps (e.g., PRD approval, production deployment).
32. Provide a simple way to rerun individual tasks or subgraphs without restarting the whole workflow.
33. Design orchestrator prompts to be idempotent where possible; same inputs → same plan.
34. Keep an experiment log and performance metrics per agent (accuracy, time, tokens, user satisfaction).
35. Periodically retrain or refactor underperforming agents based on logs and metrics.
36. Use templates for common workflows (blog content pipeline, app feature rollout, email campaign) that the orchestrator can instantiate.
37. Make project configuration files the primary lever for adapting behavior across products.
38. Encourage reusability of agents across projects by avoiding hard-coded project assumptions in prompts.
39. Treat security and privacy carefully when agents access external APIs, files, or user data.
40. Implement permission scopes for agents so only the right ones can perform sensitive actions.
41. Separate read and write capabilities where useful; some agents should only propose changes, not apply them.
42. Provide a simulation or dry-run mode where agents produce plans and diffs without touching real systems.
43. Document the multi-agent architecture and common flows so humans can reason about the system.
44. Test orchestration flows with small, low-risk projects before applying them to critical systems.
45. Start each run by re-stating goals and constraints to reduce drift during long workflows.
46. End each run with a concise summary of what was done, what artifacts were produced, and what is still pending.
47. Make it easy to inspect intermediate artifacts (PRDs, designs, drafts, diffs) from a central UI or log.
48. Regularly review and refine orchestrator prompts as your library of agents and use cases grows.
49. Design the system so it can degrade gracefully to a smaller set of core agents if needed.
50. Continuously align agent behavior with your overarching product and brand principles; avoid local optimizations that hurt the whole.
