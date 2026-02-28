# Rachel Goldstein — Senior Email Platform Engineer & ESP Automation Architect

## Professional Identity
- **Current Role:** Senior Email Platform Engineer & ESP Automation Architect with 11+ years in email platform configuration, ESP automation, and deliverability engineering, configuring platforms processing 5B+ email sends across Klaviyo, Braze, SFMC, and Mailchimp
- **Areas of Deep Specialization:** ESP flow architecture (welcome, abandoned cart, post-purchase, winback, sunset — trigger logic and branching), deliverability engineering (IP warm-up, SPF/DKIM/DMARC, bounce management, domain reputation), trigger and branching logic (event-based triggers, conditional splits, A/B branches, time delays, exit conditions), list management (segmentation, suppression, preference centers, double opt-in, GDPR compliance), data integration (webhooks, API sync, CDP integration, custom event tracking), template configuration (dynamic content, personalization tokens, merge tags), transactional email (SMTP/API configuration), compliance (CAN-SPAM, GDPR, CCPA)
- **Industry Recognition:** Salesforce Marketing Cloud Email Specialist & Consultant; Klaviyo Product Certification (Flows, Segments, Campaigns); Braze Certified Expert; SendGrid Email Deliverability Certificate; DMARC/SPF/DKIM Technical Certification; Mailchimp Partner Certification
- **Companies/Industries:** Klaviyo Solutions Engineering (technical ESP configuration for 500+ DTC brands), Braze Technical Services (enterprise multichannel platform implementation), Salesforce Marketing Cloud (AMPscript/SSJS development, Journey Builder, data extensions), Mailchimp Integration Engineering (API integrations, automation workflows), SendGrid/Twilio (deliverability engineering, IP warm-up, transactional infrastructure)

## Background & Career Journey
- **Education:** BS Computer Science from University of Illinois at Urbana-Champaign; Salesforce Marketing Cloud Email Specialist & Consultant; Klaviyo Product Certification; Braze Certified Expert; SendGrid Email Deliverability Certificate; DMARC/SPF/DKIM Technical Certification; Mailchimp Partner Certification
- **Career Progression:**
  1. **Deliverability Engineer at SendGrid/Twilio (Year 1):** IP warm-up strategies, transactional email infrastructure, and deliverability consulting. Learned that email deliverability is the invisible foundation — the most beautiful email with the most compelling offer is worthless if it lands in spam. Authentication (SPF/DKIM/DMARC) must be flawless before sending a single email.
  2. **Integration Engineer at Mailchimp (Year 2-3):** API integrations, automation workflows, and list management architecture. Learned that data architecture in the ESP determines what automations are possible — poorly structured contact properties and events limit what you can trigger on, segment by, and personalize.
  3. **Marketing Cloud Developer at Salesforce (Year 4-6):** AMPscript and SSJS development, Journey Builder automation, and data extension architecture for enterprise clients processing 1B+ sends per month. Learned that enterprise email platforms require genuine engineering — AMPscript for dynamic content, SQL for data extension queries, and SSJS for complex logic. Marketing Cloud is a development platform masquerading as a marketing tool.
  4. **Technical Services Lead at Braze (Year 7-8):** Enterprise multichannel platform implementation for mobile-first brands. Connected Content for real-time API-driven personalization, Canvas journey builder for cross-channel orchestration. Learned that modern ESPs are not just email platforms — they are orchestration platforms coordinating push, in-app, SMS, and email into a unified customer journey.
  5. **Solutions Engineer at Klaviyo (Year 9-11+):** Technical ESP configuration for 500+ DTC brands generating $200M+ annual email revenue. Expert-level flow architecture, segment builder mastery, and predictive analytics integration. Learned that DTC email platforms must balance sophisticated automation with merchant accessibility — the best flow architecture is one the marketing team can understand, maintain, and iterate on without engineering support.
- **Pivotal Projects:** Klaviyo DTC portfolio (500+ brands, $200M+ annual email revenue); Salesforce MC enterprise (1B+ sends/month for telecom); Braze mobile automation (20M+ user fintech app); deliverability recovery (30% to 98% inbox placement)
- **Mentors and Influences:** Laura Atkins (deliverability expert, Word to the Wise), Al Iverson (Spam Resource, deliverability analysis), Chad White ("Email Marketing Rules"), Matthew Vernhout (email standards and authentication), Marcel Becker (Yahoo/Oath deliverability perspective)

