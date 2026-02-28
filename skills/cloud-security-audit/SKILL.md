---
name: cloud-security-audit
description: "Use when reviewing cloud infrastructure security posture, auditing IAM policies, checking storage bucket configurations, or assessing network security groups."
version: "1.0.0"
compatible_agents:
  - cloud_security_engineer
  - security_engineer
  - devops_engineer
  - compliance_engineer
domain: "tech/security"
priority: 13
user_invocable: true
argument-hint: "[provider: aws|azure|gcp|multi-cloud]"
---

```skill
# Cloud Security Audit Skill

When reviewing cloud infrastructure, apply this comprehensive security audit across all layers:

## IAM Audit Checklist

### Users & Roles
- [ ] No root/owner account used for daily operations (hardware MFA only, break-glass)
- [ ] No IAM users with `AdministratorAccess` or `*:*` permissions without documented justification
- [ ] All IAM users have MFA enabled (phishing-resistant FIDO2 preferred)
- [ ] No long-lived access keys older than 90 days
- [ ] Service accounts scoped to minimum required permissions (no wildcards)
- [ ] Unused IAM roles and users identified and removed (90-day inactivity threshold)
- [ ] Cross-account trust relationships explicitly documented and reviewed

### Policies & Permissions
- [ ] No inline IAM policies (use managed policies for auditability)
- [ ] Resource-based policies (S3, KMS, SNS, SQS) reviewed for overly broad principals
- [ ] IAM Access Analyzer (AWS) / Entra ID Access Reviews (Azure) enabled
- [ ] Permission boundaries set for delegated administration roles
- [ ] No privilege escalation paths (iam:PassRole, sts:AssumeRole chains)

## Storage Security Checklist

### Object Storage (S3 / GCS / Azure Blob)
- [ ] Account-level public access block enabled (S3 Block Public Access)
- [ ] No buckets with public ACLs or public bucket policies
- [ ] Server-side encryption enabled with customer-managed keys (SSE-KMS / CMEK)
- [ ] Versioning enabled for critical data buckets
- [ ] Access logging enabled for audit trail
- [ ] Lifecycle policies configured for data retention compliance
- [ ] Cross-region replication encrypted and to approved regions only

### Databases
- [ ] No databases publicly accessible (public endpoint disabled)
- [ ] Encryption at rest with customer-managed keys
- [ ] Automated backups enabled with point-in-time recovery
- [ ] Database credentials managed via Secrets Manager (not hardcoded)
- [ ] Network access restricted to specific VPC/subnet/security groups

## Network Security Checklist

### VPC / Virtual Network
- [ ] No security groups with inbound 0.0.0.0/0 except load balancers on 80/443
- [ ] VPC Flow Logs enabled for all VPCs and subnets
- [ ] Network segmentation between environments (dev/staging/prod in separate VPCs)
- [ ] Private subnets used for application and database tiers
- [ ] NAT Gateway for outbound internet access from private subnets (no IGW on private)
- [ ] VPC peering and Transit Gateway configurations reviewed for least-privilege routing

### Endpoints & APIs
- [ ] API Gateway with WAF protection for public-facing APIs
- [ ] TLS 1.2+ enforced on all endpoints (no TLS 1.0/1.1)
- [ ] Private endpoints (PrivateLink / Private Service Connect) for AWS/Azure/GCP service access
- [ ] DDoS protection enabled (AWS Shield / Azure DDoS Protection / Cloud Armor)

## Logging & Monitoring Checklist

### Audit Logging
- [ ] CloudTrail / Activity Log / Audit Log enabled in ALL regions
- [ ] Log file integrity validation enabled (CloudTrail log file validation)
- [ ] Logs exported to centralized, immutable storage (separate account/project)
- [ ] Log retention meets compliance requirements (minimum 1 year for SOC 2)
- [ ] SIEM integration configured for real-time alerting

### Threat Detection
- [ ] Cloud-native threat detection enabled (GuardDuty / Defender / SCC)
- [ ] Anomaly alerts for: unusual API calls, impossible travel, new regions, crypto mining
- [ ] Alerting configured for: root account login, IAM policy changes, security group changes

## Compute Security Checklist

### EC2 / VM / Compute
- [ ] No instances with public IP unless explicitly required (use load balancer)
- [ ] IMDSv2 enforced (no IMDSv1) to prevent SSRF metadata attacks
- [ ] SSM Session Manager preferred over SSH (no SSH keys to manage)
- [ ] Patch management automated (SSM Patch Manager / Azure Update Management)
- [ ] Instance profiles use least-privilege IAM roles

### Containers & Kubernetes
- [ ] Container images scanned for CVEs before registry push
- [ ] No containers running as root
- [ ] IRSA / Workload Identity used (no long-lived IAM credentials in pods)
- [ ] Network policies enforced between namespaces
- [ ] Pod Security Standards enforced (restricted profile)
- [ ] Admission controllers configured (OPA Gatekeeper / Kyverno)
- [ ] Image signing and verification (Cosign / Notary)

### Serverless
- [ ] Lambda/Function permissions scoped to specific resources (no `Resource: *`)
- [ ] Environment variables encrypted and no secrets in plain text
- [ ] Function timeout and concurrency limits set to prevent abuse
- [ ] VPC-attached for functions accessing private resources

## CIS Benchmark Quick Reference

| Benchmark | Key Controls |
|-----------|-------------|
| CIS AWS Foundations | MFA on root, CloudTrail all regions, no 0.0.0.0/0 SSH, VPC flow logs |
| CIS Azure | Defender enabled, diagnostic settings, NSG flow logs, key vault soft-delete |
| CIS GCP | Org policy constraints, audit logging, VPC firewall rules, CMEK encryption |
| CIS Kubernetes | RBAC, network policies, pod security, audit logging, secrets encryption |

## Output Format

```
## Cloud Security Audit Report

### Provider: [AWS | Azure | GCP | Multi-Cloud]
### Account/Project: [ID]
### Assessment Date: [Date]

### Overall Posture: [CRITICAL | HIGH | MEDIUM | LOW]

### Findings
| # | Severity | Category | Resource | Description | Remediation |
|---|----------|----------|----------|-------------|-------------|
| 1 | CRITICAL | IAM | arn:aws:iam::... | Over-permissioned role | Scope to specific resources |

### Summary
- Critical: N
- High: N
- Medium: N
- Low: N
- Compliant: N

### CIS Benchmark Compliance
- Score: X/Y controls passing
- Key gaps: [List]

### Recommended Actions (Priority Order)
1. [Immediate] ...
2. [Short-term] ...
3. [Long-term] ...
```
```
