#!/usr/bin/env node

/**
 * Vibecoded Orchestrator MCP Server v2.0
 *
 * 35+ MCP tools exposing:
 * - 66 agents, 70 personas, 15 mentors (discovery, invocation, review)
 * - 10+ skills with self-extending discovery & installation
 * - 35+ PRD templates with outline generation
 * - Structured persistent memory with semantic search
 * - Lobster-style YAML workflow engine with approval gates
 * - Session management and pipeline orchestration
 *
 * Transport: stdio (standard for local MCP servers)
 */

import { McpServer } from "@modelcontextprotocol/sdk/server/mcp.js";
import { StdioServerTransport } from "@modelcontextprotocol/sdk/server/stdio.js";
import { registerAgentTools } from "./tools/agents.js";
import { registerPersonaTools } from "./tools/personas.js";
import { registerMentorTools } from "./tools/mentors.js";
import { registerSkillTools } from "./tools/skills.js";
import { registerPrdTools } from "./tools/prd.js";
import { registerSessionTools } from "./tools/sessions.js";
import { registerMemoryTools } from "./tools/memory.js";
import { registerWorkflowTools } from "./tools/workflows.js";
import { registerSkillDiscoveryTools } from "./tools/skill-discovery.js";

process.on('unhandledRejection', (reason, promise) => {
  console.error('Unhandled Rejection at:', promise, 'reason:', reason);
});

process.on('uncaughtException', (error) => {
  console.error('Uncaught Exception:', error);
  process.exit(1);
});

const server = new McpServer({
  name: "vibecoded-orchestrator",
  version: "2.0.0",
});

// Register all tool modules
registerAgentTools(server);
registerPersonaTools(server);
registerMentorTools(server);
registerSkillTools(server);
registerPrdTools(server);
registerSessionTools(server);
registerMemoryTools(server);
registerWorkflowTools(server);
registerSkillDiscoveryTools(server);

// Start the server with stdio transport
async function main(): Promise<void> {
  const transport = new StdioServerTransport();
  await server.connect(transport);
}

main().catch((error) => {
  console.error("MCP server failed to start:", error);
  process.exit(1);
});
