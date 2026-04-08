# HCA Healthcare Architecture Breakdown (From the Video Slides)

---

## Slide 1: Cloud Run Architecture

This slide shows what a **fully deployed app** looks like at HCA.

```
┌──────────────────────────────────────────────────────────────────────┐
│  HOW CODE GETS TO GCP                                                │
│                                                                      │
│  GitHub CI/CD ──→ Terraform ──→ Workload Identity (auth with GCP)    │
└──────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────── VPC Service Control (Security Wall) ─────────────────┐
│                                                                      │
│  ┌─── GCP Service Project (Where the app lives) ───┐                │
│  │                                                   │                │
│  │  🔑 Secrets (DB_PASSWORD, DB_USERNAME, etc.)      │                │
│  │       ↓                                           │                │
│  │  📦 Artifact Registry (Docker images stored here) │                │
│  │       ↓                                           │                │
│  │  🚀 Cloud Run Service ← runs your app container   │                │
│  │       ↑                                           │                │
│  │  👤 Internal User → Load Balancer → Cloud Run     │                │
│  │                                                   │                │
│  └───────────────────────────────────────────────────┘                │
│                          │                                            │
│                          │ (Serverless VPC Connector)                 │
│                          ▼                                            │
│  ┌─── GCP Service Producer Project ───┐                              │
│  │                                     │                              │
│  │  🐘 Cloud SQL Postgres (Database)   │                              │
│  │                                     │                              │
│  └─────────────────────────────────────┘                              │
└──────────────────────────────────────────────────────────────────────┘
```

