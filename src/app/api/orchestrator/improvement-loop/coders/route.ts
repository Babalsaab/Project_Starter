/**
 * API: Available Coder Backends
 * GET /api/orchestrator/improvement-loop/coders — List available coding backends
 */
import { NextResponse } from 'next/server';
import { requireAuth } from '@/lib/api-auth';

export async function GET() {
  const authResult = await requireAuth();
  if (authResult instanceof NextResponse) {
    return authResult;
  }

  // Return the list of coder backends with static metadata.
  // Availability detection runs client-side or at startup since
  // checking CLI availability requires subprocess calls that are
  // too slow for an API endpoint.
  const coders = [
    {
      id: 'claude-api',
      name: 'Claude API',
      description: 'Direct Anthropic API calls for code generation',
      setup: 'Set ANTHROPIC_API_KEY in .env.local',
      icon: 'sparkles',
    },
    {
      id: 'claude-code',
      name: 'Claude Code CLI',
      description:
        'Claude Code CLI with full tool use and multi-turn reasoning',
      setup: 'npm install -g @anthropic-ai/claude-code',
      icon: 'terminal',
    },
    {
      id: 'cursor',
      name: 'Cursor Agent',
      description: "Cursor editor's agent mode for AI-powered edits",
      setup: 'Install Cursor from cursor.com, enable CLI',
      icon: 'wand',
    },
    {
      id: 'aider',
      name: 'Aider',
      description: 'Open-source AI pair programmer (works with any model)',
      setup: 'pip install aider-chat',
      icon: 'users',
    },
    {
      id: 'manual',
      name: 'Manual (Any Tool)',
      description: 'Write instruction files for human review with any tool',
      setup: 'No setup needed — always available',
      icon: 'file-text',
    },
  ];

  return NextResponse.json({ coders });
}
