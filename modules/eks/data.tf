data "aws_vpc" "eks" {
  id = "${module.vpc.vpc_id}"
}

data "aws_subnet_ids" "private" {
  vpc_id = data.aws_vpc.eks.id

  tags = {
    Name = "${var.cluster-name}-eks-private"
  }
}

data "aws_subnet_ids" "public" {
  vpc_id = data.aws_vpc.eks.id

  tags = {
    Name = "${var.cluster-name}-eks-public"
  }
}

data "aws_security_group" "cluster" {
  vpc_id = data.aws_vpc.eks.id
  name   = "${module.cluster-sg.this_security_group_name}"
}

data "aws_security_group" "node" {
  vpc_id = data.aws_vpc.eks.id
  name   = "${module.node-sg.this_security_group_name}"
}

data "aws_security_group" "bastion" {
  vpc_id = data.aws_vpc.eks.id
  name   = "${module.ssh_sg.this_security_group_name}"
}

data "aws_ami" "bastion" {
  most_recent = true
  owners      = ["137112412989"]

  filter {
    name = "name"

    values = [
      "amzn2-ami-hvm-*-x86_64-gp2",
    ]
  }
}


data "aws_ami" "eks-worker-ami" {
  filter {
    name   = "name"
    values = ["amazon-eks-node-${var.k8s-version}-*"]
  }

  most_recent = true
  owners      = ["602401143452"] # Amazon
}

locals {
  # Common tags to be assigned to all resources
  common_tags = {
    Environment = "DEV"
    Name    = "EKS Test"
    Owner   = "snigdha.sambit.ak@outlook.com"
    Project = "EKS"
    Team    = "Awesome EKS"
    app_id  = "1000"
  }
}
