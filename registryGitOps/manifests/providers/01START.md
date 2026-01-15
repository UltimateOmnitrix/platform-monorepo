Now the actual runtime flow
Step 1

Crossplane sees gcp.yml → installs GCP provider.

Step 2

Crossplane sees runtimeConfigRef → loads controller-config.yml.

Step 3

controller-config.yml says → run provider pod as ServiceAccount crossplane-gcp.

Step 4

Pod starts as ServiceAccount crossplane-gcp.

Step 5

Kubernetes sees crossplane-gcp has annotation to Google Cloud Service Account.

Step 6

GKE injects Google Cloud identity into the pod.

Now the provider pod is logged in to Google Cloud.



Terraform creates Google SA + permissions + trust from the file prod/gke/main.tf
        ↓
service-account.yml creates Kubernetes SA + annotation
        ↓
controller-config.yml tells Crossplane to use that SA
        ↓
gcp.yml installs provider pod as that SA
        ↓
GKE injects Google identity into provider pod
        ↓
gcp-config.yml tells provider which project + use injected identity
        ↓
testingCreateBucket.yml requests bucket
        ↓
Provider calls Google API → Bucket created
