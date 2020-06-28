### VPC

# use terraform cloud remote backend

terraform {
  backend "remote" {
    organization = "tf-cloud-org"
    workspaces {
      name = "workspace"
    }
  }
}


module "eks" {
  source  = "../modules/eks"

  aws-region          = "us-east-1"
  availability-zones  = ["us-east-1a", "us-east-1b", "us-east-1c"]
  cluster-name        = "my-cluster"
  k8s-version         = "1.13"
  node-instance-type  = "t3.medium"
  desired-capacity    = "3"
  max-size            = "5"
  min-size            = "1"
  vpc-subnet-cidr     = "10.1.2.3/16"
  private-subnet-cidr = ["10.1.2.3/19", "10.1.32.0/19", "10.1.64.0/19"]
  public-subnet-cidr  = ["10.1.128.0/20", "10.1.144.0/20", "10.1.160.0/20"]
  db-subnet-cidr      = ["10.1.192.0/21", "10.1.200.0/21", "10.1.208.0/21"]
  eks-cw-logging      = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  ec2-key             = "my-key"
}

output "kubeconfig" {
  value = module.eks.kubeconfig
}

output "config-map" {
  value = module.eks.config-map
}
