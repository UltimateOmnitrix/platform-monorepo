terraform {
  # This state file will be saved under the 'networking' key
  backend "gcs" {
    prefix = "terraform/state/vpc"
  }
}

module "vpc" {
  source     = "github.com/UltimateOmnitrix/terraform-modules//modules/vpc?ref=main"
  project_id = var.project_id
  region     = "us-central1"
}

# # CRITICAL: We must output these so GKE can see them
# output "network_name" { value = module.vpc.network_name }
# output "subnet_name" { value = module.vpc.subnet_name }
# output "pods_range" { value = module.vpc.pods_range_name }
# output "services_range" { value = module.vpc.services_range_name }
