import { getServerSession } from 'next-auth';
import { redirect } from 'next/navigation';
import { authOptions } from '@/lib/auth';
import { DashboardLayout } from '@/components/layout/dashboard-layout';
import { PRDGenerator } from '@/components/features/prd-generator/prd-generator';

export default async function PRDGeneratorPage() {
  const session = await getServerSession(authOptions);

  if (!session) {
    redirect('/auth/signin');
  }

  return (
    <DashboardLayout>
      <PRDGenerator />
    </DashboardLayout>
  );
}