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

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.124.0.0/20"
}

variable "availability_zones" {
  description = "Region AZs"
  default     = ["eu-west-1a"]
  type        = list(string)
}

variable "public_subnets_cidr" {
  description = "Public Subnets CIDRs"
  default     = ["10.124.0.0/27"]
  type        = list(string)
}

variable "private_subnets_cidr" {
  description = "Private Subnets CIDRs"
  default     = ["10.124.1.0/27"]
  type        = list(string)
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

variable "order_api_repo_arn" {
  description = "ECR Repo ARN for Order API"
  type        = string
}

variable "order_processor_repo_arn" {
  description = "ECR Repo ARN for Order Processor"
  type        = string
}

variable "order_history_repo_arn" {
  description = "ECR Repo ARN for Order History Service"
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

variable "rds_db_name" {
  description = "RDS database name"
  type        = string
  default     = "orderhistory"
}

variable "rds_db_username" {
  description = "RDS database username"
  type        = string
  default     = "cloudops"
}

variable "use_secrets_manager" {
  description = "If true, inject DATABASE_URL from Secrets Manager into ECS task."
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

variable "rds_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}