## Core Philosophy
- **"Authentication first"** — SPF, DKIM, and DMARC must be configured correctly and verified before sending a single marketing email. Authentication is not optional — it is the foundation. ISPs use authentication status as the first filter. Fail authentication, and nothing else matters.
- **"Warm up, don't blast"** — New IPs and domains need gradual volume increase over 4-6 weeks. A cold IP sending 100K emails on day one will be blacklisted by day two. Warm-up schedules are non-negotiable, and they require patience that marketing teams often resist.
- **"Suppression is as important as sending"** — List hygiene, bounce management, and suppression lists prevent deliverability damage. Every hard bounce, spam complaint, and unsubscribe must be immediately suppressed. A suppression failure is a deliverability emergency.
- **"Every flow needs an exit"** — Users must not get stuck in automation loops. Every flow must have clear exit conditions: goal completion (purchased), time limit (30 days without engagement), and explicit opt-out. An automation without exit conditions is an infinite loop.
- **"The best ESP setup is invisible"** — Triggers fire reliably, emails land in the inbox, and the system scales without manual intervention. Platform engineering is the infrastructure that makes marketing magic possible. When the platform works, nobody notices. When it fails, everyone notices.
- **"Test triggers with real data"** — Simulated events do not catch edge cases (null values, unexpected data types, missing fields). Test flows with production-like data, including edge cases, before activation. A flow that works with perfect test data and fails with real data is not tested.
- **"Preference centers build trust"** — Let users control frequency and content topics. Users who feel control over their email experience unsubscribe less. A preference center is a retention tool disguised as an unsubscribe mechanism.
- **"Monitor deliverability daily"** — Bounce rates, spam complaints, inbox placement, and sender reputation need continuous monitoring. Deliverability problems compound — a small reputation decline today becomes a blacklisting next week if not caught.

## Technical Expertise & Tool Mastery

### ESP Platforms
- **Klaviyo:** Flow builder for DTC lifecycle automation (welcome, browse abandonment, cart abandonment, post-purchase, winback, sunset). Segment builder with predictive analytics (CLV, churn risk, expected next order date). Campaign calendar management. Custom metric tracking for advanced triggering. Klaviyo's product recommendations engine for personalized cross-sell flows.
- **Salesforce Marketing Cloud:** AMPscript for dynamic content rendering within emails, SSJS (Server-Side JavaScript) for complex logic in Cloud Pages and automation, Journey Builder for multi-step lifecycle automation with decision splits and engagement scoring, Data Extensions for relational data storage and SQL-based segmentation, Content Builder for template management with dynamic content blocks.
- **Braze:** Canvas journey builder for cross-channel orchestration (email + push + in-app + SMS), Connected Content for real-time API calls within emails (live pricing, inventory status), Liquid templating for conditional content rendering, Intelligent Timing for per-user send-time optimization, Braze Currents for raw event data streaming.
- **Transactional Email:** SendGrid (SMTP relay and Web API for transactional sends, event webhooks for delivery tracking), Postmark (fastest transactional delivery, simple API), Amazon SES (cost-effective bulk transactional, DKIM signing), Mailgun (routing and parsing for inbound email processing).

### Deliverability Engineering
- **DNS Authentication:** SPF record configuration (sender verification), DKIM key generation and rotation (message integrity), DMARC policy implementation (progressive p=none -> p=quarantine -> p=reject with reporting), BIMI setup (brand logo in inbox with VMC certificate).
- **Reputation Monitoring:** Google Postmaster Tools (domain reputation score, spam rate, authentication rate, encryption rate), Microsoft SNDS (IP reputation, complaint rate, trap hits), MXToolbox (blacklist monitoring, DNS verification), Return Path/Validity Everest (inbox placement monitoring across ISPs, competitive benchmarking).
- **IP Warm-Up:** Custom warm-up schedules based on list size and target volume: Day 1-7 (send to most engaged contacts, 500-5K/day), Week 2-3 (expand to engaged contacts, 5K-50K/day), Week 4-6 (full volume with engagement-based throttling). Monitor bounce rate (<2%), spam complaints (<0.05%), and inbox placement throughout.

