################################################################################
# IAM Role for EKS Addon "vpc-cni" with AWS managed policy
################################################################################

data "tls_certificate" "eks" {
  url = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.this.identity[0].oidc[0].issuer
}

data "aws_iam_policy_document" "eks_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-node"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "cni" {
  assume_role_policy = data.aws_iam_policy_document.eks_assume_role_policy.json
  name               = "${local.cluster_name}-vpc-cni-role"
}

resource "aws_iam_role_policy_attachment" "eks" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.cni.name
}

################################################################################
# IAM Role for Ingress controller
################################################################################

data "aws_iam_policy_document" "ingress_controller_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_policy" "ingress_controller_policy" {
  name        = "${local.cluster_name}-ingress-controller-policy"
  description = "My custom ingress controller policy"

  policy = file("${path.module}/policy/ingress_iam_policy.json")
}

resource "aws_iam_role" "ingress_controller" {
  assume_role_policy = data.aws_iam_policy_document.ingress_controller_assume_role_policy.json
  name               = "${local.cluster_name}-ingress-controller-role"
}

resource "aws_iam_role_policy_attachment" "ingress_controller" {
  policy_arn = aws_iam_policy.ingress_controller_policy.arn
  role       = aws_iam_role.ingress_controller.name
}

################################################################################
# IAM Role for Autuscaling
################################################################################

data "aws_iam_policy_document" "autoscaling_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:cluster-autoscaler"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_policy" "cluster_autoscaler_policy" {
  name        = "${local.cluster_name}-autoscaler-policy"
  description = "My custom cluster autoscaler policy"

  policy = file("${path.module}/policy/cluster-autoscaler-policy.json")
}

resource "aws_iam_role" "cluster_autoscaler" {
  assume_role_policy = data.aws_iam_policy_document.autoscaling_assume_role_policy.json
  name               = "${local.cluster_name}-autoscaler-role"
}

resource "aws_iam_role_policy_attachment" "cluster_autoscaler" {
  policy_arn = aws_iam_policy.cluster_autoscaler_policy.arn
  role       = aws_iam_role.cluster_autoscaler.name
}

################################################################################
# IAM Role for EBS CSI Driver
################################################################################

data "aws_iam_policy_document" "ebs_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:ebs-csi-controller-sa"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_policy" "ebs_csi_policy" {
  name        = "${local.cluster_name}-ebs-csi-policy"
  description = "My custom ebs csi policy"

  policy = file("${path.module}/policy/ebs-csi-iam-policy.json")
}

resource "aws_iam_role" "ebs_csi" {
  assume_role_policy = data.aws_iam_policy_document.ebs_assume_role_policy.json
  name               = "${local.cluster_name}-ebs-csi-role"
}

resource "aws_iam_role_policy_attachment" "ebs_csi" {
  policy_arn = aws_iam_policy.ebs_csi_policy.arn
  role       = aws_iam_role.ebs_csi.name
}


################################################################################
# IAM Role for EFS CSI Driver
################################################################################

data "aws_iam_policy_document" "efs_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:efs-csi-controller-sa"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_policy" "efs_csi_policy" {
  name        = "${local.cluster_name}-efs-csi-policy"
  description = "My custom efs csi policy"

  policy = file("${path.module}/policy/ebs-csi-iam-policy.json")
}

resource "aws_iam_role" "efs_csi" {
  assume_role_policy = data.aws_iam_policy_document.efs_assume_role_policy.json
  name               = "${local.cluster_name}-efs-csi-role"
}

resource "aws_iam_role_policy_attachment" "efs_csi" {
  policy_arn = aws_iam_policy.efs_csi_policy.arn
  role       = aws_iam_role.efs_csi.name
}

################################################################################
# IAM Role for prometheus
################################################################################

data "aws_iam_policy_document" "cwagent_prometheus_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:amazon-cloudwatch:cwagent-prometheus"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "cwagent_prometheus" {
  assume_role_policy = data.aws_iam_policy_document.cwagent_prometheus_policy.json
  name               = "${local.cluster_name}-cwagent-prometheus-role"
}


resource "aws_iam_role_policy_attachment" "cwagent_prometheus_CloudWatchAgentServerPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
  role       = aws_iam_role.cwagent_prometheus.name
}

################################################################################
# IAM Role for S3
################################################################################

data "aws_iam_policy_document" "my_s3_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.eks.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:dev:s3-get-object"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.eks.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_policy" "my_s3_policy" {
  name        = "${local.cluster_name}-my-s3-policy"
  description = "My custom my s3 policy"

  policy = file("${path.module}/policy/my-s3-bucket.json")
}

resource "aws_iam_role" "my_s3" {
  assume_role_policy = data.aws_iam_policy_document.my_s3_assume_role_policy.json
  name               = "${local.cluster_name}-my-s3-role"
}

resource "aws_iam_role_policy_attachment" "my_s3" {
  policy_arn = aws_iam_policy.my_s3_policy.arn
  role       = aws_iam_role.my_s3.name
}