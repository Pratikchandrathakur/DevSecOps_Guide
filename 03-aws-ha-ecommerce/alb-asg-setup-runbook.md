# ALB and Auto Scaling Setup Runbook

## Target Group
- Name: `ecom-tg`
- Protocol/Port: HTTP/80
- Health path: `/healthz.html`
- Thresholds: healthy=2, unhealthy=2, interval=15s

## ALB
- Name: `ecom-alb`
- Scheme: internet-facing
- Subnets: both public subnets
- SG: ALB-SG
- Listener: 80 -> `ecom-tg`

## ASG
- Name: `ecom-asg`
- Launch template: `ecom-launch-template`
- Subnets: private app subnets
- Desired=2, Min=2, Max=6
- Target tracking policy: CPU 60%
