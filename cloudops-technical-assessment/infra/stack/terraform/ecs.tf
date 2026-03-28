module "ecs" {
  source      = "./modules/ecs"
  environment = var.environment

  vpc_id          = module.vpc.vpc_id
  public_subnets  = module.vpc.public_subnets
  private_subnets = module.vpc.private_subnets

  alb_security_group_id = module.security.alb_security_group_id
  ecs_security_group_id = module.security.ecs_task_security_group_id

  order_api_image     = var.order_api_image
  processor_image     = var.processor_image
  order_history_image = var.order_history_image
  enable_https        = var.enable_https
  acm_certificate_arn = var.acm_certificate_arn
  enable_waf          = var.enable_waf
  waf_rate_limit      = var.waf_rate_limit
  waf_blocked_countries = var.waf_blocked_countries
  waf_blocked_ip_cidrs  = var.waf_blocked_ip_cidrs
  enable_waf_logging    = var.enable_waf_logging

  ecs_execution_role_arn = module.iam.ecs_execution_role_arn
  ecs_task_role_arn      = module.iam.ecs_task_role_arn

  inventory_table_name = module.dynamodb.inventory_table_name
  orders_table_name    = module.dynamodb.orders_table_name
  sqs_orders_queue_url = module.sqs.orders_queue_url

  rds_endpoint    = module.rds.endpoint
  rds_port        = module.rds.port
  rds_db_name     = module.rds.db_name
  rds_db_username = var.rds_db_username
  rds_db_password = var.rds_db_password
  use_secrets_manager       = var.use_secrets_manager
  rds_database_url_secret_arn = var.rds_database_url_secret_arn

  depends_on = [module.vpc]
}
