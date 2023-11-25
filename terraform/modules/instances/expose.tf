output "Validators-Private-IPs" {
  value = ["${aws_instance.evmos-validator.*.private_ip}"]
}

output "VPN-Server-IP" {
  value = [aws_instance.evmos_testnet_vpn.public_ip]
}

output "VPN-Server-Private-IP" {
  value = [aws_instance.evmos_testnet_vpn.private_ip]
}