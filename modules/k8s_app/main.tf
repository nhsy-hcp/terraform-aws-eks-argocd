resource "tls_private_key" "default" {
  count = var.create ? 1 : 0

  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "tls_self_signed_cert" "vault" {
  count = var.create ? 1 : 0

  private_key_pem = tls_private_key.default[0].private_key_pem

  dns_names = var.dns_names

  subject {
    common_name  = var.domain
    organization = var.organization
  }

  validity_period_hours = 24 * 365

  allowed_uses = [
    "key_encipherment",
    "digital_signature",
    "server_auth",
  ]
}

resource "kubernetes_namespace_v1" "default" {
  count = var.create ? 1 : 0

  metadata {
    name = var.namespace
  }
}

resource "kubernetes_secret_v1" "tls" {
  count = var.create ? 1 : 0

  metadata {
    name      = var.tls_secret_name
    namespace = kubernetes_namespace_v1.default[0].metadata.0.name
  }
  data = {
    (var.tls_secret_crt) = tls_self_signed_cert.vault[0].cert_pem
    (var.tls_secret_key) = tls_self_signed_cert.vault[0].private_key_pem
  }
  type = "kubernetes.io/tls"
}

resource "kubernetes_secret_v1" "tls_ca" {
  count = var.create ? 1 : 0

  metadata {
    name      = var.tls_ca_secret_name
    namespace = kubernetes_namespace_v1.default[0].metadata.0.name
  }
  data = {
    (var.tls_ca_secret_crt) = tls_self_signed_cert.vault[0].cert_pem
  }
}
