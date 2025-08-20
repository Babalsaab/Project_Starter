#!/usr/bin/env tsx

import fs from 'fs/promises';
import path from 'path';
import { execSync } from 'child_process';
import { program } from 'commander';

interface SetupConfig {
  name: string;
  description?: string;
  skipInstall?: boolean;
  skipDatabase?: boolean;
}

async function setupProject(config: SetupConfig) {
  console.log(`🚀 Setting up TaskFlow project: ${config.name}`);
  console.log('⏱️  This may take a few minutes...\n');

  try {
    // Step 1: Check prerequisites
    console.log('1️⃣ Checking prerequisites...');
    checkPrerequisites();
    console.log('✅ Prerequisites check passed\n');

    // Step 2: Install dependencies (if not skipped)
    if (!config.skipInstall) {
      console.log('2️⃣ Installing dependencies...');
      execSync('npm install', { stdio: 'inherit' });
      console.log('✅ Dependencies installed\n');
    }

    // Step 3: Setup environment
    console.log('3️⃣ Setting up environment...');
    await setupEnvironment();
    console.log('✅ Environment configured\n');

    // Step 4: Setup database (if not skipped)
    if (!config.skipDatabase) {
      console.log('4️⃣ Setting up database...');
      setupDatabase();
      console.log('✅ Database setup complete\n');
    }

    // Step 5: Generate project summary
    console.log('5️⃣ Generating project documentation...');
    await generateProjectDocs(config);
    console.log('✅ Documentation generated\n');

    // Success message
    console.log('🎉 Setup Complete!');
    console.log('\n📋 Next Steps:');
    console.log('1. npm run dev          # Start development server');
    console.log('2. Open http://localhost:3000');
    console.log('3. Sign in with demo accounts:');
    console.log('   - admin@taskflow.com (Admin)');
    console.log('   - manager@taskflow.com (Manager)');
    console.log('   - alice@taskflow.com (Member)');
    console.log('\n🎯 Happy coding!');

  } catch (error) {
    console.error('\n❌ Setup failed:', error);
    console.log('\n🔧 Troubleshooting:');
    console.log('1. Check Node.js version: node --version (requires 18+)');
    console.log('2. Clear npm cache: npm cache clean --force');
    console.log('3. Delete node_modules and reinstall: rm -rf node_modules && npm install');
    console.log('4. Check setup guide: ./SETUP.md');
    process.exit(1);
  }
}

function checkPrerequisites() {
  // Check Node.js version
  const nodeVersion = process.version;
  const majorVersion = parseInt(nodeVersion.slice(1).split('.')[0]!);
  if (majorVersion < 18) {
    throw new Error(`Node.js 18+ required. Current version: ${nodeVersion}`);
  }

  // Check npm
  try {
    execSync('npm --version', { stdio: 'pipe' });
  } catch (error) {
    throw new Error('npm not found. Please install Node.js with npm.');
  }
}

async function setupEnvironment() {
  const envPath = path.join(process.cwd(), '.env.local');
  const envExamplePath = path.join(process.cwd(), '.env.example');

  try {
    // Check if .env.local already exists
    await fs.access(envPath);
    console.log('  ⚠️  .env.local already exists, skipping...');
  } catch {
    // Copy .env.example to .env.local
    try {
      const envExample = await fs.readFile(envExamplePath, 'utf-8');
      
      // Update with secure defaults
      const envContent = envExample
        .replace('your-nextauth-secret-here', generateSecretKey())
        .replace('http://localhost:3000', 'http://localhost:3000');
      
      await fs.writeFile(envPath, envContent);
      console.log('  ✅ Created .env.local with secure defaults');
    } catch (error) {
      throw new Error(`Failed to create .env.local: ${error}`);
    }
  }
}

function setupDatabase() {
  try {
    // Generate Prisma client
    console.log('  📦 Generating Prisma client...');
    execSync('npx prisma generate', { stdio: 'pipe' });

    // Push database schema
    console.log('  🗄️  Creating database...');
    execSync('npx prisma db push', { stdio: 'pipe' });

    // Seed database
    console.log('  🌱 Seeding database...');
    execSync('npm run db:seed', { stdio: 'pipe' });

  } catch (error) {
    throw new Error(`Database setup failed: ${error}`);
  }
}

async function generateProjectDocs(config: SetupConfig) {
  const projectPath = path.join(process.cwd(), 'PROJECT_INFO.md');
  
  const content = `# ${config.name}

${config.description || 'Professional web application built with TaskFlow template'}

## Setup Information
- **Created**: ${new Date().toLocaleDateString()}
- **Template Version**: 1.0.0
- **Node.js Version**: ${process.version}

## Quick Commands

### Development
\`\`\`bash
npm run dev              # Start development server
npm run build            # Build for production
npm run lint             # Run linting
npm run type-check       # Check TypeScript
\`\`\`

### Database
\`\`\`bash
npm run db:studio        # Open database browser
npm run db:seed          # Re-seed database
npx prisma db push       # Update database schema
\`\`\`

### PRD Generation
\`\`\`bash
npm run generate:master-prd --name "${config.name}"
npm run generate:all-prds --name "${config.name}"
\`\`\`

## Demo Accounts
- **Admin**: admin@taskflow.com
- **Manager**: manager@taskflow.com  
- **Member**: alice@taskflow.com

*Any password works for demo accounts*

## Resources
- [Setup Guide](./SETUP.md)
- [Full Documentation](./README.md)
- [PRD Templates](./prd-system/templates/)

---
*Generated by TaskFlow Setup Script*
`;

  await fs.writeFile(projectPath, content);
}

function generateSecretKey(): string {
  return Math.random().toString(36).substring(2, 15) + 
         Math.random().toString(36).substring(2, 15) +
         Math.random().toString(36).substring(2, 15);
}

// CLI interface
program
  .name('setup-project')
  .description('Setup TaskFlow project with all dependencies and configuration')
  .option('-n, --name <name>', 'Project name', 'TaskFlow Project')
  .option('-d, --description <description>', 'Project description')
  .option('--skip-install', 'Skip npm install')
  .option('--skip-database', 'Skip database setup')
  .action(async (options) => {
    const config: SetupConfig = {
      name: options.name,
      description: options.description,
      skipInstall: options.skipInstall,
      skipDatabase: options.skipDatabase
    };
    
    await setupProject(config);
  });

// Parse CLI arguments if this script is run directly
if (require.main === module) {
  program.parse();
}

export { setupProject };