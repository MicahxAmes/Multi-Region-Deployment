provider "aws" {
  region = "us-east-1" # Primary region
}

provider "aws" {
  alias  = "secondary"
  region = "us-west-2" # Secondary region
}

#Primary Infrastructure
#primary_vpc, primary_sg, primary_public_subnet, primary_private_subnet, primary_igw, primary_nat_eip, primary_nat_gw, primary_public_rt, primary_public_rta, primary_private_rt, primary_private_rta
resource "aws_vpc" "primary_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
	Name = "PrimaryVPC"
  }
}

resource "aws_instance" "primary_instance" {
 ami           =var.amis["us-east-1"]
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.primary_private_subnet.id
  security_groups = [aws_security_group.secondary_sg.name]

  tags = {
    Name = "PrimaryInstance"
  }
}

resource "aws_security_group" "primary_sg" {
  vpc_id = aws_vpc.primary_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "PrimarySG"
  }
}

# Public and Private Subnets in the Primary VPC
resource "aws_subnet" "primary_public_subnet" {
  vpc_id            = aws_vpc.primary_vpc.id
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1a"

  tags = {
    Name = "PrimaryPublicSubnet"
  }
}

resource "aws_subnet" "primary_private_subnet" {
  vpc_id            = aws_vpc.primary_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "PrimaryPrivateSubnet"
  }
}

# Internet Gateway for the Primary VPC
resource "aws_internet_gateway" "primary_igw" {
  vpc_id = aws_vpc.primary_vpc.id

  tags = {
    Name = "PrimaryIGW"
  }
}

# NAT Gateway for the Primary VPC (requires an EIP)
resource "aws_eip" "primary_nat_eip" {
}

resource "aws_nat_gateway" "primary_nat_gw" {
  allocation_id = aws_eip.primary_nat_eip.id
  subnet_id     = aws_subnet.primary_public_subnet.id

  tags = {
    Name = "PrimaryNATGW"
  }
}

# Route Table for the Public Subnet in the Primary VPC
resource "aws_route_table" "primary_public_rt" {
  vpc_id = aws_vpc.primary_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.primary_igw.id
  }

  tags = {
    Name = "PrimaryPublicRT"
  }
}

resource "aws_route_table_association" "primary_public_rta" {
  subnet_id      = aws_subnet.primary_public_subnet.id
  route_table_id = aws_route_table.primary_public_rt.id
}

# Route Table for the Private Subnet in the Primary VPC
resource "aws_route_table" "primary_private_rt" {
  vpc_id = aws_vpc.primary_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.primary_nat_gw.id
  }

  tags = {
    Name = "PrimaryPrivateRT"
  }
}

resource "aws_route_table_association" "primary_private_rta" {
  subnet_id      = aws_subnet.primary_private_subnet.id
  route_table_id = aws_route_table.primary_private_rt.id
}

#Secondary Infrastructure
#secondary_vpc, secondary_sg, secondary_public_subnet, secondary_private_subnet, secondary_igw, secondary_nat_eip, secondary_nat_gw, secondary_public_rt, secondary_public_rta, secondary_private_rt, secondary_private_rta
resource "aws_vpc" "secondary_vpc" {
  provider = aws.secondary
  cidr_block = "10.1.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
	Name = "SecondaryVPC"
  }
}

resource "aws_instance" "secondary_instance" {
  provider      = aws.secondary
  ami           = var.amis["us-west-2"]
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.secondary_private_subnet.id
  security_groups = [aws_security_group.secondary_sg.name]

  tags = {
    Name = "SecondaryInstance"
  }
}

resource "aws_security_group" "secondary_sg" {
    provider = aws.secondary
  vpc_id = aws_vpc.primary_vpc.id

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "SecondarySG"
  }
}

# Public and Private Subnets in the Secondary VPC
resource "aws_subnet" "secondary_public_subnet" {
    provider = aws.secondary
  vpc_id            = aws_vpc.secondary_vpc.id
  cidr_block        = "10.0.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-2b"

  tags = {
    Name = "SecondaryPublicSubnet"
  }
}

resource "aws_subnet" "secondary_private_subnet" {
    provider = aws.secondary
  vpc_id            = aws_vpc.secondary_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-2b"

  tags = {
    Name = "PrimaryPrivateSubnet"
  }
}

# Internet Gateway for the Primary VPC
resource "aws_internet_gateway" "secondary_igw" {
    provider = aws.secondary
  vpc_id = aws_vpc.secondary_vpc.id

  tags = {
    Name = "SecondaryIGW"
  }
}

# NAT Gateway for the Primary VPC (requires an EIP)
resource "aws_eip" "Secondary_nat_eip" {
    provider = aws.secondary
}

resource "aws_nat_gateway" "Secondary_nat_gw" {
    provider = aws.secondary
  allocation_id = aws_eip.primary_nat_eip.id
  subnet_id     = aws_subnet.secondary_public_subnet.id

  tags = {
    Name = "SecondaryNATGW"
  }
}

# Route Table for the Public Subnet in the Primary VPC
resource "aws_route_table" "Secondary_public_rt" {
    provider = aws.secondary
  vpc_id = aws_vpc.secondary_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.secondary_igw.id
  }

  tags = {
    Name = "SecondaryPublicRT"
  }
}

resource "aws_route_table_association" "secondary_public_rt" {
    provider = aws.secondary
  subnet_id      = aws_subnet.secondary_public_subnet.id
  route_table_id = aws_route_table.Secondary_public_rt.id
}

# Route Table for the Private Subnet in the Primary VPC
resource "aws_route_table" "secondary_private_rt" {
    provider = aws.secondary
  vpc_id = aws_vpc.secondary_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.primary_nat_gw.id
  }

  tags = {
    Name = "SecondaryPrivateRT"
  }
}

resource "aws_route_table_association" "secondary_private_rta" {
  subnet_id      = aws_subnet.secondary_private_subnet.id
  route_table_id = aws_route_table.secondary_private_rt.id
}

resource "aws_route53_zone" "MRD-route" {
  name = "example.com"
}

output "hosted_zone_name" {
  value = aws_route53_zone.MRD-route.name
}

resource "aws_route53_health_check" "failover_health_check" {
  fqdn              = "example.com"
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = 3
}

output "health_check_id" {
  value = aws_route53_health_check.failover_health_check.id
}

resource "aws_route53_record" "failover_record" {
  zone_id = aws_route53_zone.MRD-route.zone_id
  name    = "example.com"
  type    = "A"
  set_identifier = "primary"
  failover_routing_policy {
	type = "PRIMARY"
  }
  health_check_id = aws_route53_health_check.failover_health_check.id
  records = [aws_instance.primary_instance.public_ip]
  ttl     = 60
}

resource "aws_route53_record" "failover_record_secondary" {
  zone_id = aws_route53_zone.MRD-route.zone_id
  name    = "example.com"
  type    = "A"
  set_identifier = "secondary"
  failover_routing_policy {
	type = "SECONDARY"
  }
 records = [aws_instance.secondary_instance.public_ip]
  ttl     = 60
}

