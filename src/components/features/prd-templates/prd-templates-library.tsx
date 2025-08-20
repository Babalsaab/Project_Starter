'use client';

import { useState } from 'react';
import Link from 'next/link';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { 
  FileText, 
  Download, 
  Eye, 
  Star,
  ArrowLeft,
  Search,
  Filter,
  ExternalLink,
  Code,
  Zap
} from 'lucide-react';

export function PRDTemplatesLibrary() {
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('all');

  const templates = [
    {
      id: 'master-prd',
      name: 'Master PRD Template',
      description: 'The foundation document that drives the generation of all specialized PRDs. Single source of truth for professional development.',
      category: 'core',
      featured: true,
      tags: ['foundation', 'planning', 'overview'],
      complexity: 'beginner',
      estimatedTime: '30-45 min'
    },
    {
      id: 'frontend-architecture',
      name: 'Frontend Architecture PRD',
      description: 'Comprehensive frontend planning including component architecture, state management, and UI framework decisions.',
      category: 'core',
      featured: true,
      tags: ['react', 'ui', 'components', 'state-management'],
      complexity: 'intermediate',
      estimatedTime: '45-60 min'
    },
    {
      id: 'backend-architecture',
      name: 'Backend Architecture PRD',
      description: 'Server architecture, API design, database connections, and scalability planning for robust backend systems.',
      category: 'core',
      featured: true,
      tags: ['api', 'server', 'architecture', 'scalability'],
      complexity: 'intermediate',
      estimatedTime: '45-60 min'
    },
    {
      id: 'database-design',
      name: 'Database Design PRD',
      description: 'Complete database schema design, optimization strategies, migration planning, and data architecture.',
      category: 'core',
      featured: false,
      tags: ['database', 'schema', 'optimization', 'migrations'],
      complexity: 'intermediate',
      estimatedTime: '40-50 min'
    },
    {
      id: 'security',
      name: 'Security PRD',
      description: 'Authentication, authorization, data protection, compliance requirements, and security best practices.',
      category: 'core',
      featured: true,
      tags: ['auth', 'security', 'compliance', 'encryption'],
      complexity: 'advanced',
      estimatedTime: '35-45 min'
    },
    {
      id: 'api-documentation',
      name: 'API Documentation PRD',
      description: 'Comprehensive API endpoint design, documentation standards, and developer experience optimization.',
      category: 'core',
      featured: false,
      tags: ['api', 'documentation', 'developer-experience'],
      complexity: 'beginner',
      estimatedTime: '30-40 min'
    },
    {
      id: 'uiux-design',
      name: 'UI/UX Design PRD',
      description: 'Design system creation, user experience flows, accessibility requirements, and visual design standards.',
      category: 'core',
      featured: true,
      tags: ['design-system', 'ux', 'accessibility', 'figma'],
      complexity: 'intermediate',
      estimatedTime: '50-60 min'
    },
    {
      id: 'performance',
      name: 'Performance Engineering PRD',
      description: 'Performance optimization strategies, Core Web Vitals, monitoring, and speed improvement techniques.',
      category: 'core',
      featured: false,
      tags: ['performance', 'optimization', 'monitoring', 'web-vitals'],
      complexity: 'advanced',
      estimatedTime: '35-45 min'
    },
    {
      id: 'qa-testing',
      name: 'QA/Testing PRD',
      description: 'Comprehensive testing strategy including unit, integration, E2E testing, and quality assurance processes.',
      category: 'core',
      featured: false,
      tags: ['testing', 'qa', 'automation', 'jest', 'playwright'],
      complexity: 'intermediate',
      estimatedTime: '40-50 min'
    },
    {
      id: 'analytics',
      name: 'Analytics & Data PRD',
      description: 'Data collection strategies, analytics implementation, reporting dashboards, and business intelligence.',
      category: 'core',
      featured: false,
      tags: ['analytics', 'data', 'reporting', 'business-intelligence'],
      complexity: 'intermediate',
      estimatedTime: '25-35 min'
    },
    {
      id: 'content-strategy',
      name: 'Content Strategy PRD',
      description: 'Content management, user communication strategies, and content creation workflows.',
      category: 'core',
      featured: false,
      tags: ['content', 'communication', 'cms'],
      complexity: 'beginner',
      estimatedTime: '25-35 min'
    },
    {
      id: 'mobile-development',
      name: 'Mobile Development PRD',
      description: 'Mobile application development, responsive design, and cross-platform considerations.',
      category: 'core',
      featured: false,
      tags: ['mobile', 'responsive', 'cross-platform'],
      complexity: 'intermediate',
      estimatedTime: '45-55 min'
    },
    {
      id: 'accessibility',
      name: 'Accessibility PRD',
      description: 'WCAG compliance, inclusive design principles, and accessibility testing strategies.',
      category: 'core',
      featured: false,
      tags: ['accessibility', 'wcag', 'inclusive-design'],
      complexity: 'intermediate',
      estimatedTime: '30-40 min'
    },
    {
      id: 'error-handling',
      name: 'Error Handling PRD',
      description: 'Error management strategies, logging systems, and user error experience design.',
      category: 'core',
      featured: false,
      tags: ['error-handling', 'logging', 'monitoring'],
      complexity: 'intermediate',
      estimatedTime: '25-35 min'
    },
    {
      id: 'integration',
      name: 'Integration PRD',
      description: 'Third-party service integrations, API connections, and external system interfaces.',
      category: 'core',
      featured: false,
      tags: ['integration', 'third-party', 'apis'],
      complexity: 'intermediate',
      estimatedTime: '35-45 min'
    },
    {
      id: 'infrastructure',
      name: 'Infrastructure/DevOps PRD',
      description: 'Deployment strategies, infrastructure as code, monitoring, and operational procedures.',
      category: 'core',
      featured: false,
      tags: ['devops', 'infrastructure', 'deployment', 'monitoring'],
      complexity: 'advanced',
      estimatedTime: '40-50 min'
    },
    {
      id: 'ai-ml-integration',
      name: 'AI/ML Integration PRD',
      description: 'Machine learning model integration, AI feature development, and intelligent automation implementation.',
      category: 'specialized',
      featured: true,
      tags: ['ai', 'machine-learning', 'automation', 'intelligence'],
      complexity: 'advanced',
      estimatedTime: '60-90 min'
    },
    {
      id: 'devops-infrastructure',
      name: 'DevOps Infrastructure PRD',
      description: 'Advanced deployment strategies, container orchestration, CI/CD pipelines, and infrastructure as code.',
      category: 'specialized',
      featured: false,
      tags: ['devops', 'docker', 'kubernetes', 'ci-cd', 'infrastructure'],
      complexity: 'advanced',
      estimatedTime: '55-75 min'
    },
    {
      id: 'gekb-system',
      name: 'GEKB System PRD',
      description: 'Graph-Enhanced Knowledge Base architecture for complex data relationships and intelligent information retrieval.',
      category: 'specialized',
      featured: false,
      tags: ['knowledge-base', 'graph-database', 'search', 'ai'],
      complexity: 'expert',
      estimatedTime: '50-70 min'
    },
    {
      id: 'mcp-protocol',
      name: 'MCP Protocol PRD',
      description: 'Model Context Protocol implementation for advanced AI model integration and context management.',
      category: 'specialized',
      featured: false,
      tags: ['mcp', 'ai-protocol', 'model-integration', 'context'],
      complexity: 'expert',
      estimatedTime: '45-65 min'
    }
  ];

  const filteredTemplates = templates.filter(template => {
    const matchesSearch = template.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         template.description.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         template.tags.some(tag => tag.toLowerCase().includes(searchTerm.toLowerCase()));
    const matchesCategory = selectedCategory === 'all' || 
                           (selectedCategory === 'featured' && template.featured) ||
                           template.category === selectedCategory;
    return matchesSearch && matchesCategory;
  });

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

  const getCategoryStats = () => {
    const core = templates.filter(t => t.category === 'core').length;
    const specialized = templates.filter(t => t.category === 'specialized').length;
    const featured = templates.filter(t => t.featured).length;
    return { core, specialized, featured, total: templates.length };
  };

  const stats = getCategoryStats();

  return (
    <div className="min-h-screen">
      {/* Header */}
      <div className="border-b bg-background/95 backdrop-blur supports-[backdrop-filter]:bg-background/60">
        <div className="container mx-auto px-4 py-8">
          <div className="flex items-center justify-between">
            <div>
              <div className="flex items-center space-x-4 mb-4">
                <Link href="/">
                  <Button variant="outline" size="sm">
                    <ArrowLeft className="mr-2 h-4 w-4" />
                    Back to Home
                  </Button>
                </Link>
                <div className="flex items-center space-x-2">
                  <div className="h-8 w-8 rounded-lg bg-gradient-to-br from-blue-600 to-purple-600 flex items-center justify-center">
                    <Zap className="h-4 w-4 text-white" />
                  </div>
                  <span className="text-lg font-bold">TaskFlow</span>
                </div>
              </div>
              <h1 className="text-4xl font-bold tracking-tight">PRD Template Library</h1>
              <p className="text-xl text-muted-foreground mt-2">
                Professional Product Requirements Document templates for every aspect of software development
              </p>
            </div>
            <div className="hidden md:block">
              <Link href="/auth/signin">
                <Button>
                  Get Started with PRD Generator
                  <ExternalLink className="ml-2 h-4 w-4" />
                </Button>
              </Link>
            </div>
          </div>
        </div>
      </div>

      <div className="container mx-auto px-4 py-8">
        {/* Stats */}
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-8">
          <Card>
            <CardContent className="pt-6">
              <div className="flex items-center">
                <FileText className="h-4 w-4 text-blue-600" />
                <div className="ml-2">
                  <p className="text-sm font-medium">Total Templates</p>
                  <p className="text-2xl font-bold">{stats.total}</p>
                </div>
              </div>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="pt-6">
              <div className="flex items-center">
                <Code className="h-4 w-4 text-green-600" />
                <div className="ml-2">
                  <p className="text-sm font-medium">Core Templates</p>
                  <p className="text-2xl font-bold">{stats.core}</p>
                </div>
              </div>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="pt-6">
              <div className="flex items-center">
                <Zap className="h-4 w-4 text-purple-600" />
                <div className="ml-2">
                  <p className="text-sm font-medium">Specialized</p>
                  <p className="text-2xl font-bold">{stats.specialized}</p>
                </div>
              </div>
            </CardContent>
          </Card>
          <Card>
            <CardContent className="pt-6">
              <div className="flex items-center">
                <Star className="h-4 w-4 text-yellow-600" />
                <div className="ml-2">
                  <p className="text-sm font-medium">Featured</p>
                  <p className="text-2xl font-bold">{stats.featured}</p>
                </div>
              </div>
            </CardContent>
          </Card>
        </div>

        {/* Filters and Search */}
        <div className="flex flex-col md:flex-row gap-4 mb-8">
          <div className="flex-1">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
              <Input
                placeholder="Search templates, tags, or descriptions..."
                value={searchTerm}
                onChange={(e) => setSearchTerm(e.target.value)}
                className="pl-10"
              />
            </div>
          </div>
          <div className="flex gap-2">
            <Button
              variant={selectedCategory === 'all' ? 'default' : 'outline'}
              size="sm"
              onClick={() => setSelectedCategory('all')}
            >
              All
            </Button>
            <Button
              variant={selectedCategory === 'featured' ? 'default' : 'outline'}
              size="sm"
              onClick={() => setSelectedCategory('featured')}
            >
              <Star className="mr-1 h-3 w-3" />
              Featured
            </Button>
            <Button
              variant={selectedCategory === 'core' ? 'default' : 'outline'}
              size="sm"
              onClick={() => setSelectedCategory('core')}
            >
              Core
            </Button>
            <Button
              variant={selectedCategory === 'specialized' ? 'default' : 'outline'}
              size="sm"
              onClick={() => setSelectedCategory('specialized')}
            >
              Specialized
            </Button>
          </div>
        </div>

        {/* Templates Grid */}
        <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
          {filteredTemplates.map((template) => (
            <Card key={template.id} className="relative group hover:shadow-lg transition-shadow">
              {template.featured && (
                <div className="absolute top-4 right-4">
                  <Star className="h-4 w-4 text-yellow-500 fill-current" />
                </div>
              )}
              
              <CardHeader className="pb-3">
                <div className="space-y-2">
                  <CardTitle className="text-lg group-hover:text-primary transition-colors">
                    {template.name}
                  </CardTitle>
                  <div className="flex items-center gap-2">
                    <Badge className={getComplexityColor(template.complexity)}>
                      {template.complexity}
                    </Badge>
                    <Badge variant="outline" className="text-xs">
                      {template.category}
                    </Badge>
                  </div>
                  <CardDescription className="text-sm line-clamp-3">
                    {template.description}
                  </CardDescription>
                </div>
              </CardHeader>
              
              <CardContent className="space-y-4">
                <div className="text-xs text-muted-foreground">
                  Estimated time: {template.estimatedTime}
                </div>
                
                <div className="flex flex-wrap gap-1">
                  {template.tags.slice(0, 3).map((tag) => (
                    <Badge key={tag} variant="secondary" className="text-xs">
                      {tag}
                    </Badge>
                  ))}
                  {template.tags.length > 3 && (
                    <Badge variant="secondary" className="text-xs">
                      +{template.tags.length - 3}
                    </Badge>
                  )}
                </div>

                <div className="flex gap-2">
                  <Link href={`/prd-templates/${template.id}`} className="flex-1">
                    <Button size="sm" className="w-full">
                      <Eye className="mr-1 h-3 w-3" />
                      View Template
                    </Button>
                  </Link>
                  <Button size="sm" variant="outline">
                    <Download className="h-3 w-3" />
                  </Button>
                </div>
              </CardContent>
            </Card>
          ))}
        </div>

        {filteredTemplates.length === 0 && (
          <div className="text-center py-12">
            <Search className="mx-auto h-12 w-12 text-muted-foreground" />
            <h3 className="mt-4 text-lg font-medium">No templates found</h3>
            <p className="text-muted-foreground">
              Try adjusting your search terms or filter criteria
            </p>
          </div>
        )}

        {/* CTA Section */}
        <div className="mt-16 text-center">
          <div className="bg-gradient-to-r from-blue-50 to-purple-50 dark:from-blue-900/20 dark:to-purple-900/20 rounded-lg p-8">
            <h2 className="text-2xl font-bold mb-4">Ready to Generate Your PRDs?</h2>
            <p className="text-muted-foreground mb-6 max-w-2xl mx-auto">
              Sign up for TaskFlow to access the PRD Generator and create customized 
              Product Requirements Documents for your projects in minutes.
            </p>
            <div className="flex flex-col sm:flex-row gap-4 justify-center">
              <Link href="/auth/signup">
                <Button size="lg">
                  Start Generating PRDs
                  <ExternalLink className="ml-2 h-4 w-4" />
                </Button>
              </Link>
              <Link href="/auth/signin">
                <Button size="lg" variant="outline">
                  Sign In to Continue
                </Button>
              </Link>
            </div>
          </div>
        </div>
      </div>
    </div>
  );
}