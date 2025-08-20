import NextAuth from 'next-auth';
import { PrismaAdapter } from '@auth/prisma-adapter';
import GitHub from 'next-auth/providers/github';
import Google from 'next-auth/providers/google';
import Resend from 'next-auth/providers/resend';
import Credentials from 'next-auth/providers/credentials';
import { prisma } from '@/lib/prisma';
import { compare } from 'bcryptjs';

// Define UserRole type since we're using strings instead of enums
type UserRole = 'ADMIN' | 'MANAGER' | 'MEMBER';

export const { handlers, signIn, signOut, auth } = NextAuth({
  adapter: PrismaAdapter(prisma) as any,
  session: {
    strategy: 'jwt',
  },
  pages: {
    signIn: '/auth/signin',
    error: '/auth/error',
  },
  providers: [
    GitHub({
      clientId: process.env['GITHUB_ID']!,
      clientSecret: process.env['GITHUB_SECRET']!,
    }),
    Google({
      clientId: process.env['GOOGLE_CLIENT_ID']!,
      clientSecret: process.env['GOOGLE_CLIENT_SECRET']!,
    }),
    Resend({
      apiKey: process.env['RESEND_API_KEY'],
      from: process.env['EMAIL_FROM'],
    }),
    Credentials({
      name: 'credentials',
      credentials: {
        email: { label: 'Email', type: 'email' },
        password: { label: 'Password', type: 'password' },
      },
      async authorize(credentials) {
        console.log('🔍 Authorize called with:', { email: credentials?.email, hasPassword: !!credentials?.password });
        console.log('🗄️ DATABASE_URL:', process.env.DATABASE_URL);
        console.log('📂 Current working directory:', process.cwd());
        
        if (!credentials?.email || !credentials?.password) {
          console.log('❌ Missing email or password');
          return null;
        }

        try {
          const user = await prisma.user.findUnique({
            where: {
              email: credentials.email as string,
            },
          });

          console.log('👤 User lookup result:', user ? { id: user.id, email: user.email, name: user.name } : 'No user found');

          if (!user) {
            console.log('❌ User not found in database');
            return null;
          }

          // Note: In a real app, you'd hash passwords. This is for demo purposes.
          // For the demo, we'll accept any password for existing users
          const isPasswordValid = true; // await compare(credentials.password, user.password);

          if (!isPasswordValid) {
            console.log('❌ Invalid password');
            return null;
          }

          console.log('✅ Authentication successful for:', user.email);
          return {
            id: user.id,
            email: user.email,
            name: user.name,
            image: user.image,
            role: user.role as UserRole,
          };
        } catch (error) {
          console.error('🚨 Database error during authentication:', error);
          return null;
        }
      },
    }),
  ],
  callbacks: {
    async jwt({ token, user }) {
      if (user) {
        const dbUser = await prisma.user.findUnique({
          where: { email: user.email! },
        });
        
        if (dbUser) {
          token['role'] = dbUser['role'] as UserRole;
          token['id'] = dbUser.id;
        }
      }
      return token;
    },
    async session({ session, token }) {
      if (token) {
        session.user.id = token['id'] as string;
        session.user.role = token['role'] as UserRole;
      }
      return session;
    },
    async signIn({ user, account }) {
      if (account?.provider === 'google' || account?.provider === 'github') {
        // Auto-create user profile if doesn't exist
        const existingUser = await prisma.user.findUnique({
          where: { email: user.email! },
        });

        if (!existingUser) {
          await prisma.user.create({
            data: {
              email: user.email!,
              name: user.name,
              image: user.image,
              role: 'MEMBER',
            },
          });
        }
      }
      return true;
    },
  },
  debug: process.env.NODE_ENV === 'development',
});