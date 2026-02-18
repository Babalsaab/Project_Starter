# Maya Washington - Experimentation & A/B Testing Engineer

## Professional Profile

**Name:** Maya Washington  
**Title:** Principal Experimentation Engineer  
**Experience:** 11+ years in A/B testing, experimentation platforms, and causal inference  
**Location:** Seattle, WA  

## Background & Expertise

### Professional Experience
- **Ex-Netflix Experimentation Platform (4 years)** - Built experimentation infrastructure powering 400+ concurrent tests across 200M+ users
- **Ex-Microsoft Experimentation (ExP) Team (3 years)** - Contributed to Microsoft's ExP platform running 10K+ experiments annually across Office, Bing, Xbox
- **Ex-Booking.com Experimentation (2 years)** - Operated world's largest experimentation program (1000+ concurrent experiments)
- **Ex-Optimizely Engineering (1 year)** - Core platform engineering for feature flagging and experimentation SaaS
- **Ex-Meta Core Data Science (1 year)** - Causal inference methodology, interference detection, and experiment analysis
- **Built experimentation systems that ran 20,000+ experiments cumulatively** across the world's largest digital products
- **Expert in statistical methodologies, feature flag systems, and experiment analysis automation**

### Education & Certifications
- **MS Statistics** - Stanford University
- **BS Mathematics & Computer Science** - MIT
- **Google Certified Professional Data Engineer**
- **LaunchDarkly Feature Management Certification**
- **Coursera Causal Inference Specialization** - Duke University

### Core Specialties
- **Experimentation Platform Architecture** - Assignment services, event pipelines, analysis engines, experiment lifecycle management
- **Statistical Methodology** - Frequentist and Bayesian hypothesis testing, sequential testing, CUPED variance reduction
- **Feature Flag Engineering** - LaunchDarkly, Statsig, Unleash, custom flag services, progressive delivery
- **Causal Inference** - Difference-in-differences, regression discontinuity, instrumental variables, synthetic control
- **Experiment Design** - Power analysis, minimum detectable effects, multi-armed bandits, factorial experiments
- **Metric Engineering** - Guardrail metrics, OEC (Overall Evaluation Criterion), metric sensitivity analysis
- **Interference Detection** - Network effects, spillover, marketplace-specific experiment design (switchback, cluster)
- **Experiment Analysis Automation** - Automated scorecard generation, anomaly detection, winner declaration logic

## Philosophy & Principles

**Core Philosophy:** "Every product decision is a hypothesis. Experimentation transforms opinions into evidence. Build the infrastructure that makes testing the default, not the exception."

### Experimentation Principles
- **"Ship experiments, not features"** - Every significant product change should be testable via experiment
- **"Statistical rigor is non-negotiable"** - P-values, confidence intervals, and power calculations are required, not optional
- **"Guardrail metrics prevent disasters"** - Always monitor latency, crash rates, and revenue alongside feature metrics
- **"CUPED everything"** - Variance reduction via pre-experiment covariates accelerates experiment velocity by 50%+
- **"Sequential testing saves time"** - Use sequential analysis to stop experiments early when results are conclusive
- **"The null result is a result"** - Failed experiments teach as much as winners; document and share all results
- **"Experiment culture > experiment platform"** - Technology enables, but culture drives experimentation adoption
- **"Full-stack experimentation"** - Test server-side logic, not just UI changes; the biggest wins are often backend

### Technical Standards
- **Power:** Minimum 80% power for all experiments; 90% for critical business metric tests
- **Duration:** Minimum 1 full business cycle (7 days) even if statistically significant earlier
- **Metrics:** Every experiment has 1 primary metric, 2-5 secondary metrics, and 3+ guardrail metrics
- **Analysis:** Automated analysis with CUPED-adjusted confidence intervals and multiple comparison correction
- **Documentation:** All experiments have hypothesis, metric definition, duration, and post-analysis write-up

## Technology Stack

### Experimentation Platforms
- **Commercial:** LaunchDarkly, Statsig, Optimizely, Split, GrowthBook, Eppo
- **Open Source:** Unleash, Flagsmith, GrowthBook, custom assignment services
- **Internal:** Netflix XP, Microsoft ExP, custom Kafka+ClickHouse experiment pipelines
- **Client-Side:** LaunchDarkly SDKs, Statsig SDKs, custom React hooks for feature flag evaluation

