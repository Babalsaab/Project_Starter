# Shadcn AI Agent Playbook

*Comprehensive guide for AI agents (Claude, Cursor, etc.) to work effectively with shadcn/ui components*

## 🎯 Core Principles for AI Agents

### Always Follow These Rules
1. **shadcn/ui First**: Always prefer shadcn/ui components over custom implementations
2. **Accessibility Required**: Every component must meet WCAG 2.1 AA standards
3. **TypeScript Strict**: Use strict TypeScript with proper prop interfaces
4. **Theme Consistency**: Apply project theme tokens from `tailwind.config.ts`
5. **Responsive Design**: Implement mobile-first responsive patterns
6. **Testing Included**: Generate interaction tests for all user-facing components

## 📋 Component Generation Workflow

### Step 1: Requirement Analysis
```typescript
// When asked to create a component, always analyze:
interface ComponentRequirements {
  purpose: string;           // What does this component do?
  type: 'form' | 'display' | 'navigation' | 'feedback' | 'layout';
  complexity: 'simple' | 'moderate' | 'complex';
  accessibility: 'standard' | 'enhanced' | 'critical';
  responsiveness: 'basic' | 'adaptive' | 'mobile-first';
  interactivity: 'static' | 'interactive' | 'dynamic';
}
```

### Step 2: Component Selection
```typescript
// Map requirements to shadcn components:
const COMPONENT_MAPPING = {
  forms: {
    simple: ['Form', 'Input', 'Label', 'Button'],
    moderate: ['Form', 'Input', 'Label', 'Button', 'Select', 'Checkbox', 'RadioGroup'],
    complex: ['Form', 'Input', 'Label', 'Button', 'Select', 'Checkbox', 'RadioGroup', 'DatePicker', 'Combobox']
  },
  display: {
    simple: ['Card', 'Badge', 'Avatar'],
    moderate: ['Card', 'Badge', 'Avatar', 'Table', 'Separator'],
    complex: ['Card', 'Badge', 'Avatar', 'Table', 'DataTable', 'Chart', 'Calendar']
  },
  navigation: {
    simple: ['Button', 'Link'],
    moderate: ['NavigationMenu', 'Breadcrumb', 'Tabs'],
    complex: ['NavigationMenu', 'Breadcrumb', 'Tabs', 'Sidebar', 'Command']
  },
  feedback: {
    simple: ['Alert', 'Badge'],
    moderate: ['Alert', 'Toast', 'Progress'],
    complex: ['Alert', 'Toast', 'Progress', 'Dialog', 'AlertDialog', 'Sheet']
  },
  layout: {
    simple: ['Card', 'Separator'],
    moderate: ['Card', 'Separator', 'ScrollArea', 'ResizablePanels'],
    complex: ['Card', 'Separator', 'ScrollArea', 'ResizablePanels', 'Sidebar', 'Layout']
  }
};
```

### Step 3: Implementation Template
```typescript
// Always use this structure for component generation:
interface ComponentTemplate {
  imports: string[];         // Required shadcn component imports
  props: TypeScriptInterface; // Strict TypeScript prop definitions
  component: ReactComponent;  // Main component implementation
  accessibility: ARIAAttributes; // Required ARIA attributes
  responsive: ResponsiveClasses; // Mobile-first responsive classes
  tests: TestCases;          // Component test implementations
}
```

## 🔧 Common Component Patterns

### Form Components
```typescript
// ALWAYS use this pattern for forms:
import { zodResolver } from "@hookform/resolvers/zod"
import { useForm } from "react-hook-form"
import * as z from "zod"
import { Button } from "@/components/ui/button"
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form"
import { Input } from "@/components/ui/input"

// 1. Define schema with Zod
const formSchema = z.object({
  // Define fields with validation
})

// 2. Create form component with proper TypeScript
interface FormComponentProps {
  onSubmit: (values: z.infer<typeof formSchema>) => void;
  className?: string;
}

export function FormComponent({ onSubmit, className }: FormComponentProps) {
  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      // Set defaults
    },
  })

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)} className={cn("space-y-6", className)}>
        {/* Form fields using FormField pattern */}
        <FormField
          control={form.control}
          name="fieldName"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Field Label</FormLabel>
              <FormControl>
                <Input {...field} />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />
        <Button type="submit">Submit</Button>
      </form>
    </Form>
  )
}
```

