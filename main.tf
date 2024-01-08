variable "AWS_ACCESS_KEY_ID" {
  description = "Access-key-for-AWS"
  default = "no_access_key_value_found"
}

variable "AWS_SECRET_ACCESS_KEY" {
  description = "Secret-key-for-AWS"
  default = "no_secret_key_value_found"
}

terraform {
  backend "remote" {
    organization = "jmanwel"

    workspaces {
      name = "iac_test"
    }
  }

provider "aws" {
  region = "sa-east-1"
  access_key = var.AWS_ACCESS_KEY_ID
  secret_key = var.AWS_SECRET_ACCESS_KEY
}

resource "aws_vpc" "laboratorio" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "subnet-1" {
  cidr_block = "10.0.1.0/24"
  vpc_id = aws_vpc.laboratorio.id
  map_public_ip_on_launch = "true"
  availability_zone = "sa-east-1a"
}

resource "aws_internet_gateway" "igw" {
	vpc_id = aws_vpc.laboratorio.id
}

resource "aws_route_table" "prod-public-crt" {
  vpc_id = aws_vpc.laboratorio.id
  route {
      cidr_block = "0.0.0.0/0" 
      gateway_id = aws_internet_gateway.igw.id 
  }
}

resource "aws_route_table_association" "prod-crta-public-subnet-1"{
  subnet_id = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.prod-public-crt.id
}

resource "aws_security_group" "ssh" {
  name = "allow_ssh"
  vpc_id = aws_vpc.laboratorio.id 
  ingress {
    description = "ssh"
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_security_group" "http" {
  name = "allow_http"
  vpc_id = aws_vpc.laboratorio.id 
  ingress {
    description = "http"
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }
}

resource "aws_instance" "instance" {
  ami = "ami-0b6c2d49148000cd5"
  instance_type = "t2.micro"
  key_name = "terraform_ec2_key"
  associate_public_ip_address = true
  subnet_id = aws_subnet.subnet-1.id
  security_groups = [aws_security_group.ssh.id]
}

resource "aws_key_pair" "terraform_ec2_key" {
  key_name = "terraform_ec2_key"
  public_key = var.terraform-ec2-key
}

output "instance_ip" {
  description = "The public ip for ssh access"
  value = aws_instance.instance.public_ip
}

output "sample_server_dns" {
  value = aws_instance.instance.public_dns
}