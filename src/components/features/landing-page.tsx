'use client';

import Link from 'next/link';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { 
  CheckCircle, 
  Users, 
  BarChart3, 
  Shield, 
  Zap, 
  Code,
  ArrowRight,
  Github,
  Star,
  GitBranch
} from 'lucide-react';

export function LandingPage() {
  const features = [
    {
      icon: <CheckCircle className="h-6 w-6" />,
      title: 'Task Management',
      description: 'Complete task lifecycle with Kanban boards, assignees, and progress tracking.'
    },
    {
      icon: <Users className="h-6 w-6" />,
      title: 'Team Collaboration',
      description: 'Real-time collaboration with comments, notifications, and team management.'
    },
    {
      icon: <BarChart3 className="h-6 w-6" />,
      title: 'Analytics Dashboard',
      description: 'Comprehensive insights with charts, metrics, and performance tracking.'
    },
    {
      icon: <Shield className="h-6 w-6" />,
      title: 'Enterprise Security',
      description: 'Role-based access control, OAuth integration, and data encryption.'
    },
    {
      icon: <Zap className="h-6 w-6" />,
      title: 'High Performance',
      description: 'Built with Next.js 14, optimized for speed and Core Web Vitals.'
    },
    {
      icon: <Code className="h-6 w-6" />,
      title: 'Developer Experience',
      description: 'TypeScript, shadcn/ui, Prisma, and comprehensive testing setup.'
    }
  ];

  const techStack = [
    'Next.js 14',
    'TypeScript',
    'Prisma',
    'NextAuth.js',
    'shadcn/ui',
    'Tailwind CSS',
    'React Query',
    'Jest + Playwright'
  ];

  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-50 via-white to-purple-50 dark:from-gray-900 dark:via-gray-800 dark:to-gray-900">
      {/* Header */}
      <header className="border-b bg-white/80 backdrop-blur-sm dark:bg-gray-900/80">
        <div className="container mx-auto px-4 py-4">
          <div className="flex items-center justify-between">
            <div className="flex items-center space-x-2">
              <div className="h-8 w-8 rounded-lg bg-gradient-to-br from-blue-600 to-purple-600" />
              <span className="text-xl font-bold">TaskFlow</span>
            </div>
            <div className="flex items-center space-x-4">
              <Link href="/auth/signin">
                <Button variant="ghost">Sign In</Button>
              </Link>
              <Link href="/auth/signup">
                <Button>Get Started</Button>
              </Link>
            </div>
          </div>
        </div>
      </header>

      {/* Hero Section */}
      <section className="py-20">
        <div className="container mx-auto px-4 text-center">
          <div className="mx-auto max-w-4xl">
            <Badge variant="secondary" className="mb-4">
              Professional Development Template
            </Badge>
            <h1 className="mb-6 text-5xl font-bold leading-tight">
              The Ultimate Starting Point for{' '}
              <span className="bg-gradient-to-r from-blue-600 to-purple-600 bg-clip-text text-transparent">
                Web Applications
              </span>
            </h1>
            <p className="mb-8 text-xl text-muted-foreground">
              Complete Next.js application with authentication, project management, 
              team collaboration, and a comprehensive PRD generation system. 
              Save months of development time with production-ready code.
            </p>
            <div className="flex flex-col gap-4 sm:flex-row sm:justify-center">
              <Link href="/auth/signup">
                <Button size="lg" className="w-full sm:w-auto">
                  Try Live Demo
                  <ArrowRight className="ml-2 h-4 w-4" />
                </Button>
              </Link>
              <a href="https://github.com/Babalsaab/Project_Starter" target="_blank" rel="noopener noreferrer">
                <Button variant="outline" size="lg" className="w-full sm:w-auto">
                  <Github className="mr-2 h-4 w-4" />
                  View Source Code
                </Button>
              </a>
            </div>
          </div>
        </div>
      </section>

      {/* Features Section */}
      <section className="py-20">
        <div className="container mx-auto px-4">
          <div className="mb-16 text-center">
            <h2 className="mb-4 text-3xl font-bold">Everything You Need</h2>
            <p className="text-lg text-muted-foreground">
              A complete foundation for any web application project
            </p>
          </div>
          <div className="grid gap-6 md:grid-cols-2 lg:grid-cols-3">
            {features.map((feature, index) => (
              <Card key={index} className="border-0 bg-white/50 backdrop-blur-sm dark:bg-gray-800/50">
                <CardHeader>
                  <div className="mb-2 flex h-12 w-12 items-center justify-center rounded-lg bg-gradient-to-br from-blue-600 to-purple-600 text-white">
                    {feature.icon}
                  </div>
                  <CardTitle className="text-xl">{feature.title}</CardTitle>
                </CardHeader>
                <CardContent>
                  <CardDescription className="text-base">
                    {feature.description}
                  </CardDescription>
                </CardContent>
              </Card>
            ))}
          </div>
        </div>
      </section>

      {/* Demo Section */}
      <section className="py-20 bg-white dark:bg-gray-900">
        <div className="container mx-auto px-4">
          <div className="grid gap-12 lg:grid-cols-2">
            <div>
              <h2 className="mb-6 text-3xl font-bold">
                Working Demo Application
              </h2>
              <p className="mb-6 text-lg text-muted-foreground">
                See TaskFlow in action with a complete project management application 
                featuring real data, interactive components, and all the features 
                you&apos;d expect from a modern web app.
              </p>
              <ul className="mb-8 space-y-3">
                <li className="flex items-center">
                  <CheckCircle className="mr-3 h-5 w-5 text-green-600" />
                  Complete user authentication system
                </li>
                <li className="flex items-center">
                  <CheckCircle className="mr-3 h-5 w-5 text-green-600" />
                  Interactive Kanban boards
                </li>
                <li className="flex items-center">
                  <CheckCircle className="mr-3 h-5 w-5 text-green-600" />
                  Real-time team collaboration
                </li>
                <li className="flex items-center">
                  <CheckCircle className="mr-3 h-5 w-5 text-green-600" />
                  Analytics and reporting
                </li>
              </ul>
              <Link href="/auth/signin">
                <Button size="lg">
                  Explore Demo
                  <ArrowRight className="ml-2 h-4 w-4" />
                </Button>
              </Link>
            </div>
            <div className="rounded-lg bg-gradient-to-br from-blue-600 to-purple-600 p-1">
              <div className="rounded-lg bg-white p-6 dark:bg-gray-900">
                <div className="mb-4 flex items-center justify-between">
                  <div className="flex items-center space-x-2">
                    <div className="h-3 w-3 rounded-full bg-red-500" />
                    <div className="h-3 w-3 rounded-full bg-yellow-500" />
                    <div className="h-3 w-3 rounded-full bg-green-500" />
                  </div>
                  <span className="text-sm text-muted-foreground">taskflow.demo</span>
                </div>
                <div className="space-y-3">
                  <div className="h-4 w-3/4 rounded bg-gray-200 dark:bg-gray-700" />
                  <div className="h-4 w-1/2 rounded bg-gray-200 dark:bg-gray-700" />
                  <div className="grid grid-cols-3 gap-2">
                    <div className="h-16 rounded bg-blue-100 dark:bg-blue-900/20" />
                    <div className="h-16 rounded bg-purple-100 dark:bg-purple-900/20" />
                    <div className="h-16 rounded bg-green-100 dark:bg-green-900/20" />
                  </div>
                  <div className="h-4 w-2/3 rounded bg-gray-200 dark:bg-gray-700" />
                </div>
              </div>
            </div>
          </div>
        </div>
      </section>

      {/* Tech Stack Section */}
      <section className="py-20">
        <div className="container mx-auto px-4">
          <div className="mb-16 text-center">
            <h2 className="mb-4 text-3xl font-bold">Modern Technology Stack</h2>
            <p className="text-lg text-muted-foreground">
              Built with the latest and greatest web technologies
            </p>
          </div>
          <div className="grid gap-4 md:grid-cols-4 lg:grid-cols-8">
            {techStack.map((tech) => (
              <Card key={tech} className="border-0 bg-white/50 p-4 text-center backdrop-blur-sm dark:bg-gray-800/50">
                <span className="text-sm font-medium">{tech}</span>
              </Card>
            ))}
          </div>
        </div>
      </section>

      {/* PRD System Section */}
      <section className="py-20 bg-white dark:bg-gray-900">
        <div className="container mx-auto px-4">
          <div className="grid gap-12 lg:grid-cols-2">
            <div className="order-2 lg:order-1">
              <Card className="border-0 bg-gradient-to-br from-blue-50 to-purple-50 p-6 dark:from-blue-900/20 dark:to-purple-900/20">
                <div className="mb-4 flex items-center space-x-2">
                  <GitBranch className="h-5 w-5" />
                  <span className="font-mono text-sm">generate-prds.ts</span>
                </div>
                <div className="font-mono text-sm">
                  <div className="text-blue-600 dark:text-blue-400">npm run</div>
                  <div className="ml-4 text-green-600 dark:text-green-400">generate:master-prd</div>
                  <div className="ml-4 text-green-600 dark:text-green-400">generate:core-prds</div>
                  <div className="ml-4 text-green-600 dark:text-green-400">generate:specialized-prds</div>
                  <div className="mt-2 text-gray-600 dark:text-gray-400">
                    ✓ Generated 16 PRD templates<br />
                    ✓ Created design.md companion<br />
                    ✓ Generated tasks breakdown
                  </div>
                </div>
              </Card>
            </div>
            <div className="order-1 lg:order-2">
              <h2 className="mb-6 text-3xl font-bold">
                Complete PRD Generation System
              </h2>
              <p className="mb-6 text-lg text-muted-foreground">
                Generate comprehensive Product Requirements Documents from 16 professional 
                templates covering every aspect of software development.
              </p>
              <ul className="mb-8 space-y-3">
                <li className="flex items-center">
                  <Star className="mr-3 h-5 w-5 text-yellow-600" />
                  16 Core PRD Templates
                </li>
                <li className="flex items-center">
                  <Star className="mr-3 h-5 w-5 text-yellow-600" />
                  AI/ML & DevOps Specialized Templates
                </li>
                <li className="flex items-center">
                  <Star className="mr-3 h-5 w-5 text-yellow-600" />
                  Automated Design & Task Generation
                </li>
                <li className="flex items-center">
                  <Star className="mr-3 h-5 w-5 text-yellow-600" />
                  Cross-PRD Dependency Validation
                </li>
              </ul>
              <Link href="/prd-templates">
                <Button variant="outline" size="lg">
                  View PRD Templates
                  <ArrowRight className="ml-2 h-4 w-4" />
                </Button>
              </Link>
            </div>
          </div>
        </div>
      </section>

      {/* CTA Section */}
      <section className="py-20">
        <div className="container mx-auto px-4 text-center">
          <div className="mx-auto max-w-2xl">
            <h2 className="mb-6 text-3xl font-bold">
              Start Building Today
            </h2>
            <p className="mb-8 text-lg text-muted-foreground">
              Skip months of setup and configuration. Get a production-ready 
              foundation for your next web application project.
            </p>
            <div className="flex flex-col gap-4 sm:flex-row sm:justify-center">
              <Link href="/auth/signup">
                <Button size="lg" className="w-full sm:w-auto">
                  Get Started Now
                  <ArrowRight className="ml-2 h-4 w-4" />
                </Button>
              </Link>
              <a href="https://github.com/Babalsaab/Project_Starter" target="_blank" rel="noopener noreferrer">
                <Button variant="outline" size="lg" className="w-full sm:w-auto">
                  <Github className="mr-2 h-4 w-4" />
                  Clone Repository
                </Button>
              </a>
            </div>
          </div>
        </div>
      </section>

      {/* Footer */}
      <footer className="border-t bg-white/80 backdrop-blur-sm dark:bg-gray-900/80">
        <div className="container mx-auto px-4 py-8">
          <div className="flex flex-col items-center justify-between md:flex-row">
            <div className="mb-4 flex items-center space-x-2 md:mb-0">
              <div className="h-6 w-6 rounded bg-gradient-to-br from-blue-600 to-purple-600" />
              <span className="font-bold">TaskFlow</span>
            </div>
            <p className="text-sm text-muted-foreground">
              Professional Development Template Repository - Built with ❤️ for developers
            </p>
          </div>
        </div>
      </footer>
    </div>
  );
}