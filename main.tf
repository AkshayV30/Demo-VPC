terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    random = {
      source = "hashicorp/random"
    }
  }

  cloud {
    organization = "project-demo-17-11-2022"

    workspaces {
      name = "snipe-git-actions"
    }
  }
}



module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = "pearl-vpc"
  cidr = "10.0.0.0/16"

  azs             = ["ap-south-1a", "ap-south-1b", "ap-south-1c"]
  private_subnets = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
  public_subnets  = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]

  enable_nat_gateway = true
  enable_vpn_gateway = true

  tags = {
    Terraform   = "true"
    Environment = "test"
  }
}

# Setting up the route table
resource "aws_route_table" "pearl-route" {
  vpc_id = aws_vpc.pearl-vpc.id
  route {
    # pointing to the internet
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.pearl-ig.id
  }
  route {
    ipv6_cidr_block = "::/0"
    gateway_id      = aws_internet_gateway.pearl-ig.id
  }
  tags = {
    Name = "routetable-1"
  }
}



# Creating a Security Group
resource "aws_security_group" "pearl-security-group" {
  name        = "pearl-security-1"
  description = "Enable web traffic for the project"
  vpc_id      = aws_vpc.pearl-vpc.id
  ingress {
    description = "HTTPS traffic"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "HTTP traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "SSH port"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "pearl-security=group"
  }
}

# Creating a new network interface
resource "aws_network_interface" "pearl-ni" {
  subnet_id       = aws_subnet.pearl-subnet.id
  private_ips     = ["10.0.1.10"]
  security_groups = [aws_security_group.pearl-sg.id]
}

# Attaching an elastic IP to the network interface
resource "aws_eip" "pearl-eip" {
  vpc                       = true
  network_interface         = aws_network_interface.pearl-ni.id
  associate_with_private_ip = "10.0.1.10"
}