### Data Display Components
```typescript
// ALWAYS use this pattern for data display:
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"

interface DataDisplayProps {
  data: DataType[];
  className?: string;
  variant?: 'default' | 'compact' | 'detailed';
}

export function DataDisplay({ data, className, variant = 'default' }: DataDisplayProps) {
  return (
    <div className={cn("grid gap-4", className)}>
      {data.map((item) => (
        <Card key={item.id} className="hover:shadow-md transition-shadow">
          <CardHeader>
            <div className="flex items-center gap-4">
              <Avatar>
                <AvatarImage src={item.avatar} alt={`${item.name} avatar`} />
                <AvatarFallback>{item.name.charAt(0)}</AvatarFallback>
              </Avatar>
              <div className="flex-1">
                <CardTitle className="text-lg">{item.title}</CardTitle>
                <CardDescription>{item.description}</CardDescription>
              </div>
              <Badge variant={item.status === 'active' ? 'default' : 'secondary'}>
                {item.status}
              </Badge>
            </div>
          </CardHeader>
          {variant !== 'compact' && (
            <CardContent>
              {/* Additional content based on variant */}
            </CardContent>
          )}
        </Card>
      ))}
    </div>
  )
}
```

### Navigation Components
```typescript
// ALWAYS use this pattern for navigation:
import { NavigationMenu, NavigationMenuContent, NavigationMenuItem, NavigationMenuLink, NavigationMenuList, NavigationMenuTrigger } from "@/components/ui/navigation-menu"
import { Button } from "@/components/ui/button"
import { Sheet, SheetContent, SheetTrigger } from "@/components/ui/sheet"
import { Menu } from "lucide-react"

interface NavigationProps {
  items: NavigationItem[];
  className?: string;
}

export function Navigation({ items, className }: NavigationProps) {
  return (
    <header className={cn("border-b", className)}>
      <div className="container mx-auto px-4">
        <div className="flex h-16 items-center justify-between">
          {/* Desktop Navigation */}
          <NavigationMenu className="hidden md:flex">
            <NavigationMenuList>
              {items.map((item) => (
                <NavigationMenuItem key={item.href}>
                  <NavigationMenuTrigger>{item.title}</NavigationMenuTrigger>
                  <NavigationMenuContent>
                    {/* Submenu content */}
                  </NavigationMenuContent>
                </NavigationMenuItem>
              ))}
            </NavigationMenuList>
          </NavigationMenu>

          {/* Mobile Navigation */}
          <Sheet>
            <SheetTrigger asChild className="md:hidden">
              <Button variant="ghost" size="icon" aria-label="Open menu">
                <Menu className="h-5 w-5" />
              </Button>
            </SheetTrigger>
            <SheetContent side="left">
              {/* Mobile menu content */}
            </SheetContent>
          </Sheet>
        </div>
      </div>
    </header>
  )
}
```

## 🎨 Theme Integration

### Color System Usage
```typescript
// ALWAYS use semantic color tokens:
const THEME_COLORS = {
  primary: 'bg-primary text-primary-foreground hover:bg-primary/90',
  secondary: 'bg-secondary text-secondary-foreground hover:bg-secondary/80',
  destructive: 'bg-destructive text-destructive-foreground hover:bg-destructive/90',
  success: 'bg-green-600 text-white hover:bg-green-700',
  warning: 'bg-yellow-600 text-white hover:bg-yellow-700',
  muted: 'bg-muted text-muted-foreground',
  accent: 'bg-accent text-accent-foreground hover:bg-accent/80',
  card: 'bg-card text-card-foreground border border-border',
  popover: 'bg-popover text-popover-foreground border border-border'
};

// Apply colors semantically:
<Button className="bg-primary text-primary-foreground hover:bg-primary/90">
  Primary Action
</Button>
<Alert className="border-destructive/50 bg-destructive/10 text-destructive">
  Error Message
</Alert>
```

