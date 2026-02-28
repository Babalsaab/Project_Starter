import { redirect } from 'next/navigation';
import { auth } from '../../auth';
import { LandingPage } from '@/components/features/landing-page';

export default async function HomePage() {
  const session = await auth();

  if (session) {
    redirect('/dashboard');
  }

  return <LandingPage />;
}