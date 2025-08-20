# Claude Code UI Design Workflow

A comprehensive setup for creating exceptional UI designs using Claude Code with Playwright MCP integration. These files provide the foundational workflow needed to transform Claude Code into a powerful UI design assistant, based on the viral workflow that unlocks "the missing 90% of Claude Code's incredible design capabilities."

## 🎯 What This Unlocks

Based on the viral workflow that unlocks "the missing 90% of Claude Code's incredible design capabilities," this setup enables:

- **Visual Intelligence**: Claude can see and iteratively improve its own designs
- **Pixel-Perfect Results**: Screenshot-driven feedback loops for precise implementations
- **Design System Consistency**: Comprehensive guidelines and automated validation
- **Accessibility-First**: Built-in accessibility testing and compliance
- **Responsive Excellence**: Multi-device testing and optimization
- **Performance Awareness**: Visual performance monitoring and optimization

## 📁 File Structure

```
your-project/
├── design-principles.md      # Core design philosophy and standards
├── component-standards.md    # Detailed component specifications
├── playwright-workflow.md    # Complete Playwright MCP workflow guide
├── CLAUDE.md                 # Claude Code configuration template
└── .claude/
    ├── agents/
    │   └── design-reviewer.md    # Design review subagent
    └── commands/
        ├── screenshot-review.md  # Quick screenshot review command
        ├── responsive-test.md    # Responsive testing command
        └── accessibility-audit.md # Accessibility testing command
```

## 🚀 Quick Start

### 1. Install Prerequisites

```bash
# Install Claude Code
npm install -g @anthropic-ai/claude-code

# Install Playwright MCP
npx @anthropic-ai/claude-code-installer@latest add playwright
```

### 2. Set Up Your Project Structure

Create the following files in your project root:

```bash
# Create the .claude directory structure
mkdir -p .claude/agents
mkdir -p .claude/commands

# Create the main configuration files
touch design-principles.md
touch component-standards.md  
touch playwright-workflow.md
touch CLAUDE.md

# Create the subagent and command files
touch .claude/agents/design-reviewer.md
touch .claude/commands/screenshot-review.md
touch .claude/commands/responsive-test.md
touch .claude/commands/accessibility-audit.md
```

Then copy the content from the artifacts above into each respective file, or clone this repository if you've set it up:

```bash
# If you've created your own repository with these files
git clone https://github.com/YOUR-USERNAME/YOUR-REPO-NAME.git

# Copy the essential files to your project
cp YOUR-REPO-NAME/design-principles.md ./
cp YOUR-REPO-NAME/component-standards.md ./
cp YOUR-REPO-NAME/playwright-workflow.md ./
cp YOUR-REPO-NAME/CLAUDE.md ./
cp -r YOUR-REPO-NAME/.claude ./
```

### 3. Customize for Your Project

Edit the `CLAUDE.md` file to match your specific:
- Framework (React, Vue, Svelte, etc.)
- Build tools and commands
- Project structure
- Team conventions

### 4. Start Claude Code

```bash
# Navigate to your project
cd your-project

# Start Claude Code (it will automatically load your CLAUDE.md)
claude
```

### 5. Test the Workflow

```bash
# Take your first design screenshot
/screenshot-review dashboard

# Run a comprehensive design review
@agent design-reviewer
Please review the main navigation component and provide feedback on responsive behavior.
```

## 🎨 Key Features

### Visual Design Intelligence
- **Screenshot Feedback Loops**: Claude sees its own designs and iterates
- **Design Comparison**: Side-by-side mockup vs implementation analysis
- **Pixel-Perfect Validation**: Precise measurements and alignment checking
- **Visual Regression Testing**: Automated change detection

### Comprehensive Design System
- **Modern Design Principles**: Contemporary UI patterns and trends
- **Component Standards**: Detailed specifications for all common components
- **Accessibility Guidelines**: WCAG 2.1 AA compliance requirements
- **Performance Standards**: Visual performance and optimization targets

### Automated Testing Workflows
- **Responsive Testing**: Multi-breakpoint layout validation
- **Interactive State Testing**: Hover, focus, and active state verification
- **Accessibility Auditing**: Keyboard navigation and screen reader testing
- **Cross-Browser Validation**: Consistent experience across browsers

### Developer Experience
- **Slash Commands**: Quick access to common workflows
- **Subagents**: Specialized agents for design review and validation
- **Template Configurations**: Ready-to-use Claude Code setups
- **Documentation Integration**: Context-aware design guidance

## 🛠️ Workflow Examples

### Basic Component Creation
```bash
# Ask Claude to create a modern button component
Create a button component following our design principles. 
Include all variants (primary, secondary, outline, ghost) and ensure accessibility compliance.
Take screenshots to validate the implementation.
```

### Design Review Process
```bash
# Comprehensive design review
@agent design-reviewer
Review the new checkout form for mobile usability. 
Check touch targets, form validation, and payment flow.
```

### Responsive Design Testing
```bash
# Test responsive behavior
/responsive-test product-page
# This will test layouts across all breakpoints and capture screenshots
```

### Accessibility Validation
```bash
# Run accessibility audit
/accessibility-audit contact-form
# This will test keyboard navigation, color contrast, and ARIA compliance
```

## 📱 Responsive Design Strategy

### Breakpoint System
- **Mobile**: 375px - 639px (iPhone SE baseline)
- **Tablet**: 640px - 1023px (iPad standard)
- **Desktop**: 1024px - 1439px (Standard desktop)
- **Wide**: 1440px+ (Large displays)

### Testing Approach
1. **Mobile-First Development**: Start with mobile layout
2. **Progressive Enhancement**: Add desktop features
3. **Touch-Friendly Design**: 44px minimum touch targets
4. **Content Strategy**: Prioritize content across devices

