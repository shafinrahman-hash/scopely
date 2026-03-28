variable "environment" {
  description = "Environment name (e.g., dev, prod)"
  type        = string
}

variable "dynamodb_table_arns" {
  description = "DynamoDB table ARNs the ECS task can access"
  type        = list(string)
}

variable "sqs_queue_arns" {
  description = "SQS queue ARNs the ECS task can access"
  type        = list(string)
}
