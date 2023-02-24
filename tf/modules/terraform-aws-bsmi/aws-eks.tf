module "eks_cap_dev" {
  source  = "vlmaztform01.fisdev.local/FIS-Cloud-Services/eks-cap-dev/aws"
  version = "1.0.8"
  providers = {
    aws                 = aws,
    aws.cluster_creator = aws.cluster_creator
  }

  cluster_log_retention_days                    = local.cluster_log_retention_days
  cluster_name                                  = local.cluster_name
  cluster_subnet_ids                            = local.cluster_subnet_ids
  cluster_version                               = local.cluster_version
  coredns_addon_version                         = local.coredns_addon_version
  kube_proxy_addon_version                      = local.kube_proxy_addon_version
  vpc_cni_addon_version                         = local.vpc_cni_addon_version
  vpc_cni_addon_resolve_conflicts               = local.vpc_cni_addon_resolve_conflicts
  eks_managed_node_groups                       = local.eks_managed_node_groups
  cluster_alarms_default_actions                = [data.aws_sns_topic.eks_alarms.arn]
  cluster_administrator_attach_lifecycle_policy = true
  cluster_administrator_attach_describe_policy  = true
  aws_auth_lambda_manage                        = true
  aws_auth_lambda_filename                      = data.artifactory_file.eks_bootstrapper.output_path
  aws_auth_lambda_handler                       = "FIS.Bancware.Cloud.Aws.EKSAuth::FIS.Bancware.Cloud.Aws.EKSAuth.AuthConfigurer::Apply"
  aws_auth_lambda_runtime                       = "dotnet6"
  aws_auth_iam_role_mappings = [
    {
      RoleArn  = local.eks_system_masters_iam_role_arn,
      Username = "bsmi_devops",
      Groups   = ["system:masters"]
    },
    {
      RoleArn  = aws_iam_role.harness_bootstrapper.arn,
      Username = "harness_bootstrapper",
      Groups   = ["system:masters"]
    },
    {
      RoleArn  = aws_iam_role.cpo_backend_lambda.arn,
      Username = "bsmi-orchestration-backend",
      Groups   = ["bsmi-orchestration"]
    },
    {
      RoleArn  = aws_iam_role.orchestration_lambda.arn,
      Username = "bsmi-orchestration-api",
      Groups   = ["bsmi-orchestration"]
    }
  ]

  iam_roles_for_service_accounts = {
    //https://docs.harness.io/article/lo9taq0pze-1-delegate-and-connectors-for-lambda#step_1_create_roles_and_policies
    harness_delegate = {
      name_use_prefix            = false,
      role_name                  = "${local.cluster_name}-harness-delegate",
      role_description           = "IRSA for ${local.cluster_name} Harness delegate",
      kubernetes_namespace       = "harness-delegate",          // the delegate's namespace
      kubernetes_service_account = local.harness_delegate_name, // the delegate's name/service account
      iam_policies               = [],
      iam_policy_arns = [
        "arn:aws:iam::aws:policy/AWSLambda_FullAccess",
        "${aws_iam_policy.harness_delegate.arn}"
      ]
    },
    external_dns = {
      name_use_prefix            = false,
      role_name                  = "${local.cluster_name}-external-dns"
      role_description           = "IRSA for ${local.cluster_name} external-dns"
      kubernetes_namespace       = "external-dns"
      kubernetes_service_account = "external-dns",
      iam_policies               = [],
      iam_policy_arns = [
        aws_iam_policy.external_dns.arn
      ]
    }
  }

  # Enable common CloudWatch Alarms from module
  aws_otel_ci_daemonset_restart_alarm_create      = true
  aws_otel_ci_daemonset_unavailable_alarm_create  = true
  aws_otel_ci_deployment_restart_alarm_create     = true
  aws_otel_ci_deployment_unavailable_alarm_create = true
  cluster_autoscaler_restart_alarm_create         = true
  cluster_autoscaler_unavailable_alarm_create     = true
  core_dns_restart_alarm_create                   = true
  core_dns_unavailable_alarm_create               = true
  failed_node_count_alarm_create                  = true
  fluent_bit_linux_restart_alarm_create           = true
  fluent_bit_linux_unavailable_alarm_create       = true
  kube_proxy_restart_alarm_create                 = true
  kube_proxy_unavailable_alarm_create             = true
  kube_state_metrics_restart_alarm_create         = true
  kube_state_metrics_unavailable_alarm_create     = true
  pod_cpu_utilization_alarm_create                = true
  pod_memory_utilization_alarm_create             = true
  vpc_cni_restart_alarm_create                    = true
  vpc_cni_unavailable_alarm_create                = true

  tag_app_group_email  = local.default_tags.AppGroupEmail
  tag_buc              = local.default_tags.BUC
  tag_customer_crmid   = local.default_tags.CustomerCRMID
  tag_environment_type = local.default_tags.EnvironmentType
  tag_support_group    = local.default_tags.SupportGroup
}

##################################################################################################

// Add ingress rules to the EKS control plane

resource "aws_security_group_rule" "orchestration_lambda_ingress" {
  description       = "allow orchestration lambdas ingress to Kubernetes control plane"
  security_group_id = module.eks_cap_dev.cluster_kubernetes_api_security_group_id

  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = module.orchestration_api.lambda_security_group_id
}

resource "aws_security_group_rule" "orchestration_step_function_lambda_ingress" {
  description       = "allow orchestration step function lambdas ingress to Kubernetes control plane"
  security_group_id = module.eks_cap_dev.cluster_kubernetes_api_security_group_id

  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.cpo_backend_lambda.id
}
resource "aws_security_group" "router_ingress" {
  name        = "${local.name_prefix}router-ingress"
  description = "Allow TCP from BSMI client to router."
  vpc_id      = local.nr_vpc.id
  ingress {
    description = "Open communication between BSMI and Router on port 5606"
    from_port   = 5606
    to_port     = 5606
    protocol    = "tcp"
    cidr_blocks = local.snets.routable_app.cidrs
  }
  tags = merge(local.default_tags, {
    Name = "${local.name_prefix}router-ingress"
  })
}
