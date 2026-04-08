# ─── CLOUD SQL FACTORY ENGINE ─────────────────────────────
locals {
  databases = {
    for f in fileset("${path.module}/data/databases", "*.yaml") :
    trimsuffix(f, ".yaml") => yamldecode(file("${path.module}/data/databases/${f}"))
  }
}

resource "google_sql_database_instance" "backstage" {
  for_each = local.databases

  name                = each.key
  database_version    = lookup(each.value, "version", "POSTGRES_17")
  region              = lookup(each.value, "region", "us-central1")
  deletion_protection = false # Set to true for real production!

  settings {
    tier = lookup(each.value, "tier", "db-g1-small")

    ip_configuration {
      ipv4_enabled = true
      # Authorized networks (matching your current setup)
      authorized_networks {
        value = "0.0.0.0/0"
        name  = "public-access"
      }
    }
  }
}

resource "google_sql_user" "users" {
  for_each = local.databases
  name     = lookup(each.value, "username", "backstage-user")
  instance = google_sql_database_instance.backstage[each.key].name
  password = lookup(each.value, "password", "omnitrix-secret-123")
}

output "database_instances" {
  description = "The public IP addresses of the database instances"
  value = {
    for name, instance in google_sql_database_instance.backstage :
    name => instance.public_ip_address
  }
}

# ─── KUBERNETES SECRETS (HCA BINDING) ─────────────────
# This section "bridges" the infrastructure to the app.
# It creates the secrets that Backstage is looking for.

resource "kubernetes_secret" "db_connectivity" {
  for_each = local.databases

  metadata {
    name      = "backstage-pg-secret" # Matching backstage.yml
    namespace = "default"
  }

  data = {
    publicIP = google_sql_database_instance.backstage[each.key].public_ip_address
    # These are extra fields Crossplane usually adds, good to have:
    port     = "5432"
    database = "postgres" 
  }

  type = "Opaque"
}

resource "kubernetes_secret" "db_password" {
  for_each = local.databases

  metadata {
    name      = "backstage-db-password" # Matching backstage.yml
    namespace = "default"
  }

  data = {
    password = lookup(each.value, "password", "omnitrix-secret-123")
  }

  type = "Opaque"
}
