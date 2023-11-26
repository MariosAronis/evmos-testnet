#######################################
# Deploy OpenVPNAS from AWS MarketPlace
#######################################

resource "aws_instance" "evmos_testnet_vpn" {
  ami = "ami-0be082f179862d3f7"
  instance_type = var.vpn_instance_type
  subnet_id = var.subnet-vpn.id
  vpc_security_group_ids = [var.secgroup-vpn]
  key_name = var.private_key
  root_block_device {
    volume_type = "gp2"
    volume_size = "100"
  }

  tags = {
    Name = "evmos-testnet-vpn"
  }

  volume_tags = {
    "Name" = "evmos-testnet-vpn-root-ebs"
  }
}


#################################################
# Compute & EBS Resources for validator cluster
#################################################

resource "aws_instance" "evmos-validator" {
  count = var.ec2-count
  ami                     = var.ami
  instance_type           = var.instance_type
#   disable_api_termination = false
  subnet_id               = var.subnet-priv
  vpc_security_group_ids  = [var.secgroup-priv]
  ebs_optimized           = "true"
  key_name                = var.private_key
#   iam_instance_profile    = var.evmos-validator-profile.name
  user_data = <<EOF
#!/bin/bash
apt-get update
apt-get install -y net-tools
apt-get install ca-certificates curl gnupg
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg
echo   "deb [arch="$(dpkg --print-architecture)" signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu \
"$(. /etc/os-release && echo "$VERSION_CODENAME")" stable" |   sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
apt-get update
apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin gcc make jq -y
usermod -aG docker $USER
hostnamectl set-hostname "evmos-validator-${count.index}"
EOF

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

#   provisioner "remote-exec" {
#   inline = ["sudo hostnamectl set-hostname evmos-validator-${count.index}"]
# }
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
