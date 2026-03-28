module "dynamodb" {
  source = "./modules/dynamodb"

  environment = var.environment
}

module "sqs" {
  source = "./modules/sqs"

  environment = var.environment
}

module "rds" {
  source = "./modules/rds"

  environment           = var.environment
  private_subnets       = module.vpc.private_subnets
  rds_security_group_id = module.security.rds_security_group_id

  db_name        = var.rds_db_name
  db_username    = var.rds_db_username
  db_password    = var.rds_db_password
  instance_class = var.rds_instance_class
}
