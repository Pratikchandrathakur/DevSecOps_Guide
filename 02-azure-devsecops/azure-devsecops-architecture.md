# Azure DevSecOps Architecture

## Pipeline Flow
1. Developer push/PR to GitHub
2. Trivy filesystem + secret scan
3. SonarQube analysis + quality gate
4. Docker build
5. Trivy container image CVE scan
6. Push to ACR
7. Deploy to Azure Web App (container)

## Security-by-Design Decisions
- OIDC for Azure authentication in CI/CD
- No plaintext deployment credentials
- Security gates block unsafe releases
- SARIF findings uploaded to GitHub Security tab

## Target Azure Resources
- Resource Group: `rg-devsecops-prod`
- ACR: `acrdevsecopsprod`
- App Service: `app-devsecops-node`
