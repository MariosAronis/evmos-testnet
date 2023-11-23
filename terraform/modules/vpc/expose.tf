output "sg-pub" {
  value = aws_security_group.evmos-testnet-sg1-public
}

output "sg-priv" {
  value = aws_security_group.evmos-testnet-sg-priv
}

output "subnet-pub" {
  value = aws_subnet.evmos-testnet-sn-public
}

output "subnet-priv" {
  value = aws_subnet.evmos-testnet-sn-priv
}