# Claude Code Configuration

## Project Context
This project follows modern UI/UX design principles with emphasis on visual excellence, interactive responsiveness, and accessibility. Reference the `design-principles.md` file for detailed guidelines.

## Development Environment

### Tools & Commands
- `npm run dev` - Start development server
- `npm run build` - Build for production
- `npm run test` - Run test suite
- `npm run lint` - Run ESLint
- `npm run typecheck` - TypeScript type checking
- `npm run preview` - Preview production build

### Framework & Libraries
- **Frontend**: [React/Vue/Svelte] with TypeScript
- **Styling**: Tailwind CSS (utility-first approach)
- **Icons**: Lucide React / Heroicons
- **Testing**: Vitest / Jest + Testing Library
- **Build**: Vite / Next.js / Nuxt

## Code Style Guidelines

### General Principles
- Use ES modules (import/export) syntax, not CommonJS (require)
- Destructure imports when possible: `import { useState } from 'react'`
- Use TypeScript strictly - no `any` types without explicit justification
- Prefer functional components over class components
- Use semantic HTML elements and proper ARIA attributes

### File Structure
```
src/
├── components/          # Reusable UI components
├── pages/              # Page components/routes
├── hooks/              # Custom React hooks
├── utils/              # Utility functions
├── types/              # TypeScript type definitions
├── styles/             # Global styles and Tailwind config
└── assets/             # Static assets (images, fonts)
```

### Component Standards
- One component per file with default export
- Props interface defined above component
- Use meaningful prop names and include JSDoc comments
- Implement proper loading and error states
- Follow accessibility guidelines (WCAG 2.1 AA)

### CSS/Styling
- Use Tailwind utility classes primarily
- Create custom CSS only when Tailwind utilities are insufficient
- Follow mobile-first responsive design approach
- Use CSS custom properties for theming
- Implement dark mode support by default

## Visual Development Workflow

### Design Principles Reference
Always reference the `design-principles.md` file for:
- Color palette and typography standards
- Spacing and layout guidelines
- Component design patterns
- Animation and interaction standards
- Accessibility requirements

### Playwright Integration
When working on frontend changes:

1. **Navigate to affected pages** using Playwright browser automation
2. **Take screenshots** at desktop viewport (1920x1080) and mobile (375x667)
3. **Verify against design specifications** from mockups or style guide
4. **Check console for errors** and resolve any JavaScript issues
5. **Test interactive elements** (hover states, animations, form inputs)
6. **Validate accessibility** (keyboard navigation, screen reader compatibility)

### Design Review Process
For significant UI/UX changes:
- Use the `@agent design-reviewer` subagent for comprehensive analysis
- Include both desktop and mobile screenshot comparisons
- Verify color contrast ratios meet WCAG standards
- Test with keyboard navigation only
- Check loading states and error handling

### Visual Validation Checklist
- [ ] Matches design mockup/specification
- [ ] Responsive across all breakpoints
- [ ] Interactive states work (hover, focus, active)
- [ ] Animations are smooth (60fps)
- [ ] Accessibility standards met
- [ ] No console errors or warnings
- [ ] Performance metrics acceptable
- [ ] Cross-browser compatibility verified

## Testing Strategy

### Unit Testing
- Test component logic and state management
- Mock external dependencies and APIs
- Test custom hooks independently
- Aim for 80%+ code coverage on critical components

### Integration Testing
- Test user workflows and component interactions
- Test API integration and data flow
- Use React Testing Library best practices
- Test accessibility with jest-axe

### Visual Testing
- Use Playwright for screenshot comparison testing
- Test responsive layouts across breakpoints
- Verify interactive states and animations
- Cross-browser visual consistency

## Performance Guidelines

### Optimization Targets
- First Contentful Paint: < 1.5s
- Largest Contentful Paint: < 2.5s
- Cumulative Layout Shift: < 0.1
- Bundle size: Monitor and optimize

### Implementation Rules
- Use lazy loading for routes and heavy components
- Optimize images (WebP format with fallbacks)
- Implement proper caching strategies
- Use React.memo() and useMemo() judiciously
- Code split by routes and feature boundaries

## Git Workflow

### Branch Naming
- `feature/description` - New features
- `fix/description` - Bug fixes
- `refactor/description` - Code refactoring
- `docs/description` - Documentation updates

### Commit Messages
Follow conventional commits format:
```
type(scope): description

feat(ui): add responsive navigation component
fix(auth): resolve login form validation
docs(readme): update setup instructions
```

### Pull Request Process
1. Ensure all tests pass locally
2. Run type checking and linting
3. Include screenshots for UI changes
4. Request design review for significant visual changes
5. Update documentation if needed

## Accessibility Standards

### Required Implementation
- Semantic HTML structure with proper headings
- ARIA labels and descriptions where needed
- Keyboard navigation support for all interactive elements
- Color contrast ratio 4.5:1 minimum (3:1 for large text)
- Focus indicators clearly visible
- Screen reader compatibility tested

### Testing Tools
- axe-core for automated accessibility testing
- Keyboard navigation manual testing
- Screen reader testing (VoiceOver, NVDA)
- Color contrast validation tools

## Browser Support

### Target Browsers
- Chrome (last 2 versions)
- Firefox (last 2 versions)
- Safari (last 2 versions)
- Edge (last 2 versions)
- iOS Safari (last 2 versions)
- Chrome Mobile (last 2 versions)

### Progressive Enhancement
- Core functionality works without JavaScript
- CSS Grid with Flexbox fallbacks
- Modern features with appropriate polyfills
- Graceful degradation for older browsers

## Important Notes

### Design Review Requirements
- **ALWAYS** take screenshots after implementing UI changes
- **ALWAYS** test responsive behavior on mobile and desktop
- **ALWAYS** verify interactive states (hover, focus, active)
- **ALWAYS** check console for errors and warnings
- **ALWAYS** validate accessibility with keyboard navigation

### Claude Code Specific Instructions
- Use the word "think" or "think hard" for complex design decisions
- Request screenshot validation using Playwright after UI implementations
- Reference design-principles.md for specific design guidance
- Use subagents for comprehensive design reviews on significant changes
- Always verify implementations against acceptance criteria provided in prompts

### Framework-Specific Notes
[Add specific notes for your chosen framework - React, Vue, Svelte, etc.]

---

*This file should be updated as the project evolves and new patterns are established.*