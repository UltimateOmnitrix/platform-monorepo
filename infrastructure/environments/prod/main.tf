# -----------------------------------------------------------------------------
# File: main.tf
#
# Purpose:
# This Terraform configuration defines the production infrastructure entry point
# for the platform. It initializes Terraform with a remote Google Cloud Storage
# backend, configures the Google provider, and invokes the IAM module responsible
# for establishing Workload Identity Federation (WIF).
#
# -----------------------------------------------------------------------------


# this defines tf version and confgire the remote backend 
terraform {
  required_version = "~> 1.5" # or your version

  # this allows CI/CD pipleines to dynamically specify the bucket at runtime
  # terraform apply -auto-approve -var-file="prod.tfvars" from the bootstrap-found
  backend "gcs" {}
}

provider "google" {
  project = var.project_id
  region  = "us-central1"
}

module "iam_wif" {
  source = "github.com/UltimateOmnitrix/terraform-modules//modules/iam?ref=main"
  # version = "1.0.0"

  # PASSING THE VARIABLES
  project_id  = var.project_id
  github_repo = var.github_repo
}


output "wif_provider_name" {
  value = module.iam_wif.wif_provider_name
}