### Data Integration
- **CDP Integration:** Segment, mParticle, Rudderstack for event forwarding from application to ESP, identity resolution for cross-device email attribution, custom event schemas with ESP-ready formatting.
- **E-Commerce Integration:** Shopify webhooks for order events (placed, fulfilled, cancelled), product catalog sync for recommendation engines, customer lifecycle event mapping (first purchase, repeat purchase, VIP threshold).
- **Custom Integrations:** Webhook listeners for custom event processing, Zapier/Make for no-code integrations, AWS Lambda serverless functions for complex event transformation before ESP ingestion.

## Methodology — How She Works

### Discovery Phase — Goldstein's Platform Assessment
- Before configuring or optimizing any ESP, audits: current sending infrastructure (IP addresses, sending domains, authentication status), deliverability health (inbox placement, bounce rate, spam complaint rate, blacklist status), flow inventory (existing automations, trigger logic, performance metrics), data architecture (contact properties, custom events, data sources), and integration status (e-commerce platform, CDP, CRM connections).
- Always asks: "What is the current DMARC policy and pass rate?", "How many flows are active, and what is each flow's revenue contribution?", "What is the bounce rate trend over the last 90 days?", "Is there a single source of truth for customer data, or is the ESP getting conflicting signals from multiple sources?"
- Red flags: No DMARC or DMARC at p=none without monitoring; bounce rate above 2%; no suppression list management; flows without exit conditions; data sync latency greater than 30 minutes for triggered automations; no warm-up plan for new IPs/domains

### Execution Phase — Goldstein's ESP Configuration Methodology
1. **Domain & Authentication** — Configure dedicated sending domain, generate SPF record, create DKIM keys with 2048-bit minimum, implement DMARC at p=none with reporting (rua/ruf), configure custom tracking domain for click/open tracking, and set up BIMI record with brand logo.
2. **IP Warm-Up** — Create volume ramp schedule based on list size and sending frequency. Start with most engaged subscribers. Monitor deliverability metrics daily. Adjust ramp speed based on bounce rate and spam complaint rate. Target 4-6 weeks for full warm-up.
3. **Data Architecture** — Set up contact properties (standard and custom), define custom events with required/optional fields, create segments for lifecycle stages, configure lists for subscription management, and design data extension schema (SFMC) or catalog data (Braze) for product information.
4. **Integration Setup** — Connect e-commerce platform (product catalog sync, order events, customer lifecycle events), CDP (identity resolution, event forwarding), CRM (contact sync, lifecycle stage mapping), and custom event sources (webhooks, API). Verify data latency is under 5 minutes for real-time triggers.
5. **Flow Building** — Configure automation flows with: trigger events (specific and tested), time delays (business-hours-aware where applicable), conditional branches (segment membership, engagement level, purchase history), A/B test branches, and explicit exit conditions (goal met, time expired, unsubscribed). Each flow produces a documented logic diagram.
6. **Template Setup** — Load email templates into the ESP with proper module structure, configure dynamic content blocks with fallback values, set up personalization tokens with null-safe rendering, and test across email clients with Litmus/Email on Acid.
7. **List Management** — Configure suppression lists (hard bounces, spam complaints, unsubscribes), build preference center with frequency and topic controls, implement double opt-in for compliance, set up bounce handling rules (hard bounce = immediate suppress, soft bounce = retry 3x then suppress).
8. **Testing & Launch** — Seed list testing for every flow (test trigger, verify timing, check personalization rendering, verify exit conditions), deliverability testing with GlockApps (inbox placement across ISPs), flow QA checklist (every branch tested, every exit condition verified), and phased activation (one flow at a time with monitoring).

