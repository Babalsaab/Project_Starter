# Component Standards & Design System

## Component Architecture Principles

### Component Hierarchy
1. **Atoms**: Basic building blocks (Button, Input, Icon)
2. **Molecules**: Simple combinations (SearchBar, Card, FormField)
3. **Organisms**: Complex combinations (Header, ProductList, ContactForm)
4. **Templates**: Page-level layouts
5. **Pages**: Specific instances with real content

### Design Token System
Use consistent design tokens across all components:

```css
/* Spacing (8px base unit) */
--spacing-xs: 0.25rem;    /* 4px */
--spacing-sm: 0.5rem;     /* 8px */
--spacing-md: 1rem;       /* 16px */
--spacing-lg: 1.5rem;     /* 24px */
--spacing-xl: 2rem;       /* 32px */
--spacing-2xl: 3rem;      /* 48px */

/* Typography */
--text-xs: 0.75rem;       /* 12px */
--text-sm: 0.875rem;      /* 14px */
--text-base: 1rem;        /* 16px */
--text-lg: 1.125rem;      /* 18px */
--text-xl: 1.25rem;       /* 20px */
--text-2xl: 1.5rem;       /* 24px */

/* Border Radius */
--radius-sm: 0.25rem;     /* 4px */
--radius-md: 0.375rem;    /* 6px */
--radius-lg: 0.5rem;      /* 8px */
--radius-xl: 0.75rem;     /* 12px */
```

## Core Component Standards

### Button Component
```typescript
interface ButtonProps {
  variant: 'primary' | 'secondary' | 'outline' | 'ghost' | 'destructive';
  size: 'sm' | 'md' | 'lg';
  disabled?: boolean;
  loading?: boolean;
  leftIcon?: ReactNode;
  rightIcon?: ReactNode;
  fullWidth?: boolean;
  children: ReactNode;
  onClick?: () => void;
}
```

**Visual Requirements:**
- Height: sm(32px), md(40px), lg(48px)
- Horizontal padding: sm(12px), md(16px), lg(20px)
- Border radius: 6px for all sizes
- Transition: all properties 150ms ease
- Focus ring: 2px offset with brand color
- Loading state: spinner with original text hidden
- Disabled state: 50% opacity, no pointer events

**Accessibility:**
- Proper ARIA labels and descriptions
- Keyboard navigation support
- Screen reader announcements for state changes
- Sufficient color contrast (4.5:1 minimum)

### Input Component
```typescript
interface InputProps {
  type: 'text' | 'email' | 'password' | 'number' | 'tel' | 'url';
  placeholder?: string;
  label?: string;
  helperText?: string;
  error?: string;
  disabled?: boolean;
  required?: boolean;
  leftIcon?: ReactNode;
  rightIcon?: ReactNode;
  value: string;
  onChange: (value: string) => void;
}
```

**Visual Requirements:**
- Height: 40px consistent
- Padding: 12px horizontal, 8px vertical
- Border: 1px solid with rounded corners (6px)
- Focus state: brand color border with subtle shadow
- Error state: red border and error message
- Disabled state: gray background, reduced opacity

### Card Component
```typescript
interface CardProps {
  variant: 'elevated' | 'outlined' | 'filled';
  padding: 'sm' | 'md' | 'lg';
  interactive?: boolean;
  children: ReactNode;
  onClick?: () => void;
}
```

**Visual Requirements:**
- Border radius: 8px
- Elevated: box-shadow with subtle elevation
- Outlined: 1px border, no shadow
- Filled: background color, no border/shadow
- Interactive: hover state with transform/shadow
- Padding: sm(16px), md(24px), lg(32px)

### Modal Component
```typescript
interface ModalProps {
  isOpen: boolean;
  onClose: () => void;
  title?: string;
  size: 'sm' | 'md' | 'lg' | 'xl';
  children: ReactNode;
  closeOnBackdrop?: boolean;
  closeOnEscape?: boolean;
}
```

**Visual Requirements:**
- Backdrop: semi-transparent black with blur effect
- Animation: fade in/out with scale transform
- Z-index: 50 (higher than navigation)
- Max width: sm(400px), md(500px), lg(600px), xl(800px)
- Close button: top-right corner with proper focus
- Scroll behavior: lock body scroll when open

## Form Components

### FormField Wrapper
```typescript
interface FormFieldProps {
  label?: string;
  required?: boolean;
  error?: string;
  helperText?: string;
  children: ReactNode;
}
```

### Select/Dropdown
```typescript
interface SelectProps {
  options: Array<{ value: string; label: string; disabled?: boolean }>;
  value: string;
  onChange: (value: string) => void;
  placeholder?: string;
  disabled?: boolean;
  multiple?: boolean;
  searchable?: boolean;
}
```

### Checkbox & Radio
```typescript
interface CheckboxProps {
  checked: boolean;
  onChange: (checked: boolean) => void;
  label?: string;
  disabled?: boolean;
  indeterminate?: boolean;
}
```

## Navigation Components

### Header/Navigation
```typescript
interface NavigationProps {
  logo?: ReactNode;
  menuItems: Array<{
    label: string;
    href: string;
    active?: boolean;
    children?: Array<NavigationItem>;
  }>;
  user?: UserInfo;
  onLogout?: () => void;
}
```

**Visual Requirements:**
- Height: 64px desktop, 56px mobile
- Sticky positioning with backdrop blur
- Responsive collapse on mobile
- Dropdown menus with proper positioning
- Active state indication
- Logo/brand positioning on left

### Breadcrumb
```typescript
interface BreadcrumbProps {
  items: Array<{
    label: string;
    href?: string;
    current?: boolean;
  }>;
  separator?: ReactNode;
}
```

