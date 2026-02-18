import { redirect } from 'next/navigation';
import { auth } from '../../../auth';
import { DashboardLayout } from '@/components/layout/dashboard-layout';
import { PRDGenerator } from '@/components/features/prd-generator/prd-generator';

export default async function PRDGeneratorPage() {
  const session = await auth();

  if (!session) {
    redirect('/auth/signin');
  }

  return (
    <DashboardLayout>
      <PRDGenerator />
    </DashboardLayout>
  );
}