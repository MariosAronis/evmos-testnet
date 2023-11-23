provider "aws" {
  region = var.region
}

module "vpc-main" {
  source              = "./modules/vpc"
  environment_name    = vars.environment_name
  az-1                = vars.az-1
  az-2                = vars.az-2
  cidr_prefix_testnet = vars.cidr_prefix_testnet
  cidr_prefix_vpn     = vars.cidr_prefix_vpn
}