---
name: compliance-control-check
description: "Use when mapping controls to compliance frameworks, conducting gap assessments, preparing for SOC 2 / HIPAA / PCI DSS / ISO 27001 audits, or reviewing policy completeness."
version: "1.0.0"
compatible_agents:
  - compliance_engineer
  - security_engineer
  - cloud_security_engineer
  - devops_engineer
domain: "tech/security"
priority: 12
user_invocable: true
argument-hint: "[framework: soc2|hipaa|pci-dss|iso27001|gdpr|fedramp]"
---

```skill
# Compliance Control Check Skill

When assessing compliance posture or preparing for audits, apply the relevant framework checklist:

## SOC 2 Type II — Trust Service Criteria

### Security (Common Criteria)
- [ ] CC1: Control Environment — security policies documented, roles defined, board oversight
- [ ] CC2: Communication — security awareness training, incident communication procedures
- [ ] CC3: Risk Assessment — annual risk assessment, risk register maintained and reviewed quarterly
- [ ] CC4: Monitoring — continuous monitoring of controls, internal audit program
- [ ] CC5: Control Activities — logical access controls, change management, system operations
- [ ] CC6: Logical Access — authentication (MFA), authorization (RBAC), access reviews quarterly
- [ ] CC7: System Operations — vulnerability management, incident response, backup/recovery
- [ ] CC8: Change Management — change approval process, segregation of environments, rollback procedures
- [ ] CC9: Risk Mitigation — vendor risk management, business continuity planning

### Availability
- [ ] SLA definitions and monitoring
- [ ] Disaster recovery plan tested annually
- [ ] Redundancy and failover mechanisms documented

### Processing Integrity
- [ ] Data processing accuracy controls
- [ ] Error handling and correction procedures

### Confidentiality
- [ ] Data classification scheme implemented
- [ ] Encryption at rest and in transit
- [ ] Data retention and disposal procedures

### Privacy
- [ ] Privacy notice and consent mechanisms
- [ ] Data subject rights procedures (access, deletion, portability)
- [ ] Data processing agreements with sub-processors

## HIPAA — Technical Safeguards

### Access Control (§164.312(a))
- [ ] Unique user identification for all users accessing ePHI
- [ ] Emergency access procedure for ePHI in emergencies
- [ ] Automatic logoff after period of inactivity
- [ ] Encryption of ePHI at rest

### Audit Controls (§164.312(b))
- [ ] Hardware, software, and procedural mechanisms to record access to ePHI
- [ ] Audit log review procedures and retention (minimum 6 years)
- [ ] Tamper-evident audit logs

### Integrity Controls (§164.312(c))
- [ ] Electronic mechanisms to authenticate ePHI integrity
- [ ] Data backup and recovery procedures

### Transmission Security (§164.312(e))
- [ ] Encryption of ePHI in transit (TLS 1.2+)
- [ ] Integrity controls for transmitted ePHI

### Administrative Safeguards
- [ ] Security Officer designated
- [ ] Workforce training on HIPAA security
- [ ] Security incident procedures documented
- [ ] Business Associate Agreements (BAAs) with all vendors handling PHI
- [ ] Risk analysis conducted and documented

## PCI DSS — Key Requirements

### Build and Maintain Secure Network
- [ ] Req 1: Firewall configuration protecting cardholder data
- [ ] Req 2: No vendor-supplied defaults for passwords/security parameters

### Protect Cardholder Data
- [ ] Req 3: Stored cardholder data encrypted (AES-256), PAN masked in display
- [ ] Req 4: Encryption of cardholder data across public networks (TLS 1.2+)

### Vulnerability Management
- [ ] Req 5: Anti-malware on all systems commonly affected by malware
- [ ] Req 6: Secure development practices, patching within 30 days for critical CVEs

### Access Control
- [ ] Req 7: Restrict access to cardholder data by business need to know
- [ ] Req 8: Unique IDs for all users, MFA for administrative access
- [ ] Req 9: Physical access restrictions to cardholder data

### Monitoring and Testing
- [ ] Req 10: Track and monitor all access to network resources and cardholder data
- [ ] Req 11: Quarterly vulnerability scans (ASV), annual penetration testing

### Security Policy
- [ ] Req 12: Information security policy maintained and distributed to all personnel

### CDE Scoping
- [ ] Cardholder Data Environment (CDE) boundaries clearly defined
- [ ] Network segmentation validated (no data leaking outside CDE)
- [ ] All systems in CDE inventoried and classified

## ISO 27001 — Annex A Control Categories

- [ ] A.5: Information Security Policies — documented, approved, communicated
- [ ] A.6: Organization of Information Security — roles, responsibilities, segregation
- [ ] A.7: Human Resource Security — screening, awareness, termination procedures
- [ ] A.8: Asset Management — asset inventory, classification, acceptable use
- [ ] A.9: Access Control — access policy, user registration, privilege management, MFA
- [ ] A.10: Cryptography — encryption policy, key management procedures
- [ ] A.11: Physical Security — secure areas, equipment protection
- [ ] A.12: Operations Security — change management, capacity planning, malware protection, backup, logging
- [ ] A.13: Communications Security — network controls, information transfer policies
- [ ] A.14: System Acquisition — security requirements, secure development, test data
- [ ] A.15: Supplier Relationships — supplier security policy, supply chain risk management
- [ ] A.16: Incident Management — incident response procedures, evidence collection
- [ ] A.17: Business Continuity — continuity planning, redundancy
- [ ] A.18: Compliance — legal requirements, security reviews, audit

## GDPR — Technical Requirements

- [ ] Lawful basis documented for all processing activities (Art. 6)
- [ ] Data Protection Impact Assessment (DPIA) for high-risk processing (Art. 35)
- [ ] Data Processing Records maintained (Art. 30)
- [ ] Data Subject Rights implemented: access (Art. 15), rectification (Art. 16), erasure (Art. 17), portability (Art. 20), objection (Art. 21)
- [ ] Data breach notification procedure: supervisory authority within 72 hours (Art. 33)
- [ ] Data Protection Officer designated if required (Art. 37)
- [ ] Privacy by Design and Default (Art. 25)
- [ ] Cross-border transfer mechanisms: SCCs, adequacy decisions, BCRs (Art. 46)
- [ ] Consent mechanisms: freely given, specific, informed, unambiguous (Art. 7)
- [ ] Data Processing Agreements with all processors (Art. 28)

## Gap Assessment Output Format

```
## Compliance Gap Assessment

