
resource "google_container_cluster" "gke" {
  name = "${var.project_name}-gke"
  # location                 = "us-central1-a"
  remove_default_node_pool = true
  initial_node_count       = 1
  network                  = var.network_self_link
  subnetwork               = var.subnetwork_self_link
  networking_mode          = "VPC_NATIVE"

  deletion_protection = false

  # node_locations = ["us-central1-b"]

  addons_config {
    http_load_balancing {
      disabled = true
    }

    horizontal_pod_autoscaling {
      disabled = false
    }
  }

  release_channel {
    channel = "STABLE"
  }

  workload_identity_config {
    workload_pool = "${var.project_id}.svc.id.goog"
  }


  ip_allocation_policy {
    cluster_secondary_range_name  = var.cluster_secondary_range_name
    services_secondary_range_name = var.services_secondary_range_name
  }

  private_cluster_config {
    enable_private_nodes    = true
    enable_private_endpoint = false
    master_ipv4_cidr_block  = var.master_ipv4_cidr_block
  }

  # jenkins use case
  # master_authorized_networks_config {
  #   cidr_blocks {
  #     cidr_block   = "10.0.0.0/18"
  #     display_name = "private-subnet"
  #   }
  # }
}

resource "google_service_account" "gke" {
  account_id = "${var.project_name}-gke"
  project    = var.project_id
}

resource "google_project_iam_member" "gke_logging" {
  project = var.project_id
  role    = "roles/logging.logWriter"
  member  = "serviceAccount:${google_service_account.gke.email}"
}

resource "google_project_iam_member" "gke_metrics" {
  project = var.project_id
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.gke.email}"
}

resource "google_container_node_pool" "general" {
  name     = "${var.project_name}-general"
  project  = var.project_id
  cluster  = google_container_cluster.gke.id
  location = google_container_cluster.gke.location

  autoscaling {
    total_min_node_count = var.total_min_node_count
    total_max_node_count = var.total_max_node_count
  }

  management {
    auto_upgrade = true
    auto_repair  = true
  }

  node_config {
    preemptible  = false
    machine_type = var.node_machine_type

    labels = {
      role = "general"
    }

    # taint {
    #   key    = "instance_type"
    #   value  = "spot"
    #   effect = "NO_SCHEDULE"
    # }

    service_account = google_service_account.gke.email

    oauth_scopes = ["https://www.googleapis.com/auth/cloud-platform"]
  }
}
