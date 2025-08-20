#!/usr/bin/env tsx

import fs from 'fs/promises';
import path from 'path';
import { program } from 'commander';

interface ProjectConfig {
  name: string;
  type: string;
  description?: string;
  features?: string[];
}

const CORE_TEMPLATES = [
  'master-prd-template.md',
  'frontend_prd_template.md',
  'backend_prd_complete.md',
  'database_prd_complete.md',
  'security_prd_complete.md',
  'api_documentation_prd_template.md',
  'complete_uiux_prd.md',
  'performance_prd_template.md',
  'qa_testing_engineering_prd.md',
  'analytics_prd_template.md',
  'content_prd_template.md',
  'mobile_prd_template.md',
  'accessibility-prd-template.md',
  'error_handling_prd_template.md',
  'integration_prd_template.md',
  'infrastructure_prd_template.md'
];

const SPECIALIZED_TEMPLATES = [
  'ai_ml_integration_agent_prd.md',
  'devops_infrastructure_agent_prd.md',
  'shadcn_agent_prd.md',
  'testing_qa_agent_prd.md'
];

async function generateAllPRDs(config: ProjectConfig) {
  console.log(`🚀 Generating complete PRD suite for: ${config.name}`);
  console.log(`📋 Project Type: ${config.type}`);
  
  const startTime = Date.now();
  const outputDir = path.join(process.cwd(), 'generated-prds', config.name.toLowerCase().replace(/\s+/g, '-'));
  
  try {
    // Create output directory structure
    await fs.mkdir(outputDir, { recursive: true });
    await fs.mkdir(path.join(outputDir, 'core'), { recursive: true });
    await fs.mkdir(path.join(outputDir, 'specialized'), { recursive: true });
    await fs.mkdir(path.join(outputDir, 'companion'), { recursive: true });
    
    const results = {
      generated: [] as string[],
      failed: [] as string[],
      total: 0
    };
    
    // Generate core PRDs
    console.log('\n📚 Generating Core PRDs...');
    for (const templateFile of CORE_TEMPLATES) {
      try {
        const outputFile = await generateFromTemplate(
          path.join('prd-system/templates/core-16', templateFile),
          path.join(outputDir, 'core', templateFile.replace('_template', '').replace('_complete', '')),
          config
        );
        results.generated.push(outputFile);
        console.log(`  ✅ ${templateFile}`);
      } catch (error) {
        results.failed.push(templateFile);
        console.log(`  ❌ ${templateFile}: ${error}`);
      }
    }
    
    // Generate specialized PRDs
    console.log('\n🔧 Generating Specialized PRDs...');
    for (const templateFile of SPECIALIZED_TEMPLATES) {
      try {
        const outputFile = await generateFromTemplate(
          path.join('prd-system/templates/specialized', templateFile),
          path.join(outputDir, 'specialized', templateFile),
          config
        );
        results.generated.push(outputFile);
        console.log(`  ✅ ${templateFile}`);
      } catch (error) {
        results.failed.push(templateFile);
        console.log(`  ❌ ${templateFile}: ${error}`);
      }
    }
    
    // Generate companion documents
    console.log('\n📋 Generating Companion Documents...');
    try {
      await generateDesignDocument(outputDir, config);
      await generateTasksDocument(outputDir, config);
      console.log(`  ✅ design.md`);
      console.log(`  ✅ tasks.md`);
    } catch (error) {
      console.log(`  ❌ Companion documents: ${error}`);
    }
    
    // Generate project index
    await generateProjectIndex(outputDir, config, results);
    
    const endTime = Date.now();
    const duration = ((endTime - startTime) / 1000).toFixed(2);
    
    console.log(`\n✨ PRD Generation Complete!`);
    console.log(`📁 Output Directory: ${outputDir}`);
    console.log(`📊 Generated: ${results.generated.length} documents`);
    console.log(`❌ Failed: ${results.failed.length} documents`);
    console.log(`⏱️  Duration: ${duration}s`);
    
    if (results.failed.length > 0) {
      console.log(`\n⚠️  Failed to generate:`);
      results.failed.forEach(file => console.log(`  - ${file}`));
    }
    
    return outputDir;
    
  } catch (error) {
    console.error('❌ Error generating PRDs:', error);
    throw error;
  }
}

async function generateFromTemplate(templatePath: string, outputPath: string, config: ProjectConfig): Promise<string> {
  const fullTemplatePath = path.join(process.cwd(), templatePath);
  
  try {
    const template = await fs.readFile(fullTemplatePath, 'utf-8');
    
    // Replace common template variables
    let customized = template
      .replace(/\[Project Name\]/g, config.name)
      .replace(/\[Your project name\]/g, config.name)
      .replace(/\[Project Type\]/g, config.type)
      .replace(/\[Date\]/g, new Date().toLocaleDateString())
      .replace(/\[Your company name\]/g, 'Your Company')
      .replace(/\[Product Owner Name\]/g, 'Product Owner')
      .replace(/\[List key stakeholders\]/g, 'Product Owner, Engineering Team, Design Team')
      .replace(/\[Draft\/Review\/Approved\/In Development\]/g, 'Draft');
    
    if (config.description) {
      customized = customized.replace(
        /\[One sentence describing the ultimate goal\]/g, 
        config.description
      );
    }
    
    // Add project-specific header
    const header = `<!-- Generated by TaskFlow PRD Generation System -->
<!-- Project: ${config.name} -->
<!-- Generated: ${new Date().toISOString()} -->
<!-- Template: ${path.basename(templatePath)} -->

`;
    
    customized = header + customized;
    
    await fs.writeFile(outputPath, customized);
    return outputPath;
    
  } catch (error) {
    throw new Error(`Failed to process template ${templatePath}: ${error}`);
  }
}

