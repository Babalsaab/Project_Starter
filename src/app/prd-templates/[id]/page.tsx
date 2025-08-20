import { notFound } from 'next/navigation';
import { PRDTemplateView } from '@/components/features/prd-templates/prd-template-view';

interface PRDTemplatePageProps {
  params: Promise<{
    id: string;
  }>;
}

export default async function PRDTemplatePage({ params }: PRDTemplatePageProps) {
  const { id } = await params;
  
  const validTemplates = [
    'master-prd',
    'frontend-architecture',
    'backend-architecture',
    'database-design',
    'security',
    'api-documentation',
    'uiux-design',
    'performance',
    'qa-testing',
    'analytics',
    'content-strategy',
    'mobile-development',
    'accessibility',
    'error-handling',
    'integration',
    'infrastructure',
    'ai-ml-integration',
    'devops-infrastructure',
    'gekb-system',
    'mcp-protocol'
  ];

  if (!validTemplates.includes(id)) {
    notFound();
  }

  return <PRDTemplateView templateId={id} />;
}