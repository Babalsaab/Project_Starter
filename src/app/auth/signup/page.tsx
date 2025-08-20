import { redirect } from 'next/navigation';
import { auth } from '../../../../auth';
import { SignUpForm } from '@/components/auth/signup-form';

export default async function SignUpPage() {
  const session = await auth();

  if (session) {
    redirect('/dashboard');
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-gradient-to-br from-blue-50 via-white to-purple-50 dark:from-gray-900 dark:via-gray-800 dark:to-gray-900">
      <SignUpForm />
    </div>
  );
}