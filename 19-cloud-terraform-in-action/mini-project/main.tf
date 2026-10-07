# ── VPC ──────────────────────────────────────────────────────────────
resource "aws_vpc" "main" {
  cidr_block           = "10.20.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name      = "session19-vpc"
    Session   = "19"
    ManagedBy = "Terraform"
  }
}

# ── Subnet ───────────────────────────────────────────────────────────
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.20.1.0/24"
  availability_zone       = "${var.aws_region}a"
  map_public_ip_on_launch = true

  tags = {
    Name      = "session19-public-subnet"
    Session   = "19"
    ManagedBy = "Terraform"
  }
}

# ── Internet Gateway + Route Table ──────────────────────────────────
resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name      = "session19-igw"
    Session   = "19"
    ManagedBy = "Terraform"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name      = "session19-public-rt"
    Session   = "19"
    ManagedBy = "Terraform"
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# ── Security Group ───────────────────────────────────────────────────
resource "aws_security_group" "web" {
  name        = "session19-web-sg"
  description = "Allow HTTP/HTTPS/SSH for Session 19"
  vpc_id      = aws_vpc.main.id

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name      = "session19-web-sg"
    Session   = "19"
    ManagedBy = "Terraform"
  }
}

# ── EC2 instance ──────────────────────────────────────────────────────
resource "aws_instance" "web" {
  ami                    = "ami-0c02fb55956c7d316" # Amazon Linux 2 (us-east-1 example AMI id -- LocalStack mocks the API, doesn't boot a real VM)
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.web.id]

  tags = {
    Name      = "session19-web-instance"
    Session   = "19"
    ManagedBy = "Terraform"
  }
}

# ── S3 bucket ─────────────────────────────────────────────────────────
resource "aws_s3_bucket" "app_data" {
  bucket        = var.bucket_name
  force_destroy = true

  tags = {
    Name      = var.bucket_name
    Session   = "19"
    ManagedBy = "Terraform"
  }
}
