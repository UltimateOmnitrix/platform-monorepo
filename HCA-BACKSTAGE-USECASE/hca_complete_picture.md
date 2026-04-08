# HCA Healthcare — The Complete Picture

## What Problem Were They Solving?

Before Backstage, this is what happened at HCA when a developer wanted to build a new app:

```
Developer: "Hey, I need a GCP project to build my app."
Platform Team: "Sure, fill out a ticket."
                    ⏳ (3 days later)
Platform Team: "Here's your project. Now you need a repo."
Developer: "Ok, can I get a GitHub repo?"
Platform Team: "Fill out another ticket."
                    ⏳ (2 days later)
Platform Team: "Here's your repo. Now set up CI/CD."
Developer: "How do I set up CI/CD? And how do I connect to the VPC?"
Platform Team: "Read the wiki. It's 47 pages."
Developer: "..."
                    ⏳ (2 weeks later, still not deployed)
```

**Total time to "Hello World": 2-3 weeks.**

---

## What Did They Build?

They built a **3-template system in Backstage** that does everything automatically.

**Total time to "Hello World" after: ~15 minutes.** ⚡

---

## The Platform Architecture

```
┌──────────────── GKE Cluster ────────────────────────────────┐
│                                                              │
│  ┌─── IDP Namespace (Internal Developer Platform) ───┐      │
│  │                                                    │      │
│  │  ┌────────────┐                                    │      │
│  │  │  BACKSTAGE  │ ◄── The Portal (what devs see)    │      │
│  │  └──────┬─────┘                                    │      │
│  │         │                                          │      │
│  │         ├──► Security Group Service                │      │
│  │         │    (creates IAM groups)                  │      │
│  │         │                                          │      │
│  │         ├──► Google API Wrapper Service             │      │
│  │         │    (creates GCP projects)                │      │
│  │         │                                          │      │
│  │         └──► Terraform API Wrapper Service          │      │
│  │              (creates TF workspaces)               │      │
│  │                                                    │      │
│  └────────────────────────────────────────────────────┘      │
│                                                              │
│  + Cloud SQL (Backstage database)                            │
│  + Redis/MemoryStore (caching)                               │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

Backstage itself runs on GKE. Next to it, they built **3 helper microservices** that do the heavy lifting (calling Google APIs, creating projects, setting up Terraform).

---

## The 3 Templates (Golden Paths)

Think of these like ordering food at 3 different stations:

```
🏗️ Station 1          🚀 Station 2           💻 Station 3
"BUILD THE KITCHEN"   "INSTALL THE OVEN"     "START COOKING"

GCP Developer         Cloud Run App          Cloud Run CI/CD
DEV Environment       Capability Package     via GitHub Actions
```

### You MUST go in order: 1 → 2 → 3

---

### Template 1: "GCP Developer DEV Environment" 🏗️

**Purpose:** Build the foundation — the GCP project, the repo, the networking.

**What the developer does:**
```
┌─────────────────────────────────────┐
│  Product name:    bd3               │
│  Description:     demo for next     │
│  Line of Business: [picks one]      │
│                                     │
│                        [Create] ←── clicks this
└─────────────────────────────────────┘
```

**What Backstage does automatically (22 steps):**

```
IDENTITY & TRACKING
  ├── Create app code + FinOps labels     (for cost tracking)
  ├── Create AD Group                     (who can access)
  └── Create Privileged AD Groups         (who can admin)

NETWORKING
  ├── Fetch the line of business
  ├── Fetch networking system
  ├── Fetch Shared VPC config
  ├── Find Serverless Connector           (for Cloud Run → Database)
  └── Find Internal Load Balancer subnet

TERRAFORM
  ├── Create Terraform Cloud Workspace    (hca-bd3-dev)
  ├── Assign AD group to workspace
  └── Lookup parent folder in GCP org

