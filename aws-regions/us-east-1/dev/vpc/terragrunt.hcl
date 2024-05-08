terraform {
  source = "tfr:///terraform-aws-modules/vpc/aws?version=5.8.1"
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
  name = "${include.env.locals.env}-vpc"
  cidr = "10.0.0.0/16"
  azs = ["${include.env.locals.region}a", "${include.env.locals.region}b"]
  private_subnets = include.env.locals.private_subnets
  private_subnet_tags = {
    Name = "${include.env.locals.env}-private_subnet"
    "kubernetes.io/role/internal-elb" = "1"
    "kubernetes.io/cluster/lc-${include.env.locals.env}" = "1"
    "kubernetes.io/cluster/lc-${include.env.locals.env}" = "owned"
  }
  public_subnets = ["10.0.64.0/19", "10.0.96.0/19"]
  public_subnet_tags = {
    Name = "${include.env.locals.env}-public_subnet"
    "kubernetes.io/role/elb" = "1"
    "kubernetes.io/cluster/lc-${include.env.locals.env}" = "1"
    "kubernetes.io/cluster/lc-${include.env.locals.env}" = "owned"
    "karpenter.sh/discovery" = "${include.env.locals.env}"
  }
  enable_nat_gateway = true
  single_nat_gateway = true
  one_nat_gateway_per_az = false
  enable_dns_hostnames = true
  enable_dns_support = true
  map_public_ip_on_launch = false
    tags = {
    Terraform = "true"
    Environment = "${include.env.locals.env}"
    Name = "${include.env.locals.env}-vpc"
  }
}