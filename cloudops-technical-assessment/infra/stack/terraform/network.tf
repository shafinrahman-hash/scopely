module "vpc" {
  source = "./modules/vpc"

  environment = var.environment
  vpc_name    = "${var.environment}-vpc"
  vpc_cidr    = var.vpc_cidr

  availability_zones  = var.availability_zones
  public_subnet_cidrs = var.public_subnets_cidr
  private_subnet_cidrs = var.private_subnets_cidr
}

module "security" {
  source = "./modules/security"

  environment = var.environment
  vpc_id      = module.vpc.vpc_id

  depends_on = [module.vpc]
}
