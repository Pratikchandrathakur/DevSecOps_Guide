# Incident Response Runbook (P1/P2)

## Severity Levels
- **P1**: Full outage, security breach, critical data risk
- **P2**: Major degradation, partial outage
- **P3**: Minor issue, workaround available

## Response Workflow

1. **Detect**
   - Alert from monitoring/security tooling
2. **Acknowledge**
   - On-call accepts incident within SLA (e.g., 5 minutes for P1)
3. **Contain**
   - Isolate impacted service/node/account
4. **Diagnose**
   - Check latest deployments, infra events, logs, metrics
5. **Mitigate**
   - Rollback deployment / replace instances / failover
6. **Recover**
   - Validate availability and error rate stabilization
7. **Postmortem**
   - Publish within 24–72 hours with action items

## First 15-Minute Checklist
- Confirm blast radius (single service or platform-wide)
- Validate customer impact
- Freeze non-essential changes
- Communicate status update to stakeholders
- Start incident timeline document

## Security Incident Add-ons
- Rotate suspected exposed credentials immediately
- Preserve forensic evidence (logs, snapshots)
- Disable compromised principals/tokens
- Notify compliance/legal stakeholders as required

## Exit Criteria
- Service health metrics back to normal
- Root cause identified (or narrowed with clear next actions)
- Follow-up tasks assigned with owners and deadlines
