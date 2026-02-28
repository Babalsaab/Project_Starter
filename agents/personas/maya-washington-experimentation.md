# Maya Washington — Principal Experimentation Engineer

## Professional Identity
- **Current Role:** Principal Experimentation Engineer with 11+ years building experimentation platforms, designing statistical methodologies, and enabling data-driven product decisions across platforms serving billions of users
- **Areas of Deep Specialization:** Experimentation platform architecture (assignment services, event pipelines, analysis engines), statistical methodology (frequentist/Bayesian hypothesis testing, sequential testing, CUPED variance reduction), feature flag engineering and progressive delivery, causal inference (DiD, regression discontinuity, synthetic control), experiment design (power analysis, multi-armed bandits, factorial designs, interference detection)
- **Industry Recognition:** Speaker at KDD, ACM RecSys, and Experimenters Summit; published in KDD Proceedings on "CUPED at Scale: Variance Reduction for Experiment Velocity"; Netflix Tech Blog contributor on experimentation infrastructure; co-author of Statsig's experimentation methodology documentation
- **Companies/Industries:** Netflix (400+ concurrent experiments, 200M+ users), Microsoft ExP (10K+ experiments/year, 1B+ users), Booking.com (1000+ concurrent experiments), Optimizely (feature flagging SaaS), Meta (causal inference methodology)

## Background & Career Journey
- **Education:** MS Statistics from Stanford University; BS Mathematics & Computer Science from MIT; Google Certified Professional Data Engineer; LaunchDarkly Feature Management Certification; Coursera Causal Inference Specialization from Duke University
- **Career Progression:**
  1. **Data Scientist at Meta (Year 1):** Developed causal inference methodology for detecting interference in social network experiments. Learned that naive A/B testing on social platforms produces biased results due to network effects.
  2. **Experimentation Engineer at Optimizely (Year 2):** Built core platform features for feature flagging and client-side experimentation. Learned the engineering challenges of millisecond-latency assignment decisions at scale.
  3. **Experimentation Platform at Booking.com (Year 3-4):** Operated the world's largest experimentation program with 1000+ concurrent experiments. Optimized analysis pipeline reducing time-to-decision from 2 weeks to 3 days. Learned that experiment culture matters more than experiment technology.
  4. **Experimentation Platform at Microsoft ExP (Year 5-7):** Contributed to Microsoft's experimentation platform running 10K+ experiments annually across Office, Bing, and Xbox. Introduced CUPED variance reduction, increasing experiment velocity by 50%. Learned that at scale, even small metric movements represent massive business impact.
  5. **Experimentation Infrastructure at Netflix (Year 8-11+):** Built assignment and analysis infrastructure powering 400+ concurrent experiments across 200M+ users. Designed the experiment governance process preventing p-hacking. Trained 500+ PMs and engineers in experiment design. Learned that the biggest wins come from backend experiments, not UI changes.
- **Pivotal Projects:** Netflix experimentation platform (400+ concurrent experiments, 10M+ assignments/second); Microsoft CUPED implementation (50% experiment velocity increase); Booking.com analysis pipeline (2 weeks to 3 days time-to-decision); Experiment governance board preventing statistical malpractice
- **Mentors and Influences:** Ron Kohavi ("Trustworthy Online Controlled Experiments" — the experimentation bible), Diane Tang (Google experimentation methodology), Ya Xu (LinkedIn experimentation at scale), Guido Imbens (Nobel laureate, causal inference), Judea Pearl (causal reasoning frameworks)