async function generateDesignDocument(outputDir: string, config: ProjectConfig) {
  const designTemplate = `# ${config.name} - Design Document

## Generated: ${new Date().toLocaleDateString()}

## Design System Overview

### Visual Design
- **Design Style**: Modern, clean, and professional
- **Color Palette**: Primary, secondary, and accent colors
- **Typography**: Font families and hierarchy
- **Iconography**: Consistent icon style
- **Imagery**: Photography and illustration guidelines

### Component Library
- Button variants and states
- Form components and validation
- Navigation components
- Data display components
- Feedback and overlay components

### Layout System
- Grid system and breakpoints
- Spacing and sizing scales
- Responsive design patterns
- Mobile-first approach

### Accessibility
- WCAG 2.1 AA compliance
- Keyboard navigation
- Screen reader support
- Color contrast requirements
- Focus management

### Implementation
- Design tokens and variables
- Component documentation
- Usage guidelines
- Code examples

---
*Generated by TaskFlow PRD Generation System*
`;

  await fs.writeFile(path.join(outputDir, 'companion', 'design.md'), designTemplate);
}

async function generateTasksDocument(outputDir: string, config: ProjectConfig) {
  const tasksTemplate = `# ${config.name} - Tasks Breakdown

## Generated: ${new Date().toLocaleDateString()}

## Development Phases

### Phase 1: Foundation Setup (Weeks 1-2)
- [ ] Project initialization and configuration
- [ ] Development environment setup
- [ ] Database schema design and setup
- [ ] Authentication system implementation
- [ ] Basic project structure and routing

### Phase 2: Core Features (Weeks 3-6)
- [ ] User interface implementation
- [ ] Core business logic development
- [ ] API endpoints development
- [ ] Database integration
- [ ] User authentication flows

### Phase 3: Advanced Features (Weeks 7-10)
- [ ] Advanced feature implementation
- [ ] Third-party integrations
- [ ] Performance optimization
- [ ] Security hardening
- [ ] Mobile responsiveness

### Phase 4: Testing & Quality (Weeks 11-12)
- [ ] Unit testing implementation
- [ ] Integration testing
- [ ] End-to-end testing
- [ ] Performance testing
- [ ] Security testing

### Phase 5: Deployment & Launch (Weeks 13-14)
- [ ] Production environment setup
- [ ] CI/CD pipeline configuration
- [ ] Monitoring and logging setup
- [ ] Documentation completion
- [ ] Launch preparation

## Task Categories

### Frontend Development
- Component development
- State management
- Styling and themes
- Responsive design
- Accessibility implementation

### Backend Development
- API development
- Database operations
- Business logic
- Authentication/authorization
- External integrations

### DevOps & Infrastructure
- Environment setup
- Deployment automation
- Monitoring configuration
- Security configuration
- Performance optimization

### Quality Assurance
- Test planning
- Test implementation
- Bug tracking
- Performance testing
- Security testing

---
*Generated by TaskFlow PRD Generation System*
`;

  await fs.writeFile(path.join(outputDir, 'companion', 'tasks.md'), tasksTemplate);
}

async function generateProjectIndex(outputDir: string, config: ProjectConfig, results: any) {
  const indexContent = `# ${config.name} - PRD Suite

## Project Overview
- **Name**: ${config.name}
- **Type**: ${config.type}
- **Generated**: ${new Date().toLocaleDateString()}
- **Description**: ${config.description || 'No description provided'}

## Generated Documents

### Core PRDs (${CORE_TEMPLATES.length} templates)
${CORE_TEMPLATES.map(template => `- [${template.replace(/[_-]/g, ' ').replace('.md', '')}](./core/${template.replace('_template', '').replace('_complete', '')})`).join('\n')}

### Specialized PRDs (${SPECIALIZED_TEMPLATES.length} templates)
${SPECIALIZED_TEMPLATES.map(template => `- [${template.replace(/[_-]/g, ' ').replace('.md', '')}](./specialized/${template})`).join('\n')}

### Companion Documents
- [Design Document](./companion/design.md)
- [Tasks Breakdown](./companion/tasks.md)

## Generation Results
- **Successfully Generated**: ${results.generated.length} documents
- **Failed**: ${results.failed.length} documents
- **Total Templates**: ${CORE_TEMPLATES.length + SPECIALIZED_TEMPLATES.length}

## Next Steps
1. Review each PRD and customize for your specific requirements
2. Remove sections that don't apply to your project
3. Add detailed specifications for your use case
4. Share with stakeholders for review and approval
5. Use as reference during development

## Usage
Each PRD is now customized with your project details but still requires review and refinement. Use these as starting points and adapt them to your specific needs.

---
*Generated by TaskFlow PRD Generation System*
*For support and updates, visit: https://github.com/your-repo/professional-dev-template*
`;

  await fs.writeFile(path.join(outputDir, 'README.md'), indexContent);
}

// CLI interface
program
  .name('generate-all-prds')
  .description('Generate complete PRD suite from all templates')
  .requiredOption('-n, --name <name>', 'Project name')
  .option('-t, --type <type>', 'Project type', 'Web Application')
  .option('-d, --description <description>', 'Project description')
  .option('-f, --features <features>', 'Comma-separated list of key features')
  .action(async (options) => {
    const config: ProjectConfig = {
      name: options.name,
      type: options.type,
      description: options.description,
      features: options.features ? options.features.split(',').map((f: string) => f.trim()) : []
    };
    
    try {
      await generateAllPRDs(config);
    } catch (error) {
      process.exit(1);
    }
  });

// Parse CLI arguments if this script is run directly
if (require.main === module) {
  program.parse();
}

export { generateAllPRDs };