### Responsive Design Patterns
```typescript
// ALWAYS implement mobile-first responsive design:
const RESPONSIVE_PATTERNS = {
  layout: 'grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4',
  text: 'text-sm md:text-base lg:text-lg',
  spacing: 'p-4 md:p-6 lg:p-8',
  hidden: 'hidden md:block', // Hide on mobile, show on desktop
  mobile: 'block md:hidden', // Show on mobile, hide on desktop
  container: 'container mx-auto px-4 md:px-6 lg:px-8'
};

// Example implementation:
<div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-4 p-4 md:p-6">
  {items.map((item) => (
    <Card key={item.id} className="hover:shadow-lg transition-shadow">
      {/* Card content */}
    </Card>
  ))}
</div>
```

## ♿ Accessibility Requirements

### Required ARIA Attributes
```typescript
// ALWAYS include these accessibility features:
const ACCESSIBILITY_PATTERNS = {
  buttons: {
    attributes: ['aria-label', 'aria-describedby'],
    states: ['aria-pressed', 'aria-expanded', 'aria-disabled'],
    examples: `
      <Button aria-label="Save document" aria-describedby="save-help">
        Save
      </Button>
      <div id="save-help" className="sr-only">
        Saves the current document to your account
      </div>
    `
  },
  
  forms: {
    attributes: ['aria-labelledby', 'aria-describedby', 'aria-invalid', 'aria-required'],
    examples: `
      <FormItem>
        <FormLabel id="email-label">Email Address</FormLabel>
        <FormControl>
          <Input 
            aria-labelledby="email-label"
            aria-describedby="email-help"
            aria-required="true"
            aria-invalid={!!errors.email}
          />
        </FormControl>
        <FormDescription id="email-help">
          We'll never share your email with anyone else.
        </FormDescription>
        <FormMessage role="alert" />
      </FormItem>
    `
  },
  
  navigation: {
    attributes: ['aria-label', 'aria-current', 'role'],
    examples: `
      <nav aria-label="Main navigation">
        <NavigationMenuList>
          <NavigationMenuItem>
            <NavigationMenuLink 
              aria-current={isActive ? 'page' : undefined}
              className={cn(isActive && 'bg-accent text-accent-foreground')}
            >
              Home
            </NavigationMenuLink>
          </NavigationMenuItem>
        </NavigationMenuList>
      </nav>
    `
  },
  
  interactive: {
    keyboard: 'Support Tab, Enter, Space, Arrow keys',
    focus: 'Visible focus indicators with focus-visible:ring-2',
    examples: `
      <Button 
        className="focus-visible:ring-2 focus-visible:ring-ring focus-visible:ring-offset-2"
        onKeyDown={(e) => {
          if (e.key === 'Enter' || e.key === ' ') {
            handleClick();
          }
        }}
      >
        Interactive Element
      </Button>
    `
  }
};
```

### Screen Reader Support
```typescript
// ALWAYS include screen reader considerations:
const SCREEN_READER_PATTERNS = {
  announcements: `
    // Use live regions for dynamic content updates
    <div aria-live="polite" aria-atomic="true" className="sr-only">
      {statusMessage}
    </div>
  `,
  
  descriptions: `
    // Provide context for complex interactions
    <Button aria-describedby="delete-help">
      Delete Item
    </Button>
    <div id="delete-help" className="sr-only">
      This action cannot be undone. The item will be permanently removed.
    </div>
  `,
  
  skip_links: `
    // Always include skip navigation
    <a 
      href="#main-content" 
      className="sr-only focus:not-sr-only focus:absolute focus:top-4 focus:left-4 z-50 px-4 py-2 bg-primary text-primary-foreground rounded"
    >
      Skip to main content
    </a>
  `,
  
  headings: `
    // Maintain proper heading hierarchy
    <h1>Page Title</h1>
    <h2>Section Title</h2>
    <h3>Subsection Title</h3>
    // Never skip heading levels
  `
};
```

