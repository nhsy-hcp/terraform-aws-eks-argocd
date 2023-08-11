resource "kubernetes_deployment_v1" "echoserver" {
  count = var.create ? 1 : 0

  metadata {
    name      = "echoserver"
    namespace = "default"
  }
  spec {
    replicas = 1
    selector {
      match_labels = {
        "app.kubernetes.io/name" = "echoserver"
      }
    }
    template {
      metadata {
        labels = {
          "app.kubernetes.io/name" = "echoserver"
        }
      }
      spec {
        container {
          image             = "gcr.io/google-containers/echoserver:1.10"
          name              = "echoserver"
          image_pull_policy = "IfNotPresent"
          port {
            container_port = 8080
          }
          liveness_probe {
            http_get {
              path = "/"
              port = 8080
            }
            initial_delay_seconds = 3
            period_seconds        = 3
          }
        }
      }
    }
  }
}

resource "kubernetes_service_v1" "echoserver" {
  count = var.create ? 1 : 0

  metadata {
    labels = {
      "app.kubernetes.io/name" = "echoserver"
    }
    name      = "echoserver"
    namespace = "default"
  }
  spec {
    port {
      name        = "http"
      port        = 80
      protocol    = "TCP"
      target_port = 8080
    }
    selector = {
      "app.kubernetes.io/name" = "echoserver"
    }
    session_affinity = "None"
    type             = "ClusterIP"
  }

  depends_on = [
    kubernetes_deployment_v1.echoserver[0]
  ]
}

resource "kubernetes_ingress_v1" "echoserver" {
  count = var.create ? 1 : 0

  wait_for_load_balancer = true
  metadata {
    annotations = {
      "alb.ingress.kubernetes.io/backend-protocol"   = "HTTP"
      "alb.ingress.kubernetes.io/certificate-arn"    = var.aws_acm_certificate_arn
      "alb.ingress.kubernetes.io/group.name"         = var.alb_name
      "alb.ingress.kubernetes.io/listen-ports"       = "[{\"HTTPS\":443}]"
      "alb.ingress.kubernetes.io/load-balancer-name" = var.alb_name
      "alb.ingress.kubernetes.io/target-type"        = "ip"
      "alb.ingress.kubernetes.io/scheme"             = "internet-facing"
      "kubernetes.io/ingress.class"                  = "alb"
    }
    name      = "echoserver"
    namespace = "default"
  }
  spec {
    rule {
      host = var.fqdn
      http {
        path {
          backend {
            service {
              name = "echoserver"
              port {
                number = 80
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
        var.fqdn
      ]
    }
  }
  depends_on = [
    kubernetes_service_v1.echoserver[0]
  ]
}
