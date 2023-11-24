# Create VPC
resource "aws_vpc" "evmos-testnet" {
  cidr_block           = "${var.cidr_prefix_testnet}.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = "true"

  tags = {
    Name = var.environment_name
  }
}

# Create public subnet 
resource "aws_subnet" "evmos-testnet-sn-public" {
  vpc_id                  = aws_vpc.evmos-testnet.id
  cidr_block              = "${var.cidr_prefix_testnet}.0.0/24"
  availability_zone       = var.az-1
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment_name}-public"
  }
}

# Create private subnet
resource "aws_subnet" "evmos-testnet-sn-priv" {
  vpc_id                  = aws_vpc.evmos-testnet.id
  cidr_block              = "${var.cidr_prefix_testnet}.1.0/24"
  availability_zone       = var.az-1
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.environment_name}-priv"
  }
}

# Create IGW
resource "aws_internet_gateway" "evmos-testnet-ig" {
  vpc_id = aws_vpc.evmos-testnet.id

  tags = {
    Name = var.environment_name
  }
}

# Create NAT GW & EIP for NAT GW
resource "aws_eip" "evmos-testnet-ip-nat" {

  tags = {
    Name = var.environment_name
  }
}

resource "aws_nat_gateway" "evmos-testnet-nat" {
  allocation_id = aws_eip.evmos-testnet-ip-nat.id
  subnet_id     = aws_subnet.evmos-testnet-sn-public.id

  tags = {
    Name = var.environment_name
  }
}

# Handle default route and rename to public
resource "aws_default_route_table" "evmos-testnet-rtb-public" {
  default_route_table_id = aws_vpc.evmos-testnet.default_route_table_id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.evmos-testnet-ig.id
  }

  route {
    cidr_block                = "${var.cidr_prefix_vpn}.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.evmos-testnet-vpn.id
  }

  tags = {
    Name = "${var.environment_name}-public"
  }
}

# Associate route table to public subnet
resource "aws_route_table_association" "evmos-testnet-associate-r-s-public" {
  subnet_id      = aws_subnet.evmos-testnet-sn-public.id
  route_table_id = aws_default_route_table.evmos-testnet-rtb-public.id
}

# Create route table for private subnet
resource "aws_route_table" "evmos-testnet-rtb-private" {
  vpc_id = aws_vpc.evmos-testnet.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.evmos-testnet-nat.id
  }

  route {
    cidr_block                = "${var.cidr_prefix_vpn}.0.0/16"
    vpc_peering_connection_id = aws_vpc_peering_connection.evmos-testnet-vpn.id
  }
}

# Associate route table to private subnet
resource "aws_route_table_association" "evmos-testnet-associate-r-s-private" {
  subnet_id      = aws_subnet.evmos-testnet-sn-priv.id
  route_table_id = aws_route_table.evmos-testnet-rtb-private.id
}

##############################################################################
# Following Section creates the networking recources needed for the vpn server
##############################################################################

# Create VPC for vpn server
resource "aws_vpc" "evmos-testnet-vpn" {
  cidr_block           = "${var.cidr_prefix_vpn}.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = "true"

  tags = {
    Name = "${var.environment_name}-vpn"
  }
}

# Create public subnet for vpn server
resource "aws_subnet" "evmos-testnet-vpn-sn-public" {
  vpc_id                  = aws_vpc.evmos-testnet-vpn.id
  cidr_block              = "${var.cidr_prefix_vpn}.0.0/24"
  availability_zone       = var.az-1
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.environment_name}-vpn-public"
  }
}

# Create private subnet for vpn server
resource "aws_subnet" "evmos-testnet-vpn-sn-priv" {
  vpc_id                  = aws_vpc.evmos-testnet-vpn.id
  cidr_block              = "${var.cidr_prefix_vpn}.1.0/24"
  availability_zone       = var.az-1
  map_public_ip_on_launch = false

  tags = {
    Name = "${var.environment_name}-vpn-priv"
  }
}

# Create IGW for vpn server
resource "aws_internet_gateway" "evmos-testnet-vpn-ig" {
  vpc_id = aws_vpc.evmos-testnet-vpn.id

  tags = {
    Name = var.environment_name
  }
}

# Create NAT GW for vpn server & EIP for NAT GW
resource "aws_eip" "evmos-testnet-vpn-ip-nat" {

  tags = {
    Name = var.environment_name
  }
}

resource "aws_nat_gateway" "evmos-testnet-vpn-nat" {
  allocation_id = aws_eip.evmos-testnet-vpn-ip-nat.id
  subnet_id     = aws_subnet.evmos-testnet-vpn-sn-public.id

  tags = {
    Name = var.environment_name
  }
}

# Handle default route and rename to public
resource "aws_default_route_table" "evmos-testnet-vpn-rtb-public" {
  default_route_table_id = aws_vpc.evmos-testnet-vpn.default_route_table_id

  # Route to world
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.evmos-testnet-vpn-ig.id
  }
  
  # Peering Route to testnet public network 
  route {
    cidr_block                = "${var.cidr_prefix_testnet}.0.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.evmos-testnet-vpn.id
  }

  # Peering Route to testnet private network 
  route {
    cidr_block                = "${var.cidr_prefix_testnet}.1.0/24"
    vpc_peering_connection_id = aws_vpc_peering_connection.evmos-testnet-vpn.id
  }

  tags = {
    Name = "${var.environment_name}-vpn-public"
  }

  
}

# Associate route table to public subnet
resource "aws_route_table_association" "evmos-testnet-vpn-associate-r-s-public" {
  subnet_id      = aws_subnet.evmos-testnet-vpn-sn-public.id
  route_table_id = aws_default_route_table.evmos-testnet-vpn-rtb-public.id
}

# # Create route table for private subnet
# resource "aws_route_table" "evmos-testnet-vpn-rtb-private" {
#   vpc_id = aws_vpc.evmos-testnet.id

#   route {
#     cidr_block     = "0.0.0.0/0"
#     nat_gateway_id = aws_nat_gateway.evmos-testnet-vpn-nat.id
#   }

#   route {
#     cidr_block                = "${var.cidr_prefix_vpn}.0.0/16"
#     vpc_peering_connection_id = aws_vpc_peering_connection.evmos-testnet-vpn.id
#   }
# }

# # Associate route table to private subnet
# resource "aws_route_table_association" "evmos-testnet-vpn-associate-r-s-private" {
#   subnet_id      = aws_subnet.evmos-testnet-vpn-sn-priv.id
#   route_table_id = aws_route_table.evmos-testnet-vpn-rtb-private.id
# }
