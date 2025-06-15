# main_cidr              = "10.2.0.0/19"     # 10.2.0.0   - 10.2.31.255   (8,192 IPs)
# public_cidr_range      = "10.2.0.0/24"     # 10.2.0.0   - 10.2.0.255    (256 IPs)
# master_ipv4_cidr_block = "10.2.1.128/28"   # 10.2.1.128 - 10.2.1.143    (16 IPs)
# private_cidr_range     = "10.2.4.0/22"     # 10.2.4.0   - 10.2.7.255    (1,024 IPs)
# service_ip_range       = "10.2.8.0/21"     # 10.2.8.0   - 10.2.15.255   (2,048 IPs)
# pod_ip_range           = "10.2.16.0/20"    # 10.2.16.0  - 10.2.31.255   (4,096 IPs)

locals {
  public_cidr_range      = cidrsubnet(var.main_cidr, 5, 0)
  private_cidr_range     = cidrsubnet(var.main_cidr, 3, 1)
  service_ip_range       = cidrsubnet(var.main_cidr, 2, 1)
  pod_ip_range           = cidrsubnet(var.main_cidr, 1, 1)
  master_ipv4_cidr_block = "${split("/", cidrsubnet(var.main_cidr, 8, 12))[0]}/28"
}

module "foundation" {
  source          = "../../../modules/gcp/foundation"
  project_name    = var.project_name
  billing_account = var.billing_account
}

module "network" {
  providers = {
    google = google.google_project
  }
  source = "../../../modules/gcp/network"

  project_id   = module.foundation.project_id
  project_name = var.project_name

  private_cidr_range = local.private_cidr_range
  public_cidr_range  = local.public_cidr_range

  pod_ip_range     = local.pod_ip_range
  service_ip_range = local.service_ip_range

  depends_on = [module.foundation]
}

module "cluster" {
  providers = {
    google = google.google_project
  }

  source                 = "../../../modules/gcp/cluster"
  project_id             = module.foundation.project_id
  project_name           = var.project_name
  network_self_link      = module.network.vpc_self_link
  subnetwork_self_link   = module.network.private_subnet_self_link
  master_ipv4_cidr_block = local.master_ipv4_cidr_block

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