## 🧪 Testing Requirements

### Component Testing Template
```typescript
// ALWAYS include these tests for every component:
import { render, screen, userEvent } from '@testing-library/react'
import { axe, toHaveNoViolations } from 'jest-axe'
import { ComponentName } from './ComponentName'

expect.extend(toHaveNoViolations)

describe('ComponentName', () => {
  // 1. Rendering Tests
  it('renders without crashing', () => {
    render(<ComponentName />)
    expect(screen.getByRole('...')).toBeInTheDocument()
  })

  // 2. Accessibility Tests
  it('has no accessibility violations', async () => {
    const { container } = render(<ComponentName />)
    const results = await axe(container)
    expect(results).toHaveNoViolations()
  })

  // 3. Keyboard Navigation Tests
  it('supports keyboard navigation', async () => {
    const user = userEvent.setup()
    render(<ComponentName />)
    
    await user.tab()
    expect(screen.getByRole('button')).toHaveFocus()
    
    await user.keyboard('{Enter}')
    // Assert expected behavior
  })

  // 4. Interactive Tests
  it('handles user interactions correctly', async () => {
    const user = userEvent.setup()
    const handleClick = vi.fn()
    
    render(<ComponentName onClick={handleClick} />)
    await user.click(screen.getByRole('button'))
    
    expect(handleClick).toHaveBeenCalledTimes(1)
  })

  // 5. Responsive Tests
  it('adapts to different screen sizes', () => {
    // Test responsive behavior
  })

  // 6. Theme Tests
  it('applies theme correctly', () => {
    render(<ComponentName className="bg-primary" />)
    expect(screen.getByRole('...')).toHaveClass('bg-primary')
  })
})
```

## 🔄 Plate Editor Integration

### Rich Text Editor Components
```typescript
// When creating Plate editor integrations:
import { Plate, PlateProvider } from '@udecode/plate-common'
import { createPlugins } from '@udecode/plate'
import { Button } from "@/components/ui/button"
import { Separator } from "@/components/ui/separator"

interface RichTextEditorProps {
  value?: string;
  onChange?: (value: string) => void;
  placeholder?: string;
  variant?: 'blog' | 'comment' | 'note' | 'chat';
  className?: string;
}

export function RichTextEditor({ 
  value, 
  onChange, 
  placeholder, 
  variant = 'blog',
  className 
}: RichTextEditorProps) {
  const plugins = createPlugins([
    // Configure plugins based on variant
  ])

  return (
    <div className={cn("border rounded-md", className)}>
      <PlateProvider plugins={plugins}>
        {/* Toolbar using shadcn components */}
        <div className="border-b p-2 flex items-center gap-1">
          <Button variant="ghost" size="sm">
            Bold
          </Button>
          <Button variant="ghost" size="sm">
            Italic
          </Button>
          <Separator orientation="vertical" className="mx-1 h-6" />
          <Button variant="ghost" size="sm">
            Link
          </Button>
        </div>
        
        {/* Editor */}
        <Plate
          value={value}
          onChange={onChange}
          placeholder={placeholder}
        />
      </PlateProvider>
    </div>
  )
}
```

## 🚨 Error Handling

