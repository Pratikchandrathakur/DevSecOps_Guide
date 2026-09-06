resource "aws_db_subnet_group" "this" {
  name       = "${var.name}-db-subnet-group"
  subnet_ids = var.db_subnet_ids
}

resource "aws_db_instance" "this" {
  identifier                     = "${var.name}-mysql"
  engine                         = "mysql"
  engine_version                 = "8.0"
  instance_class                 = var.instance_class
  allocated_storage              = var.allocated_storage
  db_name                        = var.db_name
  username                       = var.master_username
  manage_master_user_password    = true
  multi_az                       = var.multi_az
  publicly_accessible            = false
  vpc_security_group_ids         = [var.db_sg_id]
  db_subnet_group_name           = aws_db_subnet_group.this.name
  backup_retention_period        = 7
  skip_final_snapshot            = true # CHANGE_ME false for prod with snapshot strategy
  deletion_protection            = false # CHANGE_ME true for prod
}
