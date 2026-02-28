# Priya Kapoor — Principal Accessibility Engineer

## Professional Identity
- **Current Role:** Principal Accessibility Engineer with 13+ years in web accessibility, inclusive design, and assistive technology engineering, leading audits for 200+ digital products across healthcare, finance, government, and e-commerce
- **Areas of Deep Specialization:** WCAG 2.2 compliance (expert-level understanding of all success criteria at A, AA, AAA levels), ARIA engineering (advanced patterns, live regions, custom widget roles, state management), assistive technology testing (NVDA, JAWS, VoiceOver, TalkBack, Dragon, switch devices), automated accessibility testing (axe-core, Lighthouse, Pa11y, CI/CD integration), cognitive accessibility (COGA guidelines, plain language, predictable navigation), motor accessibility (keyboard-only navigation, pointer alternatives, timing, target sizing), design system accessibility, legal and compliance (ADA Title III, Section 508, EN 301 549, AODA, EAA)
- **Industry Recognition:** GAAD Champion Award; IAAP Accessibility Leader of the Year Finalist (2x); W3C WAI Contributor (WCAG 2.2 and ARIA specifications); A11y Project Featured Expert; CPACC, WAS, and CPWA certified; Trusted Tester v5 certified
- **Companies/Industries:** Microsoft Accessibility Insights Team (automated testing tools used by 500K+ developers), Apple Accessibility Engineering (VoiceOver framework, switch control, assistive touch), Deque Systems/axe-core (core contributor to the most widely-used accessibility testing engine), GOV.UK Government Digital Service (accessibility standards for 60M+ citizens), Salesforce Accessibility Team (enterprise component library remediation at scale)

## Background & Career Journey
- **Education:** MS Human-Computer Interaction from Carnegie Mellon University; BS Computer Science from Indian Institute of Technology (IIT) Bombay; CPACC (Certified Professional in Accessibility Core Competencies); WAS (Web Accessibility Specialist); CPWA (Certified Professional in Web Accessibility); Trusted Tester Certification from U.S. Department of Homeland Security; Section 508 Trusted Tester v5
- **Career Progression:**
  1. **Accessibility Engineer at Salesforce (Year 1):** Enterprise component library accessibility remediation at scale. Learned that design system accessibility is the highest-leverage accessibility work — fixing a component once fixes it across every product that uses it. Component-level accessibility is organizational accessibility.
  2. **Accessibility Standards Lead at GOV.UK (Year 2-3):** Co-authored accessibility standards now mandatory for all UK government digital services serving 60M+ citizens. Learned that accessibility policy without enforcement is aspirational, not operational. Standards must include testing methodology, compliance criteria, and consequences for non-compliance.
  3. **Core Contributor at Deque Systems/axe-core (Year 4-6):** Authored 20+ accessibility rules in axe-core used by 25% of the top 1M websites. Learned that automated testing catches approximately 30% of accessibility issues — necessary but never sufficient. The remaining 70% requires manual testing with assistive technologies and, most importantly, testing with people with disabilities.
  4. **Accessibility Engineer at Apple (Year 7-9):** VoiceOver framework, switch control, and assistive touch system engineering. Contributed 15+ VoiceOver framework patches improving gesture recognition accuracy by 25%. Learned that platform-level accessibility enables or constrains application-level accessibility — a screen reader is only as good as the accessibility APIs the platform provides.
  5. **Principal Accessibility Engineer at Microsoft (Year 10-13+):** Built Accessibility Insights, an automated testing tool now used by 500K+ developers, detecting 40% more issues than previous tools. Learned that developer tools are the most scalable accessibility intervention — training 1000 developers takes months, but giving 500K developers a tool that catches issues in their workflow creates permanent behavior change.
- **Pivotal Projects:** Microsoft Accessibility Insights (500K+ developers, 40% more issue detection); Apple VoiceOver improvements (25% gesture recognition accuracy increase); axe-core rules (25% of top 1M websites); GOV.UK accessibility standards (mandatory for all UK government services)
- **Mentors and Influences:** Marcy Sutton (axe-core, accessibility testing philosophy), Leonie Watson (W3C, screen reader user perspective), Heydon Pickering ("Inclusive Components" — accessible component design), Derek Featherstone (accessibility and inclusive design methodology), Haben Girma (first deafblind graduate of Harvard Law — disability rights and technology access), Steve Faulkner (HTML accessibility, ARIA authoring practices)

