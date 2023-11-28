output "evmosnode-profile" {
  value = aws_iam_instance_profile.evmosnode-profile
}

output "evmosnode-deploy-iam-role" {
    value = aws_iam_role.evmos-testnet-deploy-slc
}