resource "aws_vpc" "digipoc_vpc" {
  cidr_block = "10.0.0.0/16"

  tags = {
    Name        = "Digipoc VPC"
    Application = var.application
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.digipoc_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "1a"

  tags = {
    Name        = "Digipoc Public Subnet"
    Application = var.application
  }
}

resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.digipoc_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "1a"

  tags = {
    Name        = "Digipoc Private Subnet"
    Application = var.application
  }
}

resource "aws_internet_gateway" "internet_gateway" {
  vpc_id = aws_vpc.digipoc_vpc.id

  tags = {
    Name        = "Digipoc Internet Gateway"
    Application = var.application
  }
}

resource "aws_route_table" "public_route_table" {
  vpc_id = aws_vpc.digipoc_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.internet_gateway.id
  }

  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.internet_gateway.id
  }

  tags = {
    Name        = "Digipoc Public Route Table"
    Application = var.application
  }
}

resource "aws_route_table_association" "public_1_rt_a" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_route_table.id
}

resource "aws_security_group" "web_sg" {
  name   = "HTTP and SSH"
  vpc_id = aws_vpc.digipoc_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = -1
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "Digipoc Access from web security group"
    Application = var.application
  }
}