CODE
  ├── Fetch product base repo template
  ├── Add documentation files
  ├── Write catalog-info.yaml             (registers in Backstage)
  ├── Create GitHub repo                  (hca-bd3-nextdemo)
  ├── Wait for creation
  └── Install branching strategy          (dev / qa / main)
```

**What exists after Template 1:**

```
✅ GCP Project:       hca-bd3-dev
✅ GitHub Repo:        hca-bd3-nextdemo
    ├── .github/           (CI/CD workflows)
    ├── docs/              (documentation)
    ├── environments/      (dev/qa/prod configs)
    ├── main.tf            (Terraform)
    ├── variables.tf
    ├── outputs.tf
    ├── providers.tf
    ├── catalog-info.yaml  (Backstage catalog entry)
    ├── mkdocs.yml         (TechDocs)
    └── README.md
✅ Terraform Workspace: hca-bd3-dev (already ran apply!)
✅ IAM Groups:          created and assigned
✅ Networking:          connected to Shared VPC
```

---

### Template 2: "Cloud Run App Capability Package" 🚀

**Purpose:** Add Cloud Run infrastructure to the project created in Template 1.

**What the developer does:**
```
┌──────────────────────────────────────────────┐
│  SETUP                                        │
│    Classification:   highly-confidential       │
│    App Environment:  dev                       │
│    Product:          hca-bd3-nextdemo ← FROM TEMPLATE 1
│                                                │
│  LOAD BALANCER                                 │
│    Type:             internal                  │
│                                                │
│  FRONTEND                                      │
│    Image:            hello (sample container)   │
│    Name:             nextweb                   │
│    CICD Managed:     ✅                         │
│    LB Enabled:       ✅                         │
│                                                │
│  BACKEND:            (none for demo)           │
│  CLOUD SQL:          ❌                         │
│  CLOUD STORAGE:      ❌                         │
│                                                │
│                             [Create] ←── clicks this
└──────────────────────────────────────────────┘
```

**What Backstage does automatically (~24 steps):**

```
LOOKUP (reads from Backstage catalog)
  ├── Get Catalog info
  ├── Get Project details
  ├── Get Labels
  ├── Get Line of Business
  ├── Get Networking config
  ├── Get Shared VPC
  ├── Get Serverless Connector
  └── Get ILB Subnet

GENERATE CODE
  ├── Locate the repo (hca-bd3-nextdemo)
  ├── Fetch the repo
  ├── Render Cloud Run Terraform template
  ├── Update terraform.tfvars
  ├── Update outputs.tf
  ├── Update modules
  ├── Update variables.tf
  └── Add documentation

CREATE PR
  └── Create Pull Request in hca-bd3-nextdemo
      Branch: devplatform-cp-internal-app-deploy → dev
      Files:  +97 lines, 9 files changed
```

**The developer then:**
1. Reviews the PR
2. Approves it
3. Merges it
4. GitHub Actions runs `terraform apply`

**What exists after Template 2:**

```
Everything from Template 1, PLUS:

✅ Cloud Run Service:          deployed (nextweb)
✅ Internal Load Balancer:     configured
✅ Serverless VPC Connector:   connected
✅ Terraform:                  applied successfully
```

---

### Template 3: "GCP Cloud Run CI/CD via GitHub Actions" 💻

**Purpose:** Create the actual application code repo with CI/CD pipeline.

**What the developer does:**
```
┌──────────────────────────────────────────────┐
│  Dev Url:           https://nextweb-dev....   │
│  Ar Location:       us (Artifact Registry)    │
│  Gcp Project:       hca-bd3-dev              │
│  Region:            us-central1              │
│  Service Name:      nextweb                  │
│  Service Description: sample web app         │
│  Service Owner:     group:default/eid_bd3    │
│  Service Type:      Website                  │
│  Cloud SQL:         none                     │
│  Code Type:         Neutron Vue ← Vue.js!    │
│                                               │
│                          [Create] ←── clicks this
└──────────────────────────────────────────────┘
```

**What Backstage does automatically (~22 steps):**

```
SECURITY
  ├── Create WIF access for prod
  ├── Wait for file creation
  └── Publish PR for Workload Identity