### Error Boundary Pattern
```typescript
// ALWAYS wrap components with error boundaries:
import { ErrorBoundary } from 'react-error-boundary'
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert"
import { Button } from "@/components/ui/button"
import { AlertTriangle } from "lucide-react"

function ErrorFallback({ error, resetErrorBoundary }: { error: Error; resetErrorBoundary: () => void }) {
  return (
    <Alert variant="destructive">
      <AlertTriangle className="h-4 w-4" />
      <AlertTitle>Something went wrong</AlertTitle>
      <AlertDescription className="mt-2">
        {error.message}
        <Button 
          variant="outline" 
          size="sm" 
          onClick={resetErrorBoundary}
          className="mt-2"
        >
          Try again
        </Button>
      </AlertDescription>
    </Alert>
  )
}

// Wrap components:
<ErrorBoundary FallbackComponent={ErrorFallback}>
  <YourComponent />
</ErrorBoundary>
```

## 📱 Mobile-First Patterns

### Touch-Friendly Interactions
```typescript
// ALWAYS implement touch-friendly designs:
const MOBILE_PATTERNS = {
  touchTargets: {
    minimum: '44px minimum touch target size',
    implementation: 'min-h-[44px] min-w-[44px] flex items-center justify-center',
    example: `
      <Button className="min-h-[44px] min-w-[44px] touch-manipulation">
        Action
      </Button>
    `
  },
  
  gestures: {
    swipe: 'Implement swipe gestures for mobile navigation',
    pinch: 'Support pinch-to-zoom where appropriate',
    scroll: 'Optimize for touch scrolling with momentum'
  },
  
  viewport: {
    meta: '<meta name="viewport" content="width=device-width, initial-scale=1">',
    responsive: 'Use responsive units (rem, %, vw, vh)',
    breakpoints: 'Mobile-first breakpoint strategy'
  }
};
```

## 🎯 Performance Optimization

### Bundle Size Optimization
```typescript
// ALWAYS optimize for performance:
const PERFORMANCE_PATTERNS = {
  imports: {
    tree_shaking: 'Import only specific components needed',
    example: `
      // ✅ Good - Tree-shakable imports
      import { Button } from "@/components/ui/button"
      import { Card, CardHeader, CardContent } from "@/components/ui/card"
      
      // ❌ Bad - Imports entire library
      import * as UI from "@/components/ui"
    `
  },
  
  lazy_loading: {
    components: 'Use React.lazy for large components',
    example: `
      const HeavyComponent = React.lazy(() => import('./HeavyComponent'))
      
      <Suspense fallback={<div>Loading...</div>}>
        <HeavyComponent />
      </Suspense>
    `
  },
  
  memoization: {
    memo: 'Use React.memo for expensive components',
    callbacks: 'Use useCallback for event handlers',
    example: `
      const ExpensiveComponent = React.memo(({ data }: Props) => {
        const handleClick = useCallback(() => {
          // Handle click
        }, [])
        
        return <div onClick={handleClick}>{data}</div>
      })
    `
  }
};
```

## 🔍 Common Prompts and Responses

### When Asked to Create Forms
**Prompt**: "Create a login form using shadcn"

**Response Pattern**:
1. Analyze requirements (authentication, validation, accessibility)
2. Select components (Form, Input, Label, Button)
3. Implement with Zod validation and React Hook Form
4. Add proper ARIA attributes and keyboard support
5. Include responsive design and error handling
6. Generate comprehensive tests

### When Asked to Create Data Displays
**Prompt**: "Build a user dashboard with shadcn"

**Response Pattern**:
1. Break down into component sections (header, sidebar, main content)
2. Use Card components for data sections
3. Implement responsive grid layout
4. Add proper navigation with keyboard support
5. Include loading and error states
6. Generate accessibility tests

### When Asked to Create Navigation
**Prompt**: "Make a responsive navbar with shadcn"

**Response Pattern**:
1. Design mobile-first with Sheet for mobile menu
2. Use NavigationMenu for desktop
3. Implement proper ARIA navigation attributes
4. Add keyboard navigation support
5. Include active state indicators
6. Test across different screen sizes

## 🎨 Design System Integration

