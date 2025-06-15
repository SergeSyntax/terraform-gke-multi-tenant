
terraform {
  required_version = ">= 1.1"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.3"
    }
  }

  backend "gcs" {}
}

provider "google" {
  region = var.region
}

provider "google" {
  alias   = "google_project"
  region  = var.region
  project = module.foundation.project_id
}