SETUP
  ├── Get project labels
  ├── Create Cloud Run service definitions
  ├── Rename service deployment workflow
  ├── Add canary deployment workflow      ← for safe rollouts!
  └── Rename service canary

MULTI-ENVIRONMENT
  ├── Fetch dev project labels
  ├── Fetch prod project labels
  ├── Update GitHub workflow (promote to prod)
  ├── Update Dev service definition
  ├── Overwrite Dev service file
  ├── Update QA service definition
  ├── Overwrite QA service file
  ├── Update Prod service definition
  ├── Overwrite Prod service file
  ├── Update Canary service definition
  └── Overwrite Canary service file

DEPLOY
  └── Deploy Cloud Run workflows
```

**Creates a NEW repo:** `hca-bd3-nextweb` (the app code)

**What exists after Template 3:**

```
Everything from Templates 1 & 2, PLUS:

✅ NEW GitHub Repo:    hca-bd3-nextweb
    ├── Vue.js application code (Neutron Vue)
    ├── GitHub Actions CI/CD pipeline
    ├── Service definitions for:
    │   ├── Dev
    │   ├── QA
    │   ├── Prod
    │   └── Canary
    └── Promotion workflows (dev → QA → prod)
✅ WIF Access:         new repo can deploy to GCP
✅ Live App:           nextweb-dev.hca.... is RUNNING!
```

---

## The Factory Pattern (How They Manage Scale)

When you have 100+ teams all creating projects, you get merge conflicts. HCA solved this:

```
OLD WAY (Breaks at Scale)            NEW WAY (Factory Pattern)
─────────────────────────            ─────────────────────────
Everyone edits ONE file:             Each project = ONE file:

main.tf                              data/projects/
├── module "app-1" { }                ├── app-1.yaml
├── module "app-2" { }                ├── app-2.yaml
├── module "app-3" { }     ──►       ├── app-3.yaml
└── module "app-4" { }                └── app-4.yaml
    
💥 10 devs = merge conflicts          ✅ 10 devs = zero conflicts
   (all editing same file)               (each creates separate file)
```

**The Factory Engine** (written ONCE, never changed):
```hcl
locals {
  projects = {
    for f in fileset("data/projects", "**/*.yaml") :
    trimsuffix(f, ".yaml") => yamldecode(file("data/projects/${f}"))
  }
}

module "project_factory" {
  for_each        = local.projects
  source          = "./modules/project"
  billing_account = each.value.billing_account
  parent          = each.value.parent
  name            = each.key
}
```

**Backstage just drops a YAML file.** Terraform reads ALL YAML files and creates whatever it finds. Simple.

---

## The CI/CD Pipeline (How Code Gets to Production)

```
Developer pushes code
        │
        ▼
┌─── DEV Environment ──────────────────────────┐
│  init → validate → plan → test → APPLY       │──→ DEV Project
└───────────────────────────┬──────────────────┘
                            │ (auto-promote)
                            ▼
┌─── QA Environment ───────────────────────────┐
│  init → validate → plan → test → APPLY       │──→ QA Project
└───────────────────────────┬──────────────────┘
                            │ (manual approval ✋)
                            ▼
┌─── PROD Environment ────────────────────────┐
│  init → validate → plan → test → APPLY       │──→ PROD Project
└──────────────────────────────────────────────┘