### Framework: [SOC 2 | HIPAA | PCI DSS | ISO 27001 | GDPR | FedRAMP]
### Assessment Date: [Date]
### Assessor: [Agent/Persona]

### Overall Compliance Posture
- Compliant: N controls
- Partially Compliant: N controls
- Non-Compliant: N controls
- Not Applicable: N controls

### Gap Summary
| # | Control | Status | Gap Description | Risk Level | Remediation | Effort |
|---|---------|--------|-----------------|------------|-------------|--------|
| 1 | CC6.1 | Non-Compliant | No MFA for admin | HIGH | Implement MFA | S |

### Evidence Checklist
| Control | Evidence Type | Available | Location |
|---------|--------------|-----------|----------|
| CC6.1 | Access review logs | Yes | /evidence/access-reviews/ |

### Remediation Priority
1. [Critical] Non-compliant controls with high risk
2. [High] Partially compliant controls with gaps
3. [Medium] Controls with documentation gaps
4. [Low] Controls with minor evidence gaps

### Risk Register Entry Format
| Risk ID | Description | Likelihood | Impact | Inherent Risk | Controls | Residual Risk | Treatment | Owner | Review Date |
|---------|-------------|------------|--------|---------------|----------|---------------|-----------|-------|-------------|
```

## Control Mapping Matrix

When a control satisfies multiple frameworks, document the mapping:

```
| Control Implementation | SOC 2 | ISO 27001 | HIPAA | PCI DSS | GDPR |
|-----------------------|-------|-----------|-------|---------|------|
| MFA for all users | CC6.1 | A.9.4.2 | §164.312(d) | Req 8.3 | Art. 32 |
| Encryption at rest | CC6.7 | A.10.1.1 | §164.312(a)(2)(iv) | Req 3.4 | Art. 32 |
| Access reviews | CC6.2 | A.9.2.5 | §164.312(a)(1) | Req 7.1 | Art. 5(1)(f) |
```

This shared mapping reduces audit overhead by demonstrating one control satisfies multiple requirements.
```