### What's happening here:
1. **GitHub CI/CD** pushes code → **Terraform** deploys it → uses **Workload Identity** (same as your WIF!) to authenticate
2. The app lives inside a **VPC Service Control** perimeter (a security wall that prevents data from leaking out)
3. The app runs on **Cloud Run** (serverless containers — no GKE needed for the app itself!)
4. **Secrets** (DB password, username, connection string) are stored in GCP Secret Manager
5. Docker images are stored in **Artifact Registry** (Google's container registry)
6. The database (**Cloud SQL Postgres**) lives in a **separate project** for isolation
7. Cloud Run connects to Cloud SQL through a **Serverless VPC Connector** (private network tunnel)
8. Users access the app through an **Internal Load Balancer** (not public internet!)

### In simple terms:
> **"The app runs in Cloud Run, the database runs in a separate project, and they talk through a private tunnel. Nobody from the internet can touch it."**

---

## Slide 2: Developer Environment

This slide shows what Backstage creates BEFORE the developer writes any code.

Think of it as the **"Empty Apartment"** that the developer moves into.

```
When a dev clicks "Create" in Backstage, these 4 things happen:

┌──────────────────────────┐
│ 1. AppCode + FinOps Tags │  ← Labels the project for billing/cost tracking
├──────────────────────────┤
│ 2. Create IAM Groups     │  ← Creates the security groups so the dev has access
├──────────────────────────┤
│ 3. Fetch Parent Folder   │  ← Finds where in the GCP org to put this project
├──────────────────────────┤
│ 4. Terraform Workspace   │  ← Sets up the "state file" location for Terraform
└──────────────────────────┘

After these 4 steps, the developer gets:

┌─── An empty GCP Service Project ───┐
│                                     │
│  (Nothing deployed yet, but the     │
│   project EXISTS, IAM is set up,    │
│   networking is connected, and      │
│   Terraform is ready to go)         │
│                                     │
└─────────────────────────────────────┘
```

### In simple terms:
> **"Before the dev writes a single line of code, Backstage already created their GCP project, gave them access, connected the network, and set up Terraform. The dev just starts coding."**

---

## Slide 3: Factory Style Terraform (THE BIG ONE 🔥)

This is the **MOST IMPORTANT** slide. It explains WHY they changed from "normal" Terraform to "Factory" Terraform.

### The Problem: Merge Conflicts

Imagine 10 developers all want to create a sandbox at the same time.

**Old Way (Modular Terraform)** — Everyone edits the SAME file:

```hcl
# main.tf — EVERYONE touches this file!

module "project1" {
  source = "./modules/project"
  name   = "app-1"
}

module "project2" {     # ← Developer A adds this
  source = "./modules/project"
  name   = "app-2"
}

module "project3" {     # ← Developer B adds this AT THE SAME TIME
  source = "./modules/project"
  name   = "app-3"
}
# 💥 MERGE CONFLICT! Both devs edited the same file!
```

**New Way (Factory Style)** — Each project gets its OWN file:

```
data/projects/
├── app-1.yaml   ← Developer A creates THIS file
├── app-2.yaml   ← Developer B creates THIS file (different file!)
└── app-3.yaml   ← Developer C creates THIS file (no conflict!)
```

Each YAML file is simple:
```yaml
# data/projects/app-1.yaml
parent: folders/12345678
billing_account: 012345-67890A-BCDEF0
```

```yaml
# data/projects/app-2.yaml
parent: folders/12345678
billing_account: 012345-67890A-BCDEF0
```

### Why this is genius:
| | Old Way (Modular) | New Way (Factory) |
|:---|:---|:---|
| Adding a project | Edit `main.tf` (shared file) | Create a NEW `.yaml` file |
| 10 devs at once | 💥 Merge conflicts everywhere | ✅ Zero conflicts (separate files) |
| Terraform code | Grows bigger with every project | **Never changes** — stays the same |
| Who touches TF? | Every developer | **Only the Platform Team** |

> **"The Terraform code is LOCKED. Nobody changes it. Developers only add YAML files."**

---

## Slide 4: Sample Factory Terraform (The Engine)

This is the actual Terraform code that READS those YAML files. This code **never changes** — it's the "Factory Engine."

```hcl
# This code is written ONCE by the platform team and NEVER touched again

locals {
  projects = {
    # Step 1: Scan the data/ folder for ALL .yaml files
    for f in fileset("${var.data_dir}", "**/*.yaml") :
    
    # Step 2: Use the filename as the project name
    trimsuffix(f, ".yaml") => yamldecode(file("${var.data_dir}/${f}"))
    
    # Example: "app-1.yaml" becomes key "app-1" with the YAML content as value
  }
}

module "project_factory" {
  # Step 3: Loop over ALL projects found in the YAML files
  for_each = local.projects
  
  source          = "./modules/project"
  billing_account = each.value.billing_account  # from the YAML
  parent          = each.value.parent           # from the YAML
  name            = each.key                    # the filename
}
```

### How it works step by step:

```
1. Terraform scans: "Hey, what YAML files are in the data/ folder?"
   → Finds: app-1.yaml, app-2.yaml, app-3.yaml

2. Terraform reads each file:
   → app-1.yaml says: parent=folders/123, billing=012345
   → app-2.yaml says: parent=folders/123, billing=012345

3. Terraform creates a module FOR EACH file:
   → Creates project "app-1" with those settings
   → Creates project "app-2" with those settings

4. When a NEW developer adds app-4.yaml:
   → Terraform automatically picks it up
   → Creates project "app-4"
   → NO TERRAFORM CODE WAS CHANGED!
```

---

## Slide 5: Project Request (The YAML Spec)

This is what a REAL project request YAML file looks like at HCA:

```yaml
# project app-2
labels:
  app: app-2           # What app is this?
  team: foo            # Which team owns it?

parent: folders/12345678   # Where in GCP org does it live?

# Security policies
org_policies:
  "compute.restrictSharedVpcSubnetworks":
    rules:
      - allow:
          values:
            - projects/foo-host/regions/europe-west1/subnetworks/prod-default-ew1

# Service accounts the app needs
service_accounts:
  app-2-be: {}         # Backend service account

# GCP APIs to enable
services:
  - compute.googleapis.com      # VMs
  - container.googleapis.com    # GKE
  - run.googleapis.com          # Cloud Run
  - storage.googleapis.com      # Buckets

# Networking — connect to the Shared VPC
shared_vpc_service_config:
  host_project: foo-host
  service_identity_iam:
    "roles/vpcaccess.user":
      - cloudrun
  network_subnet_users:
    europe-west1/prod-default-ew1:
      - group:team-1@example.com
```

### What this YAML does:
When Backstage creates this file and merges the PR, Terraform's Factory Engine reads it and automatically:
1. ✅ Creates the GCP project named "app-2"
2. ✅ Labels it with the team name (for cost tracking)
3. ✅ Applies org security policies
4. ✅ Creates a service account
5. ✅ Enables the required GCP APIs
6. ✅ Connects it to the Shared VPC network
7. ✅ Gives the team IAM access to the subnet

> **All from ONE YAML file. No Terraform code touched. No merge conflicts.**

---

## How This Maps to YOUR UltimateOmnitrix

| HCA Concept | Your Equivalent |
|:---|:---|
| Factory Engine (Terraform `for_each` + `yamldecode`) | We build this in `infrastructure/factory/` |
| YAML data files (`data/projects/*.yaml`) | We put these in `infrastructure/sandboxes/*.yaml` |
| Backstage creates the YAML file via PR | Same — `fetch:template` → `publish:github:pull-request` |
| GitHub CI/CD runs Terraform | Same — `sandbox-terraform.yml` workflow |
| GCP Project creation | We create **isolated resources** (buckets, etc.) within your existing project |
| Shared VPC | You already have `platform-vpc-prod` |
| Workload Identity | You already have WIF set up |

> [!IMPORTANT]
> **The Factory Pattern changes our implementation plan.** Instead of scaffolding full Terraform directories per sandbox, Backstage should only create a **single YAML file** (`infrastructure/sandboxes/my-sandbox.yaml`). The Factory Engine reads it and provisions everything. This is simpler, cleaner, and eliminates merge conflicts.
