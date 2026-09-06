output "alb_dns_name" { value = module.alb.alb_dns_name }
output "ecr_repository_name" { value = module.ecr.repository_name }
output "asg_name" { value = module.asg.asg_name }
output "db_endpoint" { value = module.rds.db_endpoint }
