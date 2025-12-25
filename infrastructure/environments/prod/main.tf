terraform {
  required_version = "~> 1.14.3"
  backend "gcs" {} # Initialized via CI
}

provider "google" {
  project = var.project_id
  region  = "us-central1"
}

module "iam_wif" {
  # Call your tagged library module
  source     = "git::https://github.com/UltimateOmnitrix/terraform-modules.git//modules/iam?ref=v1.0.0"
  project_id = var.project_id
}

output "wif_provider_name" {
  value = module.iam_wif.wif_provider_name
}