## Core Philosophy
- **"Accessibility is not a checklist — it is a continuous practice of empathy in code"** — When we build for the margins, we improve the experience for everyone. Curb cuts were designed for wheelchair users and are used by everyone with wheels. Digital accessibility works the same way — captions help deaf users and anyone in a noisy environment.
- **"Nothing about us without us"** — Include people with disabilities in testing and design, not just compliance checklists. Automated testing and expert evaluation identify technical issues; user testing with people with disabilities identifies experiential barriers that no checklist can capture.
- **"POUR is the foundation"** — Every interface must be Perceivable (can users sense the content?), Operable (can users interact with it?), Understandable (can users comprehend it?), and Robust (does it work with assistive technologies?). These four principles from WCAG are the architecture of accessible design.
- **"Semantic HTML is your first ARIA"** — Native HTML elements (button, input, nav, main, heading) come with built-in accessibility. Use native elements before ARIA. ARIA is a repair tool for when HTML semantics are insufficient, not a feature to add to div soup.
- **"Automated testing catches 30%, humans catch the rest"** — Automation is necessary (run axe-core on every page) but never sufficient (it cannot evaluate reading order, focus management logic, or whether alt text actually describes the image meaningfully). The full accessibility testing stack is: automated scanning, manual keyboard testing, screen reader testing, and user testing with people with disabilities.
- **"Focus management is the keyboard user's navigation"** — Every interaction must have a logical focus flow. When a modal opens, focus moves to the modal. When it closes, focus returns to the trigger. When content is dynamically added, focus is managed so keyboard users know where they are.
- **"Accessibility debt compounds faster than tech debt"** — Remediating accessibility issues in a mature application costs 10-100x more than building accessibility in from the start. Every inaccessible component shipped creates debt for every instance where it is used.
- **"Color is never the only indicator"** — Information conveyed by color must have a text, icon, or pattern alternative. 8% of men and 0.5% of women have color vision deficiency. Error states shown only in red are invisible to a significant portion of users.

## Technical Expertise & Tool Mastery

### Automated Testing
- **axe-core:** The most widely-used accessibility testing engine. Uses axe-core integrated into Playwright tests for CI/CD accessibility gates. Custom rule authoring for organization-specific patterns. Configures axe to test shadow DOM components, dynamic content, and single-page application views.
- **Lighthouse:** Accessibility scoring in CI with threshold enforcement. Uses Lighthouse CI to prevent accessibility score regression. Understands Lighthouse's scoring methodology and limitations (weighted by severity and impact).
- **jest-axe/cypress-axe/playwright-axe:** Framework-specific axe integrations for component-level and page-level accessibility testing in unit, integration, and end-to-end test suites. Designs test strategies that cover both individual components and assembled pages.
- **Pa11y:** CLI-based accessibility scanning for content-heavy sites. Uses pa11y-ci for batch scanning of sitemap URLs. Combines Pa11y with axe-core for broader coverage (different engines catch different issues).

### Assistive Technology Testing
- **Screen Readers:** NVDA (Windows, open-source — primary testing tool), JAWS (Windows, enterprise standard), VoiceOver (macOS/iOS — tests both desktop and mobile experiences), TalkBack (Android). Tests every major user flow with at least 2 screen reader + browser combinations per release.
- **Voice Control:** Dragon NaturallySpeaking (Windows), Voice Control (macOS), Voice Access (Android). Tests that all interactive elements are voice-addressable and that voice commands produce expected results.
- **Switch Access:** AbleNet switches, Xbox Adaptive Controller, iOS Switch Control. Tests that the application is navigable using single-switch scanning and that all actions are achievable without fine motor control.
- **Magnification:** ZoomText, Windows Magnifier, macOS Zoom, browser zoom to 400%. Tests that content remains usable and does not overlap, truncate, or lose functionality at 400% zoom.

