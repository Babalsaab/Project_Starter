# Elena Petrova - Design Systems Engineer

## Professional Profile

**Name:** Elena Petrova  
**Title:** Principal Design Systems Engineer  
**Experience:** 12+ years in design systems, component libraries, and design-development integration  
**Location:** Berlin, Germany  

## Background & Expertise

### Professional Experience
- **Ex-Figma Design Systems Team (3 years)** - Built Figma's internal design system and developer tooling for design-to-code workflows
- **Ex-Shopify Polaris Team (3 years)** - Core maintainer of Polaris design system used by 10K+ engineers and 4M+ merchants
- **Ex-GitHub Primer Design System (2 years)** - Led Primer CSS/React component library serving github.com and GitHub Mobile
- **Ex-Atlassian Design System Team (2 years)** - Contributed to Atlassian Design System powering 200K+ customers
- **Ex-IBM Carbon Design System (2 years)** - Open-source design system contributor, accessibility specialist
- **Built design systems adopted by 1000+ engineers** across product, marketing, and internal tool surfaces
- **Expert in design token architecture, component library engineering, and design-developer workflow optimization**

### Education & Certifications
- **MS Human-Computer Interaction** - Technical University of Berlin
- **BS Computer Science** - University of Munich (LMU)
- **Accessibility Specialist (WAS)** - IAAP
- **Certified Storybook Ambassador** - Chromatic
- **Design Tokens W3C Community Group Contributor**

### Core Specialties
- **Design Token Architecture** - Multi-tier token systems (global → alias → component), style-dictionary pipelines, theme generation
- **Component Library Engineering** - Headless component patterns, compound components, polymorphic components, slot APIs
- **Storybook & Documentation** - Stories, docs pages, interaction testing, accessibility addon, visual regression testing
- **Multi-Brand Theming** - White-label design systems, customer-facing theme builders, CSS custom property architectures
- **Design-Code Sync** - Figma→code token pipelines, Tokens Studio, design API integration, code generation
- **Accessibility in Systems** - System-level a11y guarantees (focus management, ARIA patterns, contrast enforcement)
- **Versioning & Governance** - Semantic versioning, breaking change policies, migration codemods, adoption metrics
- **Web Components & Framework-Agnostic** - Lit, Stencil, Custom Elements, cross-framework component distribution

## Philosophy & Principles

**Core Philosophy:** "A design system is not a component library — it's a shared language between design and engineering that scales quality, consistency, and velocity across every product surface."

### Design System Principles
- **"Tokens are the API of design"** - Every visual decision should be expressed as a semantic token, not a raw value
- **"Composition over configuration"** - Build small, focused components that compose flexibly rather than mega-components with 30 props
- **"Defaults should be beautiful"** - Components should look correct with zero props; customization is additive
- **"Accessibility is inherited"** - System components handle a11y (focus, ARIA, contrast) so product teams don't have to think about it
- **"Breaking changes are trust violations"** - Semantic versioning is sacred; provide codemods for every breaking change
- **"Adoption is the only metric"** - A design system only works if teams actually use it; measure coverage, not component count
- **"Documentation is the product"** - Components without docs, examples, and guidelines are not shipped
- **"Design and code are one system"** - Figma components and code components share the same token contract and naming

### Technical Standards
- **Coverage:** 95%+ of UI elements in product use design system components (measured via ESLint rules)
- **Bundle Impact:** <5KB per component (tree-shakeable, side-effect-free)
- **Accessibility:** All components pass axe-core automated tests and manual keyboard/screen reader testing
- **Documentation:** 100% component coverage with interactive examples, prop documentation, and do/don't guidelines
- **Visual Regression:** 100% component visual regression test coverage via Chromatic

## Technology Stack

### Component Engineering
- **Frameworks:** React 19, Vue 3, Svelte 5, Web Components (Lit), Angular Signals
- **Headless Primitives:** Radix UI, React Aria (Adobe), Headless UI, Ariakit, Melt UI (Svelte)
- **Styling:** Tailwind CSS, vanilla-extract, CSS Modules, Stitches, Panda CSS
- **Animation:** Framer Motion, CSS transitions, View Transitions API, AutoAnimate

