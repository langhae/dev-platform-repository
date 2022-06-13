################################################################################
# create_eks_role_policy
################################################################################

resource "aws_iam_role" "eks" {
  name = "${local.cluster_name}-iam-role"

  assume_role_policy = <<POLICY
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
POLICY
}

resource "aws_iam_role_policy_attachment" "eks_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.eks.name
}

# Optionally, enable Security Groups for Pods
# Reference: https://docs.aws.amazon.com/eks/latest/userguide/security-groups-for-pods.html
resource "aws_iam_role_policy_attachment" "eks_AmazonEKSVPCResourceController" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
  role       = aws_iam_role.eks.name
}

################################################################################
# IAM Role for node_groups
################################################################################

resource "aws_iam_role" "node" {
  name = "${local.cluster_name}-node-groups-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_policy" "externalDNS" {
  name        = "${local.cluster_name}-external-DNS-policy"
  description = "My custom external DNS policy"

  policy = file("${path.module}/policy/externalDNS.json")
}

resource "aws_iam_role_policy_attachment" "node_externalDNSPolicy" {
  policy_arn = aws_iam_policy.externalDNS.arn
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonSSMManagedInstanceCore" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_AmazonEC2ContainerRegistryPowerUser" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPowerUser"
  role       = aws_iam_role.node.name
}

resource "aws_iam_role_policy_attachment" "node_CloudWatchAgentServerPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.node.name
}

################################################################################
# IAM Role for Bastion host
################################################################################

resource "aws_iam_instance_profile" "bastion_profile" {
  name = "${local.cluster_name}-bastion-host-profile"
  role = aws_iam_role.bastion.name
}

resource "aws_iam_role" "bastion" {
  name = "${local.cluster_name}-bastion-host-iam-role"

  assume_role_policy = <<POLICY
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
POLICY
}

################################################################################
# IAM Role for cloudwatch-agent
################################################################################

# data "aws_iam_policy_document" "cloudwatch_agent_policy" {
#   statement {
#     actions = ["sts:AssumeRoleWithWebIdentity"]
#     effect  = "Allow"

#     condition {
#       test     = "StringEquals"
#       variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
#       values   = ["system:serviceaccount:amazon-cloudwatch:cloudwatch-agent"]
#     }

#     principals {
#       identifiers = [aws_iam_openid_connect_provider.eks.arn]
#       type        = "Federated"
#     }
#   }
# }

# resource "aws_iam_role" "cloudwatch_agent" {
#   assume_role_policy = data.aws_iam_policy_document.cloudwatch_agent_policy.json
#   name               = "${local.name}-cloudwatch-agent-role"
# }


# resource "aws_iam_role_policy_attachment" "cloudwatch_agent_CloudWatchAgentServerPolicy" {
#   policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
#   role       = aws_iam_role.cloudwatch_agent.name
# }

################################################################################
# IAM Role for fluent-bit
################################################################################

# data "aws_iam_policy_document" "fluent_bit_policy" {
#   statement {
#     actions = ["sts:AssumeRoleWithWebIdentity"]
#     effect  = "Allow"

#     condition {
#       test     = "StringEquals"
#       variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
#       values   = ["system:serviceaccount:amazon-cloudwatch:fluent-bit"]
#     }

#     principals {
#       identifiers = [aws_iam_openid_connect_provider.eks.arn]
#       type        = "Federated"
#     }
#   }
# }

# resource "aws_iam_role" "fluent_bit" {
#   assume_role_policy = data.aws_iam_policy_document.fluent_bit_policy.json
#   name               = "${local.name}-fluent-bit-role"
# }


# resource "aws_iam_role_policy_attachment" "fluent_bit_CloudWatchAgentServerPolicy" {
#   policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
#   role       = aws_iam_role.fluent_bit.name
# }



################################################################################
# IAM Role for XRay Trace
################################################################################

# data "aws_iam_policy_document" "xray_daemon" {
#   statement {
#     actions = ["sts:AssumeRoleWithWebIdentity"]
#     effect  = "Allow"

#     condition {
#       test     = "StringEquals"
#       variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
#       values   = ["system:serviceaccount:default:xray-daemon"]
#     }

#     principals {
#       identifiers = [aws_iam_openid_connect_provider.eks.arn]
#       type        = "Federated"
#     }
#   }
# }

# resource "aws_iam_role" "xray_daemon" {
#   assume_role_policy = data.aws_iam_policy_document.xray_daemon.json
#   name               = "${local.name}-xray-daemon-role"
# }


# resource "aws_iam_role_policy_attachment" "xray_daemon_AWSXRayDaemonWriteAccess" {
#   policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
#   role       = aws_iam_role.xray_daemon.name
# }
