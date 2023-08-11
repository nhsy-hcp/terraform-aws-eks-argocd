variable "domain" {
  type = string
}

variable "create" {
  type    = bool
  default = true
}

variable "dns_names" {
  type = list(string)
}

variable "namespace" {
  type = string
}

variable "tls_secret_name" {
  type    = string
  default = "tls"
}

variable "tls_secret_crt" {
  type    = string
  default = "tls.crt"
}

variable "tls_secret_key" {
  type    = string
  default = "tls.key"
}


variable "tls_ca_secret_name" {
  type    = string
  default = "tls-ca"
}

variable "tls_ca_secret_crt" {
  type    = string
  default = "ca.crt"
}

variable "organization" {
  type    = string
  default = "ACME"
}