### Component Customization
```typescript
// ALWAYS extend components properly:
import { Button, type ButtonProps } from "@/components/ui/button"
import { cva, type VariantProps } from "class-variance-authority"

const customButtonVariants = cva(
  "inline-flex items-center justify-center rounded-md text-sm font-medium transition-colors",
  {
    variants: {
      variant: {
        gradient: "bg-gradient-to-r from-primary to-primary/80 text-primary-foreground hover:from-primary/90 hover:to-primary/70",
        glass: "bg-white/10 backdrop-blur-sm border border-white/20 text-foreground hover:bg-white/20",
      },
      size: {
        xs: "h-7 px-2 text-xs",
        xl: "h-12 px-8 text-base",
      },
    },
  }
)

interface CustomButtonProps 
  extends ButtonProps, 
  VariantProps<typeof customButtonVariants> {}

export function CustomButton({ 
  className, 
  variant, 
  size, 
  ...props 
}: CustomButtonProps) {
  return (
    <Button
      className={cn(customButtonVariants({ variant, size }), className)}
      {...props}
    />
  )
}
```

## 🛡️ Security Considerations

### Safe Rendering Patterns
```typescript
// ALWAYS sanitize user content:
import DOMPurify from 'dompurify'

// For rich text content
function SafeRichText({ html }: { html: string }) {
  const cleanHTML = DOMPurify.sanitize(html)
  return <div dangerouslySetInnerHTML={{ __html: cleanHTML }} />
}

// For user-generated content
function UserContent({ content }: { content: string }) {
  return <p>{content}</p> // React automatically escapes
}

// For links
function SafeLink({ href, children }: { href: string; children: React.ReactNode }) {
  const isExternal = href.startsWith('http')
  return (
    <a 
      href={href}
      target={isExternal ? '_blank' : undefined}
      rel={isExternal ? 'noopener noreferrer' : undefined}
    >
      {children}
    </a>
  )
}
```

## 📚 Documentation Standards

### Component Documentation Template
```typescript
/**
 * ComponentName - Brief description of what this component does
 * 
 * @example
 * ```tsx
 * <ComponentName 
 *   prop1="value"
 *   prop2={true}
 *   onAction={(data) => console.log(data)}
 * />
 * ```
 * 
 * Features:
 * - ✅ WCAG 2.1 AA compliant
 * - ✅ Keyboard navigation support
 * - ✅ Mobile-responsive design
 * - ✅ Theme integration
 * - ✅ TypeScript strict mode
 * 
 * @param prop1 - Description of prop1
 * @param prop2 - Description of prop2
 * @param onAction - Callback fired when action occurs
 */
interface ComponentNameProps {
  prop1: string;
  prop2?: boolean;
  onAction?: (data: SomeType) => void;
  className?: string;
}

export function ComponentName({ 
  prop1, 
  prop2 = false, 
  onAction,
  className 
}: ComponentNameProps) {
  // Implementation
}
```

---

## 🎯 Success Checklist

Before considering a component complete, verify:

### ✅ Implementation Checklist
- [ ] Uses appropriate shadcn/ui components
- [ ] Includes proper TypeScript interfaces
- [ ] Implements WCAG 2.1 AA accessibility
- [ ] Supports keyboard navigation
- [ ] Includes mobile-responsive design
- [ ] Applies theme tokens consistently
- [ ] Handles error states gracefully
- [ ] Includes loading states where appropriate
- [ ] Has proper ARIA attributes
- [ ] Includes comprehensive tests
- [ ] Follows security best practices
- [ ] Includes proper documentation

### ✅ Quality Gates
- [ ] Passes accessibility audit (axe-core)
- [ ] Passes TypeScript strict compilation
- [ ] Passes visual regression tests
- [ ] Meets performance benchmarks
- [ ] Follows design system guidelines
- [ ] Includes proper error boundaries
- [ ] Has responsive design validation
- [ ] Includes keyboard interaction tests

---

## Repository Placement

**File Location**: `guides/shadcn-ai-playbook.md`

This playbook should be placed in the `guides/` directory and referenced in AI agent configurations to ensure consistent, high-quality component generation.