# Complete AWS DevSecOps Playbook V2 (Production-Ready)

This version extends V1 with:
- Terraform module layout
- IAM policy JSON examples
- Rollback workflow
- Cost-optimized environment presets (S/M/L)

---

## 1) Reference Architecture

```text
GitHub Actions (OIDC)
   ├─ SAST/Secrets/Dependency Scan (SonarQube + Trivy)
   ├─ Build Docker image
   ├─ Image CVE scan (Trivy)
   ├─ Push to ECR
   └─ Deploy to EC2 ASG (instance refresh)

AWS Runtime:
Route53 -> (optional CloudFront + WAF) -> ALB (2 AZ public subnets)
-> EC2 ASG (2 AZ private app subnets)
-> RDS MySQL Multi-AZ (2 AZ private DB subnets)
+ NAT GW, CloudWatch, CloudTrail, GuardDuty, SecurityHub, AWS Backup
```

---

## 2) Terraform Layout (Recommended)

```text
infra/
├─ environments/
│  ├─ dev/
│  │  ├─ main.tf
│  │  ├─ variables.tf
│  │  ├─ terraform.tfvars
│  │  └─ outputs.tf
│  ├─ stage/
│  └─ prod/
├─ modules/
│  ├─ vpc/
│  ├─ security-groups/
│  ├─ ecr/
│  ├─ alb/
│  ├─ asg/
│  ├─ rds-mysql/
│  ├─ iam-oidc-github/
│  ├─ cloudwatch/
│  ├─ cloudtrail/
│  ├─ guardduty-securityhub/
│  └─ backup/
└─ global/
   ├─ providers.tf
   ├─ backend.tf
   └─ versions.tf
```

---

## 3) Terraform Core Files

## 3.1 `global/versions.tf`
```hcl
terraform {
  required_version = ">= 1.6.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}
```

## 3.2 `global/providers.tf`
```hcl
provider "aws" {
  region = var.aws_region
}
```

## 3.3 `global/backend.tf` (S3 remote state + lock)
```hcl
terraform {
  backend "s3" {
    bucket         = "YOUR_TF_STATE_BUCKET"
    key            = "prod/aws-devsecops/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "YOUR_TF_LOCK_TABLE"
    encrypt        = true
  }
}
```

---

## 4) Module Contracts (Inputs/Outputs)

## 4.1 `modules/vpc` inputs
- `vpc_cidr`
- `azs`
- `public_subnet_cidrs`
- `app_subnet_cidrs`
- `db_subnet_cidrs`
- `enable_nat_gateway`

outputs:
- `vpc_id`
- `public_subnet_ids`
- `app_subnet_ids`
- `db_subnet_ids`

## 4.2 `modules/security-groups` inputs
- `vpc_id`
- `allowed_admin_cidrs`
outputs:
- `alb_sg_id`
- `app_sg_id`
- `db_sg_id`

## 4.3 `modules/rds-mysql` inputs
- `db_subnet_ids`
- `db_sg_id`
- `instance_class`
- `allocated_storage`
- `multi_az`
- `db_name`
- `master_username`
- `manage_master_user_password` (true recommended)
outputs:
- `db_endpoint`
- `db_secret_arn`

---

## 5) Example: VPC Module Skeleton

```hcl
resource "aws_vpc" "this" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "ecom-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.this.id
}

# Create subnets (public/app/db), route tables, associations, NAT GW...
# Keep DB subnets without internet route
```

---

## 6) Example: Security Group Rules (Terraform)

```hcl
resource "aws_security_group" "alb_sg" {
  name   = "alb-sg"
  vpc_id = var.vpc_id

  ingress { from_port = 80  to_port = 80  protocol = "tcp" cidr_blocks = ["0.0.0.0/0"] }
  ingress { from_port = 443 to_port = 443 protocol = "tcp" cidr_blocks = ["0.0.0.0/0"] }

  egress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }
}

resource "aws_security_group" "app_sg" {
  name   = "app-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }
}

resource "aws_security_group" "db_sg" {
  name   = "db-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }
}
```

---

## 7) IAM for GitHub OIDC (Trust + Permission)

