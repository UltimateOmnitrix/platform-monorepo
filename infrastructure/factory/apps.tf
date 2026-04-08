# ─── CLOUD RUN FACTORY ENGINE ─────────────────────────────
# Scans data/apps/ for YAML files
# Each YAML file = one Cloud Run application

locals {
  cloudrun_apps = {
    for f in fileset("${path.module}/data/apps", "*.yaml") :
    trimsuffix(f, ".yaml") => yamldecode(file("${path.module}/data/apps/${f}"))
  }
}

resource "google_cloud_run_v2_service" "app" {
  for_each = local.cloudrun_apps

  name     = each.key
  location = lookup(each.value, "region", "us-central1")
  ingress  = "INGRESS_TRAFFIC_ALL"

  template {
    containers {
      # For initial deployment, we use a sample container.
      # The CI/CD pipeline (Template 3) will update this with the real image.
      image = lookup(each.value, "image", "us-docker.pkg.dev/cloudrun/container/hello")

      env {
        name  = "ENVIRONMENT"
        value = lookup(each.value, "environment", "dev")
      }
    }
  }

  labels = {
    environment = lookup(each.value, "environment", "dev")
    managed_by  = "backstage"
    sandbox     = lookup(each.value, "sandbox", "none")
  }
}

# Allow unauthenticated invocation (since this is a demo environment)
resource "google_cloud_run_v2_service_iam_member" "public_access" {
  for_each = local.cloudrun_apps

  project  = google_cloud_run_v2_service.app[each.key].project
  location = google_cloud_run_v2_service.app[each.key].location
  name     = google_cloud_run_v2_service.app[each.key].name
  role     = "roles/run.invoker"
  member   = "allUsers"
}

output "cloudrun_urls" {
  description = "The URLs of the deployed Cloud Run services"
  value = {
    for name, svc in google_cloud_run_v2_service.app :
    name => svc.uri
  }
}
