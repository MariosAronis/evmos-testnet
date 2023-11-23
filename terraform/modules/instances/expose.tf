output "Validators-Private-IPs" {
  value = ["${aws_instance.evmos-validator.*.private_ip}"]
}