#!/usr/bin/env node

const fs = require('fs');
const path = require('path');

const AGENTS_DIR = path.join(__dirname, '..', 'agents');
const PERSONAS_DIR = path.join(AGENTS_DIR, 'personas');

// Simple YAML field parser (no dependency needed)
function parseYamlField(content, field) {
  const regex = new RegExp(`^${field}:\\s*["']?(.+?)["']?\\s*$`, 'm');
  const match = content.match(regex);
  return match ? match[1].trim() : '';
}

function parseYamlList(content, field) {
  const lines = content.split('\n');
  const items = [];
  let capture = false;
  for (const line of lines) {
    if (line.match(new RegExp(`^${field}:`))) {
      capture = true;
      continue;
    }
    if (capture) {
      if (line.match(/^\s+-\s+/)) {
        items.push(line.replace(/^\s+-\s+["']?/, '').replace(/["']?\s*$/, ''));
      } else {
        break;
      }
    }
  }
  return items;
}

function loadAgents(dir, category) {
  const agents = [];
  if (!fs.existsSync(dir)) return agents;
  const files = fs.readdirSync(dir).filter(f => f.endsWith('.yaml'));
  for (const file of files) {
    const content = fs.readFileSync(path.join(dir, file), 'utf-8');
    agents.push({
      id: parseYamlField(content, 'id'),
      title: parseYamlField(content, 'title'),
      domain: parseYamlField(content, 'domain'),
      reports_to: parseYamlField(content, 'reports_to'),
      token_cap: parseYamlField(content, 'token_cap'),
      responsibilities: parseYamlList(content, 'responsibilities'),
      category,
      file,
    });
  }
  return agents;
}

function loadPersonas(dir) {
  if (!fs.existsSync(dir)) return [];
  return fs.readdirSync(dir).filter(f => f.endsWith('.md')).map(f => {
    const name = f.replace('.md', '').split('-').map(w => w.charAt(0).toUpperCase() + w.slice(1)).join(' ');
    return { file: f, name };
  });
}

// ─── Main ────────────────────────────────────────────────────────────────────

const chiefs = loadAgents(path.join(AGENTS_DIR, 'chiefs'), 'Chief');
const techAgents = loadAgents(path.join(AGENTS_DIR, 'pool', 'tech'), 'Tech');
const marketingAgents = loadAgents(path.join(AGENTS_DIR, 'pool', 'marketing'), 'Marketing');
const personas = loadPersonas(PERSONAS_DIR);

const allAgents = [...chiefs, ...techAgents, ...marketingAgents];

console.log('\n╔══════════════════════════════════════════════════════════════════╗');
console.log('║          VIBECODED ORCHESTRATOR — AGENT REGISTRY               ║');
console.log('╚══════════════════════════════════════════════════════════════════╝\n');

// Chiefs
console.log('┌─── CHIEFS (Leadership) ────────────────────────────────────────┐');
for (const a of chiefs) {
  console.log(`│  ${a.id.padEnd(20)} ${a.title.padEnd(40)} │`);
}
console.log(`└─────────────────────────────────────────────────────────────────┘\n`);

// Tech
console.log('┌─── TECH SPECIALISTS ─────────────────────────────────────────┐');
for (const a of techAgents) {
  const domain = a.domain ? `[${a.domain}]` : '';
  console.log(`│  ${a.id.padEnd(32)} ${domain.padEnd(28)} │`);
}
console.log(`└─────────────────────────────────────────────────────────────────┘\n`);

// Marketing
console.log('┌─── MARKETING SPECIALISTS ──────────────────────────────────────┐');
for (const a of marketingAgents) {
  const domain = a.domain ? `[${a.domain}]` : '';
  console.log(`│  ${a.id.padEnd(32)} ${domain.padEnd(28)} │`);
}
console.log(`└─────────────────────────────────────────────────────────────────┘\n`);

// Personas
if (personas.length > 0) {
  console.log('┌─── EXPERT PERSONAS ──────────────────────────────────────────┐');
  for (const p of personas) {
    console.log(`│  ${p.name.padEnd(60)} │`);
  }
  console.log(`└─────────────────────────────────────────────────────────────────┘\n`);
}

// Summary
console.log('─── SUMMARY ───────────────────────────────────────────────────────');
console.log(`  Chiefs:              ${chiefs.length}`);
console.log(`  Tech Specialists:    ${techAgents.length}`);
console.log(`  Marketing Agents:    ${marketingAgents.length}`);
console.log(`  Expert Personas:     ${personas.length}`);
console.log(`  Total Agents:        ${allAgents.length}`);
console.log('───────────────────────────────────────────────────────────────────\n');
