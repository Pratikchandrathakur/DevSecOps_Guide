variable "name" { type = string }
variable "db_subnet_ids" { type = list(string) }
variable "db_sg_id" { type = string }
variable "db_name" { type = string }
variable "master_username" { type = string }
variable "instance_class" { type = string }
variable "allocated_storage" { type = number }
variable "multi_az" { type = bool }
