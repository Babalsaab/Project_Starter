'use client';

import Link from 'next/link';
import { Button } from '@/components/ui/button';
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from '@/components/ui/card';
import { Zap, CheckCircle, Info } from 'lucide-react';

export function SignUpForm() {
  const benefits = [
    'Complete project management solution',
    'Team collaboration tools',
    'Real-time task tracking',
    'Analytics and insights',
    'Professional PRD templates',
    'Enterprise-grade security'
  ];

  return (
    <div className="w-full max-w-4xl grid lg:grid-cols-2 gap-8 items-center">
      {/* Left side - Benefits */}
      <div className="hidden lg:block space-y-6">
        <div>
          <div className="flex items-center space-x-2 mb-4">
            <div className="h-10 w-10 rounded-lg bg-gradient-to-br from-blue-600 to-purple-600 flex items-center justify-center">
              <Zap className="h-6 w-6 text-white" />
            </div>
            <span className="text-2xl font-bold">TaskFlow</span>
          </div>
          <h1 className="text-3xl font-bold tracking-tight">
            Start your journey with the ultimate project management platform
          </h1>
          <p className="text-lg text-muted-foreground mt-4">
            Join thousands of teams who trust TaskFlow to deliver projects on time and exceed expectations.
          </p>
        </div>

        <div className="space-y-4">
          {benefits.map((benefit, index) => (
            <div key={index} className="flex items-center space-x-3">
              <CheckCircle className="h-5 w-5 text-green-600 flex-shrink-0" />
              <span className="text-sm">{benefit}</span>
            </div>
          ))}
        </div>

        <div className="bg-gradient-to-r from-blue-50 to-purple-50 dark:from-blue-900/20 dark:to-purple-900/20 rounded-lg p-6">
          <h3 className="font-semibold mb-2">Ready to get started?</h3>
          <p className="text-sm text-muted-foreground">
            Contact your administrator to get an account set up for you.
          </p>
        </div>
      </div>

      {/* Right side - Info panel */}
      <div className="w-full max-w-md mx-auto space-y-6">
        <div className="text-center lg:hidden">
          <div className="flex items-center justify-center space-x-2 mb-4">
            <div className="h-10 w-10 rounded-lg bg-gradient-to-br from-blue-600 to-purple-600 flex items-center justify-center">
              <Zap className="h-6 w-6 text-white" />
            </div>
            <span className="text-2xl font-bold">TaskFlow</span>
          </div>
          <h1 className="text-2xl font-semibold tracking-tight">Create account</h1>
          <p className="text-sm text-muted-foreground">
            Contact your administrator to get access
          </p>
        </div>

        <Card>
          <CardHeader className="space-y-1">
            <CardTitle className="text-xl hidden lg:block">Account Access</CardTitle>
            <CardDescription>
              How to get access to TaskFlow
            </CardDescription>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="flex gap-3 p-4 bg-blue-50 dark:bg-blue-900/20 border border-blue-200 dark:border-blue-800 rounded-lg">
              <Info className="h-5 w-5 text-blue-600 flex-shrink-0 mt-0.5" />
              <div className="space-y-1">
                <p className="text-sm font-medium text-blue-900 dark:text-blue-100">
                  Registration is handled by your administrator
                </p>
                <p className="text-sm text-blue-700 dark:text-blue-300">
                  Please contact your administrator for an account, or use the demo login to explore the platform.
                </p>
              </div>
            </div>

            <div className="space-y-3">
              <Link href="/auth/signin">
                <Button className="w-full">
                  Go to Sign In
                </Button>
              </Link>
            </div>
          </CardContent>
        </Card>

        <div className="text-center text-sm">
          <span className="text-muted-foreground">Already have an account? </span>
          <Link href="/auth/signin" className="underline underline-offset-4 hover:text-primary">
            Sign in
          </Link>
        </div>
      </div>
    </div>
  );
}
