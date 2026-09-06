# Complete AWS DevSecOps Playbook  
**Use case:** Highly available, secure e-commerce deployment with CI/CD, security gates, observability, and operations runbooks.

---

## 1) Objectives

- Build a **highly available 3-tier AWS architecture** across multiple AZs.
- Implement **DevSecOps pipeline** with automated security checks (SAST, dependency, secrets, container CVEs).
- Enforce **zero direct public DB access**, least privilege IAM, and secure secret handling.
- Achieve reliable operations through **monitoring, alerting, scaling, backups, and incident response**.

---

## 2) Target Architecture (Production)

```text
Internet
  |
Route 53
  |
CloudFront (optional but recommended)
  |
WAF
  |
ALB (Public Subnets in 2 AZs)
  |
EC2 Auto Scaling Group (Private App Subnets in 2 AZs)
  |
RDS MySQL Multi-AZ (Private DB Subnets in 2 AZs)
```

**Support services:**
- ECR (container registry)
- IAM + OIDC for GitHub Actions
- Secrets Manager + SSM Parameter Store
- CloudWatch + CloudTrail + Config + GuardDuty + Security Hub
- KMS encryption keys
- AWS Backup

---

## 3) Environment Design

### 3.1 VPC & Subnets

- VPC CIDR: `10.0.0.0/16`
- Public Subnet A: `10.0.1.0/24` (`us-east-1a`) - ALB, NAT GW
- Public Subnet B: `10.0.2.0/24` (`us-east-1b`) - ALB
- App Subnet A: `10.0.10.0/24` (`us-east-1a`) - EC2
- App Subnet B: `10.0.20.0/24` (`us-east-1b`) - EC2
- DB Subnet A: `10.0.100.0/24` (`us-east-1a`) - RDS
- DB Subnet B: `10.0.200.0/24` (`us-east-1b`) - RDS standby

### 3.2 Routing

- Public route table: `0.0.0.0/0 -> IGW`
- Private app route table: `0.0.0.0/0 -> NAT Gateway`
- DB route table: **no direct internet route**

### 3.3 Security Groups

- **ALB-SG**
  - Inbound: 80/443 from `0.0.0.0/0`
  - Outbound: 80 to App-SG
- **App-SG**
  - Inbound: 80 from ALB-SG
  - Inbound: 22 only from bastion/SSM-managed path
  - Outbound: least privilege (or temporary all for bootstrap)
- **DB-SG**
  - Inbound: 3306 from App-SG only
  - No public inbound

---

## 4) IAM and Identity (Critical)

## 4.1 GitHub Actions → AWS via OIDC (No long-lived AWS keys)

- Create IAM OIDC provider for `token.actions.githubusercontent.com`
- Create deploy role trusted by GitHub repo/branch conditions
- Attach least-privilege policy for:
  - ECR push/pull
  - ECS or EC2 deploy steps
  - SSM read (if needed)
  - CloudWatch logs (if needed)

### Example trust relationship (restrict by repo + branch):
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": { "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com" },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": "repo:<ORG>/<REPO>:ref:refs/heads/main"
        }
      }
    }
  ]
}
```

---

## 5) Application Runtime Options (Choose One)

## Option A: EC2 ASG (matches your 3-tier research closely)
- Build Docker image in CI
- Store in ECR
- EC2 user-data or systemd unit pulls and runs image
- ALB routes traffic to instances

## Option B: ECS Fargate (recommended modern path)
- Build/push image to ECR
- Update ECS task definition/service
- ALB fronts ECS service
- Less server maintenance

> For your requirement, we continue with **Option A (EC2 ASG)**.

---

## 6) RDS Multi-AZ Setup

- Engine: MySQL 8+
- Template: Production
- Multi-AZ: enabled
- Public access: disabled
- DB subnet group: DB subnets only
- Encryption: KMS enabled
- Credentials: store in Secrets Manager
- Backups: automated backups + retention
- Performance Insights: enabled (recommended)

---

## 7) DevSecOps CI/CD Pipeline (GitHub Actions)

## 7.1 Pipeline Stages

1. Checkout
2. Secrets + dependency + filesystem vuln scan (Trivy)
3. SAST/Quality (SonarQube)
4. Docker build
5. Container CVE scan (Trivy image)
6. Push image to ECR
7. Deploy to EC2 ASG rollout
8. Post-deploy health check
9. Rollback if health check fails

---

## 7.2 Repository Secrets / Variables

- `SONAR_TOKEN`
- `SONAR_HOST_URL`
- `AWS_ROLE_TO_ASSUME`
- `AWS_REGION` (e.g., `us-east-1`)
- `ECR_REPOSITORY` (e.g., `ecom-web-app`)
- `ASG_NAME`
- `LAUNCH_TEMPLATE_NAME` (if rollout uses LT versioning)
- `APP_HEALTHCHECK_URL` (ALB DNS + `/healthz.html`)

---

## 7.3 Complete Workflow (`.github/workflows/aws-devsecops.yml`)

```yaml
name: AWS DevSecOps CI/CD

