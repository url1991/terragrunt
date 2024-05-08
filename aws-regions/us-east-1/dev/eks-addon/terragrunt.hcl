terraform {
    source = "tfr:///aws-ia/eks-blueprints-addons/aws?version=1.16.2"
}

include "root" {
  path = find_in_parent_folders()
}
include "env" {
  path           = find_in_parent_folders("env.hcl")
  expose         = true
  merge_strategy = "no_merge"
}

dependency "eks" {
  config_path = "../eks"
}

inputs ={
    cluster_name = dependency.eks.outputs.cluster_name
    cluster_endpoint = dependency.eks.outputs.cluster_endpoint
    cluster_version = dependency.eks.outputs.cluster_version
    oidc_provider_arn = dependency.eks.outputs.oidc_provider_arn
    enable_metrics_server                  = true
    enable_argocd = true
    argocd = {
      namespace = "tools"
      values = [
        yamlencode({
          dex ={
            enabled = false
          }
      
         })
      ]
    }
    tags = {
    Environment = include.env.locals.env
    
  }

}


# Add helm provider
generate "helm_provider" {
  path      = "helm-provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
data "aws_eks_cluster" "eks" {
  name = var.cluster_name
}

data "aws_eks_cluster_auth" "eks" {
  name = var.cluster_name
}

provider "helm" {
  kubernetes {
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    exec {
      api_version = "client.authentication.k8s.io/v1beta1"
      args        = ["eks", "get-token", "--cluster-name", data.aws_eks_cluster.eks.name]
      command     = "aws"
    }
  }
}
EOF
}