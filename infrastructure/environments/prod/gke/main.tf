terraform {
  backend "gcs" {
    prefix = "terraform/state/gke"
  }
}

# 1. READ the Network "Brain"
data "terraform_remote_state" "vpc" {
  backend = "gcs"
  config = {
    bucket = "${var.project_id}-tf-state"
    prefix = "terraform/state/vpc"
  }
}

# 2. Build GKE using the module
module "gke" {
  source              = "github.com/UltimateOmnitrix/terraform-modules//modules/gke?ref=main"
  project_id          = var.project_id
  region              = var.region
  network_name        = data.terraform_remote_state.vpc.outputs.network_name
  subnet_name         = data.terraform_remote_state.vpc.outputs.subnet_name
  pods_range_name     = data.terraform_remote_state.vpc.outputs.pods_range
  services_range_name = data.terraform_remote_state.vpc.outputs.services_range
}

# ---------------------------------------------------------
# ✅ PROVIDER CONFIGURATION (MUST BE HERE, NOT IN MODULE)
# ---------------------------------------------------------

data "google_client_config" "default" {}

# Kubernetes Provider
provider "kubernetes" {
  host                   = "https://${module.gke.cluster_endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(module.gke.cluster_ca_certificate)
}

# Helm Provider
provider "helm" {
  kubernetes = {
    host                   = "https://${module.gke.cluster_endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(module.gke.cluster_ca_certificate)
  }
}
