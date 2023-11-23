provider "aws" {
  region = var.region
}

module "vpc-main" {
  source              = "./modules/vpc"
  environment_name    = var.environment_name
  az-1                = var.az-1
  az-2                = var.az-2
  cidr_prefix_testnet = var.cidr_prefix_testnet
  cidr_prefix_vpn     = var.cidr_prefix_vpn
}