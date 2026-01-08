# ------------------------------ ------------------------------ ------------------------------
# this file is for to install & continuously manage the argocd in the K8 cluster using argocd..
# THIS IS CHILD argo cd application whose only job is install argocd, keep it in sync with git repo
# recreate it if someone breaks it
# ------------------------------ ------------------------------ ------------------------------

# installign through terraform with helm provider ok k8 cluster


# we are creating namespace even before argocd is installed cause argocd will use this namespace to install argocd
# why to use this "kubernetes_namespace" why now GKE or somehitng google resource casue, 
# namespce are managed inside by the k8, gcp or gke manages only the cluster
# 1. Create the Namespace
resource "kubernetes_namespace_v1" "argocd" {
  metadata {
    name = "argocd"
  }

  # Wait for the cluster to exist first! this checks until the nodes gets created and started...
  depends_on = [
    # google_container_node_pool.primary_nodes
    module.gke
  ]

}

# 2. Install ArgoCD via Helm
resource "helm_release" "argocd" {
  name       = "argocd"
  repository = "https://argoproj.github.io/argo-helm"
  chart      = "argo-cd"
  version    = "5.46.7" # Stable version

  # this tells k8 namespace to install where terraform created namespace
  # as metadata is actually a list of objects, we are using index 0 to get the name
  namespace = kubernetes_namespace_v1.argocd.metadata[0].name

  # CRITICAL: Must wait for nodes to be online
  depends_on = [
    #google_container_node_pool.primary_nodes
    module.gke
  ]


  # Configuration & this is helm value overriding 
  # we are exposing the argocd with cluster ip cause we are using port forwarding to access it
  # set {
  #   name  = "server.service.type"
  #   value = "ClusterIP" # We will use Port Forwarding to access it
  # }

  # # Disable HA for now to save resources (optional)
  # set {
  #   name  = "server.replicas"
  #   value = "1"
  # }

  ## the above throwed up a error using the set, so changed to bewlo ok 
  values = [
    yamlencode({
      server = {
        service = {
          type = "ClusterIP"
        }
        replicas = 1 # Run only 1 pod to save money
      }
    })
  ]
}
