variable "environment" {
  description = "Environment name"
  type        = string
  default     = "cloudops"
}

variable "vpc_name" {
  description = "VPC Name"
  type        = string
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
}

variable "availability_zones" {
  description = "Availability zones used by subnets"
  type        = list(string)
}

variable "public_subnet_cidrs" {
  description = "VPC Public Subnets CIDR"
  type        = list(string)
}

variable "private_subnet_cidrs" {
  description = "VPC Private Subnets CIDR"
  type        = list(string)
}
