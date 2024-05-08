terraform {
  source = "tfr:///terraform-aws-modules/eks/aws?version=20.8.5"
}

include "root" {
  path = find_in_parent_folders()
}
include "env" {
  path           = find_in_parent_folders("env.hcl")
  expose         = true
  merge_strategy = "no_merge"
}


inputs = {
  cluster_name = "${include.env.locals.eks-cluster-name}-${include.env.locals.env}"
  cluster_version = "${include.env.locals.cluster-version}"
  cluster_endpoint_public_access  = true
  subnet_ids  = dependency.vpc.outputs.private_subnets
  enable_irsa = true
  vpc_id = dependency.vpc.outputs.vpc_id
  cluster_addons = {
    aws-ebs-csi-driver = {
      most_recent = true
    }
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent = true
    }
  }
  create_cloudwatch_log_group = false
  prefix_separator = "-"
  create_kms_key = true
  attach_cluster_encryption_policy = true
  kms_key_administrators = "${include.env.locals.kms-admins}"
  node_security_group_tags = {
    "karpenter.sh/discovery" = "${include.env.locals.eks-cluster-name}-${include.env.locals.env}"
  }
  eks_managed_node_group_defaults = {
    disk_size = 20
    ami_type  = "AL2023_x86_64_STANDARD"
  }
  eks_managed_node_groups = {
    eks-node = {
      use_custom_launch_template = true
      capacity_type  = "SPOT"
      instance_types = ["t3.medium"]
      desired_size = 1
      min_size     = 1
      max_size     = 10
      labels = {
        Environment = "eks-node-${include.env.locals.env}"
      }

      iam_role_additional_policies = {
        policy = "${include.env.locals.policy}"
      }
      tags = {
        Environment = "${include.env.locals.env}"
        Terraform = "true"
        Name = "eks-node-${include.env.locals.env}"
      }
    }
  }
  enable_cluster_creator_admin_permissions = true
  authentication_mode = "API_AND_CONFIG_MAP"
  access_entries = {
    cluster-manager = {
      principal_arn     = "${include.env.locals.role}"
      policy_associations = {
        cluster-manager = {
          policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
          access_scope = {
            type = "cluster"
          }

        }

      }
    }
  }

  tags = {
    Environment = "${include.env.locals.env}"
    Terraform = "true"
  }
}



dependency "vpc" {
  config_path = "../vpc"
}
