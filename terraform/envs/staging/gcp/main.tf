
module "foundation" {
  source          = "../../../modules/gcp/foundation"
  project_name    = var.project_name
  billing_account = var.billing_account
}

module "network" {
  source = "../../../modules/gcp/network"

  project_id   = module.foundation.project_id
  project_name = var.project_name
  main_cidr    = var.main_cidr

  depends_on = [module.foundation]
}

module "cluster" {
  source                 = "../../../modules/gcp/cluster"
  project_id             = module.foundation.project_id
  project_name           = var.project_name
  network_self_link      = module.network.vpc_self_link
  subnetwork_self_link   = module.network.private_subnet_self_link
  master_ipv4_cidr_block = module.network.master_ipv4_cidr_block

  cluster_secondary_range_name  = module.network.cluster_secondary_range_name
  services_secondary_range_name = module.network.services_secondary_range_name

  depends_on = [module.network]
}

module "postgresql" {
  source = "../../../modules/gcp/postgresql"

  project_name = var.project_name
  project_id   = module.foundation.project_id

  depends_on = [module.network]
}

resource "random_password" "grafana_password" {
  length  = 8
  special = false
  upper   = true
  lower   = true
  numeric = true
}

resource "random_password" "keycloak_password" {
  length  = 8
  special = false
  upper   = true
  lower   = true
  numeric = true
}

resource "random_password" "argocd_password" {
  length  = 8
  special = false
  upper   = true
  lower   = true
  numeric = true
}