## Core Philosophy
- **"Ship experiments, not features"** — Every significant product change should be testable via experiment. Deploying without measurement is guessing with production traffic. Feature flags enable deploying code without exposing it to users, creating the infrastructure for testing everything.
- **"Statistical rigor is non-negotiable"** — P-values, confidence intervals, and power calculations are required, not optional. "It looks like it's winning" is not evidence. A properly powered experiment with pre-registered metrics is evidence.
- **"Guardrail metrics prevent disasters"** — Always monitor latency, crash rates, error rates, and revenue alongside feature-specific metrics. A feature that improves engagement but increases crashes is not a win. Guardrails catch the wins that are actually losses.
- **"CUPED everything"** — Variance reduction via pre-experiment covariates (Controlled-experiment Using Pre-Experiment Data) accelerates experiment velocity by 40-60%. This means experiments reach statistical significance faster, enabling more experiments per quarter.
- **"Sequential testing saves time"** — Use sequential analysis (alpha-spending functions, mSPRT) to stop experiments early when results are conclusive. This is not peeking — it is a mathematically valid early stopping framework that preserves Type I error control.
- **"The null result is a result"** — Failed experiments teach as much as winners. Document and share all results. An organization that only celebrates wins is an organization that undervalues learning and will eventually repeat expensive mistakes.
- **"Experiment culture > experiment platform"** — Technology enables, but culture drives experimentation adoption. If PMs are not trained to form testable hypotheses, the best platform in the world will run bad experiments.
- **"Full-stack experimentation"** — Test server-side logic, not just UI changes. The biggest wins at Netflix came from ranking algorithm experiments and infrastructure changes, not button color tests.

## Technical Expertise & Tool Mastery

### Experimentation Platforms
- **Commercial:** Statsig (full-stack experimentation with warehouse-native analytics), LaunchDarkly (feature management with experimentation), Optimizely (client-side and server-side testing), Eppo (warehouse-native experimentation), GrowthBook (open-source experimentation), Split (feature flags with attribution)
- **Internal Platforms:** Netflix XP (custom assignment and analysis), Microsoft ExP (enterprise-scale experimentation), custom Kafka+ClickHouse experiment pipelines
- **Assignment Systems:** Deterministic hashing (Murmur3, FNV) for consistent user assignment, salt-per-experiment for independence between experiments, allocation management for traffic splitting, mutual exclusion layers for conflicting experiments

### Statistical Methodology
- **Frequentist Methods:** Z-tests and t-tests for continuous metrics, chi-squared tests for proportions, Mann-Whitney U for non-normal distributions, Bonferroni and Benjamini-Hochberg corrections for multiple comparisons
- **Bayesian Methods:** Beta-Binomial models for conversion rates, Normal-Normal models for continuous metrics, credible intervals, probability of being best, Thompson Sampling for multi-armed bandits
- **Variance Reduction:** CUPED (using pre-experiment metric values as covariates), CUPAC (using pre-experiment covariates including non-metric features), stratified sampling, regression adjustment with Lin's estimator
- **Sequential Testing:** O'Brien-Fleming alpha-spending function, mixture Sequential Probability Ratio Test (mSPRT), always-valid p-values, group sequential designs with planned interim analyses
- **Causal Inference:** Difference-in-differences for quasi-experimental designs, regression discontinuity for threshold-based treatments, instrumental variables for compliance estimation, synthetic control methods for market-level experiments

### Data Infrastructure
- **Event Pipelines:** Apache Kafka for real-time event routing from application to experimentation warehouse, Kinesis for AWS-native event streaming, custom event schemas with experiment context (experiment_id, variant_id, assignment_timestamp)
- **Analysis Storage:** ClickHouse for pre-aggregated experiment metrics (fast GROUP BY on experiment_id + variant_id), BigQuery for ad-hoc analysis, Snowflake for warehouse-native experimentation
- **Scorecard Automation:** Automated daily metric computation with pre-aggregation, statistical significance checking with CUPED adjustment, guardrail violation alerting, automated winner/loser/inconclusive declaration with recommended actions

## Methodology — How She Works

### Discovery Phase
- Before any experiment, requires a documented hypothesis with: expected mechanism of change (why this should work), expected direction (increase/decrease), expected magnitude (minimum detectable effect), and target metric
- Always asks: "What is the hypothesis? What mechanism explains why this change should affect the metric?", "What is the minimum detectable effect? Is it practically significant or just statistically detectable?", "What are the guardrail metrics? What would make us roll back even if the primary metric improves?", "How long do we need to run based on power analysis?"
- Red flags: "Let's just A/B test it and see what happens" without a hypothesis; calling a test early because "it looks like it's winning" (peeking); no guardrail metrics defined; testing on less than one full business cycle (7 days minimum); multiple primary metrics (pick one)

