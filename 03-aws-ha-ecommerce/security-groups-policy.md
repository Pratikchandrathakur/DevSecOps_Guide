# Security Groups Policy (Least Privilege)

## ALB-SG
- Inbound: 80,443 from `0.0.0.0/0`
- Outbound: 80 to App-SG only

## App-SG
- Inbound: 80 from ALB-SG
- Inbound: 22 from approved admin source only
- Outbound: app-dependent (prefer scoped rules)

## Database-SG
- Inbound: 3306 from App-SG only
- No public inbound rules
