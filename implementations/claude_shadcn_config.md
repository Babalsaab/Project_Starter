# Claude Code Configuration for Shadcn/UI Development

*Optimized configuration for AI-assisted shadcn/ui component development*

## Project Context

This is a **modern React application** using **shadcn/ui components** with a focus on:
- Accessibility-first design (WCAG 2.1 AA compliance)
- Type-safe development with TypeScript
- Mobile-first responsive design
- AI-assisted component generation

## Component Library Stack

### Core Technologies
```yaml
ui_framework: "shadcn/ui + Radix UI primitives"
styling: "Tailwind CSS with CSS variables for theming"
rich_text: "Plate editor for advanced text editing"
validation: "Zod schemas with React Hook Form"
testing: "Vitest + Testing Library + jest-axe"
typescript: "Strict mode with comprehensive type coverage"
```

### Installed shadcn/ui Components
```bash
# Core components (update this list as you add components)
npx shadcn-ui@latest add button
npx shadcn-ui@latest add input
npx shadcn-ui@latest add form
npx shadcn-ui@latest add card
npx shadcn-ui@latest add dialog
npx shadcn-ui@latest add alert
npx shadcn-ui@latest add badge
npx shadcn-ui@latest add avatar
npx shadcn-ui@latest add table
npx shadcn-ui@latest add select
npx shadcn-ui@latest add checkbox
npx shadcn-ui@latest add radio-group
npx shadcn-ui@latest add toast
npx shadcn-ui@latest add navigation-menu
npx shadcn-ui@latest add breadcrumb
npx shadcn-ui@latest add tabs
npx shadcn-ui@latest add sheet
npx shadcn-ui@latest add dropdown-menu
npx shadcn-ui@latest add command
npx shadcn-ui@latest add separator
npx shadcn-ui@latest add scroll-area
```

## Development Guidelines

### 🎯 Component Development Rules

1. **Always prefer shadcn/ui components** over custom implementations
2. **Use TypeScript strictly** - no `any` types, comprehensive interfaces
3. **Implement accessibility first** - WCAG 2.1 AA compliance is mandatory
4. **Mobile-first responsive design** - design for 375px up
5. **Include tests** - every component needs interaction and accessibility tests
6. **Follow semantic HTML** - use proper elements and ARIA attributes

### 📁 File Structure
```
src/
├── components/
│   ├── ui/                 # shadcn/ui components
│   └── custom/             # Project-specific components
├── lib/
│   ├── utils.ts           # cn() utility and helpers
│   ├── validations.ts     # Zod schemas
│   └── types.ts           # TypeScript interfaces
├── hooks/                 # Custom React hooks
├── styles/
│   └── globals.css        # Global styles and CSS variables
└── __tests__/             # Test files
```

### 🎨 Theming Configuration

#### CSS Variables (in globals.css)
```css
@layer base {
  :root {
    --background: 0 0% 100%;
    --foreground: 222.2 84% 4.9%;
    --card: 0 0% 100%;
    --card-foreground: 222.2 84% 4.9%;
    --popover: 0 0% 100%;
    --popover-foreground: 222.2 84% 4.9%;
    --primary: 222.2 47.4% 11.2%;
    --primary-foreground: 210 40% 98%;
    --secondary: 210 40% 96%;
    --secondary-foreground: 222.2 47.4% 11.2%;
    --muted: 210 40% 96%;
    --muted-foreground: 215.4 16.3% 46.9%;
    --accent: 210 40% 96%;
    --accent-foreground: 222.2 47.4% 11.2%;
    --destructive: 0 84.2% 60.2%;
    --destructive-foreground: 210 40% 98%;
    --border: 214.3 31.8% 91.4%;
    --input: 214.3 31.8% 91.4%;
    --ring: 222.2 84% 4.9%;
    --radius: 0.5rem;
  }

  .dark {
    --background: 222.2 84% 4.9%;
    --foreground: 210 40% 98%;
    --card: 222.2 84% 4.9%;
    --card-foreground: 210 40% 98%;
    --popover: 222.2 84% 4.9%;
    --popover-foreground: 210 40% 98%;
    --primary: 210 40% 98%;
    --primary-foreground: 222.2 47.4% 11.2%;
    --secondary: 217.2 32.6% 17.5%;
    --secondary-foreground: 210 40% 98%;
    --muted: 217.2 32.6% 17.5%;
    --muted-foreground: 215 20.2% 65.1%;
    --accent: 217.2 32.6% 17.5%;
    --accent-foreground: 210 40% 98%;
    --destructive: 0 62.8% 30.6%;
    --destructive-foreground: 210 40% 98%;
    --border: 217.2 32.6% 17.5%;
    --input: 217.2 32.6% 17.5%;
    --ring: 212.7 26.8% 83.9%;
  }
}
```

