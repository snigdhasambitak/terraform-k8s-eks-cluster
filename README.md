# terraform-eks-cluster

Deploy a full managed AWS EKS cluster with Terraform

## What resources are created

1. VPC
2. Internet Gateway (IGW)
3. Public and Private Subnets
4. Security Groups, Route Tables and Route Table Associations
5. IAM roles, instance profiles and policies
6. An EKS Cluster
7. Autoscaling group and Launch Configuration
8. Worker Nodes in a private Subnet
9. bastion host for ssh access to the VPC
10. The ConfigMap required to register Nodes with EKS
11. KUBECONFIG file to authenticate kubectl using the `aws eks get-token` command. needs awscli version `1.16.156 >`

## Configuration

You can configure you config with the following input variables:

| Name                      | Description                        | Default                                                               |
| ------------------------- | ---------------------------------- | --------------------------------------------------------------------- |
| `cluster-name`            | The name of your EKS Cluster       | `eks-cluster`                                                         |
| `aws-region`              | The AWS Region to deploy EKS       | `us-east-1`                                                           |
| `availability-zones`      | AWS Availability Zones             | `["us-east-1a", "us-east-1b", "us-east-1c"]`                          |
| `k8s-version`             | The desired K8s version to launch  | `1.13`                                                                |
| `node-instance-type`      | Worker Node EC2 instance type      | `m4.large`                                                            |
| `root-block-size`         | Size of the root EBS block device  | `20`                                                                  |
| `desired-capacity`        | Autoscaling Desired node capacity  | `2`                                                                   |
| `max-size`                | Autoscaling Maximum node capacity  | `5`                                                                   |
| `min-size`                | Autoscaling Minimum node capacity  | `1`                                                                   |
| `public-min-size`         | Public Node groups ASG capacity    | `1`                                                                     |
| `public-max-size`         | Public Node groups ASG capacity    | `1`                                                                     |
| `public-desired-capacity` | Public Node groups ASG capacity    | `1`                                                                     |
| `vpc-subnet-cidr`         | Subnet CIDR                        | `10.1.2.3/16`                                                         |
| `private-subnet-cidr`     | Private Subnet CIDR                | `["10.1.2.3/19", "10.1.32.0/19", "10.1.64.0/19"]`                     |
| `public-subnet-cidr`      | Public Subnet CIDR                 | `["10.1.128.0/20", "10.1.144.0/20", "10.1.160.0/20"]`                 |
| `db-subnet-cidr`          | DB/Spare Subnet CIDR               | `["10.1.192.0/21", "10.1.200.0/21", "10.1.208.0/21"]`                 |
| `eks-cw-logging`          | EKS Logging Components             | `["api", "audit", "authenticator", "controllerManager", "scheduler"]` |
| `ec2-key`                 | EC2 Key Pair for bastion and nodes | `my-key`                                                              |

> You can create a file called terraform.tfvars or copy [variables.tf] into the project root, if you would like to over-ride the defaults.

## How to use this example

```bash
git clone https://github.com/snigdhasambitak/terraform-k8s-eks-cluster
cd terraform-k8s-eks-cluster
```

## Remote Module

> **NOTE** use `version = "2.0.0"` with terraform `0.12.x >` and `version = 1.0.4` with terraform `< 0.11x`

You can use this module as a remote source:

```terraform
module "eks" {
  source  = "/modules/eks"

  aws-region          = "us-east-1"
  availability-zones  = ["us-east-1a", "us-east-1b", "us-east-1c"]
  cluster-name        = "my-cluster"
  k8s-version         = "1.13"
  node-instance-type  = "t3.medium"
  root-block-size     = "40"
  desired-capacity    = "3"
  max-size            = "5"
  min-size            = "1"
  public-min-size     = "0" # setting to 0 will create the launch config etc, but no nodes will deploy"
  public-max-size     = "0"
  public-desired-capacity = "0"
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

```

### IAM

The AWS credentials must be associated with a user having at least the following AWS managed IAM policies

* IAMFullAccess
* AutoScalingFullAccess
* AmazonEKSClusterPolicy
* AmazonEKSWorkerNodePolicy
* AmazonVPCFullAccess
* AmazonEKSServicePolicy
* AmazonEKS_CNI_Policy
* AmazonEC2FullAccess

In addition, you will need to create the following managed policies

*EKS*

```json
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "eks:*"
            ],
            "Resource": "*"
        }
    ]
}
```


# Create a EKS cluster in AWS

Step 1: Create the modules for the creation of the eks cluster(eks-demo), master nodes, VPC and providers. Everything can be found in the root directory. the modules path is : "modules/eks/"

Step 2: Initialize the Terraform state:

$ terraform init

Step 3: Plan the Deployment

$ terraform plan -out EKS-cluster-tf

Step 4: We can apply the plan now

$ terraform apply "EKS-cluster-tf"

Step 5: Create the KubeConfig file and save it, that will be used to manage the cluster.

$ terraform output kubeconfig

$ terraform output kubeconfig > ${HOME}/.kube/config-EKS-cluster-tf

Step 6: Add this new config to the KubeCtl Config list.

$ export KUBECONFIG=${HOME}/.kube/config-EKS-cluster-tf:${HOME}/.kube/config $ echo "export KUBECONFIG=${KUBECONFIG}" >> ${HOME}/.bashrc

### Authorize worker nodes

Get the config from terraform output, and save it to a yaml file:

```bash
terraform output config-map > config-map-aws-auth.yaml
```

Configure aws cli with a user account having appropriate access and apply the config map to EKS cluster:

```bash
kubectl apply -f config-map-aws-auth.yaml
```

You can verify the worker nodes are joining the cluster

```bash
kubectl get nodes --watch
```

### Authorize users to access the cluster

Initially, only the system that deployed the cluster will be able to access the cluster. To authorize other users for accessing the cluster, `aws-auth` config needs to be modified by using the steps given below:

* Open the aws-auth file in the edit mode on the machine that has been used to deploy EKS cluster:

```bash
sudo kubectl edit -n kube-system configmap/aws-auth
```

* Add the following configuration in that file by changing the placeholders:


```yaml

mapUsers: |
  - userarn: arn:aws:iam::111122223333:user/<username>
    username: <username>
    groups:
      - system:masters
```

So, the final configuration would look like this:

```yaml
apiVersion: v1
data:
  mapRoles: |
    - rolearn: arn:aws:iam::555555555555:role/devel-worker-nodes-NodeInstanceRole-74RF4UBDUKL6
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
  mapUsers: |
    - userarn: arn:aws:iam::111122223333:user/<username>
      username: <username>
      groups:
        - system:masters
```

* Once the user map is added in the configuration we need to create cluster role binding for that user:

```bash
kubectl create clusterrolebinding ops-user-cluster-admin-binding-<username> --clusterrole=cluster-admin --user=<username>
```
Replace the placeholder with proper values

### Cleaning up

You can destroy this cluster entirely by running:

```bash
terraform plan -destroy
terraform destroy  --force
```
