resource "aws_iam_role" "site_role" {
  name               = "siterole"
  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": [
		"ec2.amazonaws.com",
		"eks.amazonaws.com",
		"ecr.amazonaws.com"
		]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "site_attachment" {
  role       = aws_iam_role.site_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "site_profile" {
  name = "site_profile"
  role = aws_iam_role.site_role.name
}

data "aws_caller_identity" "current" {}

# IAM OIDC

data "tls_certificate" "site_eks_tls_cert" {
  url = aws_eks_cluster.site_eks.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "site_eks_connect_provider" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.site_eks_tls_cert.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.site_eks.identity[0].oidc[0].issuer
}

data "aws_iam_policy_document" "site_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"
    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.site_eks_connect_provider.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:default:aws-test"]
    }
    principals {
      identifiers = [aws_iam_openid_connect_provider.site_eks_connect_provider.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "site_test_oidc" {
  assume_role_policy = data.aws_iam_policy_document.site_role_policy.json
  name               = "${var.site_name}-OIDC"
}

resource "aws_iam_policy" "site_test_policy" {
  name = "${var.site_name}-Policy-Test"
  policy = jsonencode({
    Statement = [{
      Action = [
        "s3:ListAllMyBuckets",
        "s3:GetBucketLocation"
      ]
      Effect   = "Allow"
      Resource = "arn:aws:s3:::*"
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "site_test_attach" {
  role       = aws_iam_role.site_test_oidc.name
  policy_arn = aws_iam_policy.site_test_policy.arn
}