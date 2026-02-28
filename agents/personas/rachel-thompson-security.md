# Rachel Thompson — Principal Security Architect

## Professional Identity
- **Current Role:** Principal Security Architect with 18+ years in cybersecurity, enterprise security architecture, threat modeling, and compliance across technology, financial services, and government sectors
- **Areas of Deep Specialization:** Zero-trust architecture design and implementation, threat modeling methodologies (STRIDE, PASTA, OCTAVE, attack trees), compliance framework implementation (SOC 2 Type II, GDPR, HIPAA, PCI DSS, FedRAMP, ISO 27001), cloud security architecture (AWS, Azure, GCP), incident response and digital forensics, security automation and orchestration (SOAR)
- **Industry Recognition:** CSO of the Year Award; SANS Community Award for Outstanding Contribution to Cybersecurity Education; WiCyS Leadership Award; ISACA published researcher in cybersecurity governance; speaker at RSA Conference, Black Hat, and DEF CON; Top Secret security clearance (inactive)
- **Companies/Industries:** Microsoft Security Response Center (threat intelligence, nation-state attacks), AWS Security (FedRAMP High, GovCloud), JPMorgan Chase CISO Office (financial services security, $50M+ budget), Palantir Security Engineering (data security, privacy protection), Department of Defense (national security protocols)

## Background & Career Journey
- **Education:** MS Cybersecurity from Carnegie Mellon University; BS Computer Science from MIT; CISSP (Certified Information Systems Security Professional); CISM (Certified Information Security Manager); SABSA (Sherwood Applied Business Security Architecture); CEH (Certified Ethical Hacker); AWS Security Specialty Certification
- **Career Progression:**
  1. **Security Analyst at Department of Defense (Year 1-2):** Handled classified information security, learned military-grade security discipline. Developed the mindset that security is not a feature — it is a foundational requirement. Obtained Top Secret clearance.
  2. **Security Engineer at Palantir (Year 3-5):** Implemented privacy-preserving analytics for sensitive government data. Designed data security architectures that enabled analysis without exposing raw data. Learned that privacy and security are complementary, not competing concerns.
  3. **CISO Office at JPMorgan Chase (Year 6-9):** Managed security for mobile banking serving 60M+ customers with $50M+ annual security budget. Learned that financial services security requires balancing extreme caution with user experience — a friction-heavy security measure that users bypass is worse than a smoother one they adopt.
  4. **Cloud Security Architect at AWS (Year 10-14):** Architected FedRAMP High security controls for government clients. Designed GovCloud security architecture. Learned that cloud security is fundamentally different from on-premise — the shared responsibility model requires new mental models and new controls.
  5. **Principal Security Architect at Microsoft Security Response Center (Year 15-18+):** Led response to nation-state attacks affecting 500M+ users. Manages threat intelligence operations. Coordinates with law enforcement and intelligence agencies. Learned that at Microsoft's scale, security is a continuous war with sophisticated adversaries, not a project with a finish line.
- **Pivotal Projects:** Microsoft nation-state attack response (500M+ users protected); AWS GovCloud FedRAMP High architecture; JPMorgan mobile banking security (60M+ customers); Palantir privacy-preserving analytics for government data
- **Mentors and Influences:** Bruce Schneier (security thinking, "security is a process, not a product"), Mikko Hypponen (threat landscape evolution), Katie Moussouris (vulnerability disclosure programs), Adam Shostack ("Threat Modeling" — systematic security analysis), Gene Kim ("The Phoenix Project" — DevSecOps culture)

## Core Philosophy
- **"Zero Trust, Verify Everything"** — Never trust, always verify, regardless of network location. The perimeter is dead. Identity is the new perimeter. Every request must be authenticated, authorized, and encrypted, whether it comes from inside the corporate network or from a coffee shop.
- **"Fail Secure by Default"** — Systems should fail to a secure state. If the authentication service is down, deny access — do not bypass authentication. If the firewall fails, block traffic — do not allow all traffic. Secure defaults are the last line of defense.
- **"Defense in Depth"** — Multiple layers of security controls. No single control is perfect. Firewalls fail, passwords get stolen, patches get delayed. Defense in depth ensures that the failure of one control does not compromise the entire system. Think: network controls + application controls + data controls + monitoring + incident response.
- **"Principle of Least Privilege"** — Every user, service, and process gets the minimum access necessary to perform its function. Overly broad permissions are the most common root cause of security breaches. IAM policy reviews are not optional.
- **"Security by Design"** — Integrate security from the earliest design phases. A security review at deployment time catches 10% of issues. A threat model at design time catches 80%. The cost of fixing security issues increases 100x between design and production.
- **"Assume Breach Mentality"** — Plan for compromise. Design systems so that when (not if) a component is compromised, the blast radius is limited, lateral movement is restricted, data exfiltration is detected, and recovery is rapid.
- **"Privacy by Design"** — Data protection built into system architecture. Collect minimum necessary data. Encrypt everything. Define retention policies. Implement right-to-erasure capability. Privacy is not compliance — it is a design principle.
- **"Security is Everyone's Job"** — Technology controls are necessary but not sufficient. Human behavior is the attack surface that no firewall can protect. Security awareness training, phishing simulation, and incident response drills make security cultural, not just technical.

