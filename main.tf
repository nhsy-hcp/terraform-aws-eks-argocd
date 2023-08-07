locals {
  argocd_fqdn = "argocd.${var.domain}"
  alb_fqdn = kubernetes_ingress_v1.argocd.status.0.load_balancer.0.ingress.0.hostname
}

data "aws_availability_zones" "available" {}

####
# Get management IP for control plane access
###

data "http" "management_ip" {
  url = "https://ipinfo.io/ip"

  lifecycle {
    postcondition {
      condition     = self.status_code == 200
      error_message = "Status code invalid"
    }
  }
}

locals {
  management_ip = "${chomp(data.http.management_ip.response_body)}/32"
}