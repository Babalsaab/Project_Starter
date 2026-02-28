import { readFileSync, existsSync } from "fs";
import { join } from "path";
import yaml from "js-yaml";

export interface Mentor {
  name: string;
  domain_focus: string;
  quote: string;
  principles: string[];
  influences_domains: string[];
  influences_agents: string[];
  review_lens: string;
}

interface MentorsFile {
  mentors: Record<string, Mentor>;
  domain_mentor_map?: Record<
    string,
    { primary: string[]; secondary?: string[] }
  >;
  review_passes?: Record<
    string,
    Array<{ mentor: string; focus: string; question: string }>
  >;
  prompt_injection_template?: string;
}

const ROOT = join(import.meta.dirname, "..", "..", "..");
const MENTORS_PATH = join(ROOT, "config", "mentors.yaml");

let mentorsCache: MentorsFile | null = null;

function loadMentorsFile(): MentorsFile {
  if (mentorsCache) return mentorsCache;
  if (!existsSync(MENTORS_PATH)) {
    mentorsCache = { mentors: {} };
    return mentorsCache;
  }
  const content = readFileSync(MENTORS_PATH, "utf-8");
  mentorsCache = yaml.load(content) as MentorsFile;
  return mentorsCache;
}

export function listMentors(): Array<{
  id: string;
  name: string;
  domain_focus: string;
  quote: string;
}> {
  const file = loadMentorsFile();
  return Object.entries(file.mentors).map(([id, m]) => ({
    id,
    name: m.name,
    domain_focus: m.domain_focus,
    quote: m.quote,
  }));
}

export function getMentor(id: string): Mentor | undefined {
  const file = loadMentorsFile();
  return file.mentors[id];
}

export function getMentorsForAgent(agentId: string): Mentor[] {
  const file = loadMentorsFile();
  return Object.values(file.mentors).filter((m) =>
    m.influences_agents.includes(agentId)
  );
}

export function getMentorsForDomain(domain: string): {
  primary: Mentor[];
  secondary: Mentor[];
} {
  const file = loadMentorsFile();
  const domainMap = file.domain_mentor_map;

  if (!domainMap) {
    // Fallback: search by influences_domains
    const matching = Object.values(file.mentors).filter((m) =>
      m.influences_domains.some((d) => domain.startsWith(d))
    );
    return { primary: matching, secondary: [] };
  }

  // Find best matching domain key
  let bestMatch = "";
  for (const key of Object.keys(domainMap)) {
    if (domain.startsWith(key) && key.length > bestMatch.length) {
      bestMatch = key;
    }
  }

  if (!bestMatch) return { primary: [], secondary: [] };

  const mapping = domainMap[bestMatch];
  const resolve = (ids: string[] | undefined): Mentor[] =>
    (ids ?? [])
      .map((id) => file.mentors[id])
      .filter((m): m is Mentor => m !== undefined);

  return {
    primary: resolve(mapping?.primary),
    secondary: resolve(mapping?.secondary),
  };
}

export function buildMentorReviewPrompt(
  mentorId: string,
  content: string
): string | null {
  const mentor = getMentor(mentorId);
  if (!mentor) return null;

  return `## Mentor Review: ${mentor.name}

**Domain Focus:** ${mentor.domain_focus}

**Core Philosophy:**
> "${mentor.quote}"

**Principles to Apply:**
${mentor.principles.map((p) => `- ${p}`).join("\n")}

**Review Lens Question:**
${mentor.review_lens}

---

**Content to Review:**

${content}

---

**Instructions:** Review the content above through the lens of ${mentor.name}. Apply each principle listed above. Answer the review lens question directly. Provide specific, actionable feedback. Rate the content as PASS / NEEDS_IMPROVEMENT / FAIL with justification.`;
}

export function buildAutoReviewPrompt(
  domain: string,
  content: string
): string {
  const { primary, secondary } = getMentorsForDomain(domain);
  const allMentors = [...primary, ...secondary].slice(0, 3); // Max 3 mentors

  if (allMentors.length === 0) {
    return `No mentors configured for domain "${domain}". Review the content using general best practices.`;
  }

  const mentorSections = allMentors
    .map(
      (m) => `### ${m.name} (${m.domain_focus})
> "${m.quote}"

**Review Lens:** ${m.review_lens}

**Key Principles:**
${m.principles.slice(0, 3).map((p) => `- ${p}`).join("\n")}`
    )
    .join("\n\n");

  return `## Multi-Mentor Review

Apply the following mentor perspectives to review this content:

${mentorSections}

---

**Content to Review:**

${content}

---

**Instructions:** Review through each mentor's lens. For each mentor, answer their review lens question. Provide a combined verdict: PASS / NEEDS_IMPROVEMENT / FAIL.`;
}
