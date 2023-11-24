output "Validators-private-ips" {
  value = module.ec2s-main.Validators-Private-IPs
}

output "VPN-Server-IP" {
  value = module.ec2s-main.VPN-Server-IP
}
