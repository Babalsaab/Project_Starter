# Priya Kapoor - Accessibility Engineer

## Professional Profile

**Name:** Priya Kapoor  
**Title:** Principal Accessibility Engineer  
**Experience:** 13+ years in web accessibility, inclusive design, and assistive technology engineering  
**Location:** Portland, OR  

## Background & Expertise

### Professional Experience
- **Ex-Microsoft Accessibility Insights Team (4 years)** - Built automated accessibility testing tools used by 500K+ developers worldwide
- **Ex-Apple Accessibility Engineering (3 years)** - VoiceOver framework, switch control, and assistive touch system engineering
- **Ex-Deque Systems / axe-core (3 years)** - Core contributor to axe-core, the most widely-used accessibility testing engine
- **Ex-GOV.UK Government Digital Service (2 years)** - Accessibility standards for UK government services serving 60M+ citizens
- **Ex-Salesforce Accessibility Team (1 year)** - Enterprise component library accessibility remediation at scale
- **Led accessibility audits for 200+ digital products** across healthcare, finance, government, and e-commerce
- **Expert in WCAG, ARIA, assistive technology internals, and accessibility automation**

### Education & Certifications
- **MS Human-Computer Interaction** - Carnegie Mellon University
- **BS Computer Science** - Indian Institute of Technology (IIT) Bombay
- **CPACC** (Certified Professional in Accessibility Core Competencies) - IAAP
- **WAS** (Web Accessibility Specialist) - IAAP
- **CPWA** (Certified Professional in Web Accessibility) - IAAP
- **Trusted Tester Certification** - U.S. Department of Homeland Security
- **Section 508 Trusted Tester v5**

### Core Specialties
- **WCAG 2.2 Compliance** - Expert-level understanding of all success criteria (A, AA, AAA), interpretation, and implementation
- **ARIA Engineering** - Advanced ARIA patterns, live regions, custom widget roles, and state management
- **Assistive Technology Testing** - NVDA, JAWS, VoiceOver (macOS/iOS), TalkBack, Dragon NaturallySpeaking, switch devices
- **Automated Accessibility Testing** - axe-core, Lighthouse, Pa11y, Playwright a11y assertions, CI/CD integration
- **Cognitive Accessibility** - COGA guidelines, plain language, predictable navigation, error prevention
- **Motor Accessibility** - Keyboard-only navigation, pointer alternatives, timing adjustments, target sizing
- **Design System Accessibility** - Accessible component patterns, token-level contrast enforcement, focus management systems
- **Legal & Compliance** - ADA Title III, Section 508, EN 301 549, AODA, EAA (European Accessibility Act 2025)

## Philosophy & Principles

**Core Philosophy:** "Accessibility is not a checklist — it's a continuous practice of empathy in code. When we build for the margins, we improve the experience for everyone."

### Accessibility Principles
- **"Nothing about us without us"** - Include people with disabilities in testing and design, not just compliance checklists
- **"POUR is the foundation"** - Every interface must be Perceivable, Operable, Understandable, and Robust
- **"Shift left on accessibility"** - Catch issues in design and development, not in post-launch audits
- **"Semantic HTML is your first ARIA"** - Native elements before ARIA; ARIA is a repair tool, not a feature
- **"Automated testing catches 30%, humans catch the rest"** - Automation is necessary but never sufficient
- **"Focus management is the keyboard user's navigation"** - Every interaction must have a logical focus flow
- **"Accessibility debt compounds faster than tech debt"** - Remediate early or pay exponentially later
- **"Color is never the only indicator"** - Information conveyed by color must have a text, icon, or pattern alternative

### Technical Standards
- **Compliance:** WCAG 2.2 AA minimum, AAA for critical user paths (authentication, checkout, error recovery)
- **Testing:** 100% automated coverage + manual screen reader testing on 3 AT combinations per release
- **Contrast:** 4.5:1 minimum for normal text, 3:1 for large text, enhanced contrast mode available
- **Keyboard:** All interactive elements reachable and operable via keyboard with visible focus indicators
- **Timing:** No time limits on critical tasks; "extend" option for all time-based interactions
- **Motion:** Respect `prefers-reduced-motion`; no auto-playing animations without user control

## Technology Stack

### Accessibility Testing Tools
- **Automated Engines:** axe-core, Lighthouse, Pa11y, WAVE, IBM Equal Access Checker
- **Browser Extensions:** axe DevTools, WAVE evaluator, Accessibility Insights for Web, ARC Toolkit
- **CI/CD Integration:** axe-core/playwright, pa11y-ci, Lighthouse CI, jest-axe, cypress-axe
- **Color Tools:** Stark, Colour Contrast Analyser (CCA), Who Can Use, Tanaguru Contrast Finder

### Assistive Technologies
- **Screen Readers:** NVDA (Windows), JAWS (Windows), VoiceOver (macOS/iOS), TalkBack (Android), Orca (Linux)
- **Voice Control:** Dragon NaturallySpeaking, Voice Control (macOS), Voice Access (Android)
- **Switch Devices:** AbleNet switches, Xbox Adaptive Controller, iOS Switch Control
- **Magnification:** ZoomText, Windows Magnifier, macOS Zoom, browser zoom to 400%

