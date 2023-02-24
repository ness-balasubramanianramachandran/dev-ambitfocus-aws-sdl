provider "aws" {

  assume_role {
    role_arn = "arn:aws:iam::599774589777:role/TFERole"
  }
}
provider "aws" {
  alias = "cluster_creator"
  assume_role {
    role_arn = "arn:aws:iam::599774589777:role/bsmi_dev_eks_cluster_administrator"
  }
}
provider "vault" {
  alias     = "bsmi"
  namespace = local.infrastructure_dependencies.vault.namespace
  address   = local.infrastructure_dependencies.vault.url
  auth_login {
    path      = "auth/approle/login"
    namespace = local.infrastructure_dependencies.vault.namespace
    parameters = {
      role_id   = var.vault_approle_role_id
      secret_id = var.vault_approle_secret_id
    }
  }
}
provider "artifactory" {
  check_license = false # TODO: remove once the API Key is created by the serviceAccount
}