All authenticated via WIF (Workload Identity Federation)
```

---

## The Cloud Run App Architecture (Where the App Lives)

```
┌──────────── Security Wall (VPC Service Controls) ────────────┐
│                                                               │
│  ┌─── GCP Service Project ───────────────────────┐            │
│  │                                                │            │
│  │  🔑 Secrets (DB password, username, etc.)      │            │
│  │  📦 Artifact Registry (Docker images)          │            │
│  │  🚀 Cloud Run (the app container)              │            │
│  │  ⚖️  Internal Load Balancer                    │            │
│  │                                                │            │
│  └────────────────────┬───────────────────────────┘            │
│                       │                                        │
│           (Private VPC Connector)                              │
│                       │                                        │
│  ┌────────────────────▼───────────────────────────┐            │
│  │  GCP Service Producer Project                   │            │
│  │  🐘 Cloud SQL Postgres (Database)               │            │
│  └─────────────────────────────────────────────────┘            │
│                                                               │
└───────────────────────────────────────────────────────────────┘
```

- App runs on **Cloud Run** (serverless — no servers to manage)
- Database runs in a **separate GCP project** (isolation)
- They talk through a **private tunnel** (VPC Connector)
- Users access through an **internal load balancer** (not public internet)
- Everything is inside a **VPC Service Controls** perimeter (data can't leak out)

---

## The Complete Demo — Start to Finish

```
MINUTE 0:  Cameron has NOTHING. Just a Backstage login.

═══════════════════════════════════════════════════
TEMPLATE 1: "GCP Developer DEV Environment"
═══════════════════════════════════════════════════
  Types: "bd3"
  Clicks: Create

  RESULT (after ~2 minutes):
    ✅ GCP Project created (hca-bd3-dev)
    ✅ IAM groups created
    ✅ Networking connected
    ✅ GitHub repo created (hca-bd3-nextdemo)
    ✅ Terraform workspace created & applied

═══════════════════════════════════════════════════
TEMPLATE 2: "Cloud Run App Capability Package"
═══════════════════════════════════════════════════
  Selects: project=hca-bd3, frontend=nextweb, LB=internal
  Clicks: Create

  RESULT (after ~9 minutes):
    ✅ PR created with Cloud Run Terraform
    ✅ PR merged → terraform apply
    ✅ Cloud Run service deployed
    ✅ Internal Load Balancer configured

═══════════════════════════════════════════════════
TEMPLATE 3: "GCP Cloud Run CI/CD via GitHub Actions"
═══════════════════════════════════════════════════
  Selects: service=nextweb, code=Vue.js, project=hca-bd3
  Clicks: Create

  RESULT (after ~3 minutes):
    ✅ App code repo created (hca-bd3-nextweb)
    ✅ Vue.js app scaffolded
    ✅ CI/CD pipeline running
    ✅ Dev/QA/Prod/Canary service definitions
    ✅ WIF access configured

═══════════════════════════════════════════════════

MINUTE 15: Cameron opens https://nextweb-dev.hca....
           → Sees a working Vue.js app showing 342 HCA facilities
           → Has CI/CD, canary deployments, multi-env promotion
           → All from clicking 3 forms. 🎉
```

---

## Summary Table

| What | How | Time |
|:---|:---|:---|
| GCP Project | Template 1 → API Wrapper → GCP Resource Manager | ~2 min |
| IAM Groups | Template 1 → Security Group Service → Identity API | 6 sec |
| Terraform Workspace | Template 1 → TF Wrapper → Terraform Cloud | 2 sec |
| GitHub Infra Repo | Template 1 → Backstage scaffolder → GitHub API | ~30 sec |
| Cloud Run Infra | Template 2 → PR → merge → terraform apply | ~9 min |
| Load Balancer | Template 2 → (part of Cloud Run Terraform) | (included) |
| App Code Repo | Template 3 → Backstage scaffolder → GitHub API | ~30 sec |
| CI/CD Pipeline | Template 3 → GitHub Actions injected into repo | ~2 min |
| Canary Deployments | Template 3 → workflow files in repo | (included) |
| Multi-env Promotion | Template 3 → dev/qa/prod service definitions | (included) |
| WIF for New Repo | Template 3 → Factory Pattern PR → merge | ~2 sec |
| **Live Running App** | **All 3 templates combined** | **~15 min total** |
