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
  required_version = "~> 1.14.3" # or your version

  # this allows CI/CD pipleines to dynamically specify the bucket at runtime
  # terraform apply -auto-approve -var-file="prod.tfvars" from the bootstrap-found
  backend "gcs" {
    prefix = "env/prod/iam"
  }
}

provider "google" {
  project = var.project_id
  region  = "us-central1"
}

# IN this it tf downloads the module code, reads it variables defintions, 
# and injects values passed from var.project_id into project_id.... 
# left one is variable of module (project_id) mean it is from the modules/iam/iamModulevariables.tf 
# right one is variable of env/prod/prod.tfvars 
module "iam_wif" {
  source = "github.com/UltimateOmnitrix/terraform-modules//modules/iam?ref=main"
  # version = "1.0.0" !! NEED TO Work on this 
  # and work on DataLook up too 

  # PASSING THE VARIABLES
  project_id  = var.project_id
  github_repo = var.github_repo
}


output "wif_provider_name" {
  value = module.iam_wif.wif_provider_name
}


# -----------------------------------------------------------------------------
# ********* 
# TILL LINE NUMBER 44 it is FOR THE DAY -01 
# *********
# -----------------------------------------------------------------------------