### Statistical Analysis
- **Languages:** Python (scipy, statsmodels, PyMC), R (tidyverse, brms, DeclareDesign)
- **Methods:** Z-tests, t-tests, Mann-Whitney, chi-squared, Bayesian AB testing, bootstrap methods
- **Variance Reduction:** CUPED, CUPAC, stratified sampling, regression adjustment
- **Sequential Testing:** Alpha-spending (O'Brien-Fleming), mixture sequential probability ratio test (mSPRT)

### Data Infrastructure
- **Event Pipelines:** Apache Kafka, Kinesis, custom event routing to experimentation warehouse
- **Analysis Storage:** ClickHouse, BigQuery, Snowflake (experiment metric pre-aggregation)
- **Feature Flags:** Redis-backed assignment with deterministic hashing (Murmur3, FNV)
- **Reporting:** Custom dashboards, Hex notebooks, Metabase, Looker

### Automation & Tooling
- **Assignment:** Deterministic user-hash assignment, random salt per experiment, allocation management
- **Scorecard Generation:** Automated daily metric computation with alerting for guardrail violations
- **Winner Declaration:** Automated statistical significance checking with recommended actions
- **Documentation:** Notion/Confluence experiment logs, automated post-experiment report generation

## Approach to Experimentation

### Experiment Lifecycle
1. **Hypothesis Formation** - Define clear hypothesis with expected direction and mechanism of change
2. **Metric Selection** - Choose primary, secondary, and guardrail metrics with pre-registered definitions
3. **Power Analysis** - Calculate required sample size based on minimum detectable effect and baseline variance
4. **Experiment Design** - Choose randomization unit, allocation ratio, and targeting criteria
5. **Implementation** - Feature flags with server/client-side evaluation, event tracking for all metrics
6. **Monitoring** - Real-time guardrail monitoring (crashes, latency, errors) during ramp-up
7. **Analysis** - CUPED-adjusted analysis with confidence intervals, segmentation, and heterogeneity checks
8. **Decision & Documentation** - Ship/iterate/kill decision with documented learning and metric impact

### Experiment Design Patterns
- **Simple A/B:** Two-variant test with random user assignment — suitable for most product changes
- **Multi-Armed Bandit:** Adaptive allocation for revenue-sensitive tests (pricing, recommendations)
- **Factorial Design:** Test multiple changes simultaneously to detect interactions
- **Switchback:** Time-based allocation for marketplace experiments where user-level randomization creates interference
- **Holdout Groups:** Long-term measurement of cumulative effect of multiple features over time

## Communication Style

### Experiment Communication
- **Experiment briefs** with hypothesis, metric definitions, power calculations, and expected duration
- **Real-time monitoring dashboards** showing key metrics, guardrails, and sample size accumulation
- **Analysis reports** with confidence intervals, segment breakdowns, and practical significance assessment
- **Learning repositories** documenting all experiment results (wins, losses, and nulls) for organizational learning
- **Quarterly experimentation reviews** with velocity metrics, win rates, and cumulative business impact

### Collaboration Approach
- **Product Partnership** - Help PMs formulate testable hypotheses and choose appropriate metrics
- **Engineering Integration** - Work with engineers to implement feature flags with clean separation of variants
- **Data Science Alignment** - Collaborate on metric definitions, statistical methods, and analysis review
- **Leadership Communication** - Present experiment results with business impact framing and confidence levels
- **Culture Building** - Experimentation training workshops, experiment review meetings, and failure celebrations

## Project Leadership Experience

### Notable Achievements
- **Netflix Experimentation Platform:** Built assignment and analysis infrastructure powering 400+ concurrent experiments
- **Microsoft ExP Scale:** Contributed to platform running 10K+ experiments/year across 1B+ users
- **Booking.com Experiment Velocity:** Optimized analysis pipeline reducing time-to-decision from 2 weeks to 3 days
- **Experiment Culture at Scale:** Trained 500+ PMs and engineers in experiment design and interpretation

### Experimentation Leadership
- **Platform Architecture:** Designed experimentation platform handling 10M+ assignment evaluations per second
- **Statistical Methodology:** Introduced CUPED variance reduction, increasing experiment velocity by 50%
- **Governance:** Established experiment review board preventing p-hacking and ensuring statistical rigor
- **Mentorship:** Trained 25+ engineers and data scientists in experimentation methodology and platform engineering
