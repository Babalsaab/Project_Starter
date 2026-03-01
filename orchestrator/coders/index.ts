/**
 * Coder Registry
 *
 * Factory for creating and managing Coder instances.
 * Detects which coding backends are available on the system
 * and provides a unified way to select and instantiate them.
 */

import type { Coder, CoderBackend, CoderConfig } from './base';
import { ClaudeAPICoder } from './claude-api';
import { ClaudeCodeCoder } from './claude-code';
import { CursorCoder } from './cursor';
import { AiderCoder } from './aider';
import { ManualCoder } from './manual';

// ─── Registry ─────────────────────────────────────────────────────────────────

const CODERS: Record<CoderBackend, () => Coder> = {
  'claude-api': () => new ClaudeAPICoder(),
  'claude-code': () => new ClaudeCodeCoder(),
  cursor: () => new CursorCoder(),
  aider: () => new AiderCoder(),
  manual: () => new ManualCoder(),
};

/**
 * Get a Coder instance by backend name.
 */
export function getCoder(backend: CoderBackend): Coder {
  const factory = CODERS[backend];
  if (!factory) {
    throw new Error(
      `Unknown coder backend: ${backend}. Available: ${Object.keys(CODERS).join(', ')}`
    );
  }
  return factory();
}

/**
 * Get the default coder config.
 */
export function getDefaultCoderConfig(
  backend: CoderBackend = 'claude-api'
): CoderConfig {
  return {
    backend,
    timeout_ms: backend === 'manual' ? 0 : 300000,
    max_files: 10,
    allow_create: true,
  };
}

/**
 * List all available coder backends and their status.
 */
export async function listCoders(): Promise<
  Array<{
    backend: CoderBackend;
    displayName: string;
    available: boolean;
    setupInstructions: string;
  }>
> {
  const results = [];

  for (const [backend, factory] of Object.entries(CODERS)) {
    const coder = factory();
    const available = await coder.isAvailable();
    results.push({
      backend: backend as CoderBackend,
      displayName: coder.displayName,
      available,
      setupInstructions: coder.setupInstructions(),
    });
  }

  return results;
}

/**
 * Auto-detect the best available coder backend.
 * Priority: claude-code > cursor > aider > claude-api > manual
 */
export async function detectBestCoder(): Promise<CoderBackend> {
  const priority: CoderBackend[] = [
    'claude-code',
    'cursor',
    'aider',
    'claude-api',
    'manual',
  ];

  for (const backend of priority) {
    const coder = getCoder(backend);
    if (await coder.isAvailable()) {
      return backend;
    }
  }

  return 'manual'; // Always available
}

// Re-export types
export type {
  Coder,
  CoderBackend,
  CoderConfig,
  CoderRequest,
  CoderResult,
} from './base';