#### Responsive Breakpoints
```javascript
// tailwind.config.js breakpoints
screens: {
  'xs': '375px',   // Mobile
  'sm': '640px',   // Small tablet
  'md': '768px',   // Tablet
  'lg': '1024px',  // Desktop
  'xl': '1280px',  // Large desktop
  '2xl': '1536px', // Extra large
}
```

## Component Patterns

### 🔧 Standard Form Pattern
```typescript
import { zodResolver } from "@hookform/resolvers/zod"
import { useForm } from "react-hook-form"
import * as z from "zod"
import { Button } from "@/components/ui/button"
import { Form, FormControl, FormField, FormItem, FormLabel, FormMessage } from "@/components/ui/form"
import { Input } from "@/components/ui/input"

const formSchema = z.object({
  email: z.string().email("Please enter a valid email address"),
  password: z.string().min(8, "Password must be at least 8 characters"),
})

interface LoginFormProps {
  onSubmit: (values: z.infer<typeof formSchema>) => Promise<void>;
  className?: string;
}

export function LoginForm({ onSubmit, className }: LoginFormProps) {
  const form = useForm<z.infer<typeof formSchema>>({
    resolver: zodResolver(formSchema),
    defaultValues: {
      email: "",
      password: "",
    },
  })

  return (
    <Form {...form}>
      <form onSubmit={form.handleSubmit(onSubmit)} className={cn("space-y-6", className)}>
        <FormField
          control={form.control}
          name="email"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Email</FormLabel>
              <FormControl>
                <Input 
                  type="email"
                  placeholder="Enter your email"
                  {...field} 
                />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />
        <FormField
          control={form.control}
          name="password"
          render={({ field }) => (
            <FormItem>
              <FormLabel>Password</FormLabel>
              <FormControl>
                <Input 
                  type="password"
                  placeholder="Enter your password"
                  {...field} 
                />
              </FormControl>
              <FormMessage />
            </FormItem>
          )}
        />
        <Button type="submit" className="w-full">
          Sign In
        </Button>
      </form>
    </Form>
  )
}
```

### 📊 Data Display Pattern
```typescript
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"

interface UserCardProps {
  user: {
    id: string;
    name: string;
    email: string;
    avatar?: string;
    role: string;
    status: 'active' | 'inactive';
  };
  className?: string;
}

export function UserCard({ user, className }: UserCardProps) {
  return (
    <Card className={cn("hover:shadow-md transition-shadow", className)}>
      <CardHeader>
        <div className="flex items-center gap-4">
          <Avatar>
            <AvatarImage src={user.avatar} alt={`${user.name} avatar`} />
            <AvatarFallback>{user.name.substring(0, 2).toUpperCase()}</AvatarFallback>
          </Avatar>
          <div className="flex-1">
            <CardTitle className="text-lg">{user.name}</CardTitle>
            <CardDescription>{user.email}</CardDescription>
          </div>
          <Badge variant={user.status === 'active' ? 'default' : 'secondary'}>
            {user.status}
          </Badge>
        </div>
      </CardHeader>
      <CardContent>
        <p className="text-sm text-muted-foreground">Role: {user.role}</p>
      </CardContent>
    </Card>
  )
}
```

