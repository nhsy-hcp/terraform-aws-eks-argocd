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

resource "local_file" "vault_helm_values" {
  filename = "${path.root}/files/vault-values.yaml"
  content = templatefile("${path.root}/files/vault-values-template.yaml",
    {
      alb_group_name  = var.shared_alb_name
      certificate_arn = aws_acm_certificate.default.arn
      host            = local.vault_fqdn
  })
}
