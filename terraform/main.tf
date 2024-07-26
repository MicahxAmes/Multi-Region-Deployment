provider "aws" {
  alias = "primary"
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
  ami           = var.amis["us-east-1"]
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.primary_private_subnet.id

  vpc_security_group_ids = [aws_security_group.primary_sg.id]

  associate_public_ip_address = true

  tags = {
    Name = "PrimaryInstance"
  }
}

output "primary_instance_public_ip" {
  value = aws_instance.primary_instance.public_ip
}

resource "aws_security_group" "primary_sg" {
  vpc_id = aws_vpc.primary_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    prefix_list_ids = ["pl-062e1d6f8317caab5"]
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = ["pl-062e1d6f8317caab5"]
  }

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

resource "aws_network_acl" "primary_acl" {
  vpc_id = aws_vpc.primary_vpc.id
  tags   = { Name = "PrimaryACL" }
}

resource "aws_network_acl_rule" "allow_http" {
  network_acl_id = aws_network_acl.primary_acl.id
  rule_number    = 100
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "allow_https" {
  network_acl_id = aws_network_acl.primary_acl.id
  rule_number    = 101
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
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

resource "aws_network_acl_association" "primary_public_subnet_association" {
  subnet_id      = aws_subnet.primary_public_subnet.id
  network_acl_id = aws_network_acl.primary_acl.id
}

resource "aws_network_acl_association" "primary_private_subnet_association" {
  subnet_id      = aws_subnet.primary_private_subnet.id
  network_acl_id = aws_network_acl.primary_acl.id
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

  vpc_security_group_ids = [aws_security_group.secondary_sg.id]

  associate_public_ip_address = true

  tags = {
    Name = "SecondaryInstance"
  }
}

output "secondary_instance_public_ip" {
  value = aws_instance.secondary_instance.public_ip
}

resource "aws_security_group" "secondary_sg" {
  provider = aws.secondary
  vpc_id   = aws_vpc.secondary_vpc.id
  name        = "secondary_sg"
  description = "Security group for secondary resources"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    prefix_list_ids = ["pl-09303cf8136420840"]
  }

  ingress {
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    prefix_list_ids = ["pl-09303cf8136420840"]
  }


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

resource "aws_network_acl" "secondary_acl" {
  provider = aws.secondary
  vpc_id = aws_vpc.secondary_vpc.id
  tags   = { Name = "SecondaryACL" }
}

resource "aws_network_acl_rule" "secondary_allow_http" {
  provider = aws.secondary
  network_acl_id = aws_network_acl.secondary_acl.id
  rule_number    = 100
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "secondary_allow_https" {
  provider = aws.secondary
  network_acl_id = aws_network_acl.secondary_acl.id
  rule_number    = 101
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

# Public and Private Subnets in the Secondary VPC
resource "aws_subnet" "secondary_public_subnet" {
  provider          = aws.secondary
  vpc_id            = aws_vpc.secondary_vpc.id
  cidr_block        = "10.1.1.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-west-2a"

  tags = {
    Name = "SecondaryPublicSubnet"
  }
}

resource "aws_subnet" "secondary_private_subnet" {
  provider          = aws.secondary
  vpc_id            = aws_vpc.secondary_vpc.id
  cidr_block        = "10.1.2.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "SecondaryPrivateSubnet"
  }
}

resource "aws_network_acl_association" "secondary_public_subnet_association" {
  provider      = aws.secondary
  subnet_id     = aws_subnet.secondary_public_subnet.id
  network_acl_id = aws_network_acl.secondary_acl.id
}

resource "aws_network_acl_association" "secondary_private_subnet_association" {
  provider      = aws.secondary
  subnet_id     = aws_subnet.secondary_private_subnet.id
  network_acl_id = aws_network_acl.secondary_acl.id
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
  allocation_id = aws_eip.Secondary_nat_eip.id # Corrected to use Secondary_nat_eip
  subnet_id     = aws_subnet.secondary_public_subnet.id

  tags = {
    Name = "SecondaryNATGW"
  }

  depends_on = [
    aws_eip.Secondary_nat_eip
  ]
}

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

  depends_on = [
    aws_internet_gateway.secondary_igw
  ]
}

resource "aws_route_table_association" "secondary_public_rt" {
  provider = aws.secondary
  subnet_id      = aws_subnet.secondary_public_subnet.id
  route_table_id = aws_route_table.Secondary_public_rt.id

  depends_on = [
    aws_route_table.Secondary_public_rt,
    aws_subnet.secondary_public_subnet
  ]
}

resource "aws_route_table" "secondary_private_rt" {
  provider = aws.secondary
  vpc_id = aws_vpc.secondary_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.Secondary_nat_gw.id # Corrected to use Secondary_nat_gw
  }

  tags = {
    Name = "SecondaryPrivateRT"
  }

  depends_on = [
    aws_nat_gateway.Secondary_nat_gw
  ]
}

resource "aws_route_table_association" "secondary_private_rta" {
  provider = aws.secondary
  subnet_id      = aws_subnet.secondary_private_subnet.id
  route_table_id = aws_route_table.secondary_private_rt.id

  depends_on = [
    aws_route_table.secondary_private_rt,
    aws_subnet.secondary_private_subnet
  ]
}

resource "aws_s3_bucket" "mrd_primary_bucket" {
  bucket = "mrd-primary-bucket"
}

resource "aws_s3_bucket_versioning" "mrd_primary_bucket_versioning" {
  bucket = aws_s3_bucket.mrd_primary_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket" "mrd_failover_bucket" {
  provider = aws.secondary
  bucket = "mrd-failover-bucket"
}

resource "aws_s3_bucket_versioning" "mrd_failover_bucket_versioning" {
  provider = aws.secondary
  bucket = aws_s3_bucket.mrd_failover_bucket.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_iam_role" "replication_role" {
  name = "s3_replication_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "s3.amazonaws.com",
        },
      },
    ],
  })
}

