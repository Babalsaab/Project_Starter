'use client';

import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Badge } from '@/components/ui/badge';
import { Button } from '@/components/ui/button';
import { Avatar, AvatarFallback, AvatarImage } from '@/components/ui/avatar';
import { 
  FolderOpen,
  CheckSquare,
  Users,
  Clock,
  TrendingUp,
  AlertCircle,
  Plus,
  ArrowRight
} from 'lucide-react';
import Link from 'next/link';

export function DashboardOverview() {
  // Mock data - in real app this would come from API
  const stats = [
    {
      title: 'Active Projects',
      value: '12',
      change: '+2 from last month',
      icon: FolderOpen,
      color: 'text-blue-600'
    },
    {
      title: 'Pending Tasks',
      value: '34',
      change: '-8 from last week',
      icon: CheckSquare,
      color: 'text-orange-600'
    },
    {
      title: 'Team Members',
      value: '8',
      change: '+1 new member',
      icon: Users,
      color: 'text-green-600'
    },
    {
      title: 'Overdue Tasks',
      value: '3',
      change: 'Need attention',
      icon: AlertCircle,
      color: 'text-red-600'
    }
  ];

  const recentProjects = [
    {
      id: '1',
      name: 'TaskFlow Web Application',
      description: 'Complete redesign and rebuild of the TaskFlow web application',
      status: 'In Progress',
      progress: 65,
      team: ['Alice Cooper', 'Bob Smith', 'Carol Williams'],
      dueDate: '2024-06-30'
    },
    {
      id: '2',
      name: 'Mobile Application Development',
      description: 'Native mobile applications for iOS and Android platforms',
      status: 'Planning',
      progress: 15,
      team: ['Alice Cooper', 'Bob Smith'],
      dueDate: '2024-10-31'
    },
    {
      id: '3',
      name: 'Design System 2.0',
      description: 'Comprehensive design system with components and documentation',
      status: 'In Progress',
      progress: 40,
      team: ['Carol Williams'],
      dueDate: '2024-05-15'
    }
  ];

  const recentActivity = [
    {
      id: '1',
      action: 'completed',
      entity: 'task',
      name: 'Set up Next.js project structure',
      user: 'Alice Cooper',
      time: '2 hours ago'
    },
    {
      id: '2',
      action: 'commented',
      entity: 'task',
      name: 'Implement user authentication',
      user: 'Sarah Johnson',
      time: '4 hours ago'
    },
    {
      id: '3',
      action: 'created',
      entity: 'project',
      name: 'Design System 2.0',
      user: 'Sarah Johnson',
      time: '1 day ago'
    },
    {
      id: '4',
      action: 'assigned',
      entity: 'task',
      name: 'Create dashboard layout',
      user: 'Sarah Johnson',
      time: '2 days ago'
    }
  ];

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'In Progress':
        return 'bg-blue-100 text-blue-800 dark:bg-blue-900/20 dark:text-blue-400';
      case 'Planning':
        return 'bg-yellow-100 text-yellow-800 dark:bg-yellow-900/20 dark:text-yellow-400';
      case 'Completed':
        return 'bg-green-100 text-green-800 dark:bg-green-900/20 dark:text-green-400';
      default:
        return 'bg-gray-100 text-gray-800 dark:bg-gray-900/20 dark:text-gray-400';
    }
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-3xl font-bold tracking-tight">Dashboard</h1>
          <p className="text-muted-foreground">
            Welcome back! Here's what's happening with your projects.
          </p>
        </div>
        <div className="flex space-x-2">
          <Link href="/projects/new">
            <Button>
              <Plus className="mr-2 h-4 w-4" />
              New Project
            </Button>
          </Link>
        </div>
      </div>

      {/* Stats Grid */}
      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-4">
        {stats.map((stat) => (
          <Card key={stat.title}>
            <CardHeader className="flex flex-row items-center justify-between space-y-0 pb-2">
              <CardTitle className="text-sm font-medium">
                {stat.title}
              </CardTitle>
              <stat.icon className={`h-4 w-4 ${stat.color}`} />
            </CardHeader>
            <CardContent>
              <div className="text-2xl font-bold">{stat.value}</div>
              <p className="text-xs text-muted-foreground">
                {stat.change}
              </p>
            </CardContent>
          </Card>
        ))}
      </div>

      <div className="grid gap-6 lg:grid-cols-2">
        {/* Recent Projects */}
        <Card>
          <CardHeader>
            <div className="flex items-center justify-between">
              <div>
                <CardTitle>Recent Projects</CardTitle>
                <CardDescription>
                  Your most active projects
                </CardDescription>
              </div>
              <Link href="/projects">
                <Button variant="outline" size="sm">
                  View All
                  <ArrowRight className="ml-2 h-4 w-4" />
                </Button>
              </Link>
            </div>
          </CardHeader>
          <CardContent className="space-y-4">
            {recentProjects.map((project) => (
              <div key={project.id} className="space-y-2">
                <div className="flex items-center justify-between">
                  <div className="space-y-1">
                    <Link 
                      href={`/projects/${project.id}`}
                      className="font-medium hover:underline"
                    >
                      {project.name}
                    </Link>
                    <p className="text-sm text-muted-foreground">
                      {project.description}
                    </p>
                  </div>
                  <Badge className={getStatusColor(project.status)}>
                    {project.status}
                  </Badge>
                </div>
                
                <div className="flex items-center justify-between text-sm">
                  <div className="flex items-center space-x-2">
                    <div className="flex -space-x-2">
                      {project.team.slice(0, 3).map((member, index) => (
                        <Avatar key={index} className="h-6 w-6 border-2 border-background">
                          <AvatarFallback className="text-xs">
                            {member.split(' ').map(n => n[0]).join('')}
                          </AvatarFallback>
                        </Avatar>
                      ))}
                      {project.team.length > 3 && (
                        <div className="flex h-6 w-6 items-center justify-center rounded-full border-2 border-background bg-muted text-xs">
                          +{project.team.length - 3}
                        </div>
                      )}
                    </div>
                  </div>
                  <div className="flex items-center space-x-2">
                    <Clock className="h-3 w-3" />
                    <span className="text-muted-foreground">{project.dueDate}</span>
                  </div>
                </div>
                
                <div className="space-y-1">
                  <div className="flex justify-between text-sm">
                    <span>Progress</span>
                    <span>{project.progress}%</span>
                  </div>
                  <div className="h-2 rounded-full bg-secondary">
                    <div 
                      className="h-2 rounded-full bg-primary transition-all"
                      style={{ width: `${project.progress}%` }}
                    />
                  </div>
                </div>
              </div>
            ))}
          </CardContent>
        </Card>

        {/* Recent Activity */}
        <Card>
          <CardHeader>
            <CardTitle>Recent Activity</CardTitle>
            <CardDescription>
              Latest updates from your team
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            {recentActivity.map((activity) => (
              <div key={activity.id} className="flex items-start space-x-3">
                <div className="mt-1">
                  {activity.action === 'completed' && (
                    <div className="flex h-6 w-6 items-center justify-center rounded-full bg-green-100 dark:bg-green-900/20">
                      <CheckSquare className="h-3 w-3 text-green-600 dark:text-green-400" />
                    </div>
                  )}
                  {activity.action === 'commented' && (
                    <div className="flex h-6 w-6 items-center justify-center rounded-full bg-blue-100 dark:bg-blue-900/20">
                      <TrendingUp className="h-3 w-3 text-blue-600 dark:text-blue-400" />
                    </div>
                  )}
                  {activity.action === 'created' && (
                    <div className="flex h-6 w-6 items-center justify-center rounded-full bg-purple-100 dark:bg-purple-900/20">
                      <Plus className="h-3 w-3 text-purple-600 dark:text-purple-400" />
                    </div>
                  )}
                  {activity.action === 'assigned' && (
                    <div className="flex h-6 w-6 items-center justify-center rounded-full bg-orange-100 dark:bg-orange-900/20">
                      <Users className="h-3 w-3 text-orange-600 dark:text-orange-400" />
                    </div>
                  )}
                </div>
                <div className="flex-1 space-y-1">
                  <p className="text-sm">
                    <span className="font-medium">{activity.user}</span>{' '}
                    {activity.action} {activity.entity}{' '}
                    <span className="font-medium">"{activity.name}"</span>
                  </p>
                  <p className="text-xs text-muted-foreground">
                    {activity.time}
                  </p>
                </div>
              </div>
            ))}
          </CardContent>
        </Card>
      </div>
    </div>
  );
}