variable "aws_acm_certificate_arn" {
  type = string
}

variable "fqdn" {
  type = string
}

variable "alb_name" {
  type = string
}

variable "create" {
  type    = bool
  default = true
}