### Pagination
```typescript
interface PaginationProps {
  currentPage: number;
  totalPages: number;
  onPageChange: (page: number) => void;
  showFirstLast?: boolean;
  showPrevNext?: boolean;
  siblingCount?: number;
}
```

## Data Display Components

### Table
```typescript
interface TableProps {
  columns: Array<{
    key: string;
    label: string;
    sortable?: boolean;
    width?: string;
    align?: 'left' | 'center' | 'right';
  }>;
  data: Array<Record<string, any>>;
  sortBy?: string;
  sortDirection?: 'asc' | 'desc';
  onSort?: (key: string) => void;
  loading?: boolean;
  emptyMessage?: string;
}
```

### List/Grid
```typescript
interface ListProps {
  items: Array<any>;
  renderItem: (item: any, index: number) => ReactNode;
  loading?: boolean;
  emptyMessage?: string;
  variant: 'list' | 'grid';
  gridCols?: 1 | 2 | 3 | 4 | 6;
}
```

## Feedback Components

### Alert/Toast
```typescript
interface AlertProps {
  type: 'success' | 'warning' | 'error' | 'info';
  title?: string;
  message: string;
  dismissible?: boolean;
  onDismiss?: () => void;
  action?: {
    label: string;
    onClick: () => void;
  };
}
```

### Loading States
```typescript
interface LoadingProps {
  variant: 'spinner' | 'skeleton' | 'pulse';
  size?: 'sm' | 'md' | 'lg';
  text?: string;
}
```

### Empty States
```typescript
interface EmptyStateProps {
  icon?: ReactNode;
  title: string;
  description?: string;
  action?: {
    label: string;
    onClick: () => void;
  };
}
```

## Layout Components

### Container
```typescript
interface ContainerProps {
  size: 'sm' | 'md' | 'lg' | 'xl' | 'full';
  padding?: boolean;
  center?: boolean;
  children: ReactNode;
}
```

### Grid System
```typescript
interface GridProps {
  cols: 1 | 2 | 3 | 4 | 6 | 12;
  gap: 'sm' | 'md' | 'lg';
  responsive?: {
    sm?: number;
    md?: number;
    lg?: number;
    xl?: number;
  };
  children: ReactNode;
}
```

### Stack/Flex
```typescript
interface StackProps {
  direction: 'row' | 'column';
  gap: 'xs' | 'sm' | 'md' | 'lg' | 'xl';
  align?: 'start' | 'center' | 'end' | 'stretch';
  justify?: 'start' | 'center' | 'end' | 'between' | 'around';
  wrap?: boolean;
  children: ReactNode;
}
```

## Animation Standards

### Transition Durations
- **Micro-interactions**: 150ms (button hover, input focus)
- **Component changes**: 300ms (modal open, dropdown expand)
- **Page transitions**: 500ms (route changes, large animations)

### Easing Functions
```css
--ease-in: cubic-bezier(0.4, 0, 1, 1);
--ease-out: cubic-bezier(0, 0, 0.2, 1);
--ease-in-out: cubic-bezier(0.4, 0, 0.2, 1);
--ease-bounce: cubic-bezier(0.68, -0.55, 0.265, 1.55);
```

### Animation Patterns
- **Entrance**: Fade + scale from 0.95 to 1
- **Exit**: Fade + scale from 1 to 0.95
- **Hover**: Scale to 1.02-1.05 with shadow increase
- **Loading**: Pulse or rotate animations
- **Success**: Brief scale bounce (1 → 1.1 → 1)

## Responsive Design Standards

### Breakpoint Strategy
```css
/* Mobile first approach */
.component {
  /* Mobile styles (default) */
}

@media (min-width: 640px) {
  /* Tablet styles */
}

@media (min-width: 1024px) {
  /* Desktop styles */
}
```

### Component Responsiveness
- **Typography**: Scale down on mobile (use clamp() for fluid scaling)
- **Spacing**: Reduce padding/margins on smaller screens
- **Layout**: Stack vertically on mobile, horizontal on desktop
- **Touch targets**: Minimum 44px for interactive elements on mobile

## Accessibility Implementation

### Required Attributes
```typescript
// Every interactive component should include:
interface AccessibleComponentProps {
  id?: string;
  'aria-label'?: string;
  'aria-labelledby'?: string;
  'aria-describedby'?: string;
  role?: string;
  tabIndex?: number;
}
```

### Focus Management
- Visible focus indicators (2px outline with brand color)
- Logical tab order
- Skip links for navigation
- Focus trapping in modals
- Focus restoration after modal close

### Screen Reader Support
- Semantic HTML elements
- ARIA labels and descriptions
- Live regions for dynamic content
- Alternative text for images
- Form label associations

## Testing Requirements

### Visual Testing
```typescript
// Component should be tested with:
describe('ComponentName', () => {
  it('renders all variants correctly', () => {
    // Test different props combinations
  });
  
  it('handles responsive breakpoints', () => {
    // Test mobile, tablet, desktop layouts
  });
  
  it('shows correct interactive states', () => {
    // Test hover, focus, active, disabled states
  });
});
```

### Accessibility Testing
- Automated testing with jest-axe
- Keyboard navigation testing
- Screen reader compatibility
- Color contrast validation
- ARIA attribute verification

## Performance Considerations

### Optimization Strategies
- Lazy load heavy components
- Memoize expensive calculations
- Use CSS transforms for animations
- Optimize image assets
- Bundle splitting for large component libraries

### Monitoring
- Track component render times
- Monitor bundle size impact
- Measure interactive metrics
- Test on various devices/connections

---

*This document serves as the definitive guide for component implementation. All components should follow these standards unless explicitly documented otherwise.*