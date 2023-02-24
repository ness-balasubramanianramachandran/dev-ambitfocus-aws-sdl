/**
 * File provided as part of base bitbucket scaffolding
 * this file should contain output variables.
 */

data "terraform_remote_state" "dev-gateway-primary-aws" {
  backend = "remote"

  config = {
    hostname     = "vlmaztform01.fisdev.local"
    organization = "FIS-Cloud-Services"
    workspaces = {
      name = "dev-gateway-primary-aws"
    }
  }
}
