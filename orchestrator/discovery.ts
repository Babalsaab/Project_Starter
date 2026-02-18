/**
 * Discovery Agent
 * Runs an interactive Q&A session to gather project requirements,
 * then hands off to the PRD Generator.
 */

export interface DiscoveryAnswers {
  project_name: string;
  project_type: string;
  primary_goal: string;
  audience: string;
  geography: string;
  channels: string[];
  features: string;
  design_style: string;
  tech_preference: string;
  timeline: string;
  budget_range: string;
  existing_brand: string;
}

export interface DiscoveryQuestion {
  id: keyof DiscoveryAnswers;
  text: string;
  hint?: string;
  multi?: boolean; // returns string[]
}

export interface AgentResponse {
  type: "question" | "complete" | "error";
  message: string;
  questionId?: string;
  nextAction?: string;
}

const DISCOVERY_QUESTIONS: DiscoveryQuestion[] = [
  {
    id: "project_name",
    text: "What's the name of your project or product?",
    hint: "e.g. 'TaskBuddy', 'Bloom Skincare', 'QuickLend'"
  },
  {
    id: "project_type",
    text: "What type of project is this?",
    hint: "e.g. web app, mobile app, landing page, email campaign, blog, SaaS, ecommerce, multi-channel launch"
  },
  {
    id: "primary_goal",
    text: "What is the primary goal? What does success look like in one sentence?",
    hint: "e.g. 'Get 1000 signups in the first month' or 'Build an MVP dating app for professionals in India'"
  },
  {
    id: "audience",
    text: "Who is your target audience?",
    hint: "e.g. 'Indian professionals aged 25-35 who want to invest but don't know where to start'"
  },
  {
    id: "geography",
    text: "Which geography are you targeting first?",
    hint: "e.g. India, US, UK, Southeast Asia, Global"
  },
  {
    id: "channels",
    text: "Which channels does this project need to cover?",
    hint: "e.g. web, iOS, Android, email, social, paid ads, push notifications — list all that apply",
    multi: true
  },
  {
    id: "features",
    text: "List the key features you need. Don't overthink it — just a brain dump.",
    hint: "e.g. 'user login, product listings, cart, checkout, email confirmation, admin dashboard'"
  },
  {
    id: "design_style",
    text: "What design style are you going for?",
    hint: "e.g. 'minimal and clean like Linear', 'bold and colorful like Duolingo', 'professional like Stripe', 'playful like Notion'"
  },
  {
    id: "tech_preference",
    text: "Any technology preferences or constraints?",
    hint: "e.g. 'Next.js + Supabase', 'React Native', 'must use our existing PHP backend', or 'no preference'"
  },
  {
    id: "timeline",
    text: "What's the timeline?",
    hint: "e.g. '1 week for MVP', '1 month', '3 months for full product'"
  },
  {
    id: "budget_range",
    text: "What's the budget range for this project?",
    hint: "e.g. 'bootstrapped (<$5k)', 'seed-funded ($5k-$50k)', 'growth stage ($50k+)', or 'internal project (no hard limit)'"
  },
  {
    id: "existing_brand",
    text: "Do you have existing brand guidelines, a logo, or a design system?",
    hint: "e.g. 'Yes, here's the brand doc link', 'We have a logo and color palette', 'Starting from scratch'"
  }
];

export class DiscoveryAgent {
  private currentQuestionIndex = 0;
  private answers: Partial<DiscoveryAnswers> = {};
  private projectId: string;

  constructor(projectId: string) {
    this.projectId = projectId;
  }

  /**
   * Returns the opening message to kick off the discovery conversation.
   */
  greet(): string {
    return [
      `👋 Welcome to Vibecoded Orchestrator!`,
      ``,
      `I'm your Discovery Agent. I'll ask you ${DISCOVERY_QUESTIONS.length} quick questions to understand your project,`,
      `then I'll generate a Master PRD and configure the right specialist agents to get the work done.`,
      ``,
      `Let's start. You can be as brief or detailed as you like — I'll extract what matters.`,
      ``,
      `─────────────────────────────────────────────────────`,
      `Q1/${DISCOVERY_QUESTIONS.length}: ${DISCOVERY_QUESTIONS[0]!.text}`,
      DISCOVERY_QUESTIONS[0]!.hint ? `   (${DISCOVERY_QUESTIONS[0]!.hint})` : ``
    ].join("\n");
  }

  /**
   * Processes user input and returns next question or completion signal.
   */
  respond(userInput: string): AgentResponse {
    const currentQuestion = DISCOVERY_QUESTIONS[this.currentQuestionIndex];

    // Store answer
    if (currentQuestion?.multi) {
      // Parse comma-separated or newline-separated into array
      (this.answers as any)[currentQuestion.id] = userInput
        .split(/[,\n]/)
        .map(s => s.trim())
        .filter(Boolean);
    } else if (currentQuestion) {
      (this.answers as any)[currentQuestion.id] = userInput.trim();
    }

    // Advance
    this.currentQuestionIndex++;

    // Check if complete
    if (this.currentQuestionIndex >= DISCOVERY_QUESTIONS.length) {
      return {
        type: "complete",
        message: [
          ``,
          `✅ Discovery complete! Got everything I need.`,
          ``,
          `📋 Generating your Master PRD for: ${this.answers.project_name}`,
          `   This will take a moment...`
        ].join("\n"),
        nextAction: "generate_prd"
      };
    }

    // Return next question
    const next = DISCOVERY_QUESTIONS[this.currentQuestionIndex];
    const questionNumber = this.currentQuestionIndex + 1;

    if (!next) {
      return {
        type: "complete",
        message: "Discovery complete.",
        nextAction: "generate_prd",
      };
    }

    return {
      type: "question",
      questionId: next.id,
      message: [
        ``,
        `Q${questionNumber}/${DISCOVERY_QUESTIONS.length}: ${next.text}`,
        next.hint ? `   (${next.hint})` : ``
      ].join("\n")
    };
  }

  /**
   * Returns the completed answers for PRD generation.
   */
  getAnswers(): DiscoveryAnswers {
    return this.answers as DiscoveryAnswers;
  }

  /**
   * Returns a summary of answers for logging.
   */
  getSummary(): string {
    return Object.entries(this.answers)
      .map(([k, v]) => `  ${k}: ${Array.isArray(v) ? v.join(", ") : v}`)
      .join("\n");
  }
}
