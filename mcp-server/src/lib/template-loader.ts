import { readFileSync, readdirSync, existsSync } from "fs";
import { join } from "path";

export interface TemplateSummary {
  filename: string;
  name: string;
  category: "core" | "specialized" | "companion";
  path: string;
}

const ROOT = join(import.meta.dirname, "..", "..", "..");
const TEMPLATES_BASE = join(ROOT, "config", "prd-templates");

const CATEGORY_DIRS: Array<{
  dir: string;
  category: TemplateSummary["category"];
}> = [
  { dir: join(TEMPLATES_BASE, "core"), category: "core" },
  { dir: join(TEMPLATES_BASE, "specialized"), category: "specialized" },
  { dir: join(TEMPLATES_BASE, "companion"), category: "companion" },
];

let templateCache: TemplateSummary[] | null = null;

function filenameToName(filename: string): string {
  return filename
    .replace(".md", "")
    .replace(/_/g, " ")
    .replace(/-/g, " ")
    .split(" ")
    .map((w) => w.charAt(0).toUpperCase() + w.slice(1))
    .join(" ");
}

export function listTemplates(): TemplateSummary[] {
  if (templateCache) return templateCache;

  templateCache = [];
  for (const { dir, category } of CATEGORY_DIRS) {
    if (!existsSync(dir)) continue;
    for (const f of readdirSync(dir)) {
      if (!f.endsWith(".md")) continue;
      templateCache.push({
        filename: f,
        name: filenameToName(f),
        category,
        path: join(dir, f),
      });
    }
  }

  templateCache.sort((a, b) => a.name.localeCompare(b.name));
  return templateCache;
}

export function getTemplate(filename: string): string | null {
  const templates = listTemplates();
  const match = templates.find(
    (t) =>
      t.filename === filename ||
      t.filename === filename + ".md" ||
      t.name.toLowerCase() === filename.toLowerCase()
  );
  if (!match) return null;
  if (!existsSync(match.path)) return null;
  return readFileSync(match.path, "utf-8");
}

export function searchTemplates(query: string): TemplateSummary[] {
  const kw = query.toLowerCase();
  return listTemplates().filter(
    (t) =>
      t.name.toLowerCase().includes(kw) ||
      t.filename.toLowerCase().includes(kw) ||
      t.category.includes(kw)
  );
}
