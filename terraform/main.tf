# section 1 
terraform {
  required_version = ">= 1.0.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

# section 2 Networking Infrastructure for VPC SET"

resource "aws_vpc" "vpc_network" {
  cidr_block           = "172.31.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "capstone-private-cloud-vpc"
  }
}

resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.vpc_network.id
  cidr_block              = "172.31.1.0/24"
  map_public_ip_on_launch = true
  availability_zone       = "ap-south-1a"

  tags = {
    name = "capstone-public-subnet"
  }
}

resource "aws_internet_gateway" "igw_aws" {
  vpc_id = aws_vpc.vpc_network.id

  tags = {
    Name = "capstone-gatway"
  }
}

resource "aws_route_table" "public_rt_aws_rhel" {
  vpc_id = aws_vpc.vpc_network.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw_aws.id
  }

  tags = {
    Name = "capstone-public_rt_aws_rhel"
  }
}

resource "aws_route_table_association" "public_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt_aws_rhel.id
}

# section 3 security group(internal /external ssh)
resource "aws_security_group" "aws_sg" {
  name        = "aws_sg"
  description = "managed by Terraform"
  vpc_id      = aws_vpc.vpc_network.id

  # Allow standard inbound SSH from anywhere for testing
  ingress {
    description = "External SSH management"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # Allow web traffic access for testing the Load Balancer later
  ingress {
    description = "public HTTP web Traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SELF-REFERENCING RULE: Allow all 6 internal instances to talk unblocked
  ingress {
    description = "Full Internal Cluster Communication"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  # Standard Outbound Internet Access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ansible-cluster-security-rules"
  }
}

#section 4 BARE RHEL INSTANCES PROVISIONING

# Look up the latest standard RHEL 9 x86_64 Free Tier AMI automatically
data "aws_ami" "rhel9" {
  most_recent = true
  owners      = ["309956199498"] # Official Red Hat Owner ID

  filter {
    name   = "name"
    values = ["RHEL-9.*_HVM-*-x86_64-*"]
  }
}

# Map instance identifiers to their precise professional names
variable "instance_roles" {
  type    = list(string)
  default = ["control-node", "load-balancer", "web-server-01", "web-server-02", "file-server", "database-server"]
}

resource "aws_instance" "cluster_nodes" {
  count                  = length(var.instance_roles)
  ami                    = data.aws_ami.rhel9.id
  instance_type          = "t3.micro" # Free Tier baseline node
  subnet_id              = aws_subnet.public_subnet.id
  vpc_security_group_ids = [aws_security_group.aws_sg.id]
  key_name               = "may-key"

  tags = {
    Name    = var.instance_roles[count.index]
    Project = "Ansible-RHEL-Private-Cloud"
  }
}

#section 5 output 
output "instance_ips" {
  value = {
    for idx, name in var.instance_roles : name => {
      public_ip  = aws_instance.cluster_nodes[idx].public_ip
      private_ip = aws_instance.cluster_nodes[idx].private_ip
    }
  }
  description = "Public and Private IP mappings to quickly build your Ansible inventory"
}