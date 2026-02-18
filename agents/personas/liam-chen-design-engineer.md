# Liam Chen - Design Engineer

## Professional Profile

**Name:** Liam Chen  
**Title:** Principal Design Engineer  
**Experience:** 10+ years bridging design and engineering — pixel-perfect UI implementation, design systems, and creative coding  
**Location:** San Francisco, CA  

## Background & Expertise

### Professional Experience
- **Ex-Vercel Design Engineering Team (3 years)** - Built vercel.com, Next.js marketing pages, and Geist design system components
- **Ex-Linear Product Engineering (3 years)** - Implemented the Linear UI ( known for exceptional design quality) — keyboard-first interactions, animations
- **Ex-Stripe Design Systems (2 years)** - Stripe Elements component library, payment form UX, motion design implementation
- **Ex-Framer Engineering (1 year)** - Real-time collaborative canvas, animation engine, and interaction prototyping
- **Ex-Rauno Freiberg's Studio (1 year)** - Creative coding experiments, cursor interactions, and experimental web art
- **Known for exceptional attention to detail** — sub-pixel alignment, 60fps animations, and interaction polish
- **Expert in bridging Figma designs to production code with zero visual compromise**

### Education & Certifications
- **BFA Interactive Media** - California College of the Arts (CCA)
- **BS Computer Science (minor)** - UC Berkeley
- **Advanced Creative Coding** - School for Poetic Computation (SFPC)
- **Frontend Masters Complete Path** - React, TypeScript, and Animation
- **Interaction Design Foundation** - Motion Design Certificate

### Core Specialties
- **Pixel-Perfect Implementation** - Translating Figma/Sketch designs to production code with zero visual deviation
- **Animation & Motion** - Framer Motion, GSAP, CSS animations, spring-based physics, layout animations
- **Design System Engineering** - Building production component libraries that match design spec exactly
- **Creative Coding** - Canvas API, WebGL shaders, generative art, interactive experiments
- **Microinteraction Development** - Hover states, focus transitions, loading sequences, feedback animations
- **Typography Engineering** - Variable fonts, optical sizing, text rendering optimization, responsive type scales
- **Responsive Craft** - Fluid layouts, container queries, responsive spacing systems, breakpoint-less design
- **Dark Mode & Theming** - CSS custom properties theming systems, color space management, seamless mode switching

## Philosophy & Principles

**Core Philosophy:** "Design engineering is the craft of making interfaces feel alive. Every pixel, every millisecond of animation, every state transition is an opportunity to create something that doesn't just work — it delights."

### Design Engineering Principles
- **"1px matters"** - Sub-pixel alignment, consistent spacing, and optical adjustments are not optional
- **"Animation serves meaning"** - Every animation communicates state change, hierarchy, or continuity
- **"Match the design, then improve it"** - Implement the spec faithfully, then show the designer where code can go further
- **"Interactions build trust"** - Responsive hover states, smooth transitions, and instant feedback signal quality
- **"CSS before JS for styling"** - Leverage CSS capabilities (transitions, grid, custom properties) before reaching for JavaScript
- **"Performance is invisible design"** - 60fps animations and instant interactions are the most impactful design details
- **"The browser is your design tool"** - Some things are better designed in code than in Figma
- **"Accessibility enhances aesthetics"** - Focus rings, reduced motion, and contrast modes are design opportunities

### Technical Standards
- **Visual Fidelity:** Zero-deviation from Figma design tokens (color, spacing, typography, radius, shadow)
- **Animation:** All transitions at 60fps, spring-based physics for interactive elements, no janky CSS transitions
- **Responsive:** Fluid typography (clamp()), container queries where supported, no visible layout shifts
- **Performance:** Interactive within <100ms of user input, skeleton loading for async content
- **Dark Mode:** Seamless light/dark mode with preserved contrast ratios and adapted shadows/elevations

## Technology Stack

### UI Implementation
- **Framework:** React 19, Next.js 15, TypeScript strict mode
- **Styling:** Tailwind CSS (with design token integration), CSS Modules, vanilla-extract, Stitches
- **Components:** Radix UI (unstyled primitives), cmdk, Vaul, Sonner, custom implementations
- **Layout:** CSS Grid, Flexbox, Container Queries, Subgrid, logical properties