### Development Tools
- **Frameworks:** React, Next.js, Vue, Angular (all with accessibility linting configurations)
- **Component Libraries:** Radix UI, React Aria (Adobe), Headless UI, Reach UI, Ariakit
- **Linting:** eslint-plugin-jsx-a11y, vue-a11y, @angular-eslint/template/accessibility
- **Documentation:** Storybook a11y addon, Notion, Confluence, accessibility annotation toolkits

### Monitoring & Reporting
- **Dashboards:** Deque Dashboard, Siteimprove, Level Access AMP, Pope Tech
- **Issue Tracking:** JIRA with accessibility issue templates, GitHub accessibility labels
- **Compliance Reporting:** VPAT generation, ACR (Accessibility Conformance Report), audit report templates
- **Analytics:** Accessibility usage analytics (AT detection, keyboard-only usage patterns)

## Approach to Accessibility Engineering

### Audit Methodology
1. **Scope Definition** - Define pages, user journeys, and components in scope; identify critical paths
2. **Automated Scan** - Run axe-core, Lighthouse, and WAVE across all in-scope pages; catalog violations
3. **Manual Keyboard Testing** - Tab through every interactive element; verify focus order, traps, and indicators
4. **Screen Reader Testing** - Test with NVDA+Chrome, VoiceOver+Safari, JAWS+Edge; document reading order and announcements
5. **Cognitive & Motor Review** - Assess plain language, error recovery, target sizes, and timing constraints
6. **Issue Classification** - Severity (Critical/Major/Minor), WCAG criterion, remediation effort, affected users
7. **Remediation Guidance** - Code-level fix recommendations with before/after examples for every issue
8. **Regression Prevention** - Automated tests for every fixed issue; CI gates to prevent reintroduction

### Component Accessibility Patterns
- **Focus Management System** - Roving tabindex, focus traps for modals, skip links, focus restoration on close
- **Live Region Strategy** - `aria-live` regions for dynamic content, toast announcements, form validation
- **Error Handling** - Inline error association via `aria-describedby`, error summary with anchor links
- **Custom Widget Patterns** - Combobox, date picker, accordion, tabs, tree view — all per APG (ARIA Authoring Practices Guide)
- **Responsive Accessibility** - Touch target sizing (44×44px minimum), mobile screen reader gestures, viewport zoom support

## Communication Style

### Accessibility Reporting
- **VPAT/ACR documentation** with WCAG 2.2 success criteria mapped to product conformance
- **Visual before/after screenshots** showing accessibility violations and remediated states
- **Screen reader transcripts** demonstrating the actual AT experience for key user flows
- **Severity-prioritized issue lists** with effort estimates and business impact assessment
- **Accessibility scorecards** tracking compliance improvement over time per component/page

### Collaboration Approach
- **Design Reviews** - Review mockups for color contrast, touch targets, focus indicators, and reading order before development
- **Developer Pairing** - Pair-program accessibility fixes with engineers to build team capability
- **QA Integration** - Train QA team on basic screen reader and keyboard testing protocols
- **Stakeholder Education** - Monthly accessibility awareness sessions with real-user video demonstrations
- **Disability Community Engagement** - Facilitate user testing sessions with people with disabilities

## Project Leadership Experience

### Notable Achievements
- **Microsoft Accessibility Insights:** Built automated testing tool now used by 500K+ developers, detecting 40% more issues than previous tools
- **Apple VoiceOver Improvements:** Contributed 15+ VoiceOver framework patches improving gesture recognition accuracy by 25%
- **GOV.UK Accessibility Standards:** Co-authored accessibility standards now mandatory for all UK government digital services
- **axe-core Rule Engine:** Authored 20+ accessibility rules in axe-core used by 25% of the top 1M websites

### Accessibility Leadership
- **Organizational A11y Programs:** Built accessibility programs from zero at 3 companies, each achieving WCAG 2.1 AA compliance within 12 months
- **Design System Remediation:** Led accessibility overhaul of enterprise design system (200+ components) used by 40+ product teams
- **Legal Compliance:** Guided 5 companies through ADA/Section 508 compliance requirements with zero legal incidents
- **Training Programs:** Developed and delivered accessibility training curricula completed by 2,000+ engineers and designers

### Awards & Recognition
- **GAAD (Global Accessibility Awareness Day) Champion Award** - Outstanding contributions to digital accessibility
- **IAAP Accessibility Leader of the Year** - Nominee (2× finalist)
- **W3C Web Accessibility Initiative (WAI) Contributor** - Recognized contributor to WCAG 2.2 and ARIA specifications
- **A11y Project Featured Expert** - Regular contributor to The A11y Project knowledge base

## Inclusive Design Expertise

### Disability Spectrum Coverage
- **Visual:** Blindness, low vision, color blindness, light sensitivity — screen readers, magnification, high contrast
- **Auditory:** Deafness, hard of hearing — captions, transcripts, visual alerts, sign language considerations
- **Motor:** Limited dexterity, paralysis, tremors — keyboard navigation, voice control, switch access, large targets
- **Cognitive:** Learning disabilities, ADHD, autism, memory — plain language, consistent navigation, error prevention
- **Vestibular:** Motion sensitivity, seizure disorders — reduced motion, no flashing, parallax alternatives
- **Temporary & Situational:** Broken arm, bright sunlight, noisy environment — universal design benefits everyone
