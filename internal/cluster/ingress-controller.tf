resource "yandex_iam_service_account" "k8s_alb_ingress" {
  folder_id = local.folder_id

  name        = "k8s-alb-ingress"
  description = "Service account to manage ALB Ingress resources"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_alb_ingress_alb_editor" {
  folder_id = local.folder_id

  member = "serviceAccount:${yandex_iam_service_account.k8s_alb_ingress.id}"
  role   = "alb.editor"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_alb_ingress_vpc_public_admin" {
  folder_id = local.folder_id

  member = "serviceAccount:${yandex_iam_service_account.k8s_alb_ingress.id}"
  role   = "vpc.publicAdmin"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_alb_ingress_certificate_manager_certificates_downloader" {
  folder_id = local.folder_id

  member = "serviceAccount:${yandex_iam_service_account.k8s_alb_ingress.id}"
  role   = "certificate-manager.certificates.downloader"
}

resource "yandex_resourcemanager_folder_iam_member" "k8s_alb_ingress_compute_viewer" {
  folder_id = local.folder_id

  member = "serviceAccount:${yandex_iam_service_account.k8s_alb_ingress.id}"
  role   = "compute.viewer"
}

module "k8s_alb_ingress_sa_key" {
  source = "../../modules/service-account-key"

  sa_id       = yandex_iam_service_account.k8s_alb_ingress.id
  description = "Key for ALB Ingress controller"
}

resource "kubernetes_namespace" "yc_alb_ingress_controller" {
  metadata {
    name = "yc-alb-ingress-controller"
  }

  depends_on = [yandex_kubernetes_node_group.this]
}

resource "helm_release" "yc_alb_ingress_controller" {
  repository = "oci://cr.yandex"
  chart      = "yc-marketplace/yandex-cloud/yc-alb-ingress/yc-alb-ingress-controller-chart"
  version    = "v0.1.16"

  namespace = kubernetes_namespace.yc_alb_ingress_controller.metadata[0].name
  name      = "yc-alb-ingress-controller"

  atomic            = true
  dependency_update = true
  force_update      = true
  max_history       = 1
  wait_for_jobs     = true
  cleanup_on_fail   = true

  values = [
    yamlencode({
      folderId       = local.folder_id
      clusterId      = yandex_kubernetes_cluster.this.id
      saKeySecretKey = module.k8s_alb_ingress_sa_key.json
    }),
  ]

  depends_on = [
    kubernetes_namespace.yc_alb_ingress_controller,
    yandex_resourcemanager_folder_iam_member.k8s_alb_ingress_alb_editor,
    yandex_resourcemanager_folder_iam_member.k8s_alb_ingress_vpc_public_admin,
    yandex_resourcemanager_folder_iam_member.k8s_alb_ingress_certificate_manager_certificates_downloader,
    yandex_resourcemanager_folder_iam_member.k8s_alb_ingress_compute_viewer,
  ]
}