## 7.1 Trust Policy (`github-oidc-trust.json`)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "GithubOidcTrust",
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "token.actions.githubusercontent.com:aud": "sts.amazonaws.com"
        },
        "StringLike": {
          "token.actions.githubusercontent.com:sub": [
            "repo:<ORG>/<REPO>:ref:refs/heads/main",
            "repo:<ORG>/<REPO>:pull_request"
          ]
        }
      }
    }
  ]
}
```

## 7.2 Deployment Permission Policy (`github-deploy-policy.json`)
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "ECRPushPull",
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchCheckLayerAvailability",
        "ecr:CompleteLayerUpload",
        "ecr:UploadLayerPart",
        "ecr:InitiateLayerUpload",
        "ecr:PutImage",
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ASGRefresh",
      "Effect": "Allow",
      "Action": [
        "autoscaling:StartInstanceRefresh",
        "autoscaling:DescribeAutoScalingGroups",
        "autoscaling:DescribeInstanceRefreshes"
      ],
      "Resource": "*"
    },
    {
      "Sid": "DescribeInfra",
      "Effect": "Allow",
      "Action": [
        "ec2:DescribeInstances",
        "elasticloadbalancing:DescribeTargetHealth",
        "rds:DescribeDBInstances",
        "cloudwatch:DescribeAlarms"
      ],
      "Resource": "*"
    }
  ]
}
```

> Tighten `Resource` ARNs to specific resources in production.

---

## 8) EC2 Instance Role Policy (Runtime Pull from ECR + Secrets)

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "EcrPull",
      "Effect": "Allow",
      "Action": [
        "ecr:GetAuthorizationToken",
        "ecr:BatchGetImage",
        "ecr:GetDownloadUrlForLayer"
      ],
      "Resource": "*"
    },
    {
      "Sid": "ReadSecrets",
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "ssm:GetParameter",
        "ssm:GetParameters"
      ],
      "Resource": [
        "arn:aws:secretsmanager:us-east-1:<ACCOUNT_ID>:secret:prod/ecom/*",
        "arn:aws:ssm:us-east-1:<ACCOUNT_ID>:parameter/prod/ecom/*"
      ]
    }
  ]
}
```

---

## 9) GitHub Actions Workflow (Prod with Rollback Hooks)

Create `.github/workflows/aws-devsecops.yml`:

```yaml
name: AWS DevSecOps CI/CD

on:
  push:
    branches: ["main"]
  pull_request:
    branches: ["main"]
  workflow_dispatch:

permissions:
  id-token: write
  contents: read
  security-events: write

env:
  AWS_REGION: ${{ secrets.AWS_REGION }}
  ECR_REPOSITORY: ${{ secrets.ECR_REPOSITORY }}
  IMAGE_TAG: ${{ github.sha }}

jobs:
  security-quality:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          fetch-depth: 0

      - name: Trivy FS scan
        uses: aquasecurity/trivy-action@master
        with:
          scan-type: fs
          scan-ref: .
          severity: HIGH,CRITICAL
          exit-code: 1

      - name: Sonar scan
        uses: sonarsource/sonarqube-scan-action@master
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}
          SONAR_HOST_URL: ${{ secrets.SONAR_HOST_URL }}

      - name: Quality gate
        uses: sonarsource/sonarqube-quality-gate-action@master
        timeout-minutes: 5
        env:
          SONAR_TOKEN: ${{ secrets.SONAR_TOKEN }}

  deploy:
    needs: security-quality
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Configure AWS (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_TO_ASSUME }}
          aws-region: ${{ env.AWS_REGION }}

      - name: ECR login
        id: ecr-login
        uses: aws-actions/amazon-ecr-login@v2

      - name: Build image
        run: |
          docker build -t $ECR_REPOSITORY:$IMAGE_TAG .
          docker tag $ECR_REPOSITORY:$IMAGE_TAG $ECR_REPOSITORY:latest

      - name: Trivy image scan
        uses: aquasecurity/trivy-action@master
        with:
          image-ref: "${{ env.ECR_REPOSITORY }}:${{ env.IMAGE_TAG }}"
          format: sarif
          output: trivy-results.sarif
          severity: CRITICAL
          exit-code: 1

      - name: Upload SARIF
        if: always()
        uses: github/codeql-action/upload-sarif@v3
        with:
          sarif_file: trivy-results.sarif

      - name: Push to ECR
        env:
          ECR_REGISTRY: ${{ steps.ecr-login.outputs.registry }}
        run: |
          docker tag $ECR_REPOSITORY:$IMAGE_TAG $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
          docker tag $ECR_REPOSITORY:latest $ECR_REGISTRY/$ECR_REPOSITORY:latest
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:$IMAGE_TAG
          docker push $ECR_REGISTRY/$ECR_REPOSITORY:latest

      - name: Start ASG instance refresh
        run: |
          aws autoscaling start-instance-refresh \
            --auto-scaling-group-name "${{ secrets.ASG_NAME }}" \
            --preferences '{"MinHealthyPercentage": 75, "InstanceWarmup": 180}'

      - name: Wait for warmup
        run: sleep 120

      - name: Healthcheck
        run: |
          curl -fsSL "${{ secrets.APP_HEALTHCHECK_URL }}"
