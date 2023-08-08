#module "alb_role_eks" {
#  source                                 = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
#  role_name                              = "lb_role_${module.eks.cluster_name}"
#  attach_load_balancer_controller_policy = true
#
#  oidc_providers = {
#    main = {
#      provider_arn               = module.eks.oidc_provider_arn
#      namespace_service_accounts = ["kube-system:aws-load-balancer-controller"]
#    }
#  }
#}
#
#resource "kubernetes_service_account" "alb" {
#  metadata {
#    name      = "aws-load-balancer-controller"
#    namespace = "kube-system"
#    labels = {
#      "app.kubernetes.io/name"      = "aws-load-balancer-controller"
#      "app.kubernetes.io/component" = "controller"
#    }
#    annotations = {
#      "eks.amazonaws.com/role-arn"               = module.alb_role_eks.iam_role_arn
#      "eks.amazonaws.com/sts-regional-endpoints" = "true"
#    }
#  }
#}
#
#resource "helm_release" "alb" {
#  name       = "aws-load-balancer-controller"
#  repository = "https://aws.github.io/eks-charts"
#  chart      = "aws-load-balancer-controller"
#  namespace  = "kube-system"
#
#  depends_on = [
#    module.eks.cluster_endpoint
#  ]
#
#  set {
#    name  = "region"
#    value = var.region
#  }
#
#  set {
#    name  = "vpcId"
#    value = module.vpc.vpc_id
#  }
#
#  set {
#    name  = "serviceAccount.create"
#    value = "false"
#  }
#
#  set {
#    name  = "serviceAccount.name"
#    value = "aws-load-balancer-controller"
#  }
#
#  set {
#    name  = "clusterName"
#    value = module.eks.cluster_name
#  }
#}
