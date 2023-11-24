resource "aws_vpc_peering_connection" "evmos-testnet-vpn" {
  peer_vpc_id = aws_vpc.evmos-testnet-vpn.id
  vpc_id      = aws_vpc.evmos-testnet.id
  auto_accept = true

  tags = {
    Name = "evmos-testnet-vpn"
  }

  depends_on = [aws_vpc.evmos-testnet, aws_vpc.evmos-testnet-vpn]
}