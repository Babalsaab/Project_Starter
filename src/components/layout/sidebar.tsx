'use client';

import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { cn } from '@/lib/utils';
import { Button } from '@/components/ui/button';
import {
  LayoutDashboard,
  FolderOpen,
  CheckSquare,
  Users,
  BarChart3,
  Settings,
  FileText,
  Zap,
  Bot,
  ClipboardCheck,
  RefreshCw,
} from 'lucide-react';

interface SidebarProps {
  open?: boolean;
  onOpenChange?: (open: boolean) => void;
  className?: string;
}

const navigation = [
  {
    name: 'Dashboard',
    href: '/dashboard',
    icon: LayoutDashboard,
  },
  {
    name: 'Projects',
    href: '/projects',
    icon: FolderOpen,
  },
  {
    name: 'Tasks',
    href: '/tasks',
    icon: CheckSquare,
  },
  {
    name: 'Teams',
    href: '/teams',
    icon: Users,
  },
  {
    name: 'Analytics',
    href: '/analytics',
    icon: BarChart3,
  },
  {
    name: 'PRD Generator',
    href: '/prd-generator',
    icon: FileText,
  },
  {
    name: 'Orchestrator',
    href: '/orchestrator',
    icon: Bot,
  },
  {
    name: 'Evaluation',
    href: '/orchestrator/evaluation',
    icon: ClipboardCheck,
  },
  {
    name: 'Improvement',
    href: '/orchestrator/improvement-loop',
    icon: RefreshCw,
  },
  {
    name: 'Settings',
    href: '/settings',
    icon: Settings,
  },
];

export function Sidebar({
  open: _open,
  onOpenChange,
  className,
}: SidebarProps) {
  const pathname = usePathname();

  return (
    <aside className={cn('flex w-64 flex-col border-r bg-card', className)}>
      <div className="flex h-16 items-center px-6">
        <div className="flex items-center space-x-2">
          <div className="flex h-8 w-8 items-center justify-center rounded-lg bg-gradient-to-br from-blue-600 to-purple-600">
            <Zap className="h-4 w-4 text-white" />
          </div>
          <span className="text-xl font-bold">TaskFlow</span>
        </div>
      </div>

      <nav className="flex-1 space-y-1 px-3 py-4">
        {navigation.map((item) => {
          const isActive =
            pathname === item.href || pathname.startsWith(item.href + '/');

          return (
            <Link key={item.href} href={item.href}>
              <Button
                variant={isActive ? 'secondary' : 'ghost'}
                className={cn(
                  'w-full justify-start',
                  isActive && 'bg-secondary font-medium'
                )}
                onClick={() => onOpenChange?.(false)}
              >
                <item.icon className="mr-3 h-4 w-4" />
                {item.name}
              </Button>
            </Link>
          );
        })}
      </nav>

      <div className="border-t px-3 py-4">
        <div className="rounded-lg bg-gradient-to-r from-blue-600 to-purple-600 p-3 text-white">
          <h3 className="text-sm font-medium">PRD Generation</h3>
          <p className="mt-1 text-xs opacity-90">
            Generate professional PRDs from templates
          </p>
          <Link href="/prd-generator">
            <Button
              size="sm"
              variant="secondary"
              className="mt-2 w-full"
              onClick={() => onOpenChange?.(false)}
            >
              Try Now
            </Button>
          </Link>
        </div>
      </div>
    </aside>
  );
}