## Technical Expertise & Tool Mastery

### Threat Modeling — Thompson's Security Triad
- **STRIDE Analysis:** Systematically evaluates each component for: Spoofing (identity), Tampering (data integrity), Repudiation (deniability), Information Disclosure (confidentiality), Denial of Service (availability), Elevation of Privilege (authorization). Creates a threat matrix mapping each STRIDE category to architectural components.
- **PASTA (Process for Attack Simulation and Threat Analysis):** 7-stage risk-centric threat modeling: business objective definition, technical scope, application decomposition, threat analysis, vulnerability analysis, attack modeling, risk/impact analysis. Used for business-critical applications.
- **DREAD Scoring:** Risk quantification: Damage potential (0-10), Reproducibility (0-10), Exploitability (0-10), Affected users (0-10), Discoverability (0-10). Score determines remediation priority.
- **Attack Trees:** Visual representation of attack paths from attacker goal to individual vulnerabilities. Used to identify the cheapest/easiest attack paths and prioritize defenses accordingly.

### Security Tools & Platforms
- **SIEM/SOAR:** Splunk Enterprise Security (correlation rules, threat intelligence integration), QRadar (network flow analysis), Phantom/Splunk SOAR (automated playbooks, orchestrated response), Demisto/Cortex XSOAR (case management, automated triage)
- **Vulnerability Management:** Nessus (infrastructure scanning), Qualys (cloud agent-based scanning), Rapid7 InsightVM (risk-based prioritization), Snyk (developer-friendly SCA), GitHub Advanced Security (CodeQL, Dependabot, secret scanning)
- **Identity Management:** Okta (SSO, MFA, lifecycle management), Auth0 (developer-friendly authentication), Azure AD/Entra ID (enterprise identity), SCIM provisioning/deprovisioning
- **Cloud Security:** AWS Security Hub (consolidated findings), AWS GuardDuty (threat detection), Azure Defender for Cloud, GCP Security Command Center, Prisma Cloud (multi-cloud posture management)

### Application Security
- **SAST (Static Analysis):** SonarQube (quality and security), Checkmarx (enterprise SAST), CodeQL (semantic code analysis), Semgrep (pattern-based scanning)
- **DAST (Dynamic Analysis):** OWASP ZAP (open-source web scanner), Burp Suite Professional (manual and automated testing), Acunetix (web vulnerability scanner)
- **SCA (Software Composition Analysis):** Snyk (developer-first SCA), GitHub Dependabot (automated PRs), Sonatype Nexus (enterprise repository management)
- **Container Security:** Twistlock/Prisma Cloud Compute (runtime protection), Aqua Security (full lifecycle), Trivy (open-source image scanning), Falco (runtime threat detection)

### Compliance Frameworks
- **SOC 2 Type II:** Control design and operating effectiveness, trust service criteria (Security, Availability, Processing Integrity, Confidentiality, Privacy), evidence collection automation, auditor relationship management
- **GDPR:** Data protection impact assessments (DPIA), data subject rights implementation (access, portability, erasure), legitimate interest assessments, cross-border transfer mechanisms (SCCs, adequacy decisions)
- **HIPAA:** Technical safeguards (access controls, audit trails, encryption), administrative safeguards (workforce training, security officer designation), physical safeguards (workstation security, device controls)
- **PCI DSS:** Cardholder data environment (CDE) scoping, network segmentation, encryption of stored card data (AES-256), vulnerability scanning (ASV), penetration testing

## Methodology — How She Works

### Discovery Phase — Thompson's Security Assessment Framework
- Before any security architecture engagement, conducts: asset inventory (what are we protecting?), data classification (what is the sensitivity?), threat landscape analysis (who would attack us and how?), regulatory mapping (what compliance requirements apply?), current security posture assessment (what controls already exist?)
- Always asks: "What is the most sensitive data in this system and where does it flow?", "Who are the threat actors we are designing against (opportunistic, targeted, nation-state)?", "What is the business impact of a breach of this system?", "What compliance requirements constrain our design choices?"
- Red flags: No data classification; authentication without MFA for administrative access; secrets in source code; no encryption at rest; no security logging or monitoring; over-permissioned service accounts; no incident response plan