### 🧭 Navigation Pattern
```typescript
import { NavigationMenu, NavigationMenuContent, NavigationMenuItem, NavigationMenuLink, NavigationMenuList, NavigationMenuTrigger } from "@/components/ui/navigation-menu"
import { Button } from "@/components/ui/button"
import { Sheet, SheetContent, SheetTrigger } from "@/components/ui/sheet"
import { Menu } from "lucide-react"

interface NavigationProps {
  items: Array<{
    title: string;
    href: string;
    description?: string;
    children?: Array<{ title: string; href: string; description?: string }>;
  }>;
}

export function Navigation({ items }: NavigationProps) {
  return (
    <header className="sticky top-0 z-50 w-full border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
      <div className="container flex h-14 items-center">
        <div className="mr-4 hidden md:flex">
          <NavigationMenu>
            <NavigationMenuList>
              {items.map((item) => (
                <NavigationMenuItem key={item.href}>
                  {item.children ? (
                    <>
                      <NavigationMenuTrigger>{item.title}</NavigationMenuTrigger>
                      <NavigationMenuContent>
                        <ul className="grid gap-3 p-6 md:w-[400px] lg:w-[500px] lg:grid-cols-[.75fr_1fr]">
                          {item.children.map((child) => (
                            <li key={child.href}>
                              <NavigationMenuLink asChild>
                                <a
                                  className="block select-none space-y-1 rounded-md p-3 leading-none no-underline outline-none transition-colors hover:bg-accent hover:text-accent-foreground focus:bg-accent focus:text-accent-foreground"
                                  href={child.href}
                                >
                                  <div className="text-sm font-medium leading-none">{child.title}</div>
                                  {child.description && (
                                    <p className="line-clamp-2 text-sm leading-snug text-muted-foreground">
                                      {child.description}
                                    </p>
                                  )}
                                </a>
                              </NavigationMenuLink>
                            </li>
                          ))}
                        </ul>
                      </NavigationMenuContent>
                    </>
                  ) : (
                    <NavigationMenuLink href={item.href}>
                      {item.title}
                    </NavigationMenuLink>
                  )}
                </NavigationMenuItem>
              ))}
            </NavigationMenuList>
          </NavigationMenu>
        </div>

        {/* Mobile Navigation */}
        <Sheet>
          <SheetTrigger asChild>
            <Button variant="ghost" className="mr-2 px-0 text-base hover:bg-transparent focus-visible:bg-transparent focus-visible:ring-0 focus-visible:ring-offset-0 md:hidden">
              <Menu className="h-5 w-5" />
              <span className="sr-only">Toggle Menu</span>
            </Button>
          </SheetTrigger>
          <SheetContent side="left" className="pr-0">
            <nav className="flex flex-col space-y-3">
              {items.map((item) => (
                <a
                  key={item.href}
                  href={item.href}
                  className="block px-2 py-1 text-lg"
                >
                  {item.title}
                </a>
              ))}
            </nav>
          </SheetContent>
        </Sheet>
      </div>
    </header>
  )
}
```

## Accessibility Requirements

### ♿ WCAG 2.1 AA Compliance Checklist

Every component must include:
- [ ] **Semantic HTML** - Use proper HTML elements
- [ ] **ARIA attributes** - Add aria-label, aria-describedby where needed
- [ ] **Keyboard navigation** - Full functionality with keyboard only
- [ ] **Focus management** - Visible focus indicators
- [ ] **Color contrast** - 4.5:1 for normal text, 3:1 for large text
- [ ] **Screen reader support** - Test with NVDA/VoiceOver
- [ ] **Error handling** - Clear error messages with aria-live
- [ ] **Skip links** - For main navigation

### Required ARIA Patterns
```typescript
// Form accessibility
<FormItem>
  <FormLabel id="email-label">Email Address</FormLabel>
  <FormControl>
    <Input 
      aria-labelledby="email-label"
      aria-describedby="email-help email-error"
      aria-required="true"
      aria-invalid={!!errors.email}
    />
  </FormControl>
  <FormDescription id="email-help">
    We'll use this email to send you updates
  </FormDescription>
  <FormMessage id="email-error" role="alert" />
</FormItem>

// Button accessibility
<Button aria-label="Save document" aria-describedby="save-help">
  Save
</Button>
<div id="save-help" className="sr-only">
  Saves the current document to your account
</div>

// Navigation accessibility
<nav aria-label="Main navigation">
  <NavigationMenuList>
    <NavigationMenuItem>
      <NavigationMenuLink 
        aria-current={isCurrentPage ? 'page' : undefined}
      >
        Home
      </NavigationMenuLink>
    </NavigationMenuItem>
  </NavigationMenuList>
</nav>
```

## Testing Standards

### 🧪 Required Tests

Every component needs:
1. **Rendering test** - Component renders without crashing
2. **Accessibility test** - No axe violations
3. **Keyboard test** - Keyboard navigation works
4. **Interaction test** - User interactions work correctly
5. **Responsive test** - Component adapts to screen sizes

