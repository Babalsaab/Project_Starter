'use client';

import { useState, useEffect } from 'react';
import Link from 'next/link';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { 
  ArrowLeft, 
  Download, 
  ExternalLink, 
  Clock,
  Star,
  Code,
  FileText,
  Zap,
  Copy,
  Check
} from 'lucide-react';

interface PRDTemplateViewProps {
  templateId: string;
}

export function PRDTemplateView({ templateId }: PRDTemplateViewProps) {
  const [templateContent, setTemplateContent] = useState<string>('');
  const [isLoading, setIsLoading] = useState(true);
  const [copied, setCopied] = useState(false);

  const templateData = {
    'master-prd': {
      name: 'Master PRD Template',
      description: 'The foundation document that drives the generation of all specialized PRDs. Single source of truth for professional development.',
      category: 'core',
      complexity: 'beginner',
      estimatedTime: '30-45 min',
      featured: true,
      tags: ['foundation', 'planning', 'overview'],
      dependencies: [],
    },
    'frontend-architecture': {
      name: 'Frontend Architecture PRD',
      description: 'Comprehensive frontend planning including component architecture, state management, and UI framework decisions.',
      category: 'core',
      complexity: 'intermediate',
      estimatedTime: '45-60 min',
      featured: true,
      tags: ['react', 'ui', 'components', 'state-management'],
      dependencies: ['master-prd'],
    },
    'backend-architecture': {
      name: 'Backend Architecture PRD',
      description: 'Server architecture, API design, database connections, and scalability planning for robust backend systems.',
      category: 'core',
      complexity: 'intermediate',
      estimatedTime: '45-60 min',
      featured: true,
      tags: ['api', 'server', 'architecture', 'scalability'],
      dependencies: ['master-prd'],
    },
    'database-design': {
      name: 'Database Design PRD',
      description: 'Complete database schema design, optimization strategies, migration planning, and data architecture.',
      category: 'core',
      complexity: 'intermediate',
      estimatedTime: '40-50 min',
      featured: false,
      tags: ['database', 'schema', 'optimization', 'migrations'],
      dependencies: ['backend-architecture'],
    },
    'security': {
      name: 'Security PRD',
      description: 'Authentication, authorization, data protection, compliance requirements, and security best practices.',
      category: 'core',
      complexity: 'advanced',
      estimatedTime: '35-45 min',
      featured: true,
      tags: ['auth', 'security', 'compliance', 'encryption'],
      dependencies: ['master-prd'],
    },
    'api-documentation': {
      name: 'API Documentation PRD',
      description: 'Comprehensive API endpoint design, documentation standards, and developer experience optimization.',
      category: 'core',
      complexity: 'beginner',
      estimatedTime: '30-40 min',
      featured: false,
      tags: ['api', 'documentation', 'developer-experience'],
      dependencies: ['backend-architecture'],
    },
    'uiux-design': {
      name: 'UI/UX Design PRD',
      description: 'Design system creation, user experience flows, accessibility requirements, and visual design standards.',
      category: 'core',
      complexity: 'intermediate',
      estimatedTime: '50-60 min',
      featured: true,
      tags: ['design-system', 'ux', 'accessibility', 'figma'],
      dependencies: ['master-prd'],
    },
    'performance': {
      name: 'Performance Engineering PRD',
      description: 'Performance optimization strategies, Core Web Vitals, monitoring, and speed improvement techniques.',
      category: 'core',
      complexity: 'advanced',
      estimatedTime: '35-45 min',
      featured: false,
      tags: ['performance', 'optimization', 'monitoring', 'web-vitals'],
      dependencies: ['frontend-architecture'],
    },
    'qa-testing': {
      name: 'QA/Testing PRD',
      description: 'Comprehensive testing strategy including unit, integration, E2E testing, and quality assurance processes.',
      category: 'core',
      complexity: 'intermediate',
      estimatedTime: '40-50 min',
      featured: false,
      tags: ['testing', 'qa', 'automation', 'jest', 'playwright'],
      dependencies: ['master-prd'],
    },
    'analytics': {
      name: 'Analytics & Data PRD',
      description: 'Data collection strategies, analytics implementation, reporting dashboards, and business intelligence.',
      category: 'core',
      complexity: 'intermediate',
      estimatedTime: '25-35 min',
      featured: false,
      tags: ['analytics', 'data', 'reporting', 'business-intelligence'],
      dependencies: ['master-prd'],
    },
    'content-strategy': {
      name: 'Content Strategy PRD',
      description: 'Content management, user communication strategies, and content creation workflows.',
      category: 'core',
      complexity: 'beginner',
      estimatedTime: '25-35 min',
      featured: false,
      tags: ['content', 'communication', 'cms'],
      dependencies: ['uiux-design'],
    },
    'mobile-development': {
      name: 'Mobile Development PRD',
      description: 'Mobile application development, responsive design, and cross-platform considerations.',
      category: 'core',
      complexity: 'intermediate',
      estimatedTime: '45-55 min',
      featured: false,
      tags: ['mobile', 'responsive', 'cross-platform'],
      dependencies: ['frontend-architecture'],
    },
    'accessibility': {
      name: 'Accessibility PRD',
      description: 'WCAG compliance, inclusive design principles, and accessibility testing strategies.',
      category: 'core',
      complexity: 'intermediate',
      estimatedTime: '30-40 min',
      featured: false,
      tags: ['accessibility', 'wcag', 'inclusive-design'],
      dependencies: ['uiux-design'],
    },
    'error-handling': {
      name: 'Error Handling PRD',
      description: 'Error management strategies, logging systems, and user error experience design.',
      category: 'core',
      complexity: 'intermediate',
      estimatedTime: '25-35 min',
      featured: false,
      tags: ['error-handling', 'logging', 'monitoring'],
      dependencies: ['backend-architecture'],
    },
    'integration': {
      name: 'Integration PRD',
      description: 'Third-party service integrations, API connections, and external system interfaces.',
      category: 'core',
      complexity: 'intermediate',
      estimatedTime: '35-45 min',
      featured: false,
      tags: ['integration', 'third-party', 'apis'],
      dependencies: ['api-documentation'],
    },
    'infrastructure': {
      name: 'Infrastructure/DevOps PRD',
      description: 'Deployment strategies, infrastructure as code, monitoring, and operational procedures.',
      category: 'core',
      complexity: 'advanced',
      estimatedTime: '40-50 min',
      featured: false,
      tags: ['devops', 'infrastructure', 'deployment', 'monitoring'],
      dependencies: ['backend-architecture'],
    },
    'ai-ml-integration': {
      name: 'AI/ML Integration PRD',
      description: 'Machine learning model integration, AI feature development, and intelligent automation implementation.',
      category: 'specialized',
      complexity: 'advanced',
      estimatedTime: '60-90 min',
      featured: true,
      tags: ['ai', 'machine-learning', 'automation', 'intelligence'],
      dependencies: ['backend-architecture', 'api-documentation'],
    },
    'devops-infrastructure': {
      name: 'DevOps Infrastructure PRD',
      description: 'Advanced deployment strategies, container orchestration, CI/CD pipelines, and infrastructure as code.',
      category: 'specialized',
      complexity: 'advanced',
      estimatedTime: '55-75 min',
      featured: false,
      tags: ['devops', 'docker', 'kubernetes', 'ci-cd', 'infrastructure'],
      dependencies: ['infrastructure'],
    },
    'gekb-system': {
      name: 'GEKB System PRD',
      description: 'Graph-Enhanced Knowledge Base architecture for complex data relationships and intelligent information retrieval.',
      category: 'specialized',
      complexity: 'expert',
      estimatedTime: '50-70 min',
      featured: false,
      tags: ['knowledge-base', 'graph-database', 'search', 'ai'],
      dependencies: ['database-design', 'ai-ml-integration'],
    },
    'mcp-protocol': {
      name: 'MCP Protocol PRD',
      description: 'Model Context Protocol implementation for advanced AI model integration and context management.',
      category: 'specialized',
      complexity: 'expert',
      estimatedTime: '45-65 min',
      featured: false,
      tags: ['mcp', 'ai-protocol', 'model-integration', 'context'],
      dependencies: ['ai-ml-integration'],
    }
  };

  const template = templateData[templateId as keyof typeof templateData];

  useEffect(() => {
    const fetchTemplateContent = async () => {
      if (!template) {
        setIsLoading(false);
        return;
      }

      try {
        setIsLoading(true);
        const response = await fetch(`/api/templates/${templateId}`);
        
        if (response.ok) {
          const data = await response.json();
          setTemplateContent(data.content);
        } else {
          throw new Error('Failed to fetch template');
        }
      } catch (error) {
        console.error('Error fetching template content:', error);
        // Set fallback content
        const fallbackContent = `# ${template.name}

**Template ID**: ${templateId}
**Category**: ${template.category}
**Complexity**: ${template.complexity}
**Estimated Time**: ${template.estimatedTime}

## Description
${template.description}

## Tags
${template.tags.join(', ')}

${template.dependencies.length > 0 ? `## Dependencies
${template.dependencies.map(dep => `- ${dep}`).join('\n')}` : ''}

---

*This template content could not be loaded. Please try refreshing the page or contact support.*

**Generated**: ${new Date().toISOString()}`;
        
        setTemplateContent(fallbackContent);
      } finally {
        setIsLoading(false);
      }
    };

    fetchTemplateContent();
  }, [template, templateId]);

  const getComplexityColor = (complexity: string) => {
    switch (complexity) {
      case 'beginner':
        return 'bg-green-100 text-green-800 dark:bg-green-900/20 dark:text-green-400';
      case 'intermediate':
        return 'bg-blue-100 text-blue-800 dark:bg-blue-900/20 dark:text-blue-400';
      case 'advanced':
        return 'bg-orange-100 text-orange-800 dark:bg-orange-900/20 dark:text-orange-400';
      case 'expert':
        return 'bg-red-100 text-red-800 dark:bg-red-900/20 dark:text-red-400';
      default:
        return 'bg-gray-100 text-gray-800 dark:bg-gray-900/20 dark:text-gray-400';
    }
  };

  const handleCopyContent = async () => {
    try {
      await navigator.clipboard.writeText(templateContent);
      setCopied(true);
      setTimeout(() => setCopied(false), 2000);
    } catch (err) {
      console.error('Failed to copy content:', err);
    }
  };

  const handleDownload = () => {
    const blob = new Blob([templateContent], { type: 'text/markdown' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = `${templateId}-template.md`;
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);
  };

  if (!template) {
    return (
      <div className="min-h-screen flex items-center justify-center">
        <div className="text-center">
          <h1 className="text-2xl font-bold mb-4">Template Not Found</h1>
          <Link href="/prd-templates">
            <Button>
              <ArrowLeft className="mr-2 h-4 w-4" />
              Back to Templates
            </Button>
          </Link>
        </div>
      </div>
    );
  }

  return (
    <div className="min-h-screen bg-background">
      {/* Header */}
      <div className="border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
        <div className="container mx-auto px-4 py-6">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-4">
              <Link href="/prd-templates">
                <Button variant="outline" size="sm">
                  <ArrowLeft className="mr-2 h-4 w-4" />
                  Back to Library
                </Button>
              </Link>
              <div className="flex items-center space-x-2">
                <div className="h-8 w-8 rounded-lg bg-gradient-to-br from-blue-600 to-purple-600 flex items-center justify-center">
                  <Zap className="h-4 w-4 text-white" />
                </div>
                <span className="text-lg font-bold">TaskFlow</span>
              </div>
            </div>
            <div className="flex space-x-2">
              <Button variant="outline" onClick={handleCopyContent}>
                {copied ? (
                  <Check className="mr-2 h-4 w-4" />
                ) : (
                  <Copy className="mr-2 h-4 w-4" />
                )}
                {copied ? 'Copied!' : 'Copy'}
              </Button>
              <Button onClick={handleDownload}>
                <Download className="mr-2 h-4 w-4" />
                Download
              </Button>
            </div>
          </div>
        </div>
      </div>

      <div className="container mx-auto px-4 py-8">
        {/* Template Info */}
        <Card className="mb-8">
          <CardHeader>
            <div className="flex items-start justify-between">
              <div className="space-y-2">
                <div className="flex items-center gap-2">
                  <CardTitle className="text-2xl">{template.name}</CardTitle>
                  {template.featured && (
                    <Star className="h-5 w-5 text-yellow-500 fill-current" />
                  )}
                </div>
                <div className="flex items-center gap-2">
                  <Badge className={getComplexityColor(template.complexity)}>
                    {template.complexity}
                  </Badge>
                  <Badge variant="outline">
                    {template.category}
                  </Badge>
                  <div className="flex items-center text-sm text-muted-foreground">
                    <Clock className="mr-1 h-3 w-3" />
                    {template.estimatedTime}
                  </div>
                </div>
                <CardDescription className="text-base max-w-3xl">
                  {template.description}
                </CardDescription>
              </div>
              <FileText className="h-8 w-8 text-muted-foreground" />
            </div>
          </CardHeader>
          <CardContent>
            <div className="grid grid-cols-1 md:grid-cols-3 gap-6">
              <div>
                <h4 className="font-medium mb-2">Tags</h4>
                <div className="flex flex-wrap gap-1">
                  {template.tags.map((tag) => (
                    <Badge key={tag} variant="secondary" className="text-xs">
                      {tag}
                    </Badge>
                  ))}
                </div>
              </div>
              {template.dependencies.length > 0 && (
                <div>
                  <h4 className="font-medium mb-2">Dependencies</h4>
                  <div className="space-y-1">
                    {template.dependencies.map((dep) => (
                      <div key={dep} className="text-sm text-muted-foreground">
                        • {dep}
                      </div>
                    ))}
                  </div>
                </div>
              )}
              <div>
                <h4 className="font-medium mb-2">Actions</h4>
                <div className="space-y-2">
                  <Link href="/auth/signin">
                    <Button size="sm" className="w-full">
                      <Code className="mr-2 h-3 w-3" />
                      Generate PRD
                    </Button>
                  </Link>
                  <Button size="sm" variant="outline" className="w-full" onClick={handleDownload}>
                    <Download className="mr-2 h-3 w-3" />
                    Download Template
                  </Button>
                </div>
              </div>
            </div>
          </CardContent>
        </Card>

        {/* Template Content */}
        <Card>
          <CardHeader>
            <CardTitle>Template Content</CardTitle>
            <CardDescription>
              Preview of the PRD template structure and sections
            </CardDescription>
          </CardHeader>
          <CardContent>
            {isLoading ? (
              <div className="flex items-center justify-center h-64">
                <div className="text-center">
                  <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-primary mx-auto mb-4"></div>
                  <p className="text-muted-foreground">Loading template...</p>
                </div>
              </div>
            ) : (
              <div className="prose prose-sm max-w-none dark:prose-invert">
                <pre className="whitespace-pre-wrap font-mono text-sm bg-muted p-4 rounded-lg overflow-auto max-h-96">
                  {templateContent}
                </pre>
              </div>
            )}
          </CardContent>
        </Card>

        {/* Get Started CTA */}
        <Card className="mt-8">
          <CardContent className="pt-6">
            <div className="text-center">
              <h3 className="text-lg font-semibold mb-2">Ready to use this template?</h3>
              <p className="text-muted-foreground mb-4">
                Sign up for TaskFlow to generate customized PRDs from this template
              </p>
              <div className="flex flex-col sm:flex-row gap-2 justify-center">
                <Link href="/auth/signup">
                  <Button>
                    Get Started with PRD Generator
                    <ExternalLink className="ml-2 h-4 w-4" />
                  </Button>
                </Link>
                <Link href="/prd-templates">
                  <Button variant="outline">
                    Explore More Templates
                  </Button>
                </Link>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}