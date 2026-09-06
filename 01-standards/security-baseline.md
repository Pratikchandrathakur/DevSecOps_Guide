# Security Baseline Standard

## Identity & Access
- Enforce MFA for all privileged users
- RBAC least privilege by role
- Break-glass account with monitored usage
- Service principals/roles rotated and scoped minimally
- Prefer OIDC/federation over long-lived credentials

## Secrets Management
- No plaintext secrets in repos, CI vars, or user data
- Use managed secret stores:
  - Azure Key Vault
  - AWS Secrets Manager / SSM Parameter Store
- Secret rotation policy:
  - High-risk credentials: every 30 days
  - Standard app secrets: every 90 days

## Endpoint & Server Controls
- CIS benchmark-aligned hardening
- EDR/AV enabled
- OS patching schedule enforced
- Local firewall active
- SSH hardened (no password login in production)

## Vulnerability Management
- Code scan on every PR
- Dependency scan on every PR
- Container scan before registry push
- Block release on Critical findings unless approved exception

## Logging & Audit
- Enable cloud audit logs and retention
- Centralize application + infra logs
- Alert on:
  - Privilege escalation
  - Secret access anomalies
  - Repeated auth failures

## Compliance Rhythm
- Weekly vuln report
- Monthly access review
- Quarterly DR drill
