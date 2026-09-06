# Azure Deployment Runbook

## Pre-Deploy
- Confirm pipeline green (all gates passed)
- Validate release notes/change ticket
- Confirm rollback image tag exists

## Deploy
1. Trigger workflow via merge to `main`
2. Verify ACR image pushed (`sha` + `latest`)
3. Confirm Web App updated with `sha` image tag
4. Validate app health endpoint and logs

## Post-Deploy Validation
- HTTP 200 on health route
- No error-rate spike
- Latency within SLO
- No new high/critical findings

## Rollback
- Repoint app to previous stable image tag
- Re-run smoke tests
- Document rollback reason and corrective actions
