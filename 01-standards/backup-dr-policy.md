# Backup and Disaster Recovery Policy

## Backup Targets
- Databases (full + incremental)
- App configuration and secrets metadata
- Critical file stores and stateful volumes

## RPO/RTO Targets
- Tier-1 apps: RPO <= 15 min, RTO <= 60 min
- Tier-2 apps: RPO <= 4 hr, RTO <= 8 hr

## Backup Frequency
- Daily full backups
- Log/incremental backups as supported
- Retention: 30/90/365-day tiers (operational/compliance)

## DR Testing
- Quarterly restore drills
- Semi-annual failover simulation
- Document outcomes and remediation actions

## Security
- Backup encryption at rest/in transit
- Separate backup IAM roles
- Immutable backup option for ransomware resilience
