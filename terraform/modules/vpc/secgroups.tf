# Rename default security group for evmos-testnet-default
resource "aws_default_security_group" "evmos-testnet-default" {
  vpc_id = aws_vpc.evmos-testnet.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "evmos-testnet-default"
  }
}

# Create security group for evmos-testnet public subnet
resource "aws_security_group" "evmos-testnet-sg1-public" {
  name        = "evmos-testnet-sg1-public"
  description = "Security group for publicly exposed services/ports"
  vpc_id      = aws_vpc.evmos-testnet.id

ingress {
    description = "Allow all from vpn subnets"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.cidr_prefix_vpn}.0.0/16"]
  }

  ingress {
    description = "Allow geth discovery port"
    from_port   = 30303
    to_port     = 30303
    protocol    = "tcp"
    cidr_blocks = ["${var.cidr_prefix_testnet}.0.0/16"]
  }

  ingress {
    description = "Allow geth discovery port"
    from_port   = 30303
    to_port     = 30303
    protocol    = "udp"
    cidr_blocks = ["${var.cidr_prefix_testnet}.0.0/16"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create security group for evmos-testnet private subnet
resource "aws_security_group" "evmos-testnet-sg-priv" {
  name        = "evmos-testnet-sg-priv"
  description = "Security Group for internal vpc communications"
  vpc_id      = aws_vpc.evmos-testnet.id

  ingress {
    description = "Allow all intra vpc for private subnets"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.cidr_prefix_testnet}.1.0/24", "${var.cidr_prefix_testnet}.2.0/24", "${var.cidr_prefix_testnet}.3.0/24"]
  }

  ingress {
    description = "Allow all from vpn subnets"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["${var.cidr_prefix_vpn}.0.0/16"]
  }

  ingress {
    description = "Allow geth discovery port"
    from_port   = 30303
    to_port     = 30303
    protocol    = "tcp"
    cidr_blocks = ["${var.cidr_prefix_testnet}.0.0/16"]
  }

   ingress {
    description = "Allow geth discovery port"
    from_port   = 30303
    to_port     = 30303
    protocol    = "udp"
    cidr_blocks = ["${var.cidr_prefix_testnet}.0.0/16"]
  }


  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "evmos-testnet-private"
  }
}


###############################
# Security Group for vpn server
###############################

resource "aws_security_group" "evmos-vpn-sg" {
  name        = "evmos-vpn-sg"
  description = "Security Group for vpn subnet"
  vpc_id      = aws_vpc.evmos-testnet-vpn.id 

  # Allow UDP tunelling on all IFs
  ingress {
    from_port = 943
    to_port = 943
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  } 

  # WARNING: THIS IS ONLY TEMNPORARY: Allow SSH on all IFs from admin publicIP
  # Make sure to remove this rule when tunneling is enabled/configured

  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.admin-public-ip}/32"]
  } 

  # Allow UDP tunelling on all IFs
  ingress {
    from_port = 1194
    to_port = 1194
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  } 

  # Allow HTTPS access on all IFs
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  } 

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "evmos-vpn-sg"
  }
  
}