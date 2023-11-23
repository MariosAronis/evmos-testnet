
resource "aws_instance" "evmos-validator" {
  count = var.ec2-count
  ami                     = var.ami
  instance_type           = var.instance_type
  disable_api_termination = true
  subnet_id               = var.subnet-priv
  vpc_security_group_ids  = [var.secgroup-priv]
  ebs_optimized           = "true"
  key_name                = "mariosee"
#   iam_instance_profile    = var.evmos-validator-profile.name

  root_block_device {
    volume_type = "gp2"
    volume_size = "100"
  }

  tags = {
    Name = "evmos-validator-${count.index}"
  }

  volume_tags = {
    "Name" = "evmos-validator-root-ebs-${count.index}"
  }

  lifecycle {
    ignore_changes = [ami, root_block_device]
  }
}

# Create SSD volume for evmos-validator
resource "aws_ebs_volume" "evmos-validator-chaindata" {
 count = var.ec2-count
 availability_zone = aws_instance.evmos-validator["${count.index}"].availability_zone
 size              = var.storage
 type              = "gp2"

 tags = {
   Name = "evmos-validator-chaindata-${count.index}"
 }
}

resource "aws_volume_attachment" "evmos-validator-chaindata-attach" {
 count = var.ec2-count
 device_name = "/dev/sdf"
 volume_id   = aws_ebs_volume.evmos-validator-chaindata["${count.index}"].id
 instance_id = aws_instance.evmos-validator["${count.index}"].id
}

# resource "aws_iam_policy_attachment" "iam-role-attach" {
#   name       = "iam-role-attachment"
#   roles      = [aws_iam_role.evmos-validator-role.name]
#   policy_arn = aws_iam_policy.demo-s3-policy.arn
# }
