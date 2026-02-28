import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { z } from "zod";
import {
  listTemplates,
  getTemplate,
  searchTemplates,
} from "../lib/template-loader.js";

export function registerPrdTools(server: McpServer): void {
  server.tool(
    "list_prd_templates",
    "List all 35+ PRD templates across core, specialized, and companion categories. These cover frontend, backend, database, security, accessibility, analytics, and more.",
    {
      search: z
        .string()
        .optional()
        .describe('Search by name or category, e.g. "security", "frontend", "specialized"'),
    },
    async ({ search }) => {
      const templates = search ? searchTemplates(search) : listTemplates();

      if (templates.length === 0) {
        return {
          content: [
            {
              type: "text" as const,
              text: "No templates found. Try a broader search or omit the search parameter.",
            },
          ],
        };
      }

      const grouped = new Map<string, typeof templates>();
      for (const t of templates) {
        if (!grouped.has(t.category)) grouped.set(t.category, []);
        grouped.get(t.category)!.push(t);
      }

      let output = `# PRD Templates (${templates.length})\n\n`;
      for (const [category, group] of grouped) {
        output += `## ${category.charAt(0).toUpperCase() + category.slice(1)} (${group.length})\n`;
        output += group
          .map((t) => `- **${t.name}** — \`${t.filename}\``)
          .join("\n");
        output += "\n\n";
      }

      output += `_Use \`get_prd_template\` to load a full template._`;

      return { content: [{ type: "text" as const, text: output }] };
    }
  );

  server.tool(
    "get_prd_template",
    "Load the full content of a PRD template. Returns the complete markdown template ready to be filled in.",
    {
      template: z
        .string()
        .describe(
          'Template filename or name, e.g. "master-prd-template.md" or "Security Prd Template"'
        ),
    },
    async ({ template }) => {
      const content = getTemplate(template);
      if (!content) {
        const available = listTemplates()
          .slice(0, 10)
          .map((t) => `\`${t.filename}\``)
          .join(", ");
        return {
          content: [
            {
              type: "text" as const,
              text: `Template "${template}" not found. Some available templates: ${available}. Use list_prd_templates for the full list.`,
            },
          ],
        };
      }

      return { content: [{ type: "text" as const, text: content }] };
    }
  );

  server.tool(
    "generate_prd_outline",
    "Generate a PRD outline by combining a template with project details. Returns a pre-filled template structure for you to complete.",
    {
      template: z.string().describe("Template filename to use as the base"),
      project_name: z.string().describe("Name of the project"),
      project_description: z.string().describe("Brief description of the project"),
      project_type: z
        .string()
        .optional()
        .describe('Project type, e.g. "SaaS", "e-commerce", "mobile app"'),
    },
    async ({ template, project_name, project_description, project_type }) => {
      const templateContent = getTemplate(template);
      if (!templateContent) {
        return {
          content: [
            {
              type: "text" as const,
              text: `Template "${template}" not found. Use list_prd_templates to see available templates.`,
            },
          ],
        };
      }

      const header = `# PRD: ${project_name}

**Project:** ${project_name}
**Type:** ${project_type ?? "Not specified"}
**Description:** ${project_description}
**Generated from template:** ${template}
**Date:** ${new Date().toISOString().split("T")[0]}

---

> **Instructions:** Fill in the sections below using the template structure. Replace placeholder text with project-specific details. Remove sections that don't apply.

---

`;

      return {
        content: [
          { type: "text" as const, text: header + templateContent },
        ],
      };
    }
  );
}