## ♿ Accessibility Standards

### WCAG 2.1 AA Compliance
- **Color Contrast**: 4.5:1 for normal text, 3:1 for large text
- **Keyboard Navigation**: Full functionality without mouse
- **Screen Reader Support**: Proper ARIA labels and semantic HTML
- **Focus Management**: Visible focus indicators and logical tab order

### Testing Tools Integration
- **Automated Testing**: jest-axe for automated accessibility checks
- **Manual Testing**: Keyboard navigation and screen reader verification
- **Color Contrast**: Built-in contrast ratio validation
- **User Testing**: Regular testing with assistive technology users

## 🎯 Design Principles

### Visual Excellence
- **Bold Over Safe**: Choose vibrant colors and dynamic layouts
- **Modern Aesthetic**: Dark modes, glassmorphism, micro-animations
- **Interactive Responsiveness**: Every element should feel alive
- **Premium Feel**: Advanced CSS and creative interactions

### User Experience
- **Functionality First**: Smooth performance and intuitive interactions
- **Accessibility**: Inclusive design for all users
- **Performance**: Fast loading and smooth animations
- **Cross-Platform**: Consistent experience across devices

## 🤖 Subagent System

### Design Reviewer Agent
Specialized for comprehensive UI/UX analysis:
- Visual design assessment
- Interaction and usability evaluation
- Technical implementation review
- Accessibility compliance verification

### Usage Patterns
```bash
# Invoke the design reviewer
@agent design-reviewer [specific instructions]

# Examples:
@agent design-reviewer Review the dashboard for mobile usability
@agent design-reviewer Check the new form component for accessibility
@agent design-reviewer Validate the color scheme against our brand guidelines
```

## 📊 Performance Monitoring

### Core Web Vitals Targets
- **First Contentful Paint**: < 1.5 seconds
- **Largest Contentful Paint**: < 2.5 seconds
- **Cumulative Layout Shift**: < 0.1
- **First Input Delay**: < 100ms

### Visual Performance
- **60 FPS Animations**: Smooth transitions and interactions
- **Optimized Assets**: WebP images with fallbacks
- **Efficient CSS**: Minimal render-blocking resources
- **Progressive Loading**: Skeleton screens and lazy loading

## 🔧 Customization Guide

### Adapting for Your Framework

#### React Projects
```markdown
# Add to your CLAUDE.md
- Use functional components with hooks
- Follow React best practices (useState, useEffect, useMemo)
- Implement proper prop types with TypeScript
- Use React Testing Library for component tests
```

#### Vue.js Projects
```markdown
# Add to your CLAUDE.md
- Use Composition API for complex components
- Implement proper reactive data patterns
- Follow Vue.js style guide conventions
- Use Vue Test Utils for component testing
```

#### Svelte Projects
```markdown
# Add to your CLAUDE.md
- Leverage Svelte's reactive statements
- Use stores for state management
- Implement proper component lifecycle
- Follow Svelte testing best practices
```

### Team Collaboration

#### Shared Configuration
```bash
# Commit these files to share with your team
git add CLAUDE.md design-principles.md component-standards.md
git add .claude/
git commit -m "Add Claude Code UI workflow configuration"
```

#### Individual Customization
```bash
# Create personal overrides (not committed)
cp CLAUDE.md CLAUDE.local.md
# Edit CLAUDE.local.md for personal preferences
echo "CLAUDE.local.md" >> .gitignore
```

## 🚀 Advanced Workflows

### Multi-Instance Development
```bash
# Use git worktrees for parallel development
git worktree add ../project-feature-a feature-a
git worktree add ../project-feature-b feature-b

# Run Claude Code in each worktree
cd ../project-feature-a && claude &
cd ../project-feature-b && claude &
```

### Automated Design Reviews
```bash
# Set up automated reviews in CI/CD
claude -p "Review all UI changes in this PR for design compliance" --headless
```

### Design System Evolution
```bash
# Regular design system audits
@agent design-reviewer
Audit our entire component library for consistency and identify areas for improvement.
Generate a report with recommendations for design system updates.
```

## 📖 Additional Resources

### Official Documentation
- [Claude Code Documentation](https://docs.anthropic.com/en/docs/claude-code)
- [Playwright MCP Server](https://github.com/modelcontextprotocol/servers/tree/main/src/playwright)
- [Anthropic Best Practices](https://www.anthropic.com/engineering/claude-code-best-practices)

### Design References
- [Modern UI Patterns](https://ui-patterns.com/)
- [Accessibility Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [Design System Examples](https://designsystemsrepo.com/)

### Community Examples
- [Original GitHub Repository](https://github.com/OneRedOak/claude-code-workflows) (Patrick's original workflow)
- [Video Tutorial](https://youtube.com/watch?v=example) (Based on Patrick's viral workflow)
- Create your own repository with these enhanced files
- [Community Discord](https://discord.gg/anthropic) (Join for tips and support)

## 🤝 Contributing

We welcome contributions to improve this workflow:

1. **Fork the repository**
2. **Create a feature branch** (`git checkout -b feature/amazing-improvement`)
3. **Make your changes** (update documentation, add examples, improve workflows)
4. **Test thoroughly** (ensure all examples work with latest Claude Code)
5. **Submit a pull request** (describe your changes and benefits)

### Areas for Contribution
- Additional component examples
- Framework-specific optimizations
- New subagent configurations
- Performance testing improvements
- Accessibility enhancement tools

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🙏 Acknowledgments

- **Patrick Ellis** - For developing and sharing the original viral workflow
- **Anthropic Team** - For Claude Code and excellent documentation
- **Microsoft** - For the Playwright framework
- **Design Community** - For inspiration and best practices

---

*Transform your Claude Code into an incredible UI designer. Start building better interfaces today!*