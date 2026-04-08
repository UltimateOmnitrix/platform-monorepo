terraform {
  backend "gcs" {
    prefix = "terraform/state/factory"
  }

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = var.project_id
  region  = var.region
}

# ─── KUBERNETES PROVIDER ──────────────────────────────
# This allows the Factory to update Kubernetes Secrets 
# (like DB IP/Password) as soon as the infra is built.
data "google_client_config" "default" {}

# Get GKE cluster info (from your existing GKE setup)
data "google_container_cluster" "omnitrix" {
  name     = "omnitrix-cluster"
  location = "us-central1-a"
}

provider "kubernetes" {
  host                   = "https://${data.google_container_cluster.omnitrix.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(data.google_container_cluster.omnitrix.master_auth[0].cluster_ca_certificate)
}

# ─── THE FACTORY ENGINE ─────────────────────────────
# Scans data/sandboxes/ for YAML files
# Each YAML file = one sandbox with its own resources
locals {
  sandboxes = {
    for f in fileset("${path.module}/data/sandboxes", "*.yaml") :
    trimsuffix(f, ".yaml") => yamldecode(file("${path.module}/data/sandboxes/${f}"))
  }
}

# ─── CREATE A BUCKET PER SANDBOX ────────────────────
resource "google_storage_bucket" "sandbox" {
  for_each = local.sandboxes

  name          = "sandbox-${each.key}-${var.project_id}"
  location      = lookup(each.value, "region", "US")
  force_destroy = true

  uniform_bucket_level_access = true

  labels = {
    environment = "sandbox"
    owner       = replace(replace(lookup(each.value, "owner_email", "unknown"), "@", "-at-"), ".", "-")
    managed_by  = "backstage"
    sandbox     = each.key
  }
}

# ─── GRANT OWNER ACCESS PER SANDBOX ─────────────────
resource "google_storage_bucket_iam_member" "sandbox_owner" {
  for_each = local.sandboxes

  bucket = google_storage_bucket.sandbox[each.key].name
  role   = "roles/storage.admin"
  member = "user:${each.value.owner_email}"
}
