# AWS Highly Available 3-Tier E-commerce Architecture

## Objective
Deliver fault-tolerant, scalable, and secure e-commerce hosting with no direct public DB access.

## Topology

- Route 53 (DNS)
- Internet-facing ALB in Public Subnets (2 AZs)
- EC2 Auto Scaling Group in Private App Subnets (2 AZs)
- RDS MySQL Multi-AZ in Isolated DB Subnets (2 AZs)
- NAT Gateway for outbound internet from private app tier

## CIDR Plan

- VPC: `10.0.0.0/16`
- Public-1: `10.0.1.0/24` (`us-east-1a`)
- Public-2: `10.0.2.0/24` (`us-east-1b`)
- App-1: `10.0.10.0/24` (`us-east-1a`)
- App-2: `10.0.20.0/24` (`us-east-1b`)
- DB-1: `10.0.100.0/24` (`us-east-1a`)
- DB-2: `10.0.200.0/24` (`us-east-1b`)

## Security Groups

- **ALB-SG**
  - Inbound: 80/443 from `0.0.0.0/0`
  - Outbound: 80 to `App-SG`
- **App-SG**
  - Inbound: 80 from `ALB-SG`
  - Inbound: 22 from Bastion/EC2 Instance Connect only
- **Database-SG**
  - Inbound: 3306 from `App-SG`
  - Public access disabled

## Availability Design
- At least 2 instances in ASG at all times
- Multi-AZ RDS for DB failover
- ALB health checks + ASG replacement on failure

## Operational Guarantees
- No single AZ failure causes complete outage
- Recovery automated for app-tier instance failures