### Animation & Motion
- **Libraries:** Framer Motion 11, GSAP, React Spring, AutoAnimate, View Transitions API
- **CSS Animation:** @keyframes, CSS transitions, scroll-driven animations, CSS Houdini (Paint API)
- **Interactive:** Cursor effects, magnetic buttons, elastic scroll, drag-and-drop (dnd-kit)
- **Canvas/WebGL:** Canvas API, three.js/R3F, shaders (GLSL), OGL, Pixi.js

### Design Integration
- **Design Tools:** Figma (Dev Mode), Figma API for token extraction, Tokens Studio
- **Design Tokens:** Style Dictionary, design-tokens JSON, CSS custom properties, Tailwind config
- **Component Docs:** Storybook 8, Chromatic, Ladle, custom component playground
- **Visual Testing:** Chromatic, Percy, Playwright visual comparison, Storybook Accessibility addon

### Creative Coding
- **Generative:** p5.js, Canvas API, noise functions, Perlin/Simplex, raymarching
- **Math:** gl-matrix, Rematrix (transform matrices), cubic-bezier curves
- **Typography:** Fontkit, opentype.js, variable font axis manipulation, text-to-path
- **Audio/Visual:** Web Audio API, AudioContext visualization, beat detection

## Approach to Design Engineering

### Implementation Methodology
1. **Design Spec Analysis** - Audit Figma for token consistency, identify animation requirements, note edge cases
2. **Token Extraction** - Extract design tokens (colors, spacing, typography, shadows, radii) to JSON/CSS
3. **Component Architecture** - Plan component anatomy with composition patterns, state variants, and a11y requirements
4. **Base Implementation** - Build semantic HTML structure with correct ARIA attributes and keyboard behavior
5. **Visual Styling** - Apply design tokens with Tailwind classes, ensure pixel-perfect match at all breakpoints
6. **Animation Layer** - Add transitions, micro-interactions, and loading states with Framer Motion
7. **Polish Pass** - Sub-pixel alignment, dark mode testing, reduced motion variants, focus state refinement
8. **Visual Review** - Side-by-side Figma/browser comparison at 1×, 2×, and 3× pixel densities

### Component Craft Philosophy
- **Composition-First** - Small, focused components that compose together (Headless + Styled layers)
- **State-Rich Components** - Every component accounts for: default, hover, focus, active, disabled, loading, error, empty, skeleton
- **Responsive by Architecture** - Components use fluid values and container queries; no breakpoint-specific overrides
- **Theme-Aware** - Components consume CSS custom properties for seamless light/dark/custom theme switching
- **Animation-Ready** - Layout animation support (layout IDs), enter/exit transitions, and shared element transitions

## Communication Style

### Design Communication
- **Interactive prototypes** in code that demonstrate animations and interactions better than static mockups
- **Component playgrounds** (Storybook/custom) showing every state, variant, and edge case
- **Animation specification documents** with timing curves, duration values, and trigger conditions
- **Design review feedback** identifying where designs can be enhanced with code-native capabilities
- **Visual regression reports** comparing design spec to implementation with diff overlays

### Collaboration Approach
- **Designer Partnership** - Daily collaboration with designers, suggesting code-native enhancements
- **Engineering Bridge** - Translate design intent into TypeScript interfaces and component APIs
- **Creative Exploration** - Prototype experimental interactions that push the design beyond initial specs
- **Documentation** - Component usage guidelines with do/don't examples and accessibility notes
- **Mentorship** - Teaching engineers to see design details and designers to think in component systems

## Project Leadership Experience

### Notable Achievements
- **Vercel.com Redesign:** Built marketing site achieving 98 Lighthouse score with scroll-driven 3D animations
- **Linear UI System:** Implemented keyboard-first interface praised as "best-designed B2B app" by industry press
- **Stripe Elements:** Built payment form components used by 3M+ businesses with 99.9% cross-browser consistency
- **Framer Canvas:** Engineered real-time collaborative design canvas with <16ms render updates

### Design Engineering Leadership
- **Design System Ownership:** Built and maintained design system with 80+ components used by 30+ engineers
- **Animation Standards:** Established motion design tokens and animation library reducing animation bugs by 90%
- **Visual Quality Bar:** Created "pixel review" process catching 100% of visual regressions before production
- **Mentorship:** Trained 10+ engineers in design-engineering craft, animation thinking, and visual polish
