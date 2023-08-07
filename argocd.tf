resource "random_string" "argocd_admin_password" {
  length  = 16
  special = false
}

resource "helm_release" "argocd" {
  namespace        = var.argocd_namespace
  create_namespace = true
  name             = var.argocd_release_name
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  version          = var.argocd_chart_version

  timeout = var.argocd_timeout_seconds

  set_sensitive {
    name  = "configs.secret.argocdServerAdminPassword"
    value = var.argocd_admin_password == "" ? "" : bcrypt(random_string.argocd_admin_password.result)
  }

  set {
    name  = "configs.params.server.insecure"
    value = var.argocd_insecure == false ? false : true
  }
  set {
    name  = "redis-ha.enabled"
    value = true
  }
  set {
    name  = "controller.replicas"
    value = 1
  }
  set {
    name  = "server.autoscaling.enabled"
    value = true
  }
  set {
    name  = "server.autoscaling.minReplicas"
    value = 2
  }
  set {
    name  = "repoServer.autoscaling.enabled"
    value = true
  }
  set {
    name  = "repoServer.autoscaling.minReplicas"
    value = 2
  }
  set {
    name  = "applicationSet.replicaCount"
    value = 2
  }
  set {
    name  = "dex.enabled"
    value = false
  }

  lifecycle {
    ignore_changes = [
      set_sensitive
    ]
  }

  depends_on = [
    helm_release.alb
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
    helm_release.argocd
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
      "alb.ingress.kubernetes.io/listen-ports"           = "[{\"HTTPS\":443}]"
      "alb.ingress.kubernetes.io/load-balancer-name"     = "eks"
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
