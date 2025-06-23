locals {
  public_cidr_range      = cidrsubnet(var.main_cidr, 5, 0)
  private_cidr_range     = cidrsubnet(var.main_cidr, 3, 1)
  service_ip_range       = cidrsubnet(var.main_cidr, 2, 1)
  pod_ip_range           = cidrsubnet(var.main_cidr, 1, 1)
  master_ipv4_cidr_block = "${split("/", cidrsubnet(var.main_cidr, 8, 12))[0]}/28"
  iap_ssh_source_ranges  = ["35.235.240.0/20"] # Google Cloud Identity-Aware Proxy IP range for SSH

  cluster_secondary_range_name  = "k8s-pods"
  services_secondary_range_name = "k8s-services"
}

resource "google_compute_network" "vpc" {
  name                            = "${var.project_name}-main"
  routing_mode                    = var.routing_mode
  project                         = var.project_id
  auto_create_subnetworks         = false
  delete_default_routes_on_create = true
}

resource "google_compute_route" "default_route" {
  name             = "${var.project_name}-default-route"
  project          = var.project_id
  dest_range       = "0.0.0.0/0"
  network          = google_compute_network.vpc.name
  next_hop_gateway = "default-internet-gateway"
}

resource "google_compute_subnetwork" "public" {
  name                     = "${var.project_name}-public"
  project                  = var.project_id
  ip_cidr_range            = local.public_cidr_range
  private_ip_google_access = true
  network                  = google_compute_network.vpc.id
  stack_type               = "IPV4_ONLY"
}

resource "google_compute_subnetwork" "private" {
  name                     = "${var.project_name}-private"
  project                  = var.project_id
  ip_cidr_range            = local.private_cidr_range
  network                  = google_compute_network.vpc.id
  private_ip_google_access = true # the ability to access google services api
  stack_type               = "IPV4_ONLY"

  secondary_ip_range {
    range_name    = "k8s-pods"
    ip_cidr_range = local.pod_ip_range
  }

  secondary_ip_range {
    range_name    = "k8s-services"
    ip_cidr_range = local.service_ip_range
  }
}

resource "google_compute_address" "nat" {
  name         = "${var.project_name}-nat"
  address_type = "EXTERNAL"
  project      = var.project_id
  network_tier = var.network_tier
}

resource "google_compute_router" "router" {
  name    = "${var.project_name}-router"
  project = var.project_id
  network = google_compute_network.vpc.id
}

resource "google_compute_router_nat" "nat" {
  name    = "${var.project_name}-nat"
  project = var.project_id
  router  = google_compute_router.router.name

  nat_ip_allocate_option             = "MANUAL_ONLY"
  source_subnetwork_ip_ranges_to_nat = "LIST_OF_SUBNETWORKS" # which subnet can use the nat only the one specified
  nat_ips                            = [google_compute_address.nat.self_link]

  subnetwork {
    name                    = google_compute_subnetwork.private.self_link # all the vms in the private subnet can use the nat
    source_ip_ranges_to_nat = ["ALL_IP_RANGES"]
  }
}

resource "google_compute_firewall" "allow_iap_ssh" {
  name    = "allow-iap-ssh"
  project = var.project_id
  network = google_compute_network.vpc.name

  allow {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = local.iap_ssh_source_ranges
  depends_on    = [google_compute_network.vpc]
}
