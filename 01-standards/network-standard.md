# Network Standards

## Core Principles
- Segregate by trust zones: Public, App, Data, Management
- Deny-by-default inbound rules
- Least-privilege east-west traffic
- All critical services deployed across at least 2 AZs

## Mandatory Controls
- No direct public access to databases
- Bastion or managed access paths only (no open SSH/RDP)
- WAF for internet-facing apps where possible
- TLS in transit for user and service communication

## Routing Rules
- Public subnets route to IGW
- Private app subnets route to NAT
- DB subnets have no internet route

## DNS Standards
- Internal DNS for private services
- Health-checked DNS records for critical apps
- TTL tuning for failover-sensitive endpoints

## Monitoring
- Latency, packet loss, throughput alerts
- Link/ISP uptime dashboard
- Interface and route change audit logs