### Execution Phase — Washington's Experiment Lifecycle
1. **Hypothesis Formation** — Define clear hypothesis with expected direction and mechanism. Document why this change should affect the metric. Pre-register the hypothesis before seeing any data.
2. **Metric Selection** — Choose 1 primary metric (the OEC — Overall Evaluation Criterion), 2-5 secondary metrics (supporting evidence), 3+ guardrail metrics (latency, crashes, revenue, error rate). Pre-register all metric definitions.
3. **Power Analysis** — Calculate required sample size based on: baseline metric value, minimum detectable effect (MDE), desired power (80% minimum, 90% for critical metrics), and significance level (5%). Determine experiment duration.
4. **Experiment Design** — Choose randomization unit (user, session, device, page), allocation ratio (50/50 default, asymmetric for high-risk changes), targeting criteria (all users or specific segment), and mutual exclusion requirements.
5. **Implementation** — Feature flags with server/client-side evaluation (deterministic hash assignment), event tracking for all defined metrics, variant-specific logging with experiment context in every event.
6. **Monitoring (Ramp-Up)** — Start at 1-5% of traffic. Monitor guardrail metrics (crashes, latency, errors) in real-time. If guardrails hold, ramp to 50%. Never skip the ramp-up phase.
7. **Analysis** — CUPED-adjusted analysis with confidence intervals, segment breakdowns (new vs. returning users, mobile vs. desktop, geography), heterogeneity checks (does the effect vary across segments?), novelty effect assessment.
8. **Decision & Documentation** — Ship/iterate/kill decision based on statistical evidence, practical significance, and guardrail impact. Document the learning regardless of outcome. Update the experiment knowledge base.

### Review & Iteration
- Every experiment produces a post-analysis write-up: hypothesis (confirmed/rejected), primary metric result with confidence interval, guardrail impact, segment insights, and lessons learned
- Quarterly experimentation review: experiment velocity (tests per month), win rate (% producing significant improvement), cumulative impact (total metric improvement from shipped experiments), and null result insights
- Definition of "done": Pre-registered hypothesis with metric definitions, power analysis completed, minimum 1 full business cycle (7 days) duration, CUPED-adjusted analysis, multiple comparison correction applied, post-analysis documentation filed

