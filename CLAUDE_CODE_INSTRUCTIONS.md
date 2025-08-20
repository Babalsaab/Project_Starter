# Claude Code Instructions - Professional Development Template Repository

## 🎯 **Project Objective**

Create a comprehensive, production-ready template repository that serves as the ultimate starting point for any web application project. This repository should provide:

1. **Working Demo Application** - Complete Next.js app with authentication, dashboard, and standard pages
2. **Complete PRD System** - All 16 professional PRD templates with generation capabilities
3. **Production Infrastructure** - CI/CD, testing, deployment, and monitoring setup
4. **Developer Experience** - Claude Code integration, documentation, and automation

## 📁 **Source Materials Available**

You have access to a `prd-system/` folder containing:
- **16 Core PRD Templates** (in `templates/core-16/` folder)
- **Specialized PRD Templates** (in `templates/specialized/` folder) - AI/ML, DevOps, GEKB, MCP
- **Design & Tasks Templates** (in `companion-templates/` folder) 
- **Workflow Documentation** (in `workflows/` folder)
- **Example Implementation** (in `examples/` folder)
- **Setup Guides** (in `docs/` folder)

## 🚀 **Implementation Requirements**

### **Phase 1: Repository Structure Creation**

Create the complete repository structure as outlined in `docs/repository-structure.md`. The repository should include:

```
professional-dev-template/
├── src/                     # Working Next.js application
├── prd-system/             # PRD templates and generation
├── docs/                   # Documentation
├── scripts/                # Automation scripts
├── .github/                # CI/CD workflows
├── prisma/                 # Database schema
├── tests/                  # Testing framework
└── config files            # All configuration
```

### **Phase 2: Working Demo Application**

Build a complete **TaskFlow-inspired project management application** with:

**🔐 Authentication System:**
- NextAuth.js with email/password and OAuth providers
- User registration, login, password reset flows
- Role-based access control (Admin, Manager, Member)
- Session management and security

**📊 Dashboard & Core Pages:**
- Modern dashboard with metrics and activity feed
- Projects page with creation, editing, and management
- Tasks page with Kanban board and list views
- Team management with invitations and permissions
- Analytics page with charts and reports
- Settings page with user profile and preferences

**🎨 UI Components:**
- Complete shadcn/ui integration with custom theme
- Responsive design for desktop, tablet, and mobile
- Dark/light mode support
- Accessibility compliance (WCAG 2.1 AA)
- Loading states, error boundaries, and empty states

**🗄️ Database Schema:**
- Prisma ORM with PostgreSQL/SQLite support
- Users, Projects, Tasks, Teams, Comments tables
- Proper relationships and constraints
- Database migrations and seeding scripts

**🔧 API Layer:**
- RESTful API routes for all CRUD operations
- Input validation with Zod
- Error handling and response formatting
- API documentation with OpenAPI/Swagger

### **Phase 3: PRD Generation System**

Implement the PRD generation system based on the templates provided:

**📝 Core PRD Templates Integration:**
- All 16 core PRD templates properly organized in `core-16/` folder
- Specialized PRD templates (AI/ML, DevOps, GEKB, MCP) in `specialized/` folder
- Template variables and customization system
- Cross-PRD dependency mapping
- Validation and consistency checking

**🤖 Generation Scripts:**
```typescript
// Core PRD generation
npm run generate:core-prds --project="My Project" --type="saas"
npm run generate:specialized-prds --features="ai,devops" --project="My Project"
npm run generate:design --prd="frontend" --project="My Project"  
npm run generate:tasks --prd="backend" --project="My Project"
```

**📚 Documentation Generator:**
- Automatic README generation for new projects
- API documentation generation
- Component documentation with Storybook
- Deployment guide generation

### **Phase 4: Development Experience**

**🔧 Claude Code Integration:**
- Complete `.claude/` configuration
- Specialized agents for different development aspects
- Slash commands for common operations
- Workflow documentation and automation

**🧪 Testing Framework:**
- Jest for unit testing with high coverage
- Playwright for end-to-end testing
- Component testing with Testing Library
- Visual regression testing setup

**🚀 CI/CD Pipeline:**
- GitHub Actions for continuous integration
- Automated testing, linting, and type checking
- Preview deployments for pull requests
- Production deployment automation

