#provider "aws" {
#  region     = "us-east-1"
#  access_key = ""
#  secret_key = ""
#}
provider "aws" {
  access_key                  = "mock_access_key"
  region                      = "us-east-1"
  secret_key                  = "mock_secret_key"
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    apigateway     = "http://localhost:4566"
    cloudformation = "http://localhost:4566"
    cloudwatch     = "http://localhost:4566"
    dynamodb       = "http://localhost:4566"
    es             = "http://localhost:4566"
    firehose       = "http://localhost:4566"
    iam            = "http://localhost:4566"
    kinesis        = "http://localhost:4566"
    lambda         = "http://localhost:4566"
    route53        = "http://localhost:4566"
    redshift       = "http://localhost:4566"
    s3             = "http://localhost:4566"
    secretsmanager = "http://localhost:4566"
    ses            = "http://localhost:4566"
    sns            = "http://localhost:4566"
    sqs            = "http://localhost:4566"
    ssm            = "http://localhost:4566"
    stepfunctions  = "http://localhost:4566"
    sts            = "http://localhost:4566"
    ec2            = "http://localhost:4566"
  }
}
# Create VPC

resource "aws_vpc" "test-vpc" {
  cidr_block = var.vpc_cidr
  assign_generated_ipv6_cidr_block = false
  tags = {
    "Name" = "test-production-vpc"
  }
  
}

# Create Internet Gateway

resource "aws_internet_gateway" "test-gw" {
  vpc_id = aws_vpc.test-vpc.id
  tags = {
    "Name" = "test-production-gw"
  }
}

# Create Route Table

resource "aws_route_table" "test-rt" {
  vpc_id =  aws_vpc.test-vpc.id

  route{
    cidr_block = var.public_cidr
    gateway_id = aws_internet_gateway.test-gw.id
  } 

  tags = {
    "Name" = "test-production-rt"
  }
}

# Create Subnet
# resource "aws_subnet" "test-subnet-1" {
#   vpc_id = aws_vpc.test-vpc.id
#   cidr_block = "10.0.1.0/24"
#   availability_zone = "us-east-1a"
#   tags = {
#     "Name" = "test-production-subnet-1"
#   }
# }

# resource "aws_subnet" "test-subnet-2" {
#   vpc_id = aws_vpc.test-vpc.id
#   cidr_block = "10.0..0/24"
#   availability_zone = "us-east-1b"
#   tags = {
#     "Name" = "test-production-subnet-2"
#   }
# }
resource "aws_subnet" "test-subnets" {
  count = length(var.subnet_cidrs)
  vpc_id = aws_vpc.test-vpc.id
  cidr_block = element(var.subnet_cidrs, count.index)
  availability_zone = element(var.availability_zones, count.index)

    tags = {
    "Name" = "test-production-subnets-${count.index+1}"
  }
}
 

# Associate subnet with Route Table
resource "aws_route_table_association" "test-rt-association" {
  count = length(var.subnet_cidrs)
  subnet_id = element(aws_subnet.test-subnets.*.id, count.index)
  route_table_id = aws_route_table.test-rt.id
}

# Create Security Group to allow port 22, 80

resource "aws_security_group" "test-allow-web" {
  name = "allow_web_traffic"
  vpc_id = aws_vpc.test-vpc.id

  ingress {
    description = "HTTP"
    from_port = var.http_ingress_from_port
    to_port = var.http_ingress_to_port
    protocol = var.http_ingress_protocol
    cidr_blocks = [var.public_cidr]
  }

  ingress {
    description = "SSH"
    from_port = var.ssh_ingress_from_port
    to_port = var.ssh_ingress_to_port
    protocol = var.ssh_ingress_protocol
    cidr_blocks = [var.public_cidr]
  }

  egress {
    from_port = var.public_to_port
    to_port = var.public_to_port
    protocol = var.public_protocol
  }
  tags = {
    "GroupDescription " = "Allow Web inbound traffic"
    "Name" = "allow_web_traffic"
  }

  lifecycle {
    create_before_destroy = true
  }
  
}

# Create a network interface with subnets

resource "aws_network_interface" "test-ni" {
  count = length(var.subnet_cidrs)
  subnet_id = element(aws_subnet.test-subnets.*.id, 0)
  security_groups = [aws_security_group.test-allow-web.id]
  private_ips = var.ni_private_ips
}

# Create elastic IPs

resource "aws_eip" "one" {
  vpc                       = true
  network_interface         = aws_network_interface.test-ni[0].id
  associate_with_private_ip = var.ni_private_ips[0]
  depends_on = [aws_internet_gateway.test-gw]
}

resource "aws_eip" "two" {
  vpc                       = true
  network_interface         = aws_network_interface.test-ni[0].id
  associate_with_private_ip = var.ni_private_ips[1]
  depends_on = [aws_internet_gateway.test-gw]
}

# Finally deploy instances in the subnets using AZs reference

# Example

## resource "aws_instance" "my_server" {
##   ami           = ""
##   instance_type = "t2.micro"
##   availability_zone = "us-east-1a"
##   key_name = "main_key"
#
##   network_interface = {
##     device_index = 0
##     network_interface_id = aws_network_interface.test-ni.id
##   }
#
##   tags = {
##     "Name" = "ubuntu_instance"
##   }
