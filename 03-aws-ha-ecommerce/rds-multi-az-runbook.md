# RDS Multi-AZ Runbook

## Create DB Subnet Group
- Name: `ecom-db-subnet-group`
- Include DB subnets in both AZs

## Create RDS MySQL
- Engine: MySQL 8.x
- Template: Production
- Availability: Multi-AZ instance
- Public access: No
- Security Group: Database-SG
- Credentials in Secrets Manager

## Operations
- Enable automated backups
- Monitor failover events
- Test manual failover quarterly
