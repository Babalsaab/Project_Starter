import { type McpServer } from '@modelcontextprotocol/sdk/server/mcp.js';
import { z } from 'zod';
import {
  runEvaluation,
  getLatestEvaluation,
  listEvaluations,
  compareEvaluations,
} from '../lib/evaluation-runner.js';

export function registerEvaluationTools(server: McpServer): void {
  // Tool 1: run_evaluation
  server.tool(
    'run_evaluation',
    'Run the CTO Codebase Evaluation Suite against a codebase. Evaluates 495 parameters across 21 categories (Security, Architecture, Code Quality, Performance, etc.) with weighted scoring.',
    {
      codebase_path: z
        .string()
        .describe('Absolute path to the codebase to evaluate'),
      mode: z
        .enum(['quick', 'standard', 'enhanced'])
        .optional()
        .default('standard')
        .describe(
          'Evaluation mode: quick (fast scan), standard (full), enhanced (deep + compliance)'
        ),
      skip_categories: z
        .string()
        .optional()
        .describe("Comma-separated categories to skip, e.g. 'mobile,frontend'"),
    },
    async ({ codebase_path, mode, skip_categories }) => {
      const skipList = skip_categories
        ? skip_categories.split(',').map((s) => s.trim())
        : undefined;

      const { success, message, result } = await runEvaluation(codebase_path, {
        mode,
        skipCategories: skipList,
      });

      if (!success || !result) {
        return {
          content: [
            { type: 'text' as const, text: `Evaluation failed: ${message}` },
          ],
        };
      }

      let output = `# CTO Codebase Evaluation Report\n\n`;
      output += `**Overall Score:** ${result.overall_score}/10 (${result.grade})\n`;
      output += `**Risk Level:** ${result.risk_level}\n`;
      output += `**Mode:** ${result.mode}\n`;
      output += `**Codebase:** ${result.codebase_path}\n`;
      if (result.languages_detected.length) {
        output += `**Languages:** ${result.languages_detected.join(', ')}\n`;
      }
      if (result.frameworks_detected.length) {
        output += `**Frameworks:** ${result.frameworks_detected.join(', ')}\n`;
      }
      output += `\n## Category Scores\n\n`;
      output += `| Category | Weight | Score | Grade |\n`;
      output += `|----------|--------|-------|-------|\n`;
      for (const cat of result.categories.sort((a, b) => b.weight - a.weight)) {
        output += `| ${cat.name} | ${cat.weight}% | ${cat.score}/10 | ${cat.grade} |\n`;
      }

      const criticalFindings = result.findings.filter(
        (f) => f.severity === 'critical'
      );
      const highFindings = result.findings.filter((f) => f.severity === 'high');

      output += `\n## Findings Summary\n`;
      output += `- **Critical:** ${criticalFindings.length}\n`;
      output += `- **High:** ${highFindings.length}\n`;
      output += `- **Medium:** ${result.findings.filter((f) => f.severity === 'medium').length}\n`;
      output += `- **Low:** ${result.findings.filter((f) => f.severity === 'low').length}\n`;
      output += `- **Total:** ${result.findings.length}\n`;

      if (criticalFindings.length > 0) {
        output += `\n## Critical Findings\n\n`;
        for (const f of criticalFindings.slice(0, 10)) {
          output += `- **[${f.category}]** ${f.description}`;
          if (f.file) {
            output += ` (${f.file}${f.line ? `:${f.line}` : ''})`;
          }
          output += `\n  Remediation: ${f.remediation}\n`;
        }
      }

      if (highFindings.length > 0) {
        output += `\n## High Severity Findings\n\n`;
        for (const f of highFindings.slice(0, 10)) {
          output += `- **[${f.category}]** ${f.description}`;
          if (f.file) {
            output += ` (${f.file}${f.line ? `:${f.line}` : ''})`;
          }
          output += `\n  Remediation: ${f.remediation}\n`;
        }
      }

      return { content: [{ type: 'text' as const, text: output }] };
    }
  );

  // Tool 2: get_evaluation
  server.tool(
    'get_evaluation',
    'Get the latest CTO evaluation results for a codebase. Returns scores, findings, and recommendations.',
    {
      codebase_path: z
        .string()
        .describe('Absolute path to the evaluated codebase'),
      format: z
        .enum(['summary', 'full', 'category'])
        .optional()
        .default('summary')
        .describe(
          'Output format: summary (overview), full (all details), category (per-category breakdown)'
        ),
      category: z
        .string()
        .optional()
        .describe(
          'Specific category to show details for (only with format=category)'
        ),
    },
    async ({ codebase_path, format, category }) => {
      const result = getLatestEvaluation(codebase_path);
      if (!result) {
        return {
          content: [
            {
              type: 'text' as const,
              text: `No evaluation results found for ${codebase_path}. Run \`run_evaluation\` first.`,
            },
          ],
        };
      }

      let output = '';

      if (format === 'summary') {
        output = `# Evaluation Summary\n\n`;
        output += `**Score:** ${result.overall_score}/10 (${result.grade}) | **Risk:** ${result.risk_level}\n`;
        output += `**Categories:** ${result.categories.length} evaluated\n`;
        output += `**Findings:** ${result.findings.length} total (${result.findings.filter((f) => f.severity === 'critical').length} critical, ${result.findings.filter((f) => f.severity === 'high').length} high)\n\n`;
        output += `## Top Categories\n`;
        const sorted = [...result.categories].sort((a, b) => b.score - a.score);
        output += `**Best:** ${sorted[0]?.name ?? 'N/A'} (${sorted[0]?.score ?? 0}/10)\n`;
        output += `**Worst:** ${sorted[sorted.length - 1]?.name ?? 'N/A'} (${sorted[sorted.length - 1]?.score ?? 0}/10)\n`;
      } else if (format === 'category' && category) {
        const cat = result.categories.find(
          (c) =>
            c.id === category || c.name.toLowerCase() === category.toLowerCase()
        );
        if (!cat) {
          output = `Category "${category}" not found. Available: ${result.categories.map((c) => c.id).join(', ')}`;
        } else {
          output = `# ${cat.name} (${cat.id})\n\n`;
          output += `**Score:** ${cat.score}/10 (${cat.grade}) | **Weight:** ${cat.weight}%\n`;
          output += `**Findings:** ${cat.findings_count}\n\n`;
          const catFindings = result.findings.filter(
            (f) => f.category === cat.name
          );
          if (catFindings.length > 0) {
            output += `## Findings\n\n`;
            for (const f of catFindings) {
              output += `- **[${f.severity.toUpperCase()}]** ${f.description}\n`;
              if (f.remediation) {
                output += `  Fix: ${f.remediation}\n`;
              }
            }
          }
        }
      } else {
        // full format
        output = `# Full Evaluation Report\n\n`;
        output += `**Score:** ${result.overall_score}/10 (${result.grade}) | **Risk:** ${result.risk_level}\n`;
        output += `**Mode:** ${result.mode} | **Date:** ${result.timestamp}\n\n`;
        output += `## All Categories\n\n`;
        output += `| Category | Weight | Score | Grade | Findings |\n`;
        output += `|----------|--------|-------|-------|----------|\n`;
        for (const cat of result.categories.sort(
          (a, b) => b.weight - a.weight
        )) {
          output += `| ${cat.name} | ${cat.weight}% | ${cat.score} | ${cat.grade} | ${cat.findings_count} |\n`;
        }
        output += `\n## All Findings (${result.findings.length})\n\n`;
        for (const f of result.findings) {
          output += `- **[${f.severity.toUpperCase()}] [${f.category}]** ${f.description}`;
          if (f.file) {
            output += ` (${f.file})`;
          }
          output += `\n`;
        }
      }

      return { content: [{ type: 'text' as const, text: output }] };
    }
  );

  // Tool 3: list_evaluations
  server.tool(
    'list_evaluations',
    'List all previous CTO evaluation runs for a codebase with scores and timestamps.',
    {
      codebase_path: z
        .string()
        .describe('Absolute path to the evaluated codebase'),
    },
    async ({ codebase_path }) => {
      const evals = listEvaluations(codebase_path);

      if (evals.length === 0) {
        return {
          content: [
            {
              type: 'text' as const,
              text: `No evaluation history found for ${codebase_path}.`,
            },
          ],
        };
      }

      let output = `# Evaluation History (${evals.length} runs)\n\n`;
      output += `| Run | Date | Score | Grade | Findings | Critical |\n`;
      output += `|-----|------|-------|-------|----------|----------|\n`;
      for (const e of evals) {
        output += `| ${e.run_id} | ${e.timestamp} | ${e.overall_score} | ${e.grade} | ${e.findings_total} | ${e.findings_critical} |\n`;
      }

      return { content: [{ type: 'text' as const, text: output }] };
    }
  );

  // Tool 4: compare_evaluations
  server.tool(
    'compare_evaluations',
    'Compare two CTO evaluation runs to see score changes and trend analysis.',
    {
      codebase_path: z
        .string()
        .describe('Absolute path to the evaluated codebase'),
      run_id_1: z
        .string()
        .describe("First run ID (older), e.g. 'evaluation_20260101_120000'"),
      run_id_2: z
        .string()
        .describe("Second run ID (newer), e.g. 'evaluation_20260201_120000'"),
    },
    async ({ codebase_path, run_id_1, run_id_2 }) => {
      const { resolve } = await import('path');
      const { existsSync, readFileSync } = await import('fs');
      const { join } = await import('path');

      const absPath = resolve(codebase_path);
      const dir1 = join(absPath, '.cto-evaluation', run_id_1, 'report.json');
      const dir2 = join(absPath, '.cto-evaluation', run_id_2, 'report.json');

      if (!existsSync(dir1)) {
        return {
          content: [
            {
              type: 'text' as const,
              text: `Run ${run_id_1} not found at ${dir1}`,
            },
          ],
        };
      }
      if (!existsSync(dir2)) {
        return {
          content: [
            {
              type: 'text' as const,
              text: `Run ${run_id_2} not found at ${dir2}`,
            },
          ],
        };
      }

      try {
        const result1 = JSON.parse(readFileSync(dir1, 'utf-8'));
        const result2 = JSON.parse(readFileSync(dir2, 'utf-8'));
        const comparison = compareEvaluations(result1, result2);
        return { content: [{ type: 'text' as const, text: comparison }] };
      } catch (err) {
        return {
          content: [
            {
              type: 'text' as const,
              text: `Error comparing evaluations: ${err instanceof Error ? err.message : String(err)}`,
            },
          ],
        };
      }
    }
  );
}
