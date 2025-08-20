# TaskFlow Setup Guide

## ⚡ Quick Start (< 5 minutes)

Follow these steps to get TaskFlow running locally:

### 1. Prerequisites
- Node.js 18+ and npm 9+
- Git

### 2. Clone and Install
```bash
git clone <repository-url> my-project
cd my-project
npm install
```

### 3. Environment Setup
```bash
cp .env.example .env.local
```

### 4. Database Setup
```bash
# Generate Prisma client
npx prisma generate

# Create and seed database
npx prisma db push
npm run db:seed
```

### 5. Start Development Server
```bash
npm run dev
```

🎉 **Open [http://localhost:3000](http://localhost:3000)** and start exploring!

## 🎮 Demo Accounts

The application comes pre-seeded with demo accounts:

| Role | Email | Password | Access Level |
|------|-------|----------|--------------|
| **Admin** | `admin@taskflow.com` | Any password | Full system access |
| **Manager** | `manager@taskflow.com` | Any password | Project & team management |
| **Member** | `alice@taskflow.com` | Any password | Task management |

> **Note**: For demo purposes, any password works with these accounts.

## 🛠 Available Scripts

```bash
# Development
npm run dev              # Start development server
npm run build            # Build for production
npm run start            # Start production server
npm run lint             # Run ESLint
npm run type-check       # TypeScript checking

# Database
npm run db:generate      # Generate Prisma client
npm run db:push          # Push schema to database
npm run db:seed          # Seed with demo data
npm run db:studio        # Open Prisma Studio

# PRD Generation
npm run generate:master-prd    # Generate master PRD
npm run generate:all-prds      # Generate complete PRD suite

# Testing
npm run test             # Run Jest tests
npm run test:e2e         # Run Playwright E2E tests
```

## 🏗 Project Structure

```
professional-dev-template/
├── src/
│   ├── app/                 # Next.js App Router
│   │   ├── api/            # API routes
│   │   ├── auth/           # Authentication pages
│   │   ├── dashboard/      # Main application
│   │   └── prd-templates/  # PRD template browser
│   ├── components/         # React components
│   │   ├── ui/            # shadcn/ui components
│   │   ├── features/      # Feature components
│   │   └── layout/        # Layout components
│   └── lib/               # Utilities and config
├── prd-system/            # PRD templates and docs
├── prisma/                # Database schema
├── scripts/               # Automation scripts
└── generated-prds/        # Generated PRD output
```

## 🎯 Features Working Out of the Box

### ✅ Authentication System
- Multi-provider authentication (GitHub, Google, Email, Credentials)
- Role-based access control
- Demo account system

### ✅ TaskFlow Demo Application
- Complete project management interface
- Dashboard with metrics and activity
- Project and task management
- Team collaboration features

### ✅ PRD Generation System
- 20 professional PRD templates
- Web interface for browsing templates
- Command-line generation tools
- Real template content integration

### ✅ Modern UI/UX
- shadcn/ui component library
- Dark/light theme support
- Responsive design
- Professional styling

## 🔧 Customization

### Update Branding
1. **Logo & Name**: Edit `src/components/layout/sidebar.tsx`
2. **Colors**: Modify `tailwind.config.ts`
3. **Metadata**: Update `src/app/layout.tsx`

### Add OAuth Providers
1. **Configure providers** in `src/lib/auth.ts`
2. **Add environment variables** to `.env.local`
3. **Update sign-in UI** in `src/components/auth/`

### Customize Database
1. **Edit schema** in `prisma/schema.prisma`
2. **Run migration**: `npx prisma db push`
3. **Update seed data** in `prisma/seed.ts`

## 🚀 Production Deployment

### Vercel (Recommended)
1. Push to GitHub
2. Import to Vercel
3. Add environment variables:
   - `DATABASE_URL` (PostgreSQL)
   - `NEXTAUTH_SECRET`
   - `NEXTAUTH_URL`
4. Deploy!

### Manual Deployment
1. Build: `npm run build`
2. Set up PostgreSQL database
3. Run migrations: `npx prisma migrate deploy`
4. Start: `npm start`

## 📝 Environment Variables

### Required
- `DATABASE_URL`: Database connection string
- `NEXTAUTH_SECRET`: Secret for NextAuth.js
- `NEXTAUTH_URL`: Your application URL

### Optional
- `GITHUB_ID` & `GITHUB_SECRET`: GitHub OAuth
- `GOOGLE_CLIENT_ID` & `GOOGLE_CLIENT_SECRET`: Google OAuth

## 🐛 Troubleshooting

### Common Issues

**Port 3000 in use**
```bash
# Server will automatically use port 3001
# Or kill the process: lsof -ti:3000 | xargs kill
```

**Database connection errors**
```bash
# Reset database
npx prisma migrate reset
npm run db:seed
```

**Missing dependencies**
```bash
# Clean install
rm -rf node_modules package-lock.json
npm install
```

**TypeScript errors**
```bash
# Regenerate types
npx prisma generate
npm run type-check
```

## 📚 Additional Resources

- [Next.js Documentation](https://nextjs.org/docs)
- [Prisma Documentation](https://prisma.io/docs)
- [shadcn/ui Documentation](https://ui.shadcn.com)
- [NextAuth.js Documentation](https://next-auth.js.org)

## 🤝 Contributing

1. Fork the repository
2. Create feature branch: `git checkout -b feature/amazing-feature`
3. Commit changes: `npm run commit`
4. Push to branch: `git push origin feature/amazing-feature`
5. Open Pull Request

---

**Need help?** Check the [full documentation](./README.md) or open an issue on GitHub.