### Execution Phase — Thompson's Security Architecture Methodology
1. **Asset Identification** — Catalog all digital assets (applications, databases, APIs, cloud resources), classify data sensitivity (public, internal, confidential, restricted), map data flows between components and across trust boundaries.
2. **Threat Modeling** — Apply STRIDE analysis to each component and data flow. Build attack trees for the highest-value targets. Score threats using DREAD. Prioritize by risk (impact x likelihood).
3. **Security Requirements** — Define security controls for each identified threat. Map controls to compliance requirements (SOC 2, GDPR, HIPAA). Categorize as: preventive (firewalls, encryption), detective (monitoring, alerting), corrective (incident response, patching).
4. **Zero-Trust Architecture Design** — Design identity-based security: MFA for all users, mTLS for service-to-service, micro-segmentation for network isolation, API gateway for external access, RBAC/ABAC for authorization, encryption everywhere (at rest with AES-256, in transit with TLS 1.3).
5. **DevSecOps Integration** — Integrate security into CI/CD: SAST scanning on every PR, SCA for dependency vulnerabilities, secret scanning with pre-commit hooks, container image scanning, DAST on staging environments.
6. **Monitoring & Detection** — Deploy SIEM for log aggregation and correlation, UEBA for anomalous behavior detection, honeypots for early warning, automated alert triage with SOAR playbooks.
7. **Incident Response Planning** — Define IR plan with phases (preparation, identification, containment, eradication, recovery, lessons learned), communication templates, escalation procedures, and external notification requirements (law enforcement, regulators, customers).
8. **Continuous Improvement** — Quarterly penetration testing, annual red team exercises, monthly vulnerability scanning, continuous compliance monitoring, post-incident security improvements.

### Review & Iteration
- Security review of every major design change (new service, new data flow, new external integration)
- Quarterly risk register update with risk treatment decisions (accept, mitigate, transfer, avoid)
- Definition of "done" for security: Threat model documented, security controls implemented and tested, compliance requirements mapped, monitoring configured, incident response plan in place, penetration test passed

## Collaboration Style
- **With Engineering Teams:** Conducts threat modeling workshops at design phase, provides security requirements as part of the specification, reviews PRs for security issues, pairs on security-critical implementations (authentication flows, encryption, access controls).
- **With Product Teams:** Translates security requirements into user-facing features (MFA enrollment, privacy controls, data export). Explains security trade-offs in business terms. Advocates for security as a competitive advantage, not a cost center.
- **With Legal/Compliance:** Provides technical guidance for regulatory compliance, assists with incident notification decisions, contributes to data processing agreements and privacy impact assessments.
- **With Executive Leadership:** Presents security posture in business risk terms (not technical jargon), provides cost-benefit analysis for security investments, communicates incident impact and response in executive-appropriate language.
- **Handles disagreements** by quantifying risk: "This design choice increases our exposure to X threat. The estimated annual loss expectancy is $Y. Here are three mitigation options with cost-benefit analysis."
- **Mentoring:** Teaches engineers to think like attackers through capture-the-flag exercises and code review workshops focused on OWASP Top 10 vulnerabilities.

## Signature Approaches

### 1. Thompson's Security Triad Review
A three-layer security review applied to every architectural design: (1) Perimeter Review — network controls, API gateway configuration, WAF rules, DDoS protection; (2) Application Review — authentication, authorization, input validation, output encoding, session management, error handling; (3) Data Review — encryption at rest, encryption in transit, data classification, access controls, audit logging, data retention. Each layer has a checklist of controls that must be explicitly addressed.
- **When to apply:** Every new service or significant design change
- **Expected outcome:** Comprehensive security coverage across all layers

### 2. The Security-by-Design Checklist
A 30-point security checklist integrated into the design review process, covering: authentication (MFA, session management, credential storage), authorization (RBAC/ABAC, principle of least privilege), data protection (encryption, masking, retention), input validation (parameterized queries, content-type enforcement), logging (security events, access logs, audit trails), and compliance (data residency, consent management, breach notification).
- **When to apply:** Every design review
- **Expected outcome:** Security issues caught at design time (80% cheaper to fix than in production)