### Test Template
```typescript
import { render, screen, userEvent } from '@testing-library/react'
import { axe, toHaveNoViolations } from 'jest-axe'
import { LoginForm } from './LoginForm'

expect.extend(toHaveNoViolations)

describe('LoginForm', () => {
  const mockSubmit = vi.fn()

  beforeEach(() => {
    mockSubmit.mockClear()
  })

  it('renders login form', () => {
    render(<LoginForm onSubmit={mockSubmit} />)
    
    expect(screen.getByLabelText(/email/i)).toBeInTheDocument()
    expect(screen.getByLabelText(/password/i)).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /sign in/i })).toBeInTheDocument()
  })

  it('has no accessibility violations', async () => {
    const { container } = render(<LoginForm onSubmit={mockSubmit} />)
    const results = await axe(container)
    expect(results).toHaveNoViolations()
  })

  it('supports keyboard navigation', async () => {
    const user = userEvent.setup()
    render(<LoginForm onSubmit={mockSubmit} />)

    // Tab through form elements
    await user.tab()
    expect(screen.getByLabelText(/email/i)).toHaveFocus()

    await user.tab()
    expect(screen.getByLabelText(/password/i)).toHaveFocus()

    await user.tab()
    expect(screen.getByRole('button', { name: /sign in/i })).toHaveFocus()
  })

  it('validates form input', async () => {
    const user = userEvent.setup()
    render(<LoginForm onSubmit={mockSubmit} />)

    // Submit empty form
    await user.click(screen.getByRole('button', { name: /sign in/i }))

    expect(await screen.findByText(/please enter a valid email/i)).toBeInTheDocument()
    expect(await screen.findByText(/password must be at least 8 characters/i)).toBeInTheDocument()
    expect(mockSubmit).not.toHaveBeenCalled()
  })

  it('submits valid form data', async () => {
    const user = userEvent.setup()
    render(<LoginForm onSubmit={mockSubmit} />)

    await user.type(screen.getByLabelText(/email/i), 'test@example.com')
    await user.type(screen.getByLabelText(/password/i), 'password123')
    await user.click(screen.getByRole('button', { name: /sign in/i }))

    expect(mockSubmit).toHaveBeenCalledWith({
      email: 'test@example.com',
      password: 'password123',
    })
  })
})
```

## Plate Editor Integration

### 📝 Rich Text Editor Setup

When creating rich text components, use these configurations:

```typescript
import { Plate, PlateProvider } from '@udecode/plate-common'
import { createPlugins } from '@udecode/plate'
import { Button } from "@/components/ui/button"
import { Separator } from "@/components/ui/separator"
import { ToggleGroup, ToggleGroupItem } from "@/components/ui/toggle-group"

// Editor configurations for different use cases
export const EDITOR_CONFIGS = {
  blog: {
    plugins: ['paragraph', 'heading', 'list', 'link', 'image', 'blockquote', 'code'],
    toolbar: 'full',
    features: ['markdown-shortcuts', 'slash-commands', 'drag-drop']
  },
  comment: {
    plugins: ['paragraph', 'mention', 'link', 'emoji'],
    toolbar: 'minimal',
    features: ['mentions', 'emoji-picker', 'auto-save']
  },
  note: {
    plugins: ['paragraph', 'heading', 'list', 'table', 'code', 'math'],
    toolbar: 'structured',
    features: ['table-editing', 'syntax-highlighting', 'math-formulas']
  }
}

interface RichTextEditorProps {
  value?: string;
  onChange?: (value: string) => void;
  config?: keyof typeof EDITOR_CONFIGS;
  placeholder?: string;
  className?: string;
}

export function RichTextEditor({ 
  value, 
  onChange, 
  config = 'blog',
  placeholder = "Start typing...",
  className 
}: RichTextEditorProps) {
  const editorConfig = EDITOR_CONFIGS[config]
  const plugins = createPlugins(editorConfig.plugins)

  return (
    <div className={cn("border rounded-md focus-within:ring-2 focus-within:ring-ring", className)}>
      <PlateProvider plugins={plugins}>
        {/* Toolbar using shadcn components */}
        <div className="border-b p-2 flex items-center gap-1">
          <ToggleGroup type="multiple" size="sm">
            <ToggleGroupItem value="bold" aria-label="Bold">
              <strong>B</strong>
            </ToggleGroupItem>
            <ToggleGroupItem value="italic" aria-label="Italic">
              <em>I</em>
            </ToggleGroupItem>
            <ToggleGroupItem value="underline" aria-label="Underline">
              <u>U</u>
            </ToggleGroupItem>
          </ToggleGroup>
          <Separator orientation="vertical" className="mx-1 h-6" />
          <Button variant="ghost" size="sm">
            Link
          </Button>
          <Button variant="ghost" size="sm">
            Image
          </Button>
        </div>
        
        {/* Editor */}
        <Plate
          value={value}
          onChange={onChange}
          placeholder={placeholder}
          className="min-h-[200px] p-4"
        />
      </PlateProvider>
    </div>
  )
}
```

## AI Agent Commands

### 🤖 Quick Commands

Use these commands for rapid development:

