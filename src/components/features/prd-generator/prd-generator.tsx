'use client';

import { useState } from 'react';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Button } from '@/components/ui/button';
import { Badge } from '@/components/ui/badge';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { 
  FileText, 
  Download, 
  Eye, 
  Settings, 
  Zap,
  CheckCircle,
  Clock,
  Folder,
  Search,
  Filter
} from 'lucide-react';
import Link from 'next/link';

export function PRDGenerator() {
  const [projectName, setProjectName] = useState('');
  const [projectType, setProjectType] = useState('');
  const [searchTerm, setSearchTerm] = useState('');
  const [selectedCategory, setSelectedCategory] = useState('all');

  const coreTemplates = [
    {
      id: 'master-prd',
      name: 'Master PRD',
      description: 'Foundation document and single source of truth',
      category: 'core',
      status: 'ready',
      estimatedTime: '30 min',
      dependencies: []
    },
    {
      id: 'frontend-architecture',
      name: 'Frontend Architecture',
      description: 'UI/UX components and state management',
      category: 'core',
      status: 'ready',
      estimatedTime: '45 min',
      dependencies: ['master-prd']
    },
    {
      id: 'backend-architecture',
      name: 'Backend Architecture',
      description: 'Server, API, and data architecture',
      category: 'core',
      status: 'ready',
      estimatedTime: '45 min',
      dependencies: ['master-prd']
    },
    {
      id: 'database-design',
      name: 'Database Design',
      description: 'Schema, optimization, and migrations',
      category: 'core',
      status: 'ready',
      estimatedTime: '40 min',
      dependencies: ['backend-architecture']
    },
    {
      id: 'security',
      name: 'Security PRD',
      description: 'Authentication, authorization, data protection',
      category: 'core',
      status: 'ready',
      estimatedTime: '35 min',
      dependencies: ['master-prd']
    },
    {
      id: 'api-documentation',
      name: 'API Documentation',
      description: 'Endpoint design and developer documentation',
      category: 'core',
      status: 'ready',
      estimatedTime: '30 min',
      dependencies: ['backend-architecture']
    },
    {
      id: 'uiux-design',
      name: 'UI/UX Design',
      description: 'Design system and user experience',
      category: 'core',
      status: 'ready',
      estimatedTime: '50 min',
      dependencies: ['master-prd']
    },
    {
      id: 'performance',
      name: 'Performance Engineering',
      description: 'Optimization and Core Web Vitals',
      category: 'core',
      status: 'ready',
      estimatedTime: '35 min',
      dependencies: ['frontend-architecture']
    },
    {
      id: 'qa-testing',
      name: 'QA/Testing',
      description: 'Testing strategy and automation',
      category: 'core',
      status: 'ready',
      estimatedTime: '40 min',
      dependencies: ['master-prd']
    },
    {
      id: 'analytics',
      name: 'Analytics & Data',
      description: 'Data collection and insights',
      category: 'core',
      status: 'ready',
      estimatedTime: '25 min',
      dependencies: ['master-prd']
    },
    {
      id: 'content-strategy',
      name: 'Content Strategy',
      description: 'User communication and content management',
      category: 'core',
      status: 'ready',
      estimatedTime: '30 min',
      dependencies: ['uiux-design']
    },
    {
      id: 'mobile-development',
      name: 'Mobile Development',
      description: 'Responsive design and mobile applications',
      category: 'core',
      status: 'ready',
      estimatedTime: '45 min',
      dependencies: ['frontend-architecture']
    },
    {
      id: 'accessibility',
      name: 'Accessibility',
      description: 'WCAG compliance and inclusive design',
      category: 'core',
      status: 'ready',
      estimatedTime: '30 min',
      dependencies: ['uiux-design']
    },
    {
      id: 'error-handling',
      name: 'Error Handling',
      description: 'Error management and logging strategies',
      category: 'core',
      status: 'ready',
      estimatedTime: '25 min',
      dependencies: ['backend-architecture']
    },
    {
      id: 'integration',
      name: 'Integration',
      description: 'Third-party services and API integrations',
      category: 'core',
      status: 'ready',
      estimatedTime: '35 min',
      dependencies: ['api-documentation']
    },
    {
      id: 'infrastructure',
      name: 'Infrastructure/DevOps',
      description: 'Deployment, scaling, and operations',
      category: 'core',
      status: 'ready',
      estimatedTime: '40 min',
      dependencies: ['backend-architecture']
    }
  ];

  const specializedTemplates = [
    {
      id: 'ai-ml-integration',
      name: 'AI/ML Integration',
      description: 'Machine learning models and AI features',
      category: 'specialized',
      status: 'ready',
      estimatedTime: '60 min',
      dependencies: ['backend-architecture', 'api-documentation']
    },
    {
      id: 'devops-infrastructure',
      name: 'DevOps Infrastructure',
      description: 'Advanced deployment and scaling strategies',
      category: 'specialized',
      status: 'ready',
      estimatedTime: '55 min',
      dependencies: ['infrastructure']
    },
    {
      id: 'gekb-system',
      name: 'GEKB System',
      description: 'Graph-Enhanced Knowledge Base architecture',
      category: 'specialized',
      status: 'ready',
      estimatedTime: '50 min',
      dependencies: ['database-design', 'ai-ml-integration']
    },
    {
      id: 'mcp-protocol',
      name: 'MCP Protocol',
      description: 'Model Context Protocol implementation',
      category: 'specialized',
      status: 'ready',
      estimatedTime: '45 min',
      dependencies: ['ai-ml-integration']
    }
  ];

  const allTemplates = [...coreTemplates, ...specializedTemplates];

  const filteredTemplates = allTemplates.filter(template => {
    const matchesSearch = template.name.toLowerCase().includes(searchTerm.toLowerCase()) ||
                         template.description.toLowerCase().includes(searchTerm.toLowerCase());
    const matchesCategory = selectedCategory === 'all' || template.category === selectedCategory;
    return matchesSearch && matchesCategory;
  });

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'ready':
        return 'bg-green-100 text-green-800 dark:bg-green-900/20 dark:text-green-400';
      case 'in-progress':
        return 'bg-blue-100 text-blue-800 dark:bg-blue-900/20 dark:text-blue-400';
      case 'pending':
        return 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/20 dark:text-yellow-400';
      default:
        return 'bg-gray-100 text-gray-800 dark:bg-gray-900/20 dark:text-gray-400';
    }
  };

  const handleGeneratePRD = (templateId: string) => {
    // In a real implementation, this would call an API to generate the PRD
    console.log(`Generating PRD for template: ${templateId}`, { projectName, projectType });
    alert(`PRD generation started for ${templateId}!\n\nProject: ${projectName}\nType: ${projectType}\n\nThis would normally trigger the generation process.`);
  };

  const handleBulkGenerate = () => {
    if (!projectName) {
      alert('Please enter a project name first');
      return;
    }
    alert(`Bulk PRD generation started!\n\nProject: ${projectName}\nType: ${projectType}\n\nThis would generate all core PRDs in sequence.`);
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">PRD Generator</h1>
          <p className="text-muted-foreground">
            Generate comprehensive Product Requirements Documents from professional templates
          </p>
        </div>
        <div className="flex space-x-2">
          <Button onClick={handleBulkGenerate} disabled={!projectName}>
            <Zap className="mr-2 h-4 w-4" />
            Generate All Core PRDs
          </Button>
        </div>
      </div>

      {/* Project Configuration */}
      <Card>
        <CardHeader>
          <CardTitle className="flex items-center">
            <Settings className="mr-2 h-5 w-5" />
            Project Configuration
          </CardTitle>
          <CardDescription>
            Configure your project details for PRD generation
          </CardDescription>
        </CardHeader>
        <CardContent className="grid grid-cols-1 md:grid-cols-2 gap-4">
          <div className="space-y-2">
            <Label htmlFor="projectName">Project Name *</Label>
            <Input
              id="projectName"
              placeholder="e.g., TaskFlow, E-commerce Platform"
              value={projectName}
              onChange={(e) => setProjectName(e.target.value)}
            />
          </div>
          <div className="space-y-2">
            <Label htmlFor="projectType">Project Type</Label>
            <Input
              id="projectType"
              placeholder="e.g., SaaS, E-commerce, Mobile App"
              value={projectType}
              onChange={(e) => setProjectType(e.target.value)}
            />
          </div>
        </CardContent>
      </Card>

      {/* Filters and Search */}
      <div className="flex flex-col md:flex-row gap-4">
        <div className="flex-1">
          <div className="relative">
            <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <Input
              placeholder="Search templates..."
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
            All ({allTemplates.length})
          </Button>
          <Button
            variant={selectedCategory === 'core' ? 'default' : 'outline'}
            size="sm"
            onClick={() => setSelectedCategory('core')}
          >
            Core ({coreTemplates.length})
          </Button>
          <Button
            variant={selectedCategory === 'specialized' ? 'default' : 'outline'}
            size="sm"
            onClick={() => setSelectedCategory('specialized')}
          >
            Specialized ({specializedTemplates.length})
          </Button>
        </div>
      </div>

      {/* Templates Grid */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        {filteredTemplates.map((template) => (
          <Card key={template.id} className="relative">
            <CardHeader className="pb-3">
              <div className="flex items-start justify-between">
                <div className="space-y-1">
                  <CardTitle className="text-lg">{template.name}</CardTitle>
                  <div className="flex items-center gap-2">
                    <Badge className={getStatusColor(template.status)}>
                      {template.status}
                    </Badge>
                    <Badge variant="outline" className="text-xs">
                      {template.category}
                    </Badge>
                  </div>
                </div>
                <FileText className="h-5 w-5 text-muted-foreground" />
              </div>
              <CardDescription className="text-sm">
                {template.description}
              </CardDescription>
            </CardHeader>
            <CardContent className="space-y-4">
              <div className="flex items-center justify-between text-sm text-muted-foreground">
                <div className="flex items-center">
                  <Clock className="mr-1 h-3 w-3" />
                  {template.estimatedTime}
                </div>
                <div className="flex items-center">
                  <Folder className="mr-1 h-3 w-3" />
                  {template.dependencies.length} deps
                </div>
              </div>

              {template.dependencies.length > 0 && (
                <div className="space-y-2">
                  <p className="text-xs font-medium text-muted-foreground">Dependencies:</p>
                  <div className="flex flex-wrap gap-1">
                    {template.dependencies.map((dep) => (
                      <Badge key={dep} variant="secondary" className="text-xs">
                        {dep}
                      </Badge>
                    ))}
                  </div>
                </div>
              )}

              <div className="flex gap-2">
                <Button
                  size="sm"
                  onClick={() => handleGeneratePRD(template.id)}
                  disabled={!projectName}
                  className="flex-1"
                >
                  <Download className="mr-1 h-3 w-3" />
                  Generate
                </Button>
                <Link href={`/prd-templates/${template.id}`}>
                  <Button size="sm" variant="outline">
                    <Eye className="h-3 w-3" />
                  </Button>
                </Link>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {filteredTemplates.length === 0 && (
        <div className="text-center py-12">
          <FileText className="mx-auto h-12 w-12 text-muted-foreground" />
          <h3 className="mt-4 text-lg font-medium">No templates found</h3>
          <p className="text-muted-foreground">
            Try adjusting your search or filter criteria
          </p>
        </div>
      )}

      {/* Quick Stats */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center">
              <CheckCircle className="h-4 w-4 text-green-600" />
              <div className="ml-2">
                <p className="text-sm font-medium">Core Templates</p>
                <p className="text-2xl font-bold">{coreTemplates.length}</p>
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
                <p className="text-2xl font-bold">{specializedTemplates.length}</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center">
              <Clock className="h-4 w-4 text-blue-600" />
              <div className="ml-2">
                <p className="text-sm font-medium">Avg. Time</p>
                <p className="text-2xl font-bold">38m</p>
              </div>
            </div>
          </CardContent>
        </Card>
        <Card>
          <CardContent className="pt-6">
            <div className="flex items-center">
              <FileText className="h-4 w-4 text-orange-600" />
              <div className="ml-2">
                <p className="text-sm font-medium">Total Templates</p>
                <p className="text-2xl font-bold">{allTemplates.length}</p>
              </div>
            </div>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}