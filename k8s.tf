module "echoserver" {
  source = "./modules/echoserver"

  alb_name                = var.shared_alb_name
  aws_acm_certificate_arn = aws_acm_certificate.default.arn
  fqdn                    = local.echoserver_fqdn

  depends_on = [
    module.argocd,
    module.eks_blueprints_addons
  ]
}

module "vault" {
  source = "./modules/k8s_app"

  dns_names = [
    "*.vault-internal",
  ]
  domain    = "vault-internal"
  namespace = "vault"

  depends_on = [
    module.eks_blueprints_addons
  ]
}

resource "local_file" "consul_argocd_application" {
  filename = "${path.root}/argocd/consul/consul-application.yaml"
  content = templatefile("${path.root}/templates/consul-application-template.yaml",
    {
      alb_group_name  = var.shared_alb_name
      certificate_arn = aws_acm_certificate.default.arn
      host            = local.consul_fqdn
  })
}

resource "local_file" "vault_argocd_application" {
  filename = "${path.root}/argocd/vault/vault-application.yaml"
  content = templatefile("${path.root}/templates/vault-application-template.yaml",
    {
      alb_group_name  = var.shared_alb_name
      certificate_arn = aws_acm_certificate.default.arn
      host            = local.vault_fqdn
  })
}

resource "local_file" "waypoint_argocd_application" {
  filename = "${path.root}/argocd/waypoint/waypoint-application.yaml"
  content = templatefile("${path.root}/templates/waypoint-application-template.yaml",
    {
      alb_group_name  = var.shared_alb_name
      certificate_arn = aws_acm_certificate.default.arn
      host            = local.waypoint_fqdn
  })
}

resource "local_file" "waypoint_grpc_ingress" {
  filename = "${path.root}/argocd/waypoint/waypoint-ingress.yaml"
  content = templatefile("${path.root}/templates/waypoint-ingress-template.yaml",
    {
      alb_group_name  = var.shared_alb_name
      certificate_arn = aws_acm_certificate.default.arn
      host            = local.waypoint_fqdn
  })
}