```

---

## 10) Rollback Workflow (Manual + Automated)

## 10.1 Manual rollback strategy
- Keep previous image tags immutable (`sha` tags)
- On bad deploy:
  1. Set launch template/user-data to previous known-good image tag
  2. Start ASG instance refresh
  3. Validate ALB health + app smoke tests

## 10.2 Optional rollback workflow file

`.github/workflows/aws-rollback.yml`
```yaml
name: AWS Rollback

on:
  workflow_dispatch:
    inputs:
      rollback_image_tag:
        description: "Known-good image tag (commit SHA)"
        required: true

permissions:
  id-token: write
  contents: read

jobs:
  rollback:
    runs-on: ubuntu-latest
    steps:
      - name: Configure AWS (OIDC)
        uses: aws-actions/configure-aws-credentials@v4
        with:
          role-to-assume: ${{ secrets.AWS_ROLE_TO_ASSUME }}
          aws-region: ${{ secrets.AWS_REGION }}

      - name: Trigger ASG refresh for rollback
        run: |
          echo "Set runtime to image tag: ${{ github.event.inputs.rollback_image_tag }}"
          # implement LT/version update here (SSM param or template data source)
          aws autoscaling start-instance-refresh \
            --auto-scaling-group-name "${{ secrets.ASG_NAME }}"
```

> Best practice: image tag source should come from SSM Parameter (e.g., `/prod/ecom/image_tag`) so rollback = parameter change + refresh.

---

## 11) Environment Presets (Small / Medium / Large)

## 11.1 Small (startup)
- ALB: 1
- ASG: min 2, desired 2, max 4
- EC2: `t3.micro`/`t3.small`
- RDS: `db.t4g.micro` Multi-AZ (if budget allows; else single AZ for non-prod only)
- NAT: 1
- Estimation goal: lowest cost with minimum HA in app tier

## 11.2 Medium (growing business)
- ASG: min 2, desired 4, max 8
- EC2: `t3.small`/`t3.medium`
- RDS: `db.t4g.small` or `db.t3.small` Multi-AZ
- Read replica optional for read-heavy loads
- NAT: consider 2 (one per AZ) for resilience

## 11.3 Large (high traffic)
- ASG: min 6, desired 8+, max 20+
- EC2: `c7g`/`m7g` class as workload fit
- RDS: `db.r6g` class Multi-AZ, provisioned IOPS
- ElastiCache (Redis) recommended
- WAF + CloudFront strongly recommended
- Multi-NAT architecture, cross-region DR planning

---

## 12) Cost Optimization Checklist

- Use Graviton instances where compatible
- Rightsize monthly using CloudWatch + Compute Optimizer
- Scale-to-demand with ASG target tracking
- Set log retention (avoid indefinite high-cost retention)
- Use Savings Plans/Reserved Instances for steady baseline
- Clean unused EBS snapshots, old AMIs, stale ECR tags

---

## 13) Security Hardening Checklist

- [ ] OIDC only for CI/CD authentication
- [ ] IAM policy scope restricted by resource ARN
- [ ] Secrets only in Secrets Manager/SSM
- [ ] ECR image scan enabled (plus Trivy gate in CI)
- [ ] SGs deny public DB and admin ports
- [ ] CloudTrail, Config, GuardDuty, Security Hub enabled
- [ ] KMS encryption for RDS/EBS/S3
- [ ] Patch cycle + emergency patch SLA documented

---

## 14) Operations SLO/KPI Targets

- Availability: >= 99.9%
- MTTR: < 30 min for P1 initial recovery action
- Critical vuln remediation: <= 48h
- Backup restore success: 100% in quarterly tests
- Deployment success rate: >= 95%

---

## 15) 30/60/90-Day Execution Plan

## Day 0–30
- Build base AWS infra (VPC, ALB, ASG, RDS)
- Configure OIDC + CI security gates
- Deploy first production candidate

## Day 31–60
- Add full observability + incident runbooks
- Implement backup/restore drill
- Enforce IAM and SG hardening controls

## Day 61–90
- Optimize cost/performance
- Add rollback automation maturity
- Conduct failover game day and finalize compliance evidence

---

## 16) Final Deliverables

- Terraform infra code (modular)
- Secure CI/CD pipelines (deploy + rollback)
- IAM/OIDC and least-privilege policies
- Runbooks (deploy, incident, DR, patching)
- Evidence: failover tests, vulnerability reports, recovery metrics

---

**End of V2**
