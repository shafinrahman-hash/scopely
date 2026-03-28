module "iam" {
  source = "./modules/iam"

  environment = var.environment
  dynamodb_table_arns = [
    module.dynamodb.orders_table_arn,
    module.dynamodb.inventory_table_arn
  ]
  sqs_queue_arns = [module.sqs.orders_queue_arn]
}
