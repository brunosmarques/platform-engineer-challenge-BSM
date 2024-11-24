# ServiceAccount
resource "kubernetes_service_account" "pineapple" {
  metadata {
    name = "pineapple"
    namespace = kubernetes_namespace.pizza.metadata[0].name
  }
}  

# Role
resource "kubernetes_role" "read_pods" {
  metadata {
    name      = "read-pods" 
    namespace = kubernetes_namespace.pizza.metadata[0].name 
  }

  rule {
    api_groups = [""]
    resources  = ["pods"]
    verbs      = ["get", "watch", "list"]
  }
}  

# Binding
resource "kubernetes_role_binding" "pineapple_read_pods" {
  metadata {
    name      = "pineapple_read_pods"
    namespace = kubernetes_namespace.pizza.metadata[0].name
  }

  role_ref {
    api_group = "rbac.authorization.k8s.io"
    kind      = "Role"
    name      = kubernetes_role.read_pods.metadata[0].name
  }

  subject {
    kind      = "ServiceAccount"
    name      = kubernetes_service_account.pineapple.metadata[0].name
    namespace = kubernetes_namespace.pizza.metadata[0].name 
  }
}