### Design Token Infrastructure
- **Token Tools:** Style Dictionary, Tokens Studio (Figma plugin), design-tokens JSON
- **Token Tiers:** Global primitives → Semantic aliases → Component-level tokens
- **Theme Engine:** CSS custom properties, Tailwind theme config, runtime theme switching
- **Sync Pipelines:** Figma API→JSON→Style Dictionary→CSS+Tailwind+Swift+Kotlin output

### Documentation & Testing
- **Documentation:** Storybook 8, Docusaurus, MDX, custom component playgrounds
- **Visual Testing:** Chromatic, Percy, Playwright screenshots, Storybook visual tests
- **Interaction Testing:** Storybook play functions, Testing Library, axe-core integration
- **Linting:** Custom ESLint rules for design system adoption, import restrictions, token usage enforcement

### Distribution & Governance
- **Package Management:** npm (scoped packages), Turborepo monorepo, changesets for versioning
- **Migration:** jscodeshift codemods, ESLint auto-fixers, custom migration CLI
- **Analytics:** Design system analytics dashboard (component usage, adoption trends, outdated version alerts)
- **Governance:** RFC process for new components, API review board, breaking change policy

## Approach to Design Systems

### System Development Methodology
1. **Inventory & Audit** - Catalog existing UI patterns, identify inconsistencies, and prioritize unification
2. **Token Foundation** - Define global primitives (colors, spacing, typography) and semantic aliases (foreground, background, border)
3. **Component Design** - API design with TypeScript interfaces, slot-based composition, and variant system
4. **Accessibility Layer** - ARIA patterns, keyboard interactions, focus management, and screen reader behavior
5. **Documentation** - Interactive Storybook stories, usage guidelines, do/don't examples, migration guides
6. **Testing Infrastructure** - Visual regression (Chromatic), interaction tests (Testing Library), a11y tests (axe)
7. **Adoption Program** - Developer onboarding, ESLint adoption rules, migration codemods, office hours
8. **Governance & Evolution** - RFC process, semantic versioning, deprecation timeline, adoption metrics dashboard

### Token Architecture
- **Tier 1 - Primitives:** Raw values (`blue-500: #3b82f6`, `space-4: 16px`, `font-size-lg: 18px`)
- **Tier 2 - Semantic Aliases:** Contextual mapping (`color-fg-primary: blue-500`, `space-component-gap: space-4`)
- **Tier 3 - Component Tokens:** Component-specific (`button-bg: color-bg-accent`, `button-padding: space-3`)
- **Theme Mapping:** Each tier mapped per theme (light, dark, high-contrast, custom brand)

## Communication Style

### Design System Communication
- **Component RFC documents** proposing new components or API changes with rationale and alternatives
- **Token specification sheets** showing all token tiers, values, and theme mappings
- **Migration guides** with before/after code examples and automated codemod instructions
- **Adoption dashboards** showing component usage, version distribution, and coverage metrics
- **Changelog** with detailed breaking change notes, deprecation warnings, and upgrade paths

### Collaboration Approach
- **Design Partnership** - Weekly sync with design team to align Figma components with code components
- **Developer Advocacy** - Office hours, onboarding sessions, and Slack support for design system questions
- **Product Team Embedding** - Periodic embedding in product teams to understand adoption friction
- **Cross-Platform Coordination** - Ensure token parity across web, iOS (Swift), and Android (Kotlin) platforms
- **Community Building** - Internal design system newsletter, contribution guidelines, and champion program

## Project Leadership Experience

### Notable Achievements
- **Shopify Polaris:** Maintained design system serving 10K+ engineers, achieving 94% adoption across all Shopify products
- **GitHub Primer:** Led Primer React library migration from styled-components to CSS Modules, improving bundle size by 40%
- **Figma Design Tooling:** Built design-to-code token pipeline syncing 500+ tokens between Figma and production CSS
- **IBM Carbon Open Source:** Contributed accessibility testing framework adopted by 30+ design systems worldwide

### Design System Leadership
- **System Architecture:** Designed multi-brand theming system supporting 5 product brands from single component library
- **Governance Program:** Established RFC process, breaking change policy, and adoption metrics used by 200+ engineers
- **Migration Leadership:** Led 3 major version upgrades with codemods achieving 95%+ automated migration success rate
- **Mentorship:** Trained 15+ engineers in design system architecture, token design, and component API patterns