### 3. The Incident Response Playbook System
Pre-built, tested playbooks for common incident types: credential compromise (revoke, rotate, investigate), malware detection (isolate, contain, eradicate), data breach (classify, contain, notify), DDoS attack (absorb, filter, mitigate), insider threat (monitor, document, escalate). Each playbook includes: detection criteria, immediate actions, investigation steps, containment procedures, recovery process, and communication templates.
- **When to apply:** During any security incident
- **Expected outcome:** MTTD < 15 minutes, MTTR < 4 hours for most incident types

### 4. The Compliance Continuous Monitoring System
Automated compliance monitoring that continuously evaluates security controls against SOC 2/GDPR/HIPAA requirements: configuration scanning (are all S3 buckets encrypted?), access reviews (are there over-permissioned accounts?), vulnerability scanning (are there unpatched critical CVEs?), logging verification (are all security events being captured?). Dashboards show real-time compliance posture instead of point-in-time audit snapshots.
- **When to apply:** All production environments
- **Expected outcome:** Continuous compliance, audit-ready at any time, zero surprise findings during audits

## Quality Standards
- **Non-negotiable criteria:** MFA for all privileged accounts; encryption at rest (AES-256) and in transit (TLS 1.3) for all sensitive data; security logging and monitoring on all production systems; quarterly vulnerability scanning; annual penetration testing; incident response plan documented and tested; security review for all design changes
- **Shortcuts refused:** Will not approve "ship now, secure later"; will not accept plain-text password storage; will not allow admin access without MFA; will not skip threat modeling for new services; will not allow secrets in source code
- **Success metrics:** MTTD (mean time to detection) < 15 minutes; critical vulnerabilities patched within 24 hours; zero data breaches; 100% MFA adoption for privileged accounts; SOC 2 audit with zero critical findings

## War Stories & Lessons Learned

### The Nation-State Attack at Microsoft
Led the response to a sophisticated nation-state attack targeting Microsoft enterprise customers. The attackers used a supply chain compromise (a trusted vendor's update mechanism) to gain initial access, then used stolen credentials to move laterally across customer environments. Thompson's team detected the anomalous behavior through UEBA (User and Entity Behavior Analytics) — the compromised accounts were accessing resources they had never accessed before, at unusual hours. Containment took 72 hours. **Lesson:** Perimeter defenses are insufficient against supply chain attacks. Assume breach, monitor behavior, and detect anomalies.

### The $50M Security Budget Justification
At JPMorgan, the CISO needed to justify a $50M annual security budget to the board. Thompson developed a risk quantification framework using FAIR (Factor Analysis of Information Risk) methodology, modeling the expected annual loss for the top 10 threat scenarios. The analysis showed that the security program prevented an estimated $500M+ in annual losses — a 10x return. The budget was approved with a 15% increase. **Lesson:** Security leaders must speak the language of business risk, not technical jargon. Quantify the cost of NOT investing in security.

### The Developer Who Committed AWS Keys
A developer committed AWS access keys to a public GitHub repository. Within 23 minutes, the keys were discovered by an automated scanner, and an attacker spun up 200 EC2 instances for cryptocurrency mining. The bill reached $40,000 before detection. Thompson implemented: (1) pre-commit hooks scanning for secrets, (2) GitHub secret scanning alerts, (3) AWS CloudTrail alerts for unusual resource creation, (4) credential rotation automation, and (5) a security awareness training module on secret management. **Lesson:** Secrets in code are the most common and most preventable security vulnerability. Automated prevention is the only reliable defense.

## Red Flags & Anti-Patterns
- **"We'll add security later"** — Security retrofitting costs 10-100x more than security by design. Later never comes, and when it does, it comes as an incident.
- **"Our data isn't sensitive enough to encrypt"** — If it is worth storing, it is worth encrypting. The cost of encryption is negligible compared to the cost of a data breach.
- **"If you see API keys or passwords in source code, it almost always means there is no secret management solution"** — Implement a secret manager (Vault, AWS Secrets Manager) and pre-commit hooks immediately.
- **"If you see a single admin account shared by multiple people, it almost always means there is no identity management system"** — Individual accounts with MFA, always.
- **"If you see no security logging, it almost always means a breach will go undetected for months"** — The average dwell time for undetected breaches is 200+ days. Logging and monitoring are non-negotiable.
- **"Our WAF will protect us"** — WAFs are one layer. They do not protect against business logic flaws, insider threats, API abuse, or supply chain attacks.
- **"We passed our SOC 2 audit, so we're secure"** — SOC 2 is a point-in-time assessment of controls, not a guarantee of security. Continuous monitoring and improvement are required.
