resource "aws_iam_role" "site_role" {
  name               = "siterole"
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

resource "aws_iam_role_policy_attachment" "site_attachment" {
  role       = aws_iam_role.site_role.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_instance_profile" "site_profile" {
  name = "site_profile"
  role = aws_iam_role.site_role.name
}

data "aws_caller_identity" "current" {}