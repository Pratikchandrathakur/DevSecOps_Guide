# Azure DevSecOps Prerequisites Checklist

## Accounts & Access
- [ ] Azure subscription ready
- [ ] GitHub repo with admin access
- [ ] SonarQube server or SonarCloud access

## Azure Resources
- [ ] Resource group created
- [ ] ACR created
- [ ] Linux Web App for containers created
- [ ] App has permission to pull images from ACR

## Identity
- [ ] OIDC federated credential configured for GitHub Actions
- [ ] Service principal has minimum required roles only

## GitHub Secrets
- [ ] SONAR_TOKEN
- [ ] SONAR_HOST_URL
- [ ] AZURE_CLIENT_ID
- [ ] AZURE_TENANT_ID
- [ ] AZURE_SUBSCRIPTION_ID
- [ ] ACR_NAME

## Repository Files
- [ ] `.github/workflows/devsecops.yml`
- [ ] `Dockerfile`
- [ ] `sonar-project.properties`
- [ ] `.dockerignore`
