provider "aws" {
  region = "us-east-1"  # Update as needed
}

data "aws_availability_zones" "available" {}

# -------------------------------
# VPC
# -------------------------------
resource "aws_vpc" "voiceowl_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "voiceowl-vpc"
  }
}

resource "aws_subnet" "voiceowl_subnet" {
  count                   = 2
  vpc_id                  = aws_vpc.voiceowl_vpc.id
  cidr_block              = cidrsubnet(aws_vpc.voiceowl_vpc.cidr_block, 8, count.index)
  availability_zone       = data.aws_availability_zones.available.names[count.index]
  map_public_ip_on_launch = true
  tags = {
    Name = "voiceowl-subnet-${count.index}"
  }
}

resource "aws_internet_gateway" "voiceowl_igw" {
  vpc_id = aws_vpc.voiceowl_vpc.id
  tags = {
    Name = "voiceowl-igw"
  }
}

resource "aws_route_table" "voiceowl_route_table" {
  vpc_id = aws_vpc.voiceowl_vpc.id
  tags = {
    Name = "voiceowl-route-table"
  }
}

resource "aws_route" "voiceowl_route" {
  route_table_id         = aws_route_table.voiceowl_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.voiceowl_igw.id
}

resource "aws_route_table_association" "voiceowl_subnet_assoc" {
  count          = length(aws_subnet.voiceowl_subnet)
  subnet_id      = aws_subnet.voiceowl_subnet[count.index].id
  route_table_id = aws_route_table.voiceowl_route_table.id
}

# -------------------------------
# IAM Roles for Cluster
# -------------------------------
data "aws_iam_policy_document" "voiceowl_assume_role_policy" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["eks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "voiceowl_cluster_role" {
  name               = "voiceowl-cluster-role"
  assume_role_policy = data.aws_iam_policy_document.voiceowl_assume_role_policy.json
}

resource "aws_iam_role_policy_attachment" "voiceowl_cluster_policy" {
  role       = aws_iam_role.voiceowl_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "voiceowl_service_policy" {
  role       = aws_iam_role.voiceowl_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
}

# -------------------------------
# EKS Cluster
# -------------------------------
resource "aws_eks_cluster" "voiceowl_cluster" {
  name     = "voiceowl-cluster"
  role_arn = aws_iam_role.voiceowl_cluster_role.arn

  vpc_config {
    subnet_ids = aws_subnet.voiceowl_subnet[*].id
  }

  depends_on = [
    aws_iam_role_policy_attachment.voiceowl_cluster_policy,
    aws_iam_role_policy_attachment.voiceowl_service_policy,
  ]
}

# -------------------------------
# IAM Role for Node Group
# -------------------------------
data "aws_iam_policy_document" "nodegroup_assume_role_policy" {
  statement {
    effect = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]  # MUST include this
    }
  }
}

resource "aws_iam_role" "voiceowl_nodegroup_role" {
  name               = "voiceowl-nodegroup-role"
  assume_role_policy = data.aws_iam_policy_document.nodegroup_assume_role_policy.json
}

# Attach required policies
resource "aws_iam_role_policy_attachment" "node_group_worker_policy" {
  role       = aws_iam_role.voiceowl_nodegroup_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "node_group_cni_policy" {
  role       = aws_iam_role.voiceowl_nodegroup_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "node_group_ecr_read_only" {
  role       = aws_iam_role.voiceowl_nodegroup_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}


# -------------------------------
# EKS Node Group
# -------------------------------
resource "aws_eks_node_group" "voiceowl_nodegroup" {
  cluster_name    = aws_eks_cluster.voiceowl_cluster.name
  node_group_name = "voiceowl-node-group"
  node_role_arn   = aws_iam_role.voiceowl_nodegroup_role.arn
  subnet_ids      = aws_subnet.voiceowl_subnet[*].id

  scaling_config {
    desired_size = 2
    max_size     = 3
    min_size     = 1
  }

  instance_types = ["t3.medium"]

  depends_on = [
    aws_eks_cluster.voiceowl_cluster,
  ]
}