resource "aws_iam_policy" "replication_policy" {
  name = "s3_replication_policy"
  policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket",
        ],
        Effect = "Allow",
        Resource = [
          aws_s3_bucket.mrd_primary_bucket.arn,
        ],
      },
      {
        Action = [
          "s3:GetObjectVersion",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging",
        ],
        Effect = "Allow",
        Resource = [
          "${aws_s3_bucket.mrd_primary_bucket.arn}/*",
        ],
      },
      {
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags",
          "s3:GetObjectVersionTagging",
        ],
        Effect = "Allow",
        Resource = "${aws_s3_bucket.mrd_failover_bucket.arn}/*",
      },
    ],
  })
}

resource "aws_iam_role_policy_attachment" "replication_attachment" {
  role       = aws_iam_role.replication_role.name
  policy_arn = aws_iam_policy.replication_policy.arn
}

resource "aws_s3_bucket_replication_configuration" "replication" {
  bucket = aws_s3_bucket.mrd_primary_bucket.id

  role = aws_iam_role.replication_role.arn

  rule {
    id     = "replicateAll"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.mrd_failover_bucket.arn
      storage_class = "STANDARD"
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.mrd_primary_bucket_versioning,
    aws_s3_bucket_versioning.mrd_failover_bucket_versioning
  ]
}

resource "aws_route53_health_check" "failover_health_check" {
  fqdn              = "app.amesmicah.com"
  port              = 80
  type              = "HTTP"
  resource_path     = "/"
  failure_threshold = 3
}

output "health_check_id" {
  value = aws_route53_health_check.failover_health_check.id
}

resource "aws_route53_record" "failover_record" {
  zone_id = "Z0430095YYXRFRIK2GR"
  name    = "app.amesmicah.com"
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
  zone_id = "Z0430095YYXRFRIK2GR"
  name    = "app.amesmicah.com"
  type    = "A"
  set_identifier = "secondary"
  failover_routing_policy {
    type = "SECONDARY"
  }
  health_check_id = aws_route53_health_check.failover_health_check.id
  records = [aws_instance.secondary_instance.public_ip]
  ttl     = 60
}

