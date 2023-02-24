locals {
  infrastructure_dependencies = {
    vault = {
      namespace = "AMBIT-FOCUS"
      url       = "https://vamazhashivault.fisdev.local/"
    }
    artifactory = {
      url = "https://artifactory.fis.dev/artifactory"
    }
    dns = {
      domain_controller_ips = [
        "10.7.220.112",
        "10.7.220.113"
      ]
      domains = {
        "fisdev-local" = "fisdev.local",
        "fnfis-com"    = "fnfis.com"
      }
      adexternal = {
        "external_id"    = "S-1-5-21-527237240-2000478354-839522115-1731175"
      }     
    }
    aws_account = {
      network = {
        routable_vpc = data.aws_vpc.routable_vpc
        nr_vpc       = data.aws_vpc.nr_vpc
        snet_regex = {
          routable_front_end    = "sdl-ambit-focus-frontend-snet-*"
          routable_app          = "sdl-ambit-focus-app-snet-*"
          routable_rds          = "sdl-ambit-focus-rds-snet-*"
          routable_connectivity = "sdl-ambit-focus-connectivity-snet-*"
          nr_connectivity       = "ambit-focus-nr-connectivity-snet-*"
          nr_compute            = "ambit-focus-nr-eks-snet-*"
        }
      }
      iam = {
        roles = {
          "account-admin-arn" = "arn:aws:iam::599774589777:role/AWSReservedSSO_PS-Ambit-Focus_e42ff5c9d3ba06b4"
        }
      }
    }
    access = {
      rdp_cidrs = ["10.0.0.0/8"]
    }

    monitoring = {
      eks_alarms_email_subscription = "milos.radenkovic@fisglobal.com"
    }
  }

  timezone = "Eastern Standard Time"
  on_hours = "Always"

}
