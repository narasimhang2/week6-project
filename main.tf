terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-southeast-2" 
}

# 1. Create the Custom VPC
resource "aws_vpc" "custom_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "shanthi-it-vpc"
  }
}

# 2. Create a Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.custom_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "ap-southeast-2c"
  map_public_ip_on_launch = true

  tags = {
    Name = "shanthi-it-public-subnet"
  }
}

# 3. Create a Private Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.custom_vpc.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "ap-southeast-2c"

  tags = {
    Name = "shanthi-it-private-subnet"
  }
}

# 4. Create an Internet Gateway (for Public Subnet internet access)
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.custom_vpc.id

  tags = {
    Name = "shanthi-it-vpc-igw"
  }
}

# 5. Create a Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.custom_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "shanthi-it-public-rt"
  }
}

# 6. Associate Public Subnet with the Public Route Table
resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}
# 7. Fetch the latest official Debian AMI automatically
data "aws_ami" "debian" {
  most_recent = true
  owners      = ["136693071363"] # Official Debian AWS Account ID

  filter {
    name   = "name"
    values = ["debian-12-amd64-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# 8. Create a Security Group for the EC2 instance (unchanged)
resource "aws_security_group" "ec2_sg" {
  name        = "shanthi-it-vpc-ec2-sg"
  description = "Allow SSH inbound traffic and all outbound traffic"
  vpc_id      = aws_vpc.custom_vpc.id

  ingress {
    description = "SSH access"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "shanthi-it-vpc-ec2-sg"
  }
}

# 9. Launch the Debian EC2 Instance inside the Public Subnet
resource "aws_instance" "web_server" {
  ami                         = data.aws_ami.debian.id
  instance_type               = "t3.micro"
  subnet_id                   = aws_subnet.public_subnet.id
  vpc_security_group_ids      = [aws_security_group.ec2_sg.id]
  associate_public_ip_address = true

  # Uncomment and add your AWS Key Pair name to SSH into the instance
  # key_name = "my-aws-keypair"

  tags = {
    Name = "shanthi-it-vpc-debian-ec2"
  }
}
