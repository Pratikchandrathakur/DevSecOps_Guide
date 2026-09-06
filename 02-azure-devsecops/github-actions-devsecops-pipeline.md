# GitHub Actions DevSecOps Pipeline (Azure)

## Purpose
Shift security left and enforce release gates for quality and vulnerabilities.

## Required GitHub Secrets
- `SONAR_TOKEN`
- `SONAR_HOST_URL`
- `AZURE_CLIENT_ID`
- `AZURE_TENANT_ID`
- `AZURE_SUBSCRIPTION_ID`
- `ACR_NAME`

## Workflow File
Create `.github/workflows/devsecops.yml`:

```yaml
name: DevSecOps CI/CD Pipeline

on:
  push:
    branches: [ "main" ]
  pull_request:
    branches: [ "main" ]

permissions:
  id-token: write
  contents: read
  security-events: write

jobs:
  sast-and-dependency-scan:
    name: Code & Dependency Security Checks
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Run Trivy Filesystem & Secret Scan
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: 'fs'
          scan-ref: '.'
          severity: 'HIGH,CRITICAL'
          exit-code: '1'

      - name: SonarQube Code Analysis
        uses: sonarsource/sonarqube-scan-action@master
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
          SONAR_HOST_URL: ${{ secrets.SONAR_HOST_URL }}

      - name: SonarQube Quality Gate Check
        uses: sonarsource/sonarqube-quality-gate-action@master
        timeout-minutes: 5
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}

  container-scan-and-deploy:
    name: Docker Build, Trivy Image Scan & Azure Deploy
    needs: sast-and-dependency-scan
    runs-on: ubuntu-latest
    steps:
      - name: Checkout Repository
        uses: actions/checkout@v4

      - name: Build Local Docker Image
        run: docker build -t app-image:${{ github.sha }} .

      - name: Run Trivy Image Security Scan
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: 'app-image:${{ github.sha }}'
          format: 'sarif'
          output: 'trivy-results.sarif'
          severity: 'CRITICAL'
          exit-code: '1'

      - name: Upload SARIF to GitHub Security Tab
        if: always()
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: 'trivy-results.sarif'

      - name: Log in to Azure (OIDC)
        uses: azure/login@v2
        with:
          client-id: ${{ secrets.AZURE_CLIENT_ID }}
          tenant-id: ${{ secrets.AZURE_TENANT_ID }}
          subscription-id: ${{ secrets.AZURE_SUBSCRIPTION_ID }}

      - name: Push Image to Azure Container Registry (ACR)
        run: |
          az acr login --name ${{ secrets.ACR_NAME }}
          IMAGE_URI="${{ secrets.ACR_NAME }}.azurecr.io/node-app"
          docker tag app-image:${{ github.sha }} $IMAGE_URI:${{ github.sha }}
          docker tag app-image:${{ github.sha }} $IMAGE_URI:latest
          docker push $IMAGE_URI:${{ github.sha }}
          docker push $IMAGE_URI:latest

      - name: Deploy to Azure Web App for Containers
        uses: azure/webapps-deploy@v3
        with:
          app-name: 'app-devsecops-node'
          images: '${{ secrets.ACR_NAME }}.azurecr.io/node-app:${{ github.sha }}'
```

## Security Gates
- PR blocked on failed Sonar quality gate
- PR blocked on HIGH/CRITICAL fs findings
- Deployment blocked on CRITICAL image findings
