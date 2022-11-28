# uncommnet the required provider incase u want to use it with tearrform cloud
# terraform {
#   required_providers {
#     aws = {
#       source = "hashicorp/aws"
#     }
#     # random = {
#     #   source = "hashicorp/random"
#     # }
#   }

#   cloud {
#     organization = "project-demo-17-11-2022"

#     workspaces {
#       name = "snipe-git-actions"
#     }
#   }
# }


terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      # optional
      version = "~> 3.0"
    }
  }
}

# -------------------------------------------------------------------------------------------------------------------------
# Creating a VPC
resource "aws_vpc" "pearl-vpc" {
  cidr_block = "10.0.0.0/16"
}

# Create an Internet Gateway
resource "aws_internet_gateway" "pearl-ig" {
  vpc_id = aws_vpc.pearl-vpc.id
  tags = {
    Name = "pearl-gateway"
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
    Name = "pearl-routetable-1"
  }
}

# Setting up the subnet
resource "aws_subnet" "pearl-subnet" {
  vpc_id            = aws_vpc.pearl-vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-south-1a"
  tags = {
    Name = "pearl-subnet-1"
  }
}

# Associating the subnet with the route table
resource "aws_route_table_association" "pearl-route-sub-assoc" {
  subnet_id      = aws_subnet.pearl-subnet.id
  route_table_id = aws_route_table.pearl-route.id
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
    Name = "pearl-security-group"
  }
}

# Creating a new network interface
resource "aws_network_interface" "pearl-ni" {
  subnet_id       = aws_subnet.pearl-subnet.id
  private_ips     = ["10.0.1.10"]
  security_groups = [aws_security_group.pearl-security-group.id]
}

# Attaching an elastic IP to the network interface
resource "aws_eip" "pearl-eip" {
  vpc                       = true
  network_interface         = aws_network_interface.pearl-ni.id
  associate_with_private_ip = "10.0.1.10"
}
