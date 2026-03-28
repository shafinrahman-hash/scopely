variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-1"
}

variable "environment" {
  description = "Environment name"
  type        = string
  default     = "cloudops"
}

variable "public_subnets" {
  description = "Public Subnets"
  type        = list(string)
}

variable "private_subnets" {
  description = "Private Subnets"
  type        = list(string)
}

variable "ecs_security_group_id" {
  description = "Security Group for ECS"
  type        = string
}

variable "order_api_image" {
  description = "Docker image for Order API"
  type        = string
}

variable "processor_image" {
  description = "Docker image for Order Processor"
  type        = string
}

variable "order_history_image" {
  description = "Docker image for Order History Service"
  type        = string
}

variable "enable_https" {
  description = "Enable HTTPS listener on ALB and redirect HTTP to HTTPS."
  type        = bool
  default     = false
}

variable "acm_certificate_arn" {
  description = "ACM certificate ARN used by ALB HTTPS listener."
  type        = string
  default     = null
  nullable    = true
}

variable "enable_waf" {
  description = "Enable AWS WAF on ALB."
  type        = bool
  default     = false
}

variable "waf_rate_limit" {
  description = "Rate limit (requests/5 min per IP) for WAF rate-based rule."
  type        = number
  default     = 2000
}

variable "waf_blocked_countries" {
  description = "ISO country codes to block at WAF layer."
  type        = list(string)
  default     = []
}

variable "waf_blocked_ip_cidrs" {
  description = "IP CIDRs to block at WAF layer."
  type        = list(string)
  default     = []
}

variable "enable_waf_logging" {
  description = "Enable WAF logging to CloudWatch log group."
  type        = bool
  default     = false
}

variable "vpc_id" {
  description = "vpc_id"
  type        = string
}

variable "alb_security_group_id" {
  description = "Security Group for ECS cluster ALB"
  type        = string
}

variable "ecs_execution_role_arn" {
  description = "ECS Task execution role ARN"
  type        = string
}

variable "ecs_task_role_arn" {
  description = "ECS Task task role ARN"
  type        = string
}

variable "orders_table_name" {
  description = "Name of the DynamoDB orders table"
  type        = string
}

variable "inventory_table_name" {
  description = "Name of the DynamoDB inventory table"
  type        = string
}

variable "sqs_orders_queue_url" {
  description = "URL of the SQS orders queue"
  type        = string
}

variable "rds_endpoint" {
  description = "RDS endpoint hostname"
  type        = string
}

variable "rds_port" {
  description = "RDS port"
  type        = number
}

variable "rds_db_name" {
  description = "RDS database name"
  type        = string
}

variable "rds_db_username" {
  description = "RDS database username"
  type        = string
}

variable "use_secrets_manager" {
  description = "If true, inject DATABASE_URL from Secrets Manager."
  type        = bool
  default     = false
}

variable "rds_database_url_secret_arn" {
  description = "Secrets Manager ARN that stores full DATABASE_URL value."
  type        = string
  default     = null
  nullable    = true
}

variable "rds_db_password" {
  description = "RDS database password"
  type        = string
  sensitive   = true
  default     = null
  nullable    = true
}
variable "instance_type" {
  description = "Instance type"
  type        = string
  default     = "t3.micro"
}
