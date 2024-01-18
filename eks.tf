# EKS

resource "aws_eks_cluster" "site_eks" {
  name     = "${var.site_name}-eks"
  role_arn = aws_iam_role.site_role.arn
  enabled_cluster_log_types = ["api", "audit"]
  vpc_config {
    subnet_ids = concat(aws_subnet.site_public_subnet[*].id,  aws_subnet.site_private_subnet[*].id)
	endpoint_private_access = true
    endpoint_public_access  = true
  }
  depends_on = [aws_cloudwatch_log_group.site_logs_eks, aws_route_table_association.site_public_route_table_association, aws_route_table_association.site_private_route_table_association]
}

resource "aws_eks_node_group" "site_eks_node_group" {
  cluster_name    = aws_eks_cluster.site_eks.name
  node_group_name = "${var.site_name}-eks-node-group"
  version         = aws_eks_cluster.site_eks.version
  node_role_arn   = aws_iam_role.site_role.arn
  subnet_ids      = aws_subnet.site_private_subnet[*].id
  instance_types  = ["${var.site_instance_size}"]
  ami_type = "AL2_x86_64"
  scaling_config {
    desired_size = 1
    max_size     = 2
    min_size     = 1
  }
  depends_on  = [aws_iam_role_policy_attachment.site_attachment, aws_subnet.site_private_subnet, aws_route_table_association.site_private_route_table_association]
}

# Update kubeconfig

resource "null_resource" "update_kubeconfig" {
  provisioner "local-exec" {
    command = "aws eks --region ${var.site_region} update-kubeconfig --name ${aws_eks_cluster.site_eks.name}"
  }
  
  depends_on = [aws_eks_node_group.site_eks_node_group, aws_eks_cluster.site_eks]
}

# Cloudwatch

resource "aws_cloudwatch_log_group" "site_logs_eks" {
  name              = "${var.site_name}-eks-logs"
  retention_in_days = 7
}