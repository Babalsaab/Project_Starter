# Playwright MCP Workflow for UI Development

## Overview
This document outlines the complete workflow for using Playwright MCP with Claude Code to create exceptional UI designs through iterative visual feedback and validation.

## Core Workflow Components

### 1. Orchestration Layer
Every design task should include:
- **Context**: Well-written prompts and documentation (this file, design-principles.md)
- **Tools**: Playwright MCP for visual feedback and browser automation
- **Validation**: UI mockups, style guides, acceptance criteria for comparison

### 2. Iterative Agentic Loop
The workflow follows this pattern:
1. **Analyze Spec**: Review design requirements, mockups, or style guide
2. **Implement Code**: Create or modify UI components
3. **Take Screenshot**: Use Playwright to capture current state
4. **Compare & Evaluate**: Assess against specification
5. **Identify Issues**: Note discrepancies and improvements needed
6. **Refine Code**: Make adjustments based on feedback
7. **Repeat**: Continue until specifications are met

### 3. Visual Intelligence Integration
Leverage Claude's multimodal capabilities by:
- Providing visual mockups and design references
- Taking screenshots for comparison
- Using visual feedback to guide improvements
- Accessing the model's design knowledge through image analysis

## Playwright MCP Setup

### Installation
```bash
# Install Playwright MCP for Claude Code
npx @anthropic-ai/claude-code-installer@latest add playwright
```

### Configuration Options
Add to your MCP configuration:
```json
{
  "mcpServers": {
    "playwright": {
      "command": "npx",
      "args": ["@anthropic-ai/playwright-mcp"],
      "env": {
        "PLAYWRIGHT_BROWSER": "chromium",
        "PLAYWRIGHT_DEVICE": "desktop",
        "PLAYWRIGHT_HEADLESS": "false"
      }
    }
  }
}
```

### Browser Configuration
- **Default**: Chromium in headed mode for visual feedback
- **Device emulation**: iPhone 15, iPad, desktop viewports
- **Viewport sizes**: 
  - Mobile: 375x667 (iPhone SE)
  - Tablet: 768x1024 (iPad)
  - Desktop: 1920x1080 (HD)

## Step-by-Step Workflow

### Phase 1: Preparation and Context
1. **Review Design Specification**
   - Load UI mockups, wireframes, or design references
   - Understand acceptance criteria and requirements
   - Note specific visual elements, interactions, and responsive behavior

2. **Set Up Development Environment**
   - Ensure development server is running
   - Verify Playwright MCP is configured and accessible
   - Clear any previous browser state or cache

### Phase 2: Initial Implementation
3. **Code Implementation**
   - Build components following design-principles.md and component-standards.md
   - Focus on semantic HTML structure first
   - Implement responsive design with mobile-first approach
   - Add interactive states (hover, focus, active)
   - Include accessibility attributes and proper ARIA labels

4. **Initial Screenshot Capture**
   ```bash
   # Navigate to the page and capture screenshots
   playwright navigate http://localhost:3000/your-page
   playwright screenshot --viewport 1920x1080 --name desktop-initial
   playwright screenshot --viewport 375x667 --name mobile-initial
   ```

### Phase 3: Visual Validation and Iteration
5. **Compare Against Specification**
   - Load design mockup alongside screenshots
   - Identify visual discrepancies:
     - Layout and spacing issues
     - Typography inconsistencies
     - Color and contrast problems
     - Missing interactive states
     - Responsive behavior issues

6. **Console Error Check**
   ```bash
   playwright console-logs
   playwright network-logs
   ```
   - Review for JavaScript errors
   - Check for failed network requests
   - Verify no accessibility violations

7. **Interactive Testing**
   ```bash
   # Test form interactions
   playwright click "button[type='submit']"
   playwright fill "input[name='email']" "test@example.com"
   
   # Test hover states
   playwright hover ".card"
   playwright screenshot --name hover-state
   
   # Test focus states
   playwright focus "button"
   playwright screenshot --name focus-state
   ```

### Phase 4: Responsive Testing
8. **Multi-Device Validation**
   ```bash
   # Test different viewport sizes
   playwright screenshot --viewport 375x667 --name mobile
   playwright screenshot --viewport 768x1024 --name tablet
   playwright screenshot --viewport 1440x900 --name desktop-large
   
   # Test device emulation
   playwright emulate-device "iPhone 15"
   playwright screenshot --name iphone-15
   ```

9. **Layout Verification**
   - Check text wrapping and overflow
   - Verify button and touch target sizes (min 44px)
   - Test navigation menu behavior
   - Validate form layouts on different screens

### Phase 5: Advanced Testing
10. **Accessibility Validation**
    ```bash
    # Test keyboard navigation
    playwright keyboard "Tab Tab Tab Enter"
    
    # Check color contrast
    playwright accessibility-audit
    
    # Test with screen reader simulation
    playwright aria-tree
    ```

11. **Performance Testing**
    ```bash
    # Measure loading performance
    playwright performance-metrics
    
    # Test animation smoothness
    playwright record-animation ".animated-element"
    ```

## Automated Workflow Commands

### Slash Commands for Common Tasks

#### `/screenshot-review`
```markdown
Take comprehensive screenshots of the current page:
1. Navigate to http://localhost:3000/$ARGUMENTS
2. Capture desktop view (1920x1080)
3. Capture tablet view (768x1024) 
4. Capture mobile view (375x667)
5. Test hover states on interactive elements
6. Check console for errors
7. Generate comparison report with any provided mockups
```

#### `/responsive-test`
```markdown
Test responsive behavior across breakpoints:
1. Navigate to the specified page
2. Test layouts at sm(640px), md(768px), lg(1024px), xl(1280px)
3. Verify text scaling and readability
4. Check touch target sizes on mobile
5. Test navigation menu collapse/expand
6. Capture screenshots at each breakpoint
```

