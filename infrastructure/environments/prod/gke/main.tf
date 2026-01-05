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

# 2. Build GKE inside that VPC
module "gke" {
  source              = "github.com/UltimateOmnitrix/terraform-modules//modules/gke?ref=main"
  project_id          = var.project_id
  region              = "us-central1"
  network_name        = data.terraform_remote_state.vpc.outputs.network_name
  subnet_name         = data.terraform_remote_state.vpc.outputs.subnet_name
  pods_range_name     = data.terraform_remote_state.vpc.outputs.pods_range
  services_range_name = data.terraform_remote_state.vpc.outputs.services_range
}