**📦 Production Ready:**
- Docker configuration for containerization
- Environment management and secrets
- Monitoring and logging setup
- Database backup and recovery procedures

## 🎯 **Technology Stack Requirements**

**Frontend:**
- Next.js 14 with App Router
- TypeScript with strict configuration
- Tailwind CSS with shadcn/ui components
- React Hook Form with Zod validation
- Framer Motion for animations

**Backend:**
- Next.js API routes
- Prisma ORM with PostgreSQL
- NextAuth.js for authentication
- Zod for runtime validation
- Winston for logging

**Development Tools:**
- ESLint and Prettier for code quality
- Husky for git hooks
- lint-staged for pre-commit checks
- Commitizen for conventional commits

**Testing:**
- Jest for unit testing
- Playwright for E2E testing
- Testing Library for component testing
- MSW for API mocking

**Deployment:**
- Vercel for hosting (with alternatives)
- Supabase for production database
- GitHub Actions for CI/CD
- Docker for containerization

## 📋 **Implementation Guidelines**

### **Code Quality Standards:**
- TypeScript strict mode with comprehensive typing
- ESLint rules enforced with zero warnings
- Prettier formatting with consistent style
- 90%+ test coverage for critical paths
- Comprehensive error handling and logging

### **Security Requirements:**
- Input validation on all API endpoints
- SQL injection protection with Prisma
- XSS protection with proper sanitization
- CSRF protection for state-changing operations
- Secure authentication and session management

### **Performance Targets:**
- First Contentful Paint < 1.5s
- Largest Contentful Paint < 2.5s
- Cumulative Layout Shift < 0.1
- First Input Delay < 100ms
- 90+ Lighthouse score

### **Accessibility Standards:**
- WCAG 2.1 AA compliance
- Keyboard navigation support
- Screen reader compatibility
- Proper ARIA labels and roles
- Color contrast ratios

## 🔄 **Development Workflow**

### **Getting Started Flow:**
```bash
# Clone and setup
git clone professional-dev-template my-project
cd my-project
npm install
npm run setup:project --name="My Project"
npm run dev
```

### **PRD Generation Flow:**
```bash
# Generate project PRDs
npm run generate:master-prd
npm run generate:all-prds
npm run generate:implementation-docs
```

### **Feature Development Flow:**
```bash
# Use Claude Code for feature development
claude
> /create-feature "user authentication"
> /implement-api "projects CRUD"
> /add-component "TaskBoard"
```

## 📚 **Documentation Requirements**

Create comprehensive documentation including:

**📖 User Guides:**
- Getting started guide with step-by-step setup
- Feature development workflow
- PRD generation and customization guide
- Deployment and production setup

**🔧 Technical Documentation:**
- API documentation with examples
- Database schema documentation
- Component library documentation
- Architecture decision records

**👥 Team Documentation:**
- Contributing guidelines
- Code review process
- Issue and PR templates
- Team onboarding checklist

## ✅ **Success Criteria**

The repository is successful when:

1. **Quick Start**: New user can clone, setup, and run demo in < 15 minutes
2. **Immediate Value**: Working application with authentication and core features
3. **Professional Quality**: Production-ready code with testing and CI/CD
4. **Comprehensive Coverage**: All 16 PRD templates working with generation
5. **Great DX**: Excellent developer experience with Claude Code integration
6. **Reusable**: Can be used as starting point for any web application project

## 🚨 **Important Implementation Notes**

1. **Use the provided PRD templates exactly** - they contain comprehensive professional requirements
2. **Follow the folder structure** specified in the documentation
3. **Implement real functionality** - not just placeholder components
4. **Ensure everything works** - test all features and workflows
5. **Make it production ready** - include monitoring, error handling, security
6. **Document thoroughly** - include setup guides and usage instructions

## 🎯 **Expected Deliverables**

Upon completion, the repository should contain:

- ✅ Complete working Next.js application with demo data
- ✅ All 16 PRD templates integrated and functional
- ✅ PRD generation scripts and automation
- ✅ Design and tasks template generators
- ✅ Comprehensive testing framework
- ✅ CI/CD pipeline with GitHub Actions
- ✅ Production deployment configuration
- ✅ Complete documentation and guides
- ✅ Claude Code integration and workflows

This repository will serve as the ultimate starting point for any web application project, eliminating the need to build standard functionality from scratch and providing a professional foundation for rapid development.