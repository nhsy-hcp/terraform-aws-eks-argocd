#------ general -----

output "region" {
  description = "AWS region"
  value       = var.region
}

output "eks_cluster_name" {
  description = "EKS cluster name"
  value       = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
  description = "EKS cluster EKS endpoint"
  value       = module.eks.cluster_endpoint
}

output "eks_cluster_security_group_id_eks_cluster" {
  description = "EKS cluster control plane SG"
  value       = module.eks.cluster_security_group_id
}

output "eks_node_security_group_id_cluster" {
  description = "EKS cluster nodes SG"
  value       = module.eks.node_security_group_id
}

output "ebs_csi_irsa_role_eks_iam_role_arn" {
  description = "ebs_csi_controller_role_eks_admin_cluster"
  value       = module.ebs_csi_irsa_role_eks.iam_role_arn
}

output "eks_cluster_kube_context" {
  value = "arn:aws:eks:${var.region}:${var.aws_account_id}:cluster/${var.eks_cluster_name}"
}

output "argocd_fqdn" {
  value = local.argocd_fqdn
}

output "argocd_url" {
  value = "https://${local.argocd_fqdn}"
}

output "argocd_admin_password" {
  value = random_string.argocd_admin_password.result
}

output "acm_certificate_arn" {
  value = aws_acm_certificate.default.arn
}

output "shared_alb_hostname" {
  value = local.shared_alb_hostname
}

output "echoserver_url" {
  value = "https://${local.echoserver_fqdn}"
}

output "consul_url" {
  value = "https://${local.consul_fqdn}"
}

output "vault_url" {
  value = "https://${local.vault_fqdn}"
}

output "waypoint_url" {
  value = "https://${local.waypoint_fqdn}"
}
