import { NextRequest, NextResponse } from 'next/server';
import fs from 'fs/promises';
import path from 'path';

const TEMPLATE_MAPPINGS: Record<string, string> = {
  'master-prd': 'master-prd-template.md',
  'frontend-architecture': 'frontend_prd_template.md',
  'backend-architecture': 'backend_prd_complete.md',
  'database-design': 'database_prd_complete.md',
  'security': 'security_prd_complete.md',
  'api-documentation': 'api_documentation_prd_template.md',
  'uiux-design': 'complete_uiux_prd.md',
  'performance': 'performance_prd_template.md',
  'qa-testing': 'qa_testing_engineering_prd.md',
  'analytics': 'analytics_prd_template.md',
  'content-strategy': 'content_prd_template.md',
  'mobile-development': 'mobile_prd_template.md',
  'accessibility': 'accessibility-prd-template.md',
  'error-handling': 'error_handling_prd_template.md',
  'integration': 'integration_prd_template.md',
  'infrastructure': 'infrastructure_prd_template.md',
  'ai-ml-integration': 'ai_ml_integration_agent_prd.md',
  'devops-infrastructure': 'devops_infrastructure_agent_prd.md',
  'gekb-system': 'gekb-prd-complete.md',
  'mcp-protocol': 'testing_qa_agent_prd.md' // Using testing as placeholder for MCP
};

export async function GET(
  request: NextRequest,
  { params }: { params: Promise<{ id: string }> }
) {
  try {
    const { id: templateId } = await params;
    const fileName = TEMPLATE_MAPPINGS[templateId];
    
    if (!fileName) {
      return NextResponse.json(
        { error: 'Template not found' },
        { status: 404 }
      );
    }

    // Determine which folder the template is in
    let templatePath;
    
    if (templateId === 'gekb-system') {
      // GEKB template is in the examples directory
      templatePath = path.join(
        process.cwd(),
        'prd-system',
        'examples',
        'taskflow-example',
        fileName
      );
    } else {
      const isSpecialized = ['ai-ml-integration', 'devops-infrastructure', 'mcp-protocol'].includes(templateId);
      const folder = isSpecialized ? 'specialized' : 'core-16';
      
      templatePath = path.join(
        process.cwd(),
        'prd-system',
        'templates',
        folder,
        fileName
      );
    }

    try {
      const content = await fs.readFile(templatePath, 'utf-8');
      return NextResponse.json({ content });
    } catch (fileError) {
      console.error(`Error reading template file ${templatePath}:`, fileError);
      
      // Fallback to a generic template structure
      const fallbackContent = generateFallbackTemplate(templateId);
      return NextResponse.json({ content: fallbackContent });
    }
  } catch (error) {
    console.error('Error fetching template:', error);
    return NextResponse.json(
      { error: 'Internal server error' },
      { status: 500 }
    );
  }
}

function generateFallbackTemplate(templateId: string): string {
  const templateNames: Record<string, string> = {
    'master-prd': 'Master PRD Template',
    'frontend-architecture': 'Frontend Architecture PRD',
    'backend-architecture': 'Backend Architecture PRD',
    'database-design': 'Database Design PRD',
    'security': 'Security PRD',
    'api-documentation': 'API Documentation PRD',
    'uiux-design': 'UI/UX Design PRD',
    'performance': 'Performance Engineering PRD',
    'qa-testing': 'QA/Testing PRD',
    'analytics': 'Analytics & Data PRD',
    'content-strategy': 'Content Strategy PRD',
    'mobile-development': 'Mobile Development PRD',
    'accessibility': 'Accessibility PRD',
    'error-handling': 'Error Handling PRD',
    'integration': 'Integration PRD',
    'infrastructure': 'Infrastructure/DevOps PRD',
    'ai-ml-integration': 'AI/ML Integration PRD',
    'devops-infrastructure': 'DevOps Infrastructure PRD',
    'gekb-system': 'Global Error Knowledge Base (GEKB) System PRD',
    'mcp-protocol': 'MCP Protocol PRD'
  };

  const templateName = templateNames[templateId] || 'PRD Template';

  return `# ${templateName}

## Document Information
- **Document Type**: Product Requirements Document
- **Version**: 1.0
- **Created**: ${new Date().toLocaleDateString()}
- **Status**: Template
- **Template ID**: ${templateId}

## Overview
This is a professional PRD template for ${templateName.toLowerCase()}. Use this template as a starting point for creating comprehensive product requirements documents.

## Table of Contents
1. [Project Overview](#project-overview)
2. [Technical Requirements](#technical-requirements)
3. [Feature Specifications](#feature-specifications)
4. [Implementation Timeline](#implementation-timeline)
5. [Success Metrics](#success-metrics)

## Project Overview

### Problem Statement
[Describe the specific problem this PRD addresses]

### Solution Approach
[Outline the proposed solution approach]

### Key Objectives
- Primary objective 1
- Primary objective 2
- Primary objective 3

## Technical Requirements

### Technology Stack
- **Primary Technology**: [Main technology/framework]
- **Supporting Technologies**: [Additional tools and technologies]
- **Infrastructure**: [Hosting and deployment requirements]

### Performance Requirements
- **Response Time**: [Target response times]
- **Scalability**: [Scalability requirements]
- **Availability**: [Uptime requirements]

## Feature Specifications

### Core Features
1. **Feature 1**
   - Description: [Detailed feature description]
   - Acceptance Criteria: [Clear success criteria]
   - Priority: High/Medium/Low

2. **Feature 2**
   - Description: [Detailed feature description]
   - Acceptance Criteria: [Clear success criteria]
   - Priority: High/Medium/Low

### Optional Features
- Optional feature A
- Optional feature B
- Optional feature C

## Implementation Timeline

### Phase 1: Planning & Setup (Weeks 1-2)
- [ ] Requirements gathering
- [ ] Technical planning
- [ ] Resource allocation

### Phase 2: Development (Weeks 3-8)
- [ ] Core feature development
- [ ] Integration implementation
- [ ] Testing and validation

### Phase 3: Launch (Weeks 9-10)
- [ ] Final testing
- [ ] Deployment preparation
- [ ] Go-live activities

## Success Metrics

### Key Performance Indicators
- **Metric 1**: [Target value and measurement method]
- **Metric 2**: [Target value and measurement method]
- **Metric 3**: [Target value and measurement method]

### Acceptance Criteria
- All core features implemented and tested
- Performance requirements met
- User acceptance testing completed

---

**Note**: This is a template structure. Customize each section with project-specific requirements and details.

**Template Source**: Professional Development Template Repository
**Generated**: ${new Date().toISOString()}`;
}