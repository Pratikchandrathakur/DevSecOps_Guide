# AWS DevSecOps V3 (Safe Defaults)

This project provides:
- Terraform infra for AWS 3-tier HA setup
- GitHub Actions DevSecOps CI/CD + rollback workflow
- Secure defaults with placeholders (`CHANGE_ME`)

## 1) Where to edit first (required)

1. `infra/environments/dev/terraform.tfvars`
2. `infra/environments/stage/terraform.tfvars`
3. `infra/environments/prod/terraform.tfvars`
4. `.github/workflows/aws-devsecops.yml` (if your branch is not `main`)
5. IAM trust policy in `policies/github-oidc-trust.json`

Search all files for: `CHANGE_ME`

## 2) Folder Structure

```text
.
├─ infra/
│  ├─ global/
│  │  ├─ backend.tf
│  │  ├─ providers.tf
│  │  └─ versions.tf
│  ├─ modules/
│  │  ├─ vpc/
│  │  ├─ security-groups/
│  │  ├─ ecr/
│  │  ├─ alb/
│  │  ├─ asg/
│  │  └─ rds-mysql/
│  └─ environments/
│     ├─ dev/
│     ├─ stage/
│     └─ prod/
├─ .github/workflows/
│  ├─ aws-devsecops.yml
│  └─ aws-rollback.yml
├─ app/
│  ├─ Dockerfile
│  ├─ .dockerignore
│  └─ sonar-project.properties
└─ policies/
   ├─ github-oidc-trust.json
   ├─ github-deploy-policy.json
   └─ ec2-instance-role-policy.json
```

## 3) Prerequisites

- AWS account + CLI configured
- Terraform >= 1.6
- GitHub repository
- SonarQube (or SonarCloud)
- App code with `server.js` listening on `APP_PORT`

## 4) Terraform deploy commands

From each env folder (e.g. `infra/environments/dev`):

```bash
terraform init
terraform plan -out tfplan
terraform apply tfplan
```

## 5) GitHub Secrets to create

- `SONAR_TOKEN`
- `SONAR_HOST_URL`
- `AWS_ROLE_TO_ASSUME`
- `AWS_REGION`
- `ECR_REPOSITORY`
- `ASG_NAME`
- `APP_HEALTHCHECK_URL`

## 6) Important Notes

- This template deploys **EC2 ASG path** (not ECS).
- DB password is managed by RDS when `manage_master_user_password = true`.
- Replace open defaults before production:
  - `admin_cidr_blocks`
  - instance sizes
  - retention days
