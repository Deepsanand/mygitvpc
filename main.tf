terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}

resource "aws_vpc" "myvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "myvpc"
  }
}

resource "aws_subnet" "mypublicsub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "mypublicsub"
  }
}

resource "aws_subnet" "myprivatesub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "ap-south-1b"

  tags = {
    Name = "myprivatesub"
  }
}

resource "aws_internet_gateway" "myigw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "myigw"
  }
}

resource "aws_eip" "myeip" {
  domain   = "vpc"
}

resource "aws_nat_gateway" "mynat" {
  allocation_id = aws_eip.myeip.id
  subnet_id     = aws_subnet.mypublicsub.id

  tags = {
    Name = "mynat"
  }
}

resource "aws_route_table" "mypublicrt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myigw.id
  }
    tags = {
    Name = "mypublicrt"
  }
}

resource "aws_route_table" "myprivatert" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.mynat.id
  }
    tags = {
    Name = "myprivatert"
  }
}

resource "aws_route_table_association" "pubrtassociation" {
  subnet_id      = aws_subnet.mypublicsub.id
  route_table_id = aws_route_table.mypublicrt.id
}

resource "aws_route_table_association" "prvrtassociation" {
  subnet_id      = aws_subnet.myprivatesub.id
  route_table_id = aws_route_table.myprivatert.id
}

resource "aws_security_group" "mypubsg" {
  name        = "mypubsg"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
  ingress {
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
  }
    egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mypubsg"
  }
}

resource "aws_security_group" "mypvtsg" {
  name        = "mypvtsg"
  vpc_id      = aws_vpc.myvpc.id

  ingress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["10.0.1.0/24"]
  }
    egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
  }

  tags = {
    Name = "mypvtsg"
  }
}

resource "aws_instance" "mypubinstance" {
  ami           = "ami-067c21fb1979f0b27"
  instance_type = "t2.micro"
  key_name   = "ppkkey"
  associate_public_ip_address = true
  subnet_id = aws_subnet.mypublicsub.id
  vpc_security_group_ids = [aws_security_group.mypubsg.id]
}

resource "aws_instance" "mypvtinstance" {
  ami           = "ami-067c21fb1979f0b27"
  instance_type = "t2.micro"
  key_name   = "ppkkey"
  associate_public_ip_address = false
  subnet_id = aws_subnet.myprivatesub.id
  vpc_security_group_ids = [aws_security_group.mypvtsg.id]
}