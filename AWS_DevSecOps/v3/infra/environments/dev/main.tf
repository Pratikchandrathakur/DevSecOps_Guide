module "vpc" {
  source              = "../../modules/vpc"
  name                = var.name_prefix
  vpc_cidr            = var.vpc_cidr
  azs                 = var.azs
  public_subnet_cidrs = var.public_subnet_cidrs
  app_subnet_cidrs    = var.app_subnet_cidrs
  db_subnet_cidrs     = var.db_subnet_cidrs
}

module "sg" {
  source            = "../../modules/security-groups"
  name              = var.name_prefix
  vpc_id            = module.vpc.vpc_id
  admin_cidr_blocks = var.admin_cidr_blocks
}

module "ecr" {
  source = "../../modules/ecr"
  name   = "${var.name_prefix}-app"
}

module "alb" {
  source            = "../../modules/alb"
  name              = var.name_prefix
  vpc_id            = module.vpc.vpc_id
  public_subnet_ids = module.vpc.public_subnet_ids
  alb_sg_id         = module.sg.alb_sg_id
}

module "asg" {
  source           = "../../modules/asg"
  name             = var.name_prefix
  app_subnet_ids   = module.vpc.app_subnet_ids
  app_sg_id        = module.sg.app_sg_id
  target_group_arn = module.alb.target_group_arn
  instance_type    = var.instance_type
  desired_capacity = var.desired_capacity
  min_size         = var.min_size
  max_size         = var.max_size
  ami_id           = var.ami_id
}

module "rds" {
  source               = "../../modules/rds-mysql"
  name                 = var.name_prefix
  db_subnet_ids        = module.vpc.db_subnet_ids
  db_sg_id             = module.sg.db_sg_id
  db_name              = var.db_name
  master_username      = var.db_user
  instance_class       = var.db_instance_class
  allocated_storage    = var.db_allocated_storage
  multi_az             = var.db_multi_az
}
