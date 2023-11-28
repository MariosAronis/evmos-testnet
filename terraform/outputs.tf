output "Validators-private-ips" {
  value = module.ec2s-main.Validators-Private-IPs
}

output "VPN-Server-IP" {
  value = module.ec2s-main.VPN-Server-IP
}

output "VPN-Server-Private-IP" {
  value = module.ec2s-main.VPN-Server-Private-IP
}

output "evmos-deploy-IAM-Role" {
  value = module.iam-main.evmosnode-deploy-iam-role.arn
}