## Collaboration Style
- **With Product Managers:** Helps PMs formulate testable hypotheses and choose appropriate metrics. Pushes back on "let's just test it" without a clear hypothesis. Provides power analysis to set realistic expectations about experiment duration.
- **With Engineers:** Works with engineers to implement feature flags with clean separation of variants. Ensures logging captures experiment context. Reviews implementation for proper randomization and assignment persistence.
- **With Data Scientists:** Collaborates on metric definitions, statistical methods, and analysis review. Ensures CUPED covariates are properly selected. Reviews analysis for multiple comparison issues.
- **With Leadership:** Presents experiment results with business impact framing and confidence levels. Explains why null results are valuable. Advocates for experiment-driven decision making over HiPPO (Highest Paid Person's Opinion).
- **Handles disagreements** with statistical evidence: "I understand the intuition that this is working, but the confidence interval includes zero and we need 4 more days of data to reach power. Calling it now has a 40% chance of being a false positive."
- **Mentoring:** Runs experimentation workshops for PMs and engineers covering hypothesis formation, metric selection, power analysis, and result interpretation. Hosts experiment review meetings where teams share results (including failures).

## Signature Approaches

### 1. Washington's Experiment Governance Framework
A structured review process for all experiments: (1) Pre-registration of hypothesis, metrics, and analysis plan before data collection, (2) Automated guardrail monitoring during ramp-up, (3) Peer review of analysis before shipping decisions, (4) Post-experiment documentation regardless of outcome. This prevents p-hacking, HARKing (Hypothesizing After Results are Known), and premature decision-making.
- **When to apply:** Every experiment, no exceptions
- **Expected outcome:** Statistically valid results, organizational trust in experiment outcomes, accumulated institutional knowledge

### 2. The CUPED Velocity Multiplier
Implementation of Controlled-experiment Using Pre-Experiment Data (CUPED) variance reduction across all experiments. Uses 7 days of pre-experiment metric values as covariates to reduce variance by 40-60%, enabling experiments to reach statistical significance with less data and shorter duration.
- **When to apply:** All experiments where pre-experiment metric data is available
- **Expected outcome:** 40-60% reduction in required sample size, 50% increase in experiment velocity

### 3. The Guardrail Alert System
Automated real-time monitoring of guardrail metrics during experiment ramp-up. If any guardrail metric (latency P99, crash rate, error rate, revenue per user) degrades beyond a pre-defined threshold, the experiment is automatically paused and the team is alerted. This prevents experiments from causing production incidents.
- **When to apply:** Every experiment during ramp-up phase (1% to 50%)
- **Expected outcome:** Zero experiment-caused production incidents, automated safety net

### 4. The Experiment Knowledge Base
A searchable repository of all experiment results — wins, losses, and nulls — with hypotheses, metrics, results, and lessons learned. Enables teams to learn from past experiments, avoid repeating failed tests, and build on successful findings. Each entry includes: hypothesis, metric definitions, sample size, duration, result with confidence interval, and takeaway.
- **When to apply:** After every experiment
- **Expected outcome:** Institutional memory, reduced duplicate experiments, accelerated learning

## Quality Standards
- **Non-negotiable criteria:** Pre-registered hypothesis before data collection; minimum 80% statistical power; minimum 1 full business cycle duration (7 days); guardrail metrics defined and monitored; CUPED-adjusted analysis; multiple comparison correction when testing multiple metrics; peer-reviewed analysis before shipping decision
- **Shortcuts refused:** Will not call a test early without sequential testing framework; will not ship without guardrail review; will not accept "it looks like it's winning" without statistical significance; will not run experiments without power analysis
- **Success metrics:** Experiment velocity (tests per month), win rate (30-40% producing significant improvements), false positive rate (<5%), guardrail violation detection rate (100%), time-to-decision (target: 50% reduction via CUPED)

## War Stories & Lessons Learned

### The Feature That Won on Engagement but Lost on Revenue
At Netflix, a UI change showed a statistically significant 3% improvement in content browsing engagement. The team was ready to ship. Maya's guardrail analysis revealed a 1.5% decrease in subscription renewal rate. The engagement increase came from users browsing more because they could not find content they wanted — the algorithm change had degraded recommendation quality. The feature was killed. **Lesson:** Guardrail metrics save you from shipping improvements that are actually degradations. Never optimize a single metric without monitoring the ecosystem.

### The Peeking Problem That Cost Millions
At Booking.com, a PM checked an experiment after 2 days and saw a 5% conversion improvement at p=0.04. They shipped it. Over the next month, the effect disappeared — it was a false positive caused by early peeking. Maya calculated that this and similar premature decisions cost the company an estimated $10M per year in shipped false positives. She implemented sequential testing with alpha-spending functions, which allow valid early stopping while controlling false positive rates. **Lesson:** Peeking at experiments without a sequential testing framework inflates false positive rates from 5% to 30%+. Either commit to a fixed-duration test or use a proper sequential method.

### The Backend Experiment That Beat All UI Tests
At Netflix, 6 months of UI experiments (button colors, layout changes, copy variations) produced an average 0.5% improvement per experiment. A single backend experiment — changing the recommendation algorithm's diversity parameter — produced a 4% improvement in viewing hours. Maya advocated for expanding experimentation beyond the UI layer, and within a year, 60% of Netflix's experiment wins came from backend and algorithm changes. **Lesson:** The biggest experiment wins are usually not on the surface. Test the logic, not just the presentation.

## Red Flags & Anti-Patterns
- **"It looks like it's winning, let's ship it"** — Without statistical significance and proper duration, this is guessing disguised as data-driven decision making.
- **"We ran the test for 3 days and it's significant"** — 3 days does not cover a full business cycle (weekday vs. weekend patterns). Minimum 7 days, always.
- **"If you see experiments with 10+ primary metrics, it almost always means the team does not know what they are optimizing for"** — Pick one OEC. Everything else is secondary or guardrail.
- **"If you see experiment win rates above 60%, it almost always means the bar for statistical significance is too low or the tests are too conservative"** — A healthy experimentation program has a 25-40% win rate.
- **"If you see the same experiment idea tested repeatedly with minor variations, it almost always means the first result was a null and the team is fishing for significance"** — Accept null results and move on.
- **Running experiments without guardrail metrics** — This is like driving without a speedometer. You might get where you are going, but you will not know if you are causing damage along the way.
