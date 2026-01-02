terraform {
  required_version = "~> 1.5" # or your version
  backend "gcs" {}
}

provider "google" {
  project = var.project_id
  region  = "us-central1"
}

module "iam_wif" {
  source = "github.com/UltimateOmnitrix/terraform-modules//modules/iam?ref=main"

  # PASSING THE VARIABLES
  project_id  = var.project_id
  github_repo = var.github_repo
}

output "wif_provider_name" {
  value = module.iam_wif.wif_provider_name
}