#### `/accessibility-audit`
```markdown
Perform comprehensive accessibility testing:
1. Run automated accessibility checks
2. Test keyboard navigation flow
3. Verify ARIA labels and descriptions
4. Check color contrast ratios
5. Test with simulated screen reader
6. Generate accessibility report with recommendations
```

## Integration with Design Review Process

### Subagent Configuration
Create `.claude/agents/visual-qa.md`:
```markdown
# Visual QA Agent

You are a design-focused QA engineer specializing in UI/UX validation.

## Tools Available
- playwright (for screenshots and browser automation)
- design-principles.md (for reference standards)
- component-standards.md (for component specifications)

## Process
1. **Visual Analysis**: Compare implementations against mockups
2. **Responsive Testing**: Verify layouts across all breakpoints  
3. **Interactive States**: Test hover, focus, and active states
4. **Accessibility**: Ensure WCAG 2.1 AA compliance
5. **Performance**: Check for visual jank and loading issues

## Report Format
Provide structured feedback with:
- Screenshots at each breakpoint
- Specific issues with pixel-perfect details
- Accessibility violations and fixes
- Performance recommendations
- Priority ranking (high/medium/low)
```

### Automated Review Triggers
In your CLAUDE.md, add:
```markdown
## Visual Development Standards

### Automatic Screenshot Review
When implementing frontend changes:
1. Navigate to affected pages using Playwright
2. Capture screenshots at desktop (1920x1080) and mobile (375x667) viewports
3. Compare against design specifications in context folder
4. Check for console errors and accessibility violations
5. Test interactive elements and responsive behavior

### Comprehensive Design Review
For significant UI changes or new components:
- Use @agent visual-qa for detailed analysis
- Include before/after screenshots
- Test across all supported browsers
- Validate against design-principles.md requirements
```

## Advanced Playwright Workflows

### User Journey Testing
```bash
# Test complete user flows
playwright navigate "/signup"
playwright fill "input[name='email']" "user@example.com"
playwright fill "input[name='password']" "securePassword123"
playwright click "button[type='submit']"
playwright wait-for-selector ".success-message"
playwright screenshot --name signup-success
```

### A/B Testing Support
```bash
# Test different design variants
playwright navigate "/feature?variant=a"
playwright screenshot --name variant-a
playwright navigate "/feature?variant=b" 
playwright screenshot --name variant-b
```

### Performance Monitoring
```bash
# Monitor Core Web Vitals
playwright performance-trace start
playwright navigate "/heavy-page"
playwright performance-trace stop
playwright performance-report
```

### Cross-Browser Testing
```bash
# Test across different browsers
playwright browser chromium
playwright screenshot --name chrome-version
playwright browser firefox  
playwright screenshot --name firefox-version
playwright browser webkit
playwright screenshot --name safari-version
```

## Integration with Development Workflow

### Pre-Commit Hooks
Add visual regression testing to git hooks:
```json
{
  "husky": {
    "hooks": {
      "pre-commit": "claude -p 'Run visual regression tests on changed components' --headless"
    }
  }
}
```

### CI/CD Integration
```yaml
# .github/workflows/visual-tests.yml
name: Visual Regression Tests
on: [pull_request]
jobs:
  visual-tests:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Install dependencies
        run: npm install
      - name: Run Claude Code visual tests
        run: claude -p "Test all components for visual regressions" --headless
```

### Development Server Integration
```javascript
// Auto-screenshot on file changes (optional)
const chokidar = require('chokidar');
chokidar.watch('src/components/**/*.{js,tsx,css}').on('change', () => {
  exec('claude -p "Take screenshots of affected components" --headless');
});
```

## Best Practices

### Screenshot Naming Convention
- `{component}-{viewport}-{state}-{timestamp}.png`
- Examples:
  - `button-desktop-hover-20250117.png`
  - `modal-mobile-open-20250117.png`
  - `form-tablet-error-20250117.png`

### Comparison Strategies
1. **Side-by-side**: Place mockup and screenshot side by side
2. **Overlay**: Use semi-transparent overlay to spot differences
3. **Diff highlighting**: Mark specific areas that don't match
4. **Measurement**: Use pixel-perfect measurements for spacing

### Performance Optimization
- Use headless mode for CI/CD pipelines
- Cache screenshots for unchanged components
- Compress images for storage efficiency
- Parallelize tests across multiple viewports

### Error Handling
```javascript
// Robust screenshot capture with retry logic
async function captureWithRetry(selector, maxRetries = 3) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      await playwright.waitForSelector(selector, { timeout: 5000 });
      return await playwright.screenshot();
    } catch (error) {
      if (i === maxRetries - 1) throw error;
      await playwright.wait(1000);
    }
  }
}
```

## Troubleshooting Guide

### Common Issues
1. **Screenshots not matching**: Check viewport size and zoom level
2. **Timing issues**: Add wait conditions for dynamic content
3. **Font rendering**: Ensure consistent font loading across environments
4. **Animation capturing**: Disable animations for stable screenshots
5. **Network issues**: Mock external resources for consistent results

### Debug Commands
```bash
# Verbose logging
playwright --debug navigate "/page"

# Slow motion for debugging
playwright --slow-mo 1000 click "button"

# Trace recording
playwright trace start
# ... perform actions ...
playwright trace stop
playwright trace show
```

### Recovery Strategies
- Reset browser state between tests
- Clear cache and cookies
- Restart browser instances
- Use fresh user profiles
- Verify network connectivity

---

*This workflow should be customized based on your specific project needs and integrated with your existing development processes.*