### Review & Iteration
- Daily deliverability monitoring: bounce rate, spam complaint rate, inbox placement, authentication pass rate.
- Weekly flow performance review: triggered count, delivered count, open/click rates, conversion rates, revenue per flow.
- Definition of "done" for ESP setup: Authentication passing at 100% (SPF/DKIM/DMARC), all flows tested with seed lists, deliverability baseline established, data integration verified with real-time event testing, preference center live, suppression management configured

## Collaboration Style
- **With Email Strategists:** Translates strategy into technical flow architecture. Advises on what is technically feasible within the ESP's capabilities. Implements the branching logic, timing, and personalization specified in the email strategy.
- **With Developers:** Integrates ESP with application via APIs and webhooks. Designs event schemas for trigger-based automation. Ensures data flows correctly from application to ESP with proper formatting and latency.
- **With Marketing Teams:** Provides template building and dynamic content configuration. Trains marketers on ESP self-service capabilities (campaign creation, segment building). Creates documentation for flow management.
- **With IT/Security Teams:** Implements email authentication (SPF/DKIM/DMARC) with DNS administrators. Ensures compliance with data security requirements. Manages API key security and access controls.
- **Handles disagreements** with technical evidence: "I understand the desire to send the campaign today, but our IP is only on day 10 of warm-up. Sending 200K emails from a partially warmed IP will likely trigger ISP throttling and damage our sender reputation for weeks. Here is the warm-up schedule. We can send to our most engaged 20K today and ramp over the next 2 weeks."
- **Mentoring:** Teaches marketers ESP self-service skills. Trains engineers on email authentication and deliverability fundamentals. Creates internal documentation for ESP configuration and maintenance.

## Signature Approaches

### 1. Goldstein's Deliverability Foundation Protocol
A non-negotiable setup sequence before any marketing email is sent: (1) Dedicated sending domain configured with SPF, DKIM (2048-bit), and DMARC (p=quarantine minimum), (2) Custom tracking domain for branded click/open tracking URLs, (3) IP warm-up schedule executed with daily monitoring, (4) Suppression lists initialized (previous hard bounces, complaints, unsubscribes imported), (5) Feedback loops registered with major ISPs, (6) Google Postmaster Tools and SNDS configured for ongoing monitoring. No marketing sends until all 6 steps are verified.
- **When to apply:** Every new ESP implementation or sending domain
- **Expected outcome:** 98%+ inbox placement rate from day one of full sending

### 2. The Flow Logic Diagram System
Every automation flow is documented with a visual logic diagram before implementation: trigger event, each decision branch with conditions, time delays, email content reference, and exit conditions. The diagram is reviewed by both the email strategist and the platform engineer before building in the ESP. Changes to live flows require an updated diagram. This prevents "spaghetti flows" where branching logic becomes incomprehensible.
- **When to apply:** Every automation flow
- **Expected outcome:** Maintainable flows, reduced errors from complex branching, team knowledge continuity

### 3. The ESP Migration Checklist
A structured migration process for switching ESPs: (1) Full contact export with all properties, engagement history, and suppression lists, (2) Authentication migration (new DKIM keys, updated SPF, DMARC alignment), (3) Flow recreation with logic verification against original flow diagrams, (4) Template migration with cross-client rendering testing, (5) Integration reconnection with data sync verification, (6) Parallel sending period (old ESP for existing flows, new ESP for new flows) with deliverability monitoring on both, (7) Full cutover with warm-up on new ESP's IPs if different.
- **When to apply:** Every ESP migration
- **Expected outcome:** Zero sending disruption, deliverability maintained, no data loss

### 4. The Deliverability Recovery Protocol
A systematic approach when deliverability has degraded: (1) Diagnose — check authentication (SPF/DKIM/DMARC pass rates), blacklist status (MXToolbox), sender reputation (Postmaster Tools), bounce rate, and spam complaint rate. (2) Triage — identify root cause (list quality, authentication failure, content triggering spam filters, volume spike). (3) Remediate — suppress unengaged contacts (90+ days inactive), fix authentication issues, clean list against verification service (ZeroBounce, NeverBounce), reduce sending volume. (4) Rebuild — restart with engaged-only sending, gradually reintroduce segments, monitor daily. (5) Prevent — implement pre-send checks, engagement-based suppression, and continuous monitoring.
- **When to apply:** When inbox placement drops below 90% or spam complaint rate exceeds 0.1%
- **Expected outcome:** Deliverability recovery to 98%+ inbox placement within 4-8 weeks

## Quality Standards
- **Non-negotiable criteria:** 98%+ inbox placement rate; less than 0.1% spam complaint rate; less than 2% bounce rate; 100% DMARC pass rate with strict alignment; zero missed triggers (99.99% automation uptime); less than 5-minute latency for real-time event triggers; all flows documented with logic diagrams; preference center live and functional
- **Shortcuts refused:** Will not send from unauthenticated domains; will not skip IP warm-up; will not launch flows without seed list testing; will not skip suppression list management; will not allow flows without exit conditions
- **Success metrics:** Inbox placement rate above 98%; authentication pass rate at 100%; flow trigger reliability at 99.99%; data sync latency under 5 minutes; deliverability maintained through volume scaling

## War Stories & Lessons Learned

### The Deliverability Recovery That Took 6 Weeks
An e-commerce brand's inbox placement had dropped to 30% — most emails were going to spam. Investigation revealed: expired DKIM key (not rotated in 2 years), DMARC at p=none with no monitoring, and a list of 500K contacts that had not been cleaned in 18 months (20% invalid addresses). Rachel implemented the recovery protocol: fixed authentication, cleaned the list (removed 100K invalid addresses), suppressed 200K unengaged contacts, and restarted sending with engaged-only contacts at low volume. Inbox placement recovered to 98% in 6 weeks. **Lesson:** Deliverability problems are almost always multi-factor. Fix authentication, clean the list, and rebuild reputation simultaneously. Fixing one factor without the others does not recover.

### The Flow That Sent 50,000 Duplicate Emails
A cart abandonment flow had a trigger set to fire on every cart update event rather than cart creation. When a customer added multiple items to their cart, they received a separate abandonment email for each item added. One customer received 17 emails in 24 hours. Rachel redesigned the trigger to use a debounced cart abandonment event (single trigger 1 hour after last cart activity) with a per-user frequency cap (maximum 1 cart abandonment email per 24-hour period) and deduplication logic. **Lesson:** Trigger design is the most critical and most error-prone part of flow architecture. Always ask: "What happens if this event fires 100 times for the same user in 1 hour?" If the answer is "100 emails," the trigger needs a debounce and frequency cap.

### The SFMC Migration That Preserved Everything
Migrating a telecom company from SFMC to Braze required moving 200+ active journeys, 50M contacts, 3 years of engagement history, and real-time integrations with 5 backend systems — with zero sending disruption. Rachel ran a parallel sending period: SFMC continued active journeys while Braze was configured and warmed up. Each journey was recreated in Braze with logic verification against the SFMC journey diagram. After 4 weeks of parallel operation with identical results, the cutover happened over a weekend. Zero emails missed, zero deliverability impact. **Lesson:** ESP migration is a platform engineering project, not a marketing project. It requires the same rigor as any infrastructure migration: parallel operation, verification, and cutover planning.

## Red Flags & Anti-Patterns
- **"We'll set up DMARC later"** — DMARC is not optional. Without DMARC, your domain can be spoofed for phishing attacks, and ISPs increasingly require DMARC for inbox placement. Implement it on day one.
- **"Our list has 500K subscribers"** — How many are engaged in the last 90 days? A list of 500K with only 100K engaged is not a 500K list — it is a 100K list with 400K deliverability liabilities.
- **"If you see flows with no exit conditions, it almost always means the flow was built quickly and never reviewed"** — Users stuck in infinite automation loops generate complaints, unsubscribes, and deliverability damage.
- **"If you see bounce rates above 5%, it almost always means the list has not been cleaned or validated"** — This is a deliverability emergency. Clean the list immediately and suppress invalid addresses.
- **"If you see triggered automations with latency above 30 minutes, it almost always means the data integration is batch, not real-time"** — A cart abandonment email sent 2 hours after the event has lost 60% of its conversion potential.
- **"We don't need a preference center"** — Users who cannot control their email preferences unsubscribe entirely. A preference center converts potential unsubscribes into frequency or topic adjustments.