- **"Generate a {component} form using shadcn"** - Creates form with validation
- **"Create a responsive {layout} with shadcn"** - Builds layout components  
- **"Add Plate editor for {use case}"** - Integrates rich text editing
- **"Make this component accessible"** - Adds ARIA attributes and keyboard support
- **"Test this component"** - Generates comprehensive test suite
- **"Optimize for mobile"** - Improves responsive design

### Component Generation Commands

```bash
# Generate form components
"Create a contact form with name, email, message fields using shadcn and Zod validation"

# Generate data display
"Build a user dashboard with cards showing stats, recent activity, and user profile"

# Generate navigation
"Make a responsive header with logo, navigation menu, and mobile hamburger menu"

# Generate complex layouts
"Create a admin panel layout with sidebar navigation, header, and main content area"

# Add rich text editing
"Add a blog post editor with Plate using heading, paragraph, list, and link plugins"
```

## Performance Guidelines

### 📊 Optimization Rules

1. **Bundle size** - Keep component imports specific
2. **Rendering** - Use React.memo for expensive components
3. **Images** - Use next/image for optimized loading
4. **Fonts** - Preload critical fonts
5. **CSS** - Purge unused Tailwind classes

```typescript
// ✅ Good - Specific imports
import { Button } from "@/components/ui/button"
import { Card, CardHeader, CardContent } from "@/components/ui/card"

// ❌ Bad - Barrel imports
import * as UI from "@/components/ui"

// ✅ Good - Memoized expensive components
const ExpensiveUserList = React.memo(({ users }: { users: User[] }) => {
  return (
    <div className="space-y-4">
      {users.map(user => <UserCard key={user.id} user={user} />)}
    </div>
  )
})

// ✅ Good - Optimized image loading
import Image from 'next/image'

<Image
  src="/avatar.jpg"
  alt="User avatar"
  width={64}
  height={64}
  className="rounded-full"
  priority={isAboveFold}
/>
```

## MCP Server Integration

### 🔗 shadcn/ui MCP Server

Configure the MCP server for component access:

```json
{
  "mcpServers": {
    "shadcn-ui-server": {
      "command": "npx",
      "args": [
        "@jpisnice/shadcn-ui-mcp-server",
        "--framework", "react",
        "--github-api-key", "${GITHUB_TOKEN}"
      ],
      "env": {
        "GITHUB_TOKEN": "your_github_token_here"
      }
    }
  }
}
```

### Available MCP Commands

- `get_component` - Retrieve component source code
- `get_component_demo` - Get usage examples
- `list_components` - Show available components
- `install_component` - Add component to project

## Error Handling

### 🚨 Error Boundaries

Always wrap components in error boundaries:

```typescript
import { ErrorBoundary } from 'react-error-boundary'
import { Alert, AlertDescription, AlertTitle } from "@/components/ui/alert"
import { Button } from "@/components/ui/button"
import { AlertTriangle, RotateCcw } from "lucide-react"

function ErrorFallback({ 
  error, 
  resetErrorBoundary 
}: { 
  error: Error; 
  resetErrorBoundary: () => void 
}) {
  return (
    <Alert variant="destructive" className="max-w-lg">
      <AlertTriangle className="h-4 w-4" />
      <AlertTitle>Something went wrong</AlertTitle>
      <AlertDescription className="mt-2">
        <p className="mb-3">{error.message}</p>
        <Button 
          variant="outline" 
          size="sm" 
          onClick={resetErrorBoundary}
          className="h-8 px-3"
        >
          <RotateCcw className="mr-2 h-3 w-3" />
          Try again
        </Button>
      </AlertDescription>
    </Alert>
  )
}

// Usage
<ErrorBoundary 
  FallbackComponent={ErrorFallback}
  onError={(error, errorInfo) => {
    console.error('Component error:', error, errorInfo)
  }}
>
  <YourComponent />
</ErrorBoundary>
```

## Git Workflow

### 📝 Commit Standards

Use conventional commits for component changes:

```bash
feat(ui): add user profile card component
fix(form): improve validation error display
docs(button): update usage examples
test(dialog): add accessibility tests
style(card): improve responsive spacing
refactor(nav): simplify mobile menu logic
```

### Pre-commit Hooks

Ensure quality with automated checks:

```bash
# .husky/pre-commit
#!/usr/bin/env sh
. "$(dirname -- "$0")/_/husky.sh"

npm run lint
npm run type-check
npm run test:a11y
npm run build
```

---

## Repository Placement

**File Location**: `CLAUDE_SHADCN.md` (project root)

This configuration file should be placed in the root directory of your project and referenced by Claude Code for optimal shadcn/ui development assistance.