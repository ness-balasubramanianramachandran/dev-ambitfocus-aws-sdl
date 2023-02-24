locals {
  infrastructure_instance_type_obj = lookup(local.infrastructure_instance_types, var.infrastructure_instance_type, {})

  //BSMI network
  routable_vpc = var.infrastructure_dependencies.aws_account.network.routable_vpc
  nr_vpc       = var.infrastructure_dependencies.aws_account.network.nr_vpc

  snets = {
    "routable_front_end" = {
      "cidrs" = [for s in data.aws_subnet.routable_front_end : s.cidr_block]
      "ids"   = data.aws_subnets.routable_front_end.ids
    }
    "routable_app" = {
      "cidrs" = [for s in data.aws_subnet.routable_app : s.cidr_block]
      "ids"   = data.aws_subnets.routable_app.ids
    }
    "routable_rds" = {
      "cidrs" = [for s in data.aws_subnet.routable_rds : s.cidr_block]
      "ids"   = data.aws_subnets.routable_rds.ids
    }
    "routable_connectivity" = {
      "cidrs" = [for s in data.aws_subnet.routable_connectivity : s.cidr_block]
      "ids"   = data.aws_subnets.routable_connectivity.ids
    }
    "nr_compute" = {
      "cidrs" = [for s in data.aws_subnet.nr_compute : s.cidr_block]
      "ids"   = data.aws_subnets.nr_compute.ids
    }
    "nr_connectivity" = {
      "cidrs" = [for s in data.aws_subnet.nr_connectivity : s.cidr_block]
      "ids"   = data.aws_subnets.nr_connectivity.ids
    }
  }
  ad_cidrs = [
    "${var.infrastructure_dependencies.dns.domain_controller_ips[0]}/32",
    "${var.infrastructure_dependencies.dns.domain_controller_ips[1]}/32"
  ]
  // bootstrappers vars
  artifactory_bootstrapper_repo         = "abpb-generic-dev"
  artifactory_eks_bootstrapper_path     = "lambda-test/FIS.Bancware.Cloud.Aws.EKSAuth-0.0.0.15.zip"
  artifactory_harness_bootstrapper_path = "lambda-test/FIS.Bancware.Cloud.Aws.Harness-0.0.0.8.zip"
  harness_delegate_name                 = "bsmi-dev-delegate"
  harness_delegate_token                = data.vault_generic_secret.harness_delegate.data["delegate_token"]
  harness_account_id                    = data.vault_generic_secret.harness_delegate.data["account_id"]
  harness_delegate_profile              = data.vault_generic_secret.harness_delegate.data["delegate_profile"]

  // EKS vars
  cluster_name                    = "bsmi_dev"
  cluster_version                 = "1.21"
  cluster_log_retention_days      = 7
  cluster_subnet_ids              = local.snets.nr_connectivity.ids
  coredns_addon_version           = "v1.8.4-eksbuild.1"
  kube_proxy_addon_version        = "v1.21.2-eksbuild.2"
  vpc_cni_addon_version           = "v1.10.2-eksbuild.1"
  vpc_cni_addon_resolve_conflicts = "OVERWRITE"
  eks_alarms_email_subscription   = var.infrastructure_dependencies.monitoring.eks_alarms_email_subscription
  eks_secret_kms_config = {
    deletion_window_in_days = 30
    enable_key_rotation     = true
    policy                  = null
  }
  eks_managed_node_groups = merge(
    {
      "compute_cluster_ng" = {
        vpc_security_group_ids        = [aws_security_group.router_ingress.id]
        attach_cluster_security_group = true
        cluster_name                  = local.cluster_name
        subnet_ids                    = local.snets.nr_compute.ids
        instance_types                = [local.infrastructure_instance_type_obj.eks.ng.cc.instance_type]
        desired_size                  = local.infrastructure_instance_type_obj.eks.ng.cc.desired_size
        min_size                      = local.infrastructure_instance_type_obj.eks.ng.cc.min_size
        max_size                      = local.infrastructure_instance_type_obj.eks.ng.cc.max_size
        block_device_mappings = {
          "root" = {
            "device_name" = "/dev/xvda",
            "ebs" = {
              delete_on_termination = true
              encrypted             = true
              kms_key_id            = aws_kms_key.eks_ebs.arn
              volume_type           = local.infrastructure_instance_type_obj.eks.ng.cc.ebs_volume_type
              volume_size           = local.infrastructure_instance_type_obj.eks.ng.cc.ebs_volume_size
            }
          },
        }
      }
    },
    { for s in local.snets.nr_compute.ids :
      "calc_engine_${index(local.snets.nr_compute.ids, s)}" => {
        subnet_ids     = [s]
        instance_types = [local.infrastructure_instance_type_obj.eks.ng.ce.instance_type]
        desired_size   = local.infrastructure_instance_type_obj.eks.ng.ce.desired_size
        min_size       = local.infrastructure_instance_type_obj.eks.ng.ce.min_size
        max_size       = local.infrastructure_instance_type_obj.eks.ng.ce.max_size
        block_device_mappings = {
          "root" = {
            "device_name" = "/dev/xvda",
            "ebs" = {
              delete_on_termination = true
              encrypted             = true
              kms_key_id            = aws_kms_key.eks_ebs.arn
              volume_type           = local.infrastructure_instance_type_obj.eks.ng.ce.ebs_volume_type
              volume_size           = local.infrastructure_instance_type_obj.eks.ng.ce.ebs_volume_size
            }
          },
        },
        labels = {
          "bsmi.fis.com/node-type" = "calculation-engine"
        },
        taints = {
          "bsmi.fis.com/node-type" = {
            value  = "calculation-engine"
            effect = "NoSchedule"
          }
        }
      }
  })

  eks_system_masters_iam_role_arn = var.infrastructure_dependencies.aws_account.iam.roles.account-admin-arn

  log_retention_days = 30
  step_function_lambdas = toset([
    for lambda_name in [
      "cpo-backend-create-namespace",
      "cpo-backend-create-namespace-secrets",
      "cpo-backend-deploy-router",
      "cpo-backend-create-router-service",
      "cpo-backend-deploy-calc-engine",
      "cpo-backend-evaluate-heartbeat-status",
      "cpo-backend-teardown",
    ] :
    {
      name = "${local.name_prefix}${lambda_name}"
      arn  = "arn:${data.aws_partition.current.id}:lambda:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:function:${local.name_prefix}${lambda_name}"
    }
  ])

  step_function_handler_root = "FIS.BalanceSheetManager.Aws.CPO::FIS.BalanceSheetManager.Aws.CPO.StepFunctions"
  step_function_handlers = {
    create_namespace          = "${local.step_function_handler_root}::CreateNamespace"
    deploy_router             = "${local.step_function_handler_root}::DeployRouter"
    deploy_calc_engine        = "${local.step_function_handler_root}::DeployCalcEngine"
    evaluate-heartbeat-status = "${local.step_function_handler_root}::EvaluateHeartbeatStatus"
    teardown                  = "${local.step_function_handler_root}::TearDown"
  }

  step_function_env_vars = {
    EKS_CLUSTER_NAME = local.cluster_name
  }

  //Mssql Server
  mssql_server_ami             = "ami-013827243f5b07ffc"
  mssql_server_instance_prefix = "vwawsbsmidb${var.environment_code}0"
  mssql_server_userdata_params = {
    VAULT_DOWNLOAD_URL = "https://releases.hashicorp.com/vault/1.11.2/vault_1.11.2_windows_amd64.zip"
    VAULT_SERVER       = "vamazhashivault.fisdev.local"
    VAULT_NAMESPACE    = "AMBIT-FOCUS"
    VAULT_ROLE         = "${local.name_prefix}bsmi-mssqlserver"
    VAULT_KV           = "bsmi-${var.environment_code}-kv"
    ANSIBLE_USER       = "ansible"
    VMNAME             = "override_this_name"
    DC_HOST            = "VWAWSNVDC01.fisdev.local"
    DC_FULLOUPATH      = "OU=AMBIT_FOCUS,OU=AWS_NorthVirginia,OU=AWS,DC=fisdev,DC=local"
    DC_DOMAIN          = "FISDEV.LOCAL"
  }
  //Application Server
  application_server_ami             = "ami-013827243f5b07ffc"
  application_server_instance_prefix = "vwawsbsmias${var.environment_code}0"
  application_server_userdata_params = {
    VAULT_DOWNLOAD_URL = "https://releases.hashicorp.com/vault/1.11.2/vault_1.11.2_windows_amd64.zip"
    VAULT_SERVER       = "vamazhashivault.fisdev.local"
    VAULT_NAMESPACE    = "AMBIT-FOCUS"
    VAULT_ROLE         = "${local.name_prefix}bsmi-appserver"
    VAULT_KV           = "bsmi-${var.environment_code}-kv"
    ANSIBLE_USER       = "ansible"
    VMNAME             = "override_this"
    DC_HOST            = "VWAWSNVDC01.fisdev.local"
    DC_FULLOUPATH      = "OU=AMBIT_FOCUS,OU=AWS_NorthVirginia,OU=AWS,DC=fisdev,DC=local"
    DC_DOMAIN          = "FISDEV.LOCAL"
  }
  //File Gateway
  file_gateway_ami           = "ami-044238dc0ff5b8208"
  file_gateway_instance_type = "t3.medium"
  file_gateway_timezone      = "GMT" 

  // RDS SQL 
  rds_sql_port           = "2433"
  db_engine              = "sqlserver-se"
  db_engine_version      = "15.00.4073.23.v1" //todo: switch to 14.0.3436.1 (2017) due to SSAS...
  db_license_model       = "license-included"
  rds_sql_password       = data.vault_generic_secret.rds_sql_credentials.data["value"]
  rds_sql_username       = "sqladmin"
  database_backup_window = "00:00-04:00"

  cloudwatch_metric_prometheus_namespace = "EKS/Prometheus"

  //FIS domain user and password
  focus_ADUSER = data.vault_generic_secret.fsx_ad_user.data["username"]
  focus_ADPASS = data.vault_generic_secret.fsx_ad_user.data["password"]

  name_prefix = "${var.environment_code}-"
  environment_code2type = {
    "de" = "Dev"
  }
  default_tags = tomap({
    "AppGroupEmail"   = "AmbitRisk.EMEA.Help@fisglobal.com"
    "BUC"             = "4012.523420.9820..0000.0000.3117"
    "CustomerCRMID"   = "${var.customer_crmid}"
    "EnvironmentType" = lookup(local.environment_code2type, var.environment_code, "Dev")
    "SupportGroup"    = "Ambit Risk EMEA"
  })
  ec2_tags = tomap({
    "SolutionCentralID" = "12662"
    "MaintenanceWindow" = "Never"
    "Tier"              = "App"
    "SLA"               = "99.5"
    "OnHours"           = "${var.on_hours}"
    "ExpirationDate"    = "Never"
  })
  s3_tags = tomap({
    "SLA"            = "99.99"
    "NPI"            = "False"
    "ExpirationDate" = "Never"
  })
}
