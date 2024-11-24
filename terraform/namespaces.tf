resource "kubernetes_namespace" "pizza" {
  metadata {
    name = "pizza"
  }
}

resource "kubernetes_namespace" "burguer" {
  metadata {
    name = "burguer"
  }
}