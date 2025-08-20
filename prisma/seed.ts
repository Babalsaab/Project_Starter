import { PrismaClient } from '@prisma/client';
import { hash } from 'bcryptjs';

const prisma = new PrismaClient();

async function main() {
  console.log('Starting database seed...');

  // Create demo users
  const adminUser = await prisma.user.upsert({
    where: { email: 'admin@taskflow.com' },
    update: {},
    create: {
      email: 'admin@taskflow.com',
      name: 'Admin User',
      role: 'ADMIN',
      title: 'System Administrator',
      department: 'IT',
      location: 'San Francisco, CA',
      timezone: 'America/Los_Angeles',
      bio: 'System administrator with 10+ years of experience in managing enterprise applications.',
      preferences: JSON.stringify({
        theme: 'dark',
        notifications: { email: true, browser: true },
        dashboardLayout: 'grid'
      })
    },
  });

  const managerUser = await prisma.user.upsert({
    where: { email: 'manager@taskflow.com' },
    update: {},
    create: {
      email: 'manager@taskflow.com',
      name: 'Sarah Johnson',
      role: 'MANAGER',
      title: 'Project Manager',
      department: 'Product',
      location: 'New York, NY',
      timezone: 'America/New_York',
      bio: 'Experienced project manager specializing in agile methodologies and team leadership.',
      preferences: JSON.stringify({
        theme: 'light',
        notifications: { email: true, browser: true },
        dashboardLayout: 'list'
      })
    },
  });

  const memberUsers = await Promise.all([
    prisma.user.upsert({
      where: { email: 'alice@taskflow.com' },
      update: {},
      create: {
        email: 'alice@taskflow.com',
        name: 'Alice Cooper',
        role: 'MEMBER',
        title: 'Frontend Developer',
        department: 'Engineering',
        location: 'Austin, TX',
        timezone: 'America/Chicago',
        bio: 'Frontend developer with expertise in React and TypeScript.',
        preferences: JSON.stringify({
          theme: 'light',
          notifications: { email: false, browser: true },
          dashboardLayout: 'grid'
        })
      },
    }),
    prisma.user.upsert({
      where: { email: 'bob@taskflow.com' },
      update: {},
      create: {
        email: 'bob@taskflow.com',
        name: 'Bob Smith',
        role: 'MEMBER',
        title: 'Backend Developer',
        department: 'Engineering',
        location: 'Seattle, WA',
        timezone: 'America/Los_Angeles',
        bio: 'Backend developer experienced in Node.js and database optimization.',
        preferences: JSON.stringify({
          theme: 'dark',
          notifications: { email: true, browser: false },
          dashboardLayout: 'list'
        })
      },
    }),
    prisma.user.upsert({
      where: { email: 'carol@taskflow.com' },
      update: {},
      create: {
        email: 'carol@taskflow.com',
        name: 'Carol Williams',
        role: 'MEMBER',
        title: 'UX Designer',
        department: 'Design',
        location: 'Los Angeles, CA',
        timezone: 'America/Los_Angeles',
        bio: 'UX designer passionate about creating intuitive user experiences.',
        preferences: JSON.stringify({
          theme: 'light',
          notifications: { email: true, browser: true },
          dashboardLayout: 'grid'
        })
      },
    }),
  ]);

  // Create teams
  const engineeringTeam = await prisma.team.create({
    data: {
      name: 'Engineering Team',
      description: 'Full-stack development team responsible for building and maintaining the platform.',
      color: '#3B82F6',
      ownerId: managerUser.id,
      settings: JSON.stringify({
        defaultTaskPriority: 'MEDIUM',
        autoAssignment: true,
        standupsEnabled: true
      })
    },
  });

  const designTeam = await prisma.team.create({
    data: {
      name: 'Design Team',
      description: 'Creative team focused on user experience and visual design.',
      color: '#EC4899',
      ownerId: managerUser.id,
      settings: JSON.stringify({
        defaultTaskPriority: 'HIGH',
        autoAssignment: false,
        standupsEnabled: false
      })
    },
  });

  // Add team members
  await Promise.all([
    prisma.teamMember.create({
      data: {
        teamId: engineeringTeam.id,
        userId: memberUsers[0].id, // Alice
        role: 'MEMBER',
      },
    }),
    prisma.teamMember.create({
      data: {
        teamId: engineeringTeam.id,
        userId: memberUsers[1].id, // Bob
        role: 'MEMBER',
      },
    }),
    prisma.teamMember.create({
      data: {
        teamId: designTeam.id,
        userId: memberUsers[2].id, // Carol
        role: 'MEMBER',
      },
    }),
  ]);

  // Create projects
  const webAppProject = await prisma.project.create({
    data: {
      name: 'TaskFlow Web Application',
      description: 'Complete redesign and rebuild of the TaskFlow web application with modern technologies.',
      status: 'IN_PROGRESS',
      priority: 'HIGH',
      color: '#10B981',
      startDate: new Date('2024-01-15'),
      endDate: new Date('2024-06-30'),
      budget: 150000,
      progress: 65,
      tags: 'frontend,backend,ui/ux,priority',
      ownerId: managerUser.id,
      teamId: engineeringTeam.id,
      settings: JSON.stringify({
        allowGuestAccess: false,
        autoProgressUpdate: true,
        deadlineNotifications: true
      })
    },
  });

  const mobileAppProject = await prisma.project.create({
    data: {
      name: 'Mobile Application Development',
      description: 'Native mobile applications for iOS and Android platforms.',
      status: 'PLANNING',
      priority: 'MEDIUM',
      color: '#8B5CF6',
      startDate: new Date('2024-03-01'),
      endDate: new Date('2024-10-31'),
      budget: 200000,
      progress: 15,
      tags: 'mobile,ios,android,react-native',
      ownerId: managerUser.id,
      teamId: engineeringTeam.id,
      settings: JSON.stringify({
        allowGuestAccess: false,
        autoProgressUpdate: false,
        deadlineNotifications: true
      })
    },
  });

  const designSystemProject = await prisma.project.create({
    data: {
      name: 'Design System 2.0',
      description: 'Comprehensive design system with components, guidelines, and documentation.',
      status: 'IN_PROGRESS',
      priority: 'HIGH',
      color: '#F59E0B',
      startDate: new Date('2024-02-01'),
      endDate: new Date('2024-05-15'),
      budget: 75000,
      progress: 40,
      tags: 'design,components,documentation',
      ownerId: managerUser.id,
      teamId: designTeam.id,
      settings: JSON.stringify({
        allowGuestAccess: true,
        autoProgressUpdate: true,
        deadlineNotifications: false
      })
    },
  });

  // Add project members
  await Promise.all([
    // Web App Project
    prisma.projectMember.create({
      data: { projectId: webAppProject.id, userId: memberUsers[0].id, role: 'MEMBER' },
    }),
    prisma.projectMember.create({
      data: { projectId: webAppProject.id, userId: memberUsers[1].id, role: 'MEMBER' },
    }),
    prisma.projectMember.create({
      data: { projectId: webAppProject.id, userId: memberUsers[2].id, role: 'MEMBER' },
    }),
    // Mobile App Project
    prisma.projectMember.create({
      data: { projectId: mobileAppProject.id, userId: memberUsers[0].id, role: 'MEMBER' },
    }),
    prisma.projectMember.create({
      data: { projectId: mobileAppProject.id, userId: memberUsers[1].id, role: 'MEMBER' },
    }),
    // Design System Project
    prisma.projectMember.create({
      data: { projectId: designSystemProject.id, userId: memberUsers[2].id, role: 'MEMBER' },
    }),
  ]);

  // Create tasks
  const tasks = [
    // Web App Project Tasks
    {
      title: 'Set up Next.js project structure',
      description: 'Initialize Next.js 14 project with TypeScript, ESLint, and Prettier configuration.',
      status: 'DONE',
      priority: 'HIGH',
      tags: 'setup,nextjs,typescript',
      projectId: webAppProject.id,
      assigneeId: memberUsers[0].id,
      creatorId: managerUser.id,
      dueDate: new Date('2024-01-20'),
      completedAt: new Date('2024-01-18'),
      estimatedHours: 8,
      actualHours: 6,
      position: 1,
    },
    {
      title: 'Design authentication flow',
      description: 'Create wireframes and user flows for login, registration, and password reset.',
      status: 'DONE',
      priority: 'HIGH',
      tags: 'design,auth,wireframes',
      projectId: webAppProject.id,
      assigneeId: memberUsers[2].id,
      creatorId: managerUser.id,
      dueDate: new Date('2024-01-25'),
      completedAt: new Date('2024-01-23'),
      estimatedHours: 16,
      actualHours: 18,
      position: 2,
    },
    {
      title: 'Implement user authentication',
      description: 'Integrate NextAuth.js with email/password and OAuth providers.',
      status: 'IN_PROGRESS',
      priority: 'HIGH',
      tags: 'backend,auth,nextauth',
      projectId: webAppProject.id,
      assigneeId: memberUsers[1].id,
      creatorId: managerUser.id,
      dueDate: new Date('2024-02-05'),
      estimatedHours: 24,
      actualHours: 16,
      position: 3,
    },
    {
      title: 'Create dashboard layout',
      description: 'Build responsive dashboard with sidebar navigation and main content area.',
      status: 'IN_PROGRESS',
      priority: 'MEDIUM',
      tags: 'frontend,layout,responsive',
      projectId: webAppProject.id,
      assigneeId: memberUsers[0].id,
      creatorId: managerUser.id,
      dueDate: new Date('2024-02-10'),
      estimatedHours: 20,
      actualHours: 12,
      position: 4,
    },
    {
      title: 'Set up database schema',
      description: 'Design and implement Prisma schema for users, projects, and tasks.',
      status: 'REVIEW',
      priority: 'HIGH',
      tags: 'database,prisma,schema',
      projectId: webAppProject.id,
      assigneeId: memberUsers[1].id,
      creatorId: managerUser.id,
      dueDate: new Date('2024-01-30'),
      estimatedHours: 12,
      actualHours: 14,
      position: 5,
    },
    {
      title: 'Implement task management UI',
      description: 'Create task list, creation form, and editing interface.',
      status: 'TODO',
      priority: 'MEDIUM',
      tags: 'frontend,tasks,ui',
      projectId: webAppProject.id,
      assigneeId: memberUsers[0].id,
      creatorId: managerUser.id,
      dueDate: new Date('2024-02-15'),
      estimatedHours: 32,
      position: 6,
    },
    // Mobile App Project Tasks
    {
      title: 'Research mobile frameworks',
      description: 'Evaluate React Native vs Flutter vs native development approaches.',
      status: 'IN_PROGRESS',
      priority: 'HIGH',
      tags: 'research,mobile,framework',
      projectId: mobileAppProject.id,
      assigneeId: memberUsers[0].id,
      creatorId: managerUser.id,
      dueDate: new Date('2024-03-15'),
      estimatedHours: 40,
      actualHours: 24,
      position: 1,
    },
    {
      title: 'Create mobile app mockups',
      description: 'Design high-fidelity mockups for key mobile screens.',
      status: 'TODO',
      priority: 'MEDIUM',
      tags: 'design,mobile,mockups',
      projectId: mobileAppProject.id,
      assigneeId: memberUsers[2].id,
      creatorId: managerUser.id,
      dueDate: new Date('2024-03-30'),
      estimatedHours: 60,
      position: 2,
    },
    // Design System Project Tasks
    {
      title: 'Audit current components',
      description: 'Review existing UI components and identify inconsistencies.',
      status: 'DONE',
      priority: 'MEDIUM',
      tags: 'audit,components,design',
      projectId: designSystemProject.id,
      assigneeId: memberUsers[2].id,
      creatorId: managerUser.id,
      dueDate: new Date('2024-02-10'),
      completedAt: new Date('2024-02-08'),
      estimatedHours: 16,
      actualHours: 14,
      position: 1,
    },
    {
      title: 'Create component library structure',
      description: 'Set up Storybook and define component organization.',
      status: 'IN_PROGRESS',
      priority: 'HIGH',
      tags: 'storybook,components,structure',
      projectId: designSystemProject.id,
      assigneeId: memberUsers[2].id,
      creatorId: managerUser.id,
      dueDate: new Date('2024-02-25'),
      estimatedHours: 24,
      actualHours: 18,
      position: 2,
    },
  ];

  const createdTasks = await Promise.all(
    tasks.map((task) => prisma.task.create({ data: task }))
  );

  // Create comments
  await Promise.all([
    prisma.comment.create({
      data: {
        content: 'Great work on the project setup! The folder structure looks clean and well-organized.',
        authorId: managerUser.id,
        taskId: createdTasks[0]!.id,
      },
    }),
    prisma.comment.create({
      data: {
        content: 'I\'ve added some additional OAuth providers to the requirements. Please include Google and GitHub.',
        authorId: managerUser.id,
        taskId: createdTasks[2]!.id,
      },
    }),
    prisma.comment.create({
      data: {
        content: 'The authentication flow looks good. Should we also include two-factor authentication?',
        authorId: memberUsers[1]!.id,
        taskId: createdTasks[1]!.id,
      },
    }),
    prisma.comment.create({
      data: {
        content: 'Working on this now. The database relationships are more complex than initially thought.',
        authorId: memberUsers[1]!.id,
        taskId: createdTasks[4]!.id,
      },
    }),
  ]);

  // Create activity logs
  await Promise.all([
    prisma.activityLog.create({
      data: {
        action: 'created',
        entity: 'project',
        entityId: webAppProject.id,
        description: 'Created new project: TaskFlow Web Application',
        userId: managerUser.id,
        projectId: webAppProject.id,
        metadata: JSON.stringify({ budget: 150000, priority: 'HIGH' })
      },
    }),
    prisma.activityLog.create({
      data: {
        action: 'assigned',
        entity: 'task',
        entityId: createdTasks[0]!.id,
        description: 'Assigned task "Set up Next.js project structure" to Alice Cooper',
        userId: managerUser.id,
        projectId: webAppProject.id,
        taskId: createdTasks[0]!.id,
      },
    }),
    prisma.activityLog.create({
      data: {
        action: 'completed',
        entity: 'task',
        entityId: createdTasks[0]!.id,
        description: 'Completed task "Set up Next.js project structure"',
        userId: memberUsers[0]!.id,
        projectId: webAppProject.id,
        taskId: createdTasks[0]!.id,
      },
    }),
  ]);

  // Create notifications
  await Promise.all([
    prisma.notification.create({
      data: {
        title: 'Welcome to TaskFlow!',
        message: 'Your account has been set up successfully. Start by exploring your dashboard.',
        type: 'info',
        userId: adminUser.id,
        data: JSON.stringify({ source: 'system', category: 'welcome' })
      },
    }),
    prisma.notification.create({
      data: {
        title: 'Task Due Soon',
        message: 'Your task "Implement user authentication" is due in 2 days.',
        type: 'warning',
        userId: memberUsers[1]!.id,
        data: JSON.stringify({ taskId: createdTasks[2]!.id, daysUntilDue: 2 })
      },
    }),
    prisma.notification.create({
      data: {
        title: 'New Comment',
        message: 'Sarah Johnson commented on your task "Set up Next.js project structure".',
        type: 'info',
        read: false,
        userId: memberUsers[0]!.id,
        data: JSON.stringify({ taskId: createdTasks[0]!.id, commenterId: managerUser.id })
      },
    }),
  ]);

  console.log('Database seeded successfully!');
  console.log(`Created users: ${[adminUser, managerUser, ...memberUsers].length}`);
  console.log(`Created teams: 2`);
  console.log(`Created projects: 3`);
  console.log(`Created tasks: ${createdTasks.length}`);
}

main()
  .then(async () => {
    await prisma.$disconnect();
  })
  .catch(async (e) => {
    console.error('Error seeding database:', e);
    await prisma.$disconnect();
    process.exit(1);
  });