/**
 * Enhanced Memory MCP Tools v2.0
 *
 * Structured persistent memory with:
 * - Semantic search (TF-IDF + BM25 hybrid)
 * - Auto-categorization (section, type, tags)
 * - Cross-session tracking
 * - Relationship graph between facts
 * - Memory statistics and analytics
 * - Backward-compatible with MEMORY.md
 */

import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import {
  writeFact,
  updateFact,
  deleteFact,
  searchMemory,
  readAllFacts,
  getSections,
  getRelatedFacts,
  getMemoryStats,
  startSession,
  endSession,
  migrateFromMarkdown,
} from "../lib/memory-store.js";

export function registerMemoryTools(server: McpServer): void {
  server.tool(
    "memory_read",
    "Read the project's persistent structured memory. Returns categorized facts organized by section with tags and types. Supports section filtering.",
    {
      section: z
        .string()
        .optional()
        .describe("Filter by section name, e.g. 'Architecture Decisions', 'Key Conventions'"),
    },
    async ({ section }) => {
      const facts = readAllFacts(section);

      if (facts.length === 0) {
        const sections = getSections();
        if (sections.length === 0) {
          return {
            content: [
              {
                type: "text" as const,
                text: "No facts in memory yet. Use `memory_write` to start recording project context.\n\nIf you have an existing MEMORY.md, use `memory_migrate` to import it.",
              },
            ],
          };
        }
        return {
          content: [
            {
              type: "text" as const,
              text: `No facts found in section "${section}". Available sections:\n${sections.map((s) => `- **${s.name}** (${s.count} facts)`).join("\n")}`,
            },
          ],
        };
      }

      // Group by section
      const grouped = new Map<string, typeof facts>();
      for (const fact of facts) {
        const existing = grouped.get(fact.section) ?? [];
        existing.push(fact);
        grouped.set(fact.section, existing);
      }

      let output = `# Project Memory (${facts.length} facts)\n\n`;

      for (const [sectionName, sectionFacts] of grouped) {
        output += `## ${sectionName}\n\n`;
        for (const fact of sectionFacts) {
          const tags = fact.tags.length > 0 ? ` \`[${fact.tags.join(", ")}]\`` : "";
          const type = fact.type !== "note" ? ` _(${fact.type})_` : "";
          output += `- ${fact.content}${tags}${type} — ${fact.created_at}\n`;
        }
        output += "\n";
      }

      return { content: [{ type: "text" as const, text: output }] };
    }
  );

  server.tool(
    "memory_write",
    "Write a structured fact to persistent memory. Auto-categorizes by section, type, and tags. Use for architectural decisions, key conventions, patterns, errors, and preferences.",
    {
      fact: z
        .string()
        .describe("The fact or context to remember. Be concise and specific."),
      section: z
        .string()
        .optional()
        .describe("Section header (auto-detected if omitted). E.g. 'Architecture Decisions', 'Key Conventions', 'Errors & Solutions'"),
      tags: z
        .array(z.string())
        .optional()
        .describe("Tags for categorization (auto-detected if omitted). E.g. ['frontend', 'agent', 'security']"),
      type: z
        .enum(["decision", "convention", "pattern", "error", "preference", "discovery", "note"])
        .optional()
        .describe("Fact type (auto-detected if omitted)"),
      confidence: z
        .number()
        .min(0)
        .max(1)
        .optional()
        .describe("Confidence level 0-1 (default 0.8). Use lower for uncertain facts."),
      related_to: z
        .array(z.string())
        .optional()
        .describe("IDs of related facts (auto-detected if omitted)"),
    },
    async ({ fact: content, section, tags, type, confidence, related_to }) => {
      const fact = writeFact({
        content,
        section,
        tags,
        type,
        confidence,
        related_facts: related_to,
      });

      let output = `Saved to memory:\n`;
      output += `- **ID:** \`${fact.id}\`\n`;
      output += `- **Section:** ${fact.section}\n`;
      output += `- **Type:** ${fact.type}\n`;
      output += `- **Tags:** ${fact.tags.join(", ") || "(none)"}\n`;
      output += `- **Confidence:** ${fact.confidence}\n`;

      if (fact.related_facts.length > 0) {
        output += `- **Related facts:** ${fact.related_facts.length} auto-detected\n`;
      }
      output += `\nAlso synced to MEMORY.md and daily log.`;

      return { content: [{ type: "text" as const, text: output }] };
    }
  );

  server.tool(
    "memory_search",
    "Semantic search across project memory using hybrid BM25 + TF-IDF scoring. Finds relevant facts even with different wording. Supports filtering by section, tags, and type.",
    {
      query: z.string().describe("Search query. Can be a question, keyword, or description of what you're looking for."),
      section: z.string().optional().describe("Filter results to a specific section"),
      tags: z
        .array(z.string())
        .optional()
        .describe("Filter results by tags"),
      type: z
        .enum(["decision", "convention", "pattern", "error", "preference", "discovery", "note"])
        .optional()
        .describe("Filter by fact type"),
      top_k: z.number().optional().describe("Max results to return (default 10)"),
    },
    async ({ query, section, tags, type, top_k }) => {
      const results = searchMemory(query, { section, tags, type, topK: top_k });

      if (results.length === 0) {
        const sections = getSections();
        return {
          content: [
            {
              type: "text" as const,
              text: `No results found for "${query}".\n\nAvailable sections: ${sections.map((s) => s.name).join(", ") || "(empty memory)"}`,
            },
          ],
        };
      }

      let output = `# Memory Search: "${query}" (${results.length} results)\n\n`;

      for (const result of results) {
        const { fact, score, matchType } = result;
        const factTags = fact.tags.length > 0 ? ` [${fact.tags.join(", ")}]` : "";
        output += `### ${fact.section} — Score: ${score.toFixed(3)} (${matchType})\n`;
        output += `- ${fact.content}${factTags}\n`;
        output += `  _Type: ${fact.type} | ID: \`${fact.id}\` | ${fact.created_at}_\n\n`;
      }

      return { content: [{ type: "text" as const, text: output }] };
    }
  );

  server.tool(
    "memory_update",
    "Update an existing fact in memory by its ID.",
    {
      fact_id: z.string().describe("The fact ID to update (e.g. mem_17...)"),
      content: z.string().optional().describe("New content text"),
      section: z.string().optional().describe("New section"),
      tags: z.array(z.string()).optional().describe("New tags"),
      type: z
        .enum(["decision", "convention", "pattern", "error", "preference", "discovery", "note"])
        .optional(),
      confidence: z.number().min(0).max(1).optional().describe("New confidence level"),
    },
    async ({ fact_id, content, section, tags, type, confidence }) => {
      const updated = updateFact(fact_id, { content, section, tags, type, confidence });
      if (!updated) {
        return {
          content: [{ type: "text" as const, text: `Fact "${fact_id}" not found.` }],
        };
      }
      return {
        content: [
          {
            type: "text" as const,
            text: `Updated fact \`${fact_id}\`: ${updated.content}\nSection: ${updated.section} | Tags: ${updated.tags.join(", ")}`,
          },
        ],
      };
    }
  );

  server.tool(
    "memory_delete",
    "Remove a fact from memory by its ID.",
    {
      fact_id: z.string().describe("The fact ID to delete"),
    },
    async ({ fact_id }) => {
      const deleted = deleteFact(fact_id);
      return {
        content: [
          {
            type: "text" as const,
            text: deleted
              ? `Deleted fact \`${fact_id}\` and removed all references to it.`
              : `Fact "${fact_id}" not found.`,
          },
        ],
      };
    }
  );

  server.tool(
    "memory_stats",
    "Get statistics about the project's persistent memory: fact counts, section breakdown, type distribution, top tags.",
    {},
    async () => {
      const stats = getMemoryStats();

      let output = `# Memory Statistics\n\n`;
      output += `**Total Facts:** ${stats.totalFacts}\n`;
      output += `**Sessions:** ${stats.totalSessions}\n\n`;

      if (stats.sections.length > 0) {
        output += `## Sections\n`;
        output += stats.sections.map((s) => `- **${s.name}:** ${s.count} facts`).join("\n");
        output += "\n\n";
      }

      if (Object.keys(stats.typeBreakdown).length > 0) {
        output += `## By Type\n`;
        output += Object.entries(stats.typeBreakdown)
          .map(([t, count]) => `- ${t}: ${count}`)
          .join("\n");
        output += "\n\n";
      }

      if (stats.topTags.length > 0) {
        output += `## Top Tags\n`;
        output += stats.topTags.map((t) => `- \`${t.tag}\`: ${t.count}`).join("\n");
        output += "\n\n";
      }

      if (stats.recentFacts.length > 0) {
        output += `## Recent Facts\n`;
        output += stats.recentFacts
          .map((f) => `- [${f.created_at}] ${f.content.slice(0, 80)}...`)
          .join("\n");
      }

      return { content: [{ type: "text" as const, text: output }] };
    }
  );

  server.tool(
    "memory_related",
    "Find facts related to a specific fact by its ID. Shows the knowledge graph around a fact.",
    {
      fact_id: z.string().describe("The fact ID to find relations for"),
    },
    async ({ fact_id }) => {
      const related = getRelatedFacts(fact_id);
      if (related.length === 0) {
        return {
          content: [
            {
              type: "text" as const,
              text: `No related facts found for "${fact_id}".`,
            },
          ],
        };
      }

      let output = `# Related Facts for \`${fact_id}\`\n\n`;
      output += related
        .map((f) => `- **[${f.section}]** ${f.content} — \`${f.id}\``)
        .join("\n");

      return { content: [{ type: "text" as const, text: output }] };
    }
  );

  server.tool(
    "memory_migrate",
    "Migrate facts from an existing MEMORY.md file into the structured memory store. Preserves sections and timestamps.",
    {},
    async () => {
      const count = migrateFromMarkdown();
      if (count === 0) {
        return {
          content: [
            {
              type: "text" as const,
              text: "No migration needed. Either MEMORY.md doesn't exist or the store already has data.",
            },
          ],
        };
      }
      return {
        content: [
          {
            type: "text" as const,
            text: `Migrated ${count} facts from MEMORY.md into the structured memory store.`,
          },
        ],
      };
    }
  );

  server.tool(
    "memory_session_start",
    "Start a new memory session for tracking facts created during a work session.",
    {
      summary: z.string().describe("Brief description of what this session is about"),
    },
    async ({ summary }) => {
      const session = startSession(summary);
      return {
        content: [
          {
            type: "text" as const,
            text: `Started memory session \`${session.id}\`: ${summary}\n\nAll facts created with this session_id will be tracked.`,
          },
        ],
      };
    }
  );
}
