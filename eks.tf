module "eks" {

  source  = "terraform-aws-modules/eks/aws"
  version = "19.16.0"

  cluster_name    = var.eks_cluster_name
  cluster_version = var.eks_k8s_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnets

  cluster_endpoint_public_access = true

  # restrict access to management ip address
  cluster_endpoint_public_access_cidrs = [local.management_ip]

  create_cluster_security_group = true
  create_node_security_group    = true

  eks_managed_node_group_defaults = {
    ami_type = "AL2_x86_64"
  }

  cluster_enabled_log_types              = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
  cloudwatch_log_group_retention_in_days = 1

  cluster_addons = {
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
    aws-ebs-csi-driver = {
      most_recent              = true
      service_account_role_arn = module.ebs_csi_irsa_role_eks.iam_role_arn
    }
  }

  # Extend node-to-node security group rules
  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
  }

  eks_managed_node_groups = {
    one = {
      name = var.eks_cluster_name

      instance_types = var.eks_node_instance_types
      capacity_type  = var.eks_node_capacity_type

      min_size     = var.eks_node_workers["min_size"]
      max_size     = var.eks_node_workers["max_size"]
      desired_size = var.eks_node_workers["desired_size"]

      key_name = var.eks_managed_node_groups_ssh_key_pair
    }
  }
}

# creates IAM role for ebs-csi-controller
module "ebs_csi_irsa_role_eks" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "5.16.0"

  role_name             = "ebs-csi-controller-role-${module.eks.cluster_name}"
  attach_ebs_csi_policy = true

  oidc_providers = {
    main = {
      provider_arn               = module.eks.oidc_provider_arn
      namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
    }
  }
}
