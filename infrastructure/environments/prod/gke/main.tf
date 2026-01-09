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


## BELOW IS DAY 03


#As terraform needs to talk to GKE cluster, tf needs where the cluster is, 
# who it is (identity)
# proof the cluster with certificate 

# the below lines, mean tf, get my currnt google cloud login details, 
# these comes from gcloud auth login, by this way tf gets a temp
data "google_client_config" "default" {}


# Kubernetes Provider this has the address of k8 api server, 
# and the token saying authencticated via google iam ,
# and the cluster CA certificate...
# THIS mean,  A TF Plugin that behaves like a k8 client (similar to kubectl)
provider "kubernetes" {
  host                   = "https://${module.gke.cluster_endpoint}"        # this is k8 api server url 
  token                  = data.google_client_config.default.access_token  # thsi is a short-lived oauth token issued by google
  cluster_ca_certificate = base64decode(module.gke.cluster_ca_certificate) # this is the cluster ca certificate
}

# Helm Provider 
# this helm proivdder tf plugin wraps the helm client and talks to k8 on your behalf acts like helm CLI
provider "helm" {
  kubernetes = {
    host                   = "https://${module.gke.cluster_endpoint}"
    token                  = data.google_client_config.default.access_token
    cluster_ca_certificate = base64decode(module.gke.cluster_ca_certificate)
  }
}
