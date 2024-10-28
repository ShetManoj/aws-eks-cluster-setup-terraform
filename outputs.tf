output "cluster_id" {
  value = aws_eks_cluster.manoj.id
}

output "node_group_id" {
  value = aws_eks_node_group.manoj.id
}

output "vpc_id" {
  value = aws_vpc.manoj_vpc.id
}

output "subnet_ids" {
  value = aws_subnet.manoj_subnet[*].id
}