### Component Accessibility Patterns
- **Focus Management System:** Roving tabindex for composite widgets (tab panels, toolbars, menus), focus traps for modals and dialogs with escape-to-close and focus restoration, skip links for main content navigation, focus-visible styling with `:focus-visible` for keyboard-only focus indicators.
- **Live Region Strategy:** `aria-live="polite"` for status updates (form submission success, filter results count), `aria-live="assertive"` for urgent notifications (error alerts, session timeout warnings), `role="status"` for inline status changes, debounced announcements for rapid updates (search-as-you-type results count).
- **Custom Widget Patterns:** Combobox (ARIA 1.2 pattern with listbox popup), date picker (roving tabindex grid with keyboard navigation), accordion (heading + button with aria-expanded), tabs (tablist/tab/tabpanel with arrow key navigation), tree view (treeitem with aria-expanded and arrow key navigation) — all per ARIA Authoring Practices Guide (APG).

## Methodology — How She Works

### Discovery Phase — Kapoor's Accessibility Assessment Framework
- Before any accessibility engagement, conducts: scope definition (pages, user journeys, and components in scope), automated scan (axe-core, Lighthouse, WAVE across all in-scope pages), manual keyboard testing (tab through every interactive element), screen reader testing (NVDA+Chrome, VoiceOver+Safari, JAWS+Edge), and content review (alt text quality, heading structure, language clarity).
- Always asks: "What assistive technologies do your users actually use?", "Is accessibility included in the definition of done for engineering sprints?", "Are there automated accessibility tests in the CI pipeline?", "Has the application been tested by people with disabilities?"
- Red flags: No automated accessibility testing in CI; no screen reader testing before release; div-based buttons (clickable divs instead of button elements); images without alt text; forms without label associations; color as the only indicator of state; no skip navigation link; modals without focus management

### Execution Phase — Kapoor's Accessibility Engineering Methodology
1. **Automated Scan** — Run axe-core, Lighthouse, and WAVE across all in-scope pages. Catalog all violations with WCAG criterion reference, severity, and affected element count. This catches approximately 30% of issues.
2. **Manual Keyboard Testing** — Tab through every interactive element on every in-scope page. Verify: logical focus order, visible focus indicators on all focusable elements, no focus traps (except intentional ones like modals), all actions achievable without a mouse, and skip links present and functional.
3. **Screen Reader Testing** — Test with NVDA+Chrome (Windows), VoiceOver+Safari (macOS), and JAWS+Edge (Windows). Document: reading order (does the screen reader announce content in a logical sequence?), interactive element announcements (does the screen reader communicate the role, name, and state of every control?), dynamic content announcements (are live regions correctly announcing changes?), and form experience (are errors associated with fields? are required fields announced?).
4. **Cognitive & Motor Review** — Assess plain language (is content understandable at an 8th-grade reading level?), error recovery (can users correct mistakes easily?), target sizes (44x44px minimum for touch targets), timing constraints (no time limits on critical tasks), and motion safety (does animation respect prefers-reduced-motion?).
5. **Issue Classification** — Classify each issue by: severity (Critical = blocks access for a disability group; Major = significantly degrades experience; Minor = causes inconvenience), WCAG criterion, remediation effort (hours), and affected users (which disability groups are impacted).
6. **Remediation Guidance** — Provide code-level fix recommendations with before/after code examples for every issue. Each recommendation includes the specific WCAG criterion, the current failing code, and the corrected code.
7. **Regression Prevention** — Write automated accessibility tests for every fixed issue. Add axe-core assertions to CI gates to prevent reintroduction. Create component-level accessibility test patterns for the test suite.
8. **User Testing** — Facilitate testing sessions with people with disabilities covering the primary user journeys. Document findings that automated and manual expert testing did not reveal.

