resource "random_string" "argocd_admin_password" {
  length  = 16
  special = false
}

module "argocd" {
  source  = "aws-ia/eks-blueprints-addons/aws"
  version = "~> 1.5"

  cluster_name      = module.eks.cluster_name
  cluster_endpoint  = module.eks.cluster_endpoint
  cluster_version   = module.eks.cluster_version
  oidc_provider_arn = module.eks.oidc_provider_arn

  enable_argocd = true

  argocd = {
    name          = "argocd"
    chart_version = var.argocd_chart_version
    set = [
      {
        name  = "configs.params.server.insecure"
        value = var.argocd_insecure == false ? false : true
      },
      {
        name  = "redis-ha.enabled"
        value = true
      },
      {
        name  = "controller.replicas"
        value = 1
      },
      {
        name  = "server.replicas"
        value = 2
      },
      {
        name  = "repoServer.replicas"
        value = 2
      },
      {
        name  = "applicationSet.replicaCount"
        value = 2
      },
      {
        name  = "dex.enabled"
        value = false
      }
    ]

    set_sensitive = [
      {
        name  = "configs.secret.argocdServerAdminPassword"
        value = bcrypt(random_string.argocd_admin_password.result)
      }
    ]
    timeout = var.argocd_timeout_seconds
    wait    = true
  }

  depends_on = [
    module.eks,
    module.eks_blueprints_addons
  ]
}

resource "kubernetes_service_v1" "argocd" {
  metadata {
    annotations = {
      "alb.ingress.kubernetes.io/backend-protocol-version" = "HTTP2"
    }
    labels = {
      app = "argocd-grpc"
    }
    name      = "argocd-grpc"
    namespace = "argocd"
  }
  spec {
    port {
      name        = "443"
      port        = 443
      protocol    = "TCP"
      target_port = 8080
    }
    selector = {
      "app.kubernetes.io/name" = "argocd-server"
    }
    session_affinity = "None"
    type             = "ClusterIP"
  }

  depends_on = [
    module.argocd
  ]
}

resource "kubernetes_ingress_v1" "argocd" {
  wait_for_load_balancer = true
  metadata {
    annotations = {
      "alb.ingress.kubernetes.io/actions.ssl-redirect"   = "{\"Type\": \"redirect\", \"RedirectConfig\": { \"Protocol\": \"HTTPS\", \"Port\": \"443\", \"StatusCode\": \"HTTP_301\"}}"
      "alb.ingress.kubernetes.io/backend-protocol"       = "HTTPS"
      "alb.ingress.kubernetes.io/certificate-arn"        = aws_acm_certificate.default.arn
      "alb.ingress.kubernetes.io/conditions.argocd-grpc" = <<-EOT
        [{"field":"http-header","httpHeaderConfig":{"httpHeaderName": "Content-Type", "values":["application/grpc"]}}]
        EOT
      "alb.ingress.kubernetes.io/group.name"             = var.shared_alb_name
      "alb.ingress.kubernetes.io/listen-ports"           = "[{\"HTTPS\":443}]"
      "alb.ingress.kubernetes.io/load-balancer-name"     = var.shared_alb_name
      "alb.ingress.kubernetes.io/scheme"                 = "internet-facing"
      "alb.ingress.kubernetes.io/target-type"            = "ip"
      "kubernetes.io/ingress.class"                      = "alb"
    }
    name      = "argocd"
    namespace = "argocd"
  }
  spec {
    rule {
      host = local.argocd_fqdn
      http {
        path {
          backend {
            service {
              name = "argocd-grpc"
              port {
                number = 443
              }
            }
          }
          path      = "/"
          path_type = "Prefix"

        }
        path {
          backend {
            service {
              name = "argocd-server"
              port {
                number = 443
              }
            }
          }
          path      = "/"
          path_type = "Prefix"
        }
      }
    }
    tls {
      hosts = [
        local.argocd_fqdn
      ]
    }
  }
  depends_on = [
    kubernetes_service_v1.argocd
  ]
}
