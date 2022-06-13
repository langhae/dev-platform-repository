output "aws-availability-zone" {
  value = data.aws_availability_zones.available
}

output "aws_eks_cluster_name" {
  value = aws_eks_cluster.this.name
}

output "aws_region_name" {
  value = local.region
}

output "provisioner_instance" {
  value = {
    public_ip   = aws_instance.provisioner.public_ip
    public_dns  = aws_instance.provisioner.public_dns
    private_ip  = aws_instance.provisioner.private_ip
    private_dns = aws_instance.provisioner.private_dns
  }
}

output "aws_ami_version" {
  value = data.aws_ami.eks_default
}

output "aws_ingress_controller_iam_role" {
  value = aws_iam_role.ingress_controller
}

output "aws_cluster_autoscaler_iam_role" {
  value = aws_iam_role.cluster_autoscaler
}

output "aws_ebs_csi_iam_role" {
  value = aws_iam_role.ebs_csi
}

output "aws_efs_csi_iam_role" {
  value = aws_iam_role.efs_csi
}

output "aws_prometheus_iam_role" {
  value = aws_iam_role.cwagent_prometheus
}

output "aws_my_s3_iam_roe" {
  value = aws_iam_role.my_s3
}