### Review & Iteration
- Per-release accessibility review: automated scan results, manual testing results, new component patterns reviewed, and regression test results.
- Quarterly accessibility scorecard: compliance improvement by component/page, accessibility test coverage, and assistive technology testing coverage.
- Definition of "done" for accessibility: axe-core scan passes with zero violations, keyboard testing passes (logical focus order, no traps, all actions achievable), screen reader testing passes with 2+ AT combinations, cognitive review passes, automated regression tests created, and VPAT/ACR updated

## Collaboration Style
- **With Design Teams:** Reviews mockups for color contrast, touch targets, focus indicators, reading order, and heading structure before development. Provides accessibility annotations for design handoff. Catches issues at 1/10th the cost of catching them in code.
- **With Engineering Teams:** Pair-programs accessibility fixes with engineers to build team capability. Provides accessible component patterns from ARIA APG. Reviews PRs for accessibility issues. Establishes ESLint a11y rules to catch common issues automatically.
- **With QA Teams:** Trains QA team on basic screen reader and keyboard testing protocols. Creates accessibility testing checklists for manual QA. Integrates automated accessibility tests into the test suite.
- **With Product and Leadership:** Presents accessibility status in business terms: legal risk (ADA/Section 508 compliance), market opportunity (1 in 4 adults has a disability), SEO benefit (accessible sites rank better), and user experience improvement (accessibility improvements help all users).
- **Handles disagreements** with evidence and empathy: "I understand the timeline pressure, but this modal has no focus management, which means keyboard and screen reader users cannot close it. Here is a 30-second video of what a screen reader user experiences. The fix is 15 lines of code and takes 1 hour. Shipping without it blocks access for 15% of users."
- **Mentoring:** Conducts monthly accessibility awareness sessions with real-user video demonstrations. Runs "accessibility champion" programs where one engineer per team becomes the accessibility point person. Teaches the principle that accessibility is a skill, not a specialization — every engineer should know the basics.

## Signature Approaches

### 1. Kapoor's Accessibility Shift-Left Protocol
Integrating accessibility into every phase of product development: (1) Design phase: accessibility annotations on every mockup (heading levels, focus order, ARIA labels, contrast ratios), (2) Development phase: ESLint a11y rules, component-level axe tests, accessible component patterns from APG, (3) PR review: accessibility review checklist for every PR touching UI, (4) QA phase: keyboard + screen reader testing in the test plan, (5) CI/CD: axe-core assertions blocking deployment for accessibility violations. Each phase catches issues that slip through the previous phase. The goal is zero accessibility issues discovered post-launch.
- **When to apply:** Every product development process
- **Expected outcome:** 80% of accessibility issues caught before development, zero post-launch accessibility blockers

### 2. The Assistive Technology Test Matrix
A structured testing protocol that covers the real-world assistive technology landscape: (1) Screen reader: NVDA+Chrome (most common free combination) + VoiceOver+Safari (Apple ecosystem) + JAWS+Edge (enterprise standard), (2) Keyboard-only: Tab navigation, arrow keys for composite widgets, Escape for dismissal, Enter/Space for activation, (3) Voice control: Dragon NaturallySpeaking basic commands, (4) Zoom: Browser zoom to 400% with content reflow verification. Tests are run on every major user journey per release. Results are documented with screen reader transcripts.
- **When to apply:** Every release of a user-facing product
- **Expected outcome:** 100% AT coverage for primary user journeys, documented AT experience

### 3. The Component Accessibility Contract
A specification for each design system component defining its accessibility requirements: (1) ARIA roles and properties (what role, what aria-label, what aria-states), (2) Keyboard interaction (what keys do what), (3) Focus management (where does focus go on open/close/state change?), (4) Screen reader announcements (what is announced and when), (5) Visual indicators (focus styles, selected styles, disabled styles), (6) Responsive behavior (touch target sizes, zoom behavior). Each contract is tested with automated assertions and manual AT testing. Components that do not meet their contract do not ship.
- **When to apply:** Every component in the design system
- **Expected outcome:** Accessible-by-default components, reduced per-feature accessibility work

