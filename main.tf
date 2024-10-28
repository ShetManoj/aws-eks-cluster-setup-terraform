resource "aws_vpc" "manoj_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "manoj_subnet" {
  count = 2
  vpc_id = aws_vpc.manoj_vpc.id
  cidr_block = cidrsubnet(aws_vpc.manoj_vpc.cidr_block, 8, count.index)
  availability_zone = element(["us-east-1a", "us-east-1b"], count.index)
  map_public_ip_on_launch = true
}

resource "aws_internet_gateway" "manoj_internet_gateway" {
  vpc_id = aws_vpc.manoj_vpc.id
}

resource "aws_route_table" "manoj_route_table" {
  vpc_id = aws_vpc.manoj_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.manoj_internet_gateway.id
  }
}

resource "aws_route_table_association" "manoj_route_table_association" {
  count = 2
  subnet_id = aws_subnet.manoj_subnet[count.index].id
  route_table_id = aws_route_table.manoj_route_table.id
}

resource "aws_security_group" "manoj_cluster_secutriy_group" {
  vpc_id = aws_vpc.manoj_vpc.id

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
}

resource "aws_security_group" "manoj_node_security_group" {
  vpc_id = aws_vpc.manoj_vpc.id

  ingress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
}

resource "aws_eks_cluster" "manoj" {
  name = "manoj-cluster"
  role_arn = aws_iam_role.manoj_cluster_role.arn 

  vpc_config {
    subnet_ids = aws_subnet.manoj_subnet[ * ].id
    security_group_ids = [ aws_security_group.manoj_cluster_secutriy_group.id ]
  }
}

resource "aws_eks_node_group" "manoj" {
  cluster_name = aws_eks_cluster.manoj.name
  node_group_name = "manoj-node-group"
  node_role_arn = aws_iam_role.manoj_node_group_role.arn
  subnet_ids = aws_subnet.manoj_subnet[ * ].id

  scaling_config {
    desired_size = 3
    max_size = 3
    min_size = 3
  }

  instance_types = [ "t2.medium" ]

  remote_access {
    ec2_ssh_key = var.ssh_key_name
    source_security_group_ids = [ aws_security_group.manoj_node_security_group.id ]
  }
}

resource "aws_iam_role" "manoj_cluster_role" {
  name = "manoj-cluster-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "manoj_cluster_role_policy" {
  role = aws_iam_role.manoj_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role" "manoj_node_group_role" {
  name = "manoj-node-group-role"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF

}

resource "aws_iam_role_policy_attachment" "manoj_node_group_role_policy" {
  role = aws_iam_role.manoj_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}

resource "aws_iam_role_policy_attachment" "manoj_node_group_cni_policy" {
  role = aws_iam_role.manoj_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}

resource "aws_iam_role_policy_attachment" "manoj_node_group_registry_policy" {
  role = aws_iam_role.manoj_node_group_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}