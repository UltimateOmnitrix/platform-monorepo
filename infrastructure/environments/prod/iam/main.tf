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
    prefix = "terraform/state/iam"
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



# ---------------------------------------------------------
# # ✅ CROSSPLANE IDENTITY (Day 4)
# # ---------------------------------------------------------

# # the process goes by this way, in first resource, google_service_account your are creating a service account, 
# # in the second using hte IAM you are giving the permission as owner to that service account 
# # in the third we binding to KSA (Workload Identity) of the Kubernetes workload identity pool , by which mean KSA impersonates the GSA 

# # 1. Create the Google Service Account (GSA)
# resource "google_service_account" "crossplane" {
#   account_id   = "crossplane-provider"
#   display_name = "Crossplane Provider GSA"
#   project      = var.project_id
# }

# # 2. Grant "Owner" access (For the Demo - easiest way)
# resource "google_project_iam_member" "crossplane_owner" {
#   project = var.project_id
#   role    = "roles/owner" # ⚠️ Powerful! For production, Scope this down.
#   member  = "serviceAccount:${google_service_account.crossplane.email}"
# }

# # 3. Bind GSA to KSA (Workload Identity)
# # "Allow the 'provider-gcp-*' pods in 'crossplane-system' to act as this GSA"

# # the below binding process is super simple first you will install the provider-gcp, so the crossplane deploys provider controller pods 
# # into crossplane-system namespace 
# # usually the pods which are deployed gets provider spsecifc KSA (provider-gcp), we binding those to the GSA tto secrurely access GCP API's
# resource "google_service_account_iam_member" "crossplane_bind" {
#   service_account_id = google_service_account.crossplane.name
#   role               = "roles/iam.workloadIdentityUser"
#   member             = "serviceAccount:${var.project_id}.svc.id.goog[crossplane-system/provider-gcp]"

#   # ✅ CRITICAL: Wait for the cluster to be finished!
#   depends_on = [module.gke]
# }

# # 4. Output the Email (We need this for the next step)
# output "crossplane_email" {
#   value = google_service_account.crossplane.email
# }



## Day 06 Task 6.3 
# Create GSA for External Secrets
resource "google_service_account" "eso" {
  account_id   = "external-secrets-sa"
  display_name = "External Secrets Operator SA"
  project      = var.project_id
}

# Grant Secret Accessor Role to the GSA
resource "google_project_iam_member" "eso_secret_accessor" {
  project = var.project_id
  role    = "roles/secretmanager.secretAccessor"
  member  = "serviceAccount:${google_service_account.eso.email}"
}

# Bind GSA to the Kubernetes Service Account via Workload Identity
resource "google_service_account_iam_member" "eso_bind" {
  service_account_id = google_service_account.eso.name
  role               = "roles/iam.workloadIdentityUser"

  # the below syntax is serviceAccount:<PROJECT_ID>.svc.id.goog[<namespace>/<serviceaccount-name>]
  member = "serviceAccount:${var.project_id}.svc.id.goog[external-secrets/external-secrets]"
}

output "eso_email" {
  value = google_service_account.eso.email
}
