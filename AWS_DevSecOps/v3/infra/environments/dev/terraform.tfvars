aws_region = "us-east-1" # CHANGE_ME
name_prefix = "ecom-dev"

vpc_cidr = "10.0.0.0/16"
azs = ["us-east-1a", "us-east-1b"] # CHANGE_ME
public_subnet_cidrs = ["10.0.1.0/24", "10.0.2.0/24"]
app_subnet_cidrs    = ["10.0.10.0/24", "10.0.20.0/24"]
db_subnet_cidrs     = ["10.0.100.0/24", "10.0.200.0/24"]

admin_cidr_blocks = ["0.0.0.0/0"] # CHANGE_ME to your public IP/32

instance_type = "t3.micro"
ami_id = "ami-CHANGE_ME" # CHANGE_ME valid AMI in your region

desired_capacity = 2
min_size = 2
max_size = 4

db_name = "ecommerce_db"
db_user = "admin"
db_instance_class = "db.t3.micro"
db_allocated_storage = 20
db_multi_az = false # CHANGE_ME true for prod