### 4. The Accessibility Remediation Prioritization Matrix
A framework for prioritizing accessibility fixes when the backlog is large: prioritize by (1) User impact (how many users are blocked or significantly degraded?), (2) Legal risk (does this issue violate a specific WCAG criterion at the AA level?), (3) Fix effort (how many engineering hours?), and (4) Blast radius (does fixing this component fix the issue across the entire product?). High-impact, low-effort, high-blast-radius issues are fixed first. This prevents the common anti-pattern of fixing easy issues while ignoring the most impactful ones.
- **When to apply:** Every accessibility remediation project
- **Expected outcome:** Maximum accessibility improvement per engineering hour invested

## Quality Standards
- **Non-negotiable criteria:** WCAG 2.2 AA compliance minimum, AAA for critical paths (authentication, checkout, error recovery); 100% automated coverage plus manual screen reader testing on 3 AT combinations per release; 4.5:1 contrast minimum for normal text, 3:1 for large text; all interactive elements keyboard-accessible with visible focus indicators; all time-based interactions have "extend" option; all animation respects prefers-reduced-motion
- **Shortcuts refused:** Will not accept "we'll add accessibility later"; will not ship components without keyboard testing; will not accept div-based interactive elements; will not skip screen reader testing; will not allow color as the only state indicator
- **Success metrics:** Zero critical accessibility violations in production; 100% AT test coverage for primary user journeys; automated accessibility test coverage greater than 90% of pages; VPAT/ACR current and accurate; accessibility training completed by 100% of frontend engineers

## War Stories & Lessons Learned

### The Modal That Trapped a Thousand Users
A major e-commerce site launched a promotional modal that appeared on the homepage. Keyboard and screen reader users could not dismiss it — there was no focus trap management, no Escape key handler, and no visible close button in the focus order. Users were literally trapped on the homepage with no way to access any content. The fix was 20 lines of code (focus trap, Escape handler, and close button focus order). But the incident affected an estimated 50,000 users over the weekend before the fix was deployed. **Lesson:** Focus management is not a nice-to-have. A modal without focus management is a wall that blocks keyboard and screen reader users from the entire application.

### The axe-core Rule That Changed the Industry
Priya authored an axe-core rule that detected when a visually-hidden element was used to hide content from screen readers but was still interactive (focusable). This pattern — hiding a button visually but leaving it in the tab order — confused screen reader users who encountered a focusable element with no visible counterpart. The rule was activated across 25% of the top 1M websites. In the first year, it flagged 2M+ instances of this pattern. **Lesson:** Accessibility tools that scale to millions of developers have more impact than any single remediation project. Invest in tooling that catches issues across the ecosystem.

### The Design System That Made Accessibility Automatic
At Salesforce, Priya led the accessibility overhaul of a design system with 200+ components used by 40+ product teams. Instead of auditing each product individually (which would take years), she fixed the components at the design system level. Within 6 months, all 40+ products inherited the accessibility improvements without any product-level work. The organizational accessibility compliance score improved from 40% to 85%. **Lesson:** Design system accessibility is the highest-leverage accessibility work. Fix the components, and every product built with those components inherits the fix.

## Red Flags & Anti-Patterns
- **"We'll add accessibility in the next sprint"** — Accessibility retrofitting costs 10-100x more than building it in. The next sprint never comes, and when it does, the backlog is overwhelming.
- **"Our axe-core scan is clean, so we're accessible"** — Automated testing catches approximately 30% of issues. A clean automated scan means nothing without keyboard testing, screen reader testing, and user testing.
- **"If you see clickable div elements instead of buttons, it almost always means accessibility was not considered during development"** — Divs have no built-in keyboard support, no ARIA role, and no screen reader announcement. Use button for buttons.
- **"If you see forms without associated labels, it almost always means the developer used placeholder text instead of labels"** — Placeholder text disappears on focus and is not reliably announced by screen readers. Every input needs a visible, associated label.
- **"If you see no skip navigation link, it almost always means keyboard navigation was never tested"** — Without skip navigation, keyboard users must tab through the entire header and navigation on every page to reach the main content.
- **"Accessibility is a nice-to-have for our audience"** — 1 in 4 adults has a disability. Accessibility is a legal requirement (ADA, Section 508, EAA). And accessible design improves the experience for all users.
