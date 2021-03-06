
resource "aws_vpc" "myvpc" {
  cidr_block = var.vpccidr

  tags = {
    Name = "${var.env_code}-VPC"
  }
}

data "aws_availability_zones" "az" {
  state = "available"
}

locals {
  public_subnet_cidr  = [var.pubsubnet[0], var.pubsubnet[1]]
  private_subnet_cidr = [var.privsubnet[0], var.privsubnet[1]]
}

resource "aws_subnet" "public" {
  count = length(local.public_subnet_cidr)

  vpc_id                  = aws_vpc.myvpc.id
  cidr_block              = local.public_subnet_cidr[count.index]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.az.names[count.index]

  tags = {
    Name = "${var.env_code} Public${count.index}-Subnet"
  }
}

resource "aws_subnet" "private" {
  count = length(local.private_subnet_cidr)

  vpc_id            = aws_vpc.myvpc.id
  cidr_block        = local.private_subnet_cidr[count.index]
  availability_zone = data.aws_availability_zones.az.names[count.index]

  tags = {
    Name = "${var.env_code} Private${count.index}-Subnet"
  }
}

resource "aws_internet_gateway" "igw" {

  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "${var.env_code}-IGW"
  }
}

resource "aws_eip" "eipnat" {
  count = length(local.private_subnet_cidr)

  vpc = true

  tags = {
    Name = "${var.env_code}-EIP_NAT${count.index}"
  }
}

resource "aws_nat_gateway" "ngw" {
  count = length(local.private_subnet_cidr)

  allocation_id = aws_eip.eipnat[count.index].id
  subnet_id     = aws_subnet.public[count.index].id

  tags = {
    Name = "${var.env_code}-NGW${count.index}"
  }
}

resource "aws_route_table" "publicroute" {

  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = var.secgrpcidr
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.env_code}-PublicRouteTable"
  }
}

resource "aws_route_table_association" "associatepub" {
  count = length(local.public_subnet_cidr)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.publicroute.id
}

resource "aws_route_table" "privateroute" {
  count = length(local.private_subnet_cidr)

  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block     = var.secgrpcidr
    nat_gateway_id = aws_nat_gateway.ngw[count.index].id
  }

  tags = {
    Name = "${var.env_code}-PrivateRouteTable${count.index}"
  }
}

resource "aws_route_table_association" "associatepriv" {
  count = length(local.private_subnet_cidr)

  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.privateroute[count.index].id
}