on:
  push:
    branches: ["main"]
  pull_request:
    branches: ["main"]

permissions:
  id-token: write
  contents: read
  security-events: write

env:
  AWS_REGION: ${{ secrets.AWS_REGION }}
  ECR_REPOSITORY: ${{ secrets.ECR_REPOSITORY }}
  IMAGE_TAG: ${{ github.sha }}

jobs:
  security-and-quality:
    name: SAST + Secret + Dependency Scans
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Trivy FS + Secret Scan
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: "fs"
          scan-ref: "."
          severity: "HIGH,CRITICAL"
          exit-code: "1"

      - name: SonarQube Scan
        uses: sonarsource/sonarqube-scan-action@master
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
          SONAR_HOST_URL: ${{ secrets.SONAR_HOST_URL }}

      - name: SonarQube Quality Gate
        uses: sonarsource/sonarqube-quality-gate-action@master
        timeout-minutes: 5
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}

  build-scan-push-deploy:
    name: Build + Image Scan + ECR Push + Deploy
    needs: security-and-quality
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Configure AWS Credentials (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_TO_ASSUME }}
          aws-region: ${{ env.AWS_REGION }}

      - name: Login to Amazon ECR
        id: ecr-login
        uses: aws-actions/amazon-ecr-login@v2

      - name: Build Docker image
        run: |
          docker build -t $ECR_REPOSITORY:$IMAGE_TAG .
          docker tag $ECR_REPOSITORY:$IMAGE_TAG $ECR_REPOSITORY:latest

      - name: Trivy Image Scan (SARIF)
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: "${{ env.ECR_REPOSITORY }}:${{ env.IMAGE_TAG }}"
          format: "sarif"
          output: "trivy-results.sarif"
          severity: "CRITICAL"
          exit-code: "1"

      - name: Upload SARIF
        if: always()
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: "trivy-results.sarif"

      - name: Push image to ECR
        env:
          ECR_REGISTRY: ${{ steps.ecr-login.outputs.registry }}
        run: |
          docker tag $ECR_REPOSITORY:$IMAGE_TAG $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
          docker tag $ECR_REPOSITORY:latest $ECR_REGISTRY/$ECR_REPOSITORY:latest
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest

      - name: Rollout on ASG instances (instance refresh)
        run: |
          aws autoscaling start-instance-refresh \
            --auto-scaling-group-name "${{ secrets.ASG_NAME }}" \
            --preferences '{"MinHealthyPercentage": 50, "InstanceWarmup": 120}'

      - name: Wait before health check
        run: sleep 90

      - name: Health Check
        run: |
          curl -fsSL "${{ secrets.APP_HEALTHCHECK_URL }}" || exit 1
```

---

## 8) Docker Hardening

### Dockerfile baseline
```dockerfile
FROM node:20-alpine AS builder
WORKDIR /usr/src/app
COPY package*.json ./
RUN npm ci --only=production

FROM node:20-alpine AS runner
WORKDIR /usr/src/app
USER node
COPY --chown=node:node --from=builder /usr/src/app/node_modules ./node_modules
COPY --chown=node:node . .
EXPOSE 3000
CMD ["node", "server.js"]
```

### Add `.dockerignore`
```gitignore
node_modules
npm-debug.log
.git
.github
coverage
.env
```

---

## 9) SonarQube Configuration

Create `sonar-project.properties`:

```properties
sonar.projectKey=ecom-devsecops-aws
sonar.projectName=Ecom-DevSecOps-AWS
sonar.sources=.
sonar.exclusions=**/node_modules/**,**/coverage/**,**/*.spec.js,**/*.test.js
sonar.sourceEncoding=UTF-8
```

---

## 10) Deployment on EC2 ASG (Image Pull Pattern)

## 10.1 Launch Template user-data (pull from ECR securely)

```bash
#!/bin/bash
set -e

dnf update -y
dnf install -y docker awscli
systemctl enable docker
systemctl start docker

REGION="us-east-1"
ACCOUNT_ID="$(aws sts get-caller-identity --query Account --output text)"
REPO_NAME="ecom-web-app"
IMAGE_TAG="latest"

aws ecr get-login-password --region "$REGION" \
  | docker login --username AWS --password-stdin "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com"

docker pull "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:$IMAGE_TAG"

docker rm -f ecom-app || true
docker run -d --name ecom-app -p 80:3000 \
  --restart always \
  "$ACCOUNT_ID.dkr.ecr.$REGION.amazonaws.com/$REPO_NAME:$IMAGE_TAG"

echo "healthy" > /var/www/html/healthz.html || true
```

> Better: Use SSM/Secrets Manager for runtime env vars, not inline values.

---

## 11) Observability and Alerting

## 11.1 CloudWatch Alarms
- ALB 5XX > threshold
- Target unhealthy host count > 0
- EC2 CPU > 80% sustained
- RDS CPU, FreeStorage, Connections, Failover events
- ASG in-service instances < desired

## 11.2 Logs
- App logs to CloudWatch Logs
- ALB access logs to S3
- VPC Flow Logs enabled
- CloudTrail org/account trail enabled

## 11.3 Security Monitoring
- GuardDuty enabled
- Security Hub aggregation enabled
- AWS Config rules for drift/compliance

---

## 12) Backup, DR, and Resilience

- RDS automated backups with retention
- Snapshot policy before major releases
- Cross-region snapshot copy (if compliance/business needs)
- Quarterly restore tests
- Simulate:
  - EC2 instance failure
  - AZ app-tier failure
  - RDS failover
- Record RTO/RPO outcomes

---

## 13) Operations Runbook

## Daily
- Review alarms and failed deployments
- Check ALB target health
- Check critical security findings
- Validate backup jobs status

## Weekly
- Patch AMI/base image refresh
- Vulnerability triage and fix sprint
- IAM access review of privileged roles

## Monthly
- Cost optimization review (rightsizing)
- DR tabletop/failover mini-test
- Security policy exception review

---

## 14) Incident Response (Quick SOP)

1. Detect and classify (P1/P2/P3)
2. Contain (block traffic, isolate host, rotate creds)
3. Diagnose (recent deploy, logs, CloudTrail, metrics)
4. Recover (rollback image, instance refresh, failover)
5. Postmortem (RCA + action items with owners/dates)

---

## 15) Go-Live Checklist

- [ ] Multi-AZ app + DB validated
- [ ] Security groups least privilege verified
- [ ] No plaintext secrets in code/pipeline
- [ ] CI/CD gates active and blocking on critical findings
- [ ] Observability + alerting configured
- [ ] Backup + restore test passed
- [ ] Rollback strategy tested
- [ ] Runbooks and on-call ownership confirmed

---

## 16) Common Pitfalls and Fixes

- **Problem:** Pipeline uses static AWS keys  
  **Fix:** Move to OIDC role assumption only

- **Problem:** DB exposed publicly  
  **Fix:** Set Public Access = No, restrict DB-SG to App-SG

- **Problem:** App deploys despite critical vulnerabilities  
  **Fix:** Enforce Trivy `exit-code: 1` on critical findings

- **Problem:** Unstable releases  
  **Fix:** Add health checks + rollback criteria + instance refresh controls

---

## 17) Recommended Next Upgrade Path

- Move EC2 ASG workloads to ECS/Fargate for lower ops overhead
- Add IaC with Terraform (VPC, ALB, ASG, RDS, IAM, CloudWatch)
- Add policy-as-code checks (Checkov/tfsec) in CI
- Add canary or blue/green deployment strategy

---

## 18) Deliverables Checklist (Project Completion)

- [ ] AWS network + HA architecture implemented
- [ ] RDS Multi-AZ live with secure connectivity
- [ ] GitHub Actions DevSecOps pipeline active
- [ ] ECR integrated with deployment path
- [ ] Security and quality gates enforced
- [ ] Monitoring, alerts, and incident runbooks operational
- [ ] DR and failover tests documented

---

**End of Playbook**
