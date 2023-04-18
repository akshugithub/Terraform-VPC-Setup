# Configure the AWS Provider
provider "aws" {
  region = "ap-south-1"
}

# creating vpc
resource "aws_vpc" "myvpc" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "VPC"
  }
}

# creating public subnet
resource "aws_subnet" "pubsub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.1.0/24"

  tags = {
    Name = "Public-Subnet"
  }
}

# creating private subnet
resource "aws_subnet" "privsub" {
  vpc_id     = aws_vpc.myvpc.id
  cidr_block = "10.0.2.0/24"

  tags = {
    Name = "Private-subnet"
  }
}

# creating internetgateway
resource "aws_internet_gateway" "myigw" {
  vpc_id = aws_vpc.myvpc.id

  tags = {
    Name = "IGW"
  }
}
# creating elasticip
#resource "aws_eip" "myeip" {
 # vpc      = true
#}

# creating natgw
resource "aws_nat_gateway" "mynatgw" {
  allocation_id = aws_eip.myeip.id
  subnet_id     = aws_subnet.pubsub.id

  tags = {
    Name = "NATGW"
  }
}

# creating public routetable
resource "aws_route_table" "pubrt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.myigw.id
  }
  tags = {
    Name = "Public-RT"
  }
}

# creating public routetable association
resource "aws_route_table_association" "pubrtassociation" {
  subnet_id      = aws_subnet.pubsub.id
   route_table_id = aws_route_table.pubrt.id
}

# creating privateroutetable
resource "aws_route_table" "privrt" {
  vpc_id = aws_vpc.myvpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.mynatgw.id
  }
  tags = {
    Name = "Private-RT"
  }
}

# creating privaterouttable association
resource "aws_route_table_association" "privassociation" {
  subnet_id      = aws_subnet.privsub.id
  route_table_id = aws_route_table.privrt.id
}

# creating security group to allow ibound traffic from 443,80,22

resource "aws_security_group" "inboundtraffic" {
 name        = "tfsecgrp"
 description = "Allow traffic from 443,80,22"
 vpc_id      = aws_vpc.myvpc.id

ingress {
   description = "HTTPS"
   from_port   = 443
   to_port     = 443
   protocol    = "tcp"
   cidr_blocks = ["0.0.0.0/0"]
 }
ingress {
   description = "HTTP"
   from_port   = 80
   to_port     = 80
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
     from_port   = 0
     to_port     = 0
     protocol    = "-1"
     cidr_blocks = ["0.0.0.0/0"]
   }
  
    tags = {
      Name = "tfsecgrp"
    }
  }
  
  # creating network interface
  resource "aws_network_interface" "networkinterface" {
    subnet_id       = aws_subnet.pubsub.id
    security_groups = [aws_security_group.inboundtraffic.id]
  
        tags = {
         Name = "NI"
      }
  }
  
  # assigning elasticip to network interface
  resource "aws_eip" "myeip" {
    vpc      = true
    network_interface = aws_network_interface.networkinterface.id
  
    tags = {
      Name = "myEIP"
  }
  }
  # creating ec2 instance
  resource "aws_instance" "server" {
   ami = "ami-0be0a52ed3f231c12"
   instance_type = "t2.micro"
   subnet_id = aws_subnet.pubsub.id
   associate_public_ip_address = true
   key_name = "mykeypair"
  
    tags = {
      Name = "server"
   }
  }
    
