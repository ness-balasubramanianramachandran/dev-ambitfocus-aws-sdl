resource "aws_cloudwatch_metric_alarm" "external_dns_restart" {
  alarm_name          = "${local.cluster_name}/external-dns-restart"
  alarm_description   = "External DNS pod has restarted"
  evaluation_periods  = 5
  datapoints_to_alarm = 1
  period              = 60
  namespace           = "ContainerInsights"
  metric_name         = "pod_number_of_container_restarts"
  statistic           = "Sum"
  dimensions = {
    ClusterName = local.cluster_name
    Namespace   = "external-dns"
    PodName     = "external-dns"
  }
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0

  # TODO: pass in SNS topic ARNs once escalation procedures are defined
  alarm_actions             = []
  ok_actions                = []
  insufficient_data_actions = []

  tags = merge(local.default_tags, { Name = "${local.cluster_name}/external-dns-restart" })
}

resource "aws_cloudwatch_metric_alarm" "external_dns_unavailable" {
  alarm_name          = "${local.cluster_name}/external-dns-unavailable"
  alarm_description   = "External DNS pod is unavailable"
  evaluation_periods  = 10
  datapoints_to_alarm = 10
  period              = 60
  namespace           = local.cloudwatch_metric_prometheus_namespace
  metric_name         = "kube_deployment_status_replicas_unavailable"
  statistic           = "Maximum"
  dimensions = {
    ClusterName = local.cluster_name
    Namespace   = "external-dns"
    Deployment  = "external-dns"
  }
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0

  # TODO: pass in SNS topic ARNs once escalation procedures are defined
  alarm_actions             = []
  ok_actions                = []
  insufficient_data_actions = []

  tags = merge(local.default_tags, { Name = "${local.cluster_name}/external-dns-unavailable" })
}

resource "aws_cloudwatch_metric_alarm" "external_dns_errors" {
  alarm_name          = "${local.cluster_name}/external-dns-errors"
  alarm_description   = "External DNS is experiencing errors syncing records between Kubernetes and Route53"
  evaluation_periods  = 5
  datapoints_to_alarm = 1
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0

  metric_query {
    id = "registry_errors"
    metric {
      metric_name = "external_dns_registry_errors_total"
      namespace   = local.cloudwatch_metric_prometheus_namespace
      period      = 60
      stat        = "Sum"
      dimensions = {
        ClusterName = local.cluster_name
      }
    }
  }

  metric_query {
    id = "source_errors"
    metric {
      metric_name = "external_dns_source_errors_total"
      namespace   = local.cloudwatch_metric_prometheus_namespace
      period      = 60
      stat        = "Sum"
      dimensions = {
        ClusterName = local.cluster_name
      }
    }
  }

  metric_query {
    id          = "external_dns_errors"
    expression  = "SUM([registry_errors,source_errors])"
    label       = "Total Errors"
    return_data = "true"
  }

  # TODO: pass in SNS topic ARNs once escalation procedures are defined
  alarm_actions             = []
  ok_actions                = []
  insufficient_data_actions = []

  tags = merge(local.default_tags, { Name = "${local.cluster_name}/external-dns-errors" })
}

resource "aws_cloudwatch_metric_alarm" "cluster_autoscaler_errors" {
  alarm_name          = "${local.cluster_name}/cluster-autoscaler-errors"
  alarm_description   = "Cluster Autoscaler is experiencing errors"
  evaluation_periods  = 5
  datapoints_to_alarm = 1
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0

  # the cluster_autoscaler_errors_total is only emitted if an error happens, so need to use FILL to set default value to 0
  # otherwise alarm will enter InsufficientData state
  metric_query {
    id = "cluster_autoscaler_errors_total"
    metric {
      metric_name = "cluster_autoscaler_errors_total"
      namespace   = local.cloudwatch_metric_prometheus_namespace
      period      = 60
      stat        = "Sum"
      dimensions = {
        ClusterName = local.cluster_name
      }
    }
  }

  metric_query {
    id          = "errors_total"
    expression  = "FILL(cluster_autoscaler_errors_total, 0)"
    label       = "Errors"
    return_data = "true"
  }

  tags = merge(local.default_tags, { Name = "${local.cluster_name}/cluster-autoscaler-errors" })
}

resource "aws_cloudwatch_metric_alarm" "cluster_autoscaler_unneeded_nodes" {
  alarm_name          = "${local.cluster_name}/cluster-autoscaler-unneeded-nodes-sustained"
  alarm_description   = "Cluster Autoscaler indicates unneeded nodes are present for a sustained period"
  evaluation_periods  = 10
  datapoints_to_alarm = 10
  period              = 60
  namespace           = local.cloudwatch_metric_prometheus_namespace
  metric_name         = "cluster_autoscaler_unneeded_nodes_count"
  statistic           = "Maximum"
  dimensions = {
    ClusterName = local.cluster_name
  }
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0

  # TODO: pass in SNS topic ARNs once escalation procedures are defined
  alarm_actions             = []
  ok_actions                = []
  insufficient_data_actions = []

  tags = merge(local.default_tags, { Name = "${local.cluster_name}/cluster-autoscaler-unneeded-nodes-sustained" })
}

resource "aws_cloudwatch_metric_alarm" "cluster_autoscaler_failed_scale_ups" {
  alarm_name          = "${local.cluster_name}/cluster-autoscaler-failed-scale-up"
  alarm_description   = "Cluster Autoscaler experienced failure(s) scaling up nodes"
  evaluation_periods  = 5
  datapoints_to_alarm = 1
  comparison_operator = "GreaterThanThreshold"
  threshold           = 0

  # the cluster_autoscaler_failed_scale_ups_total is only emitted if a failure happens, so need to use FILL to set default value to 0
  # otherwise alarm will enter InsufficientData state
  metric_query {
    id = "cluster_autoscaler_failed_scale_ups_total"
    metric {
      metric_name = "cluster_autoscaler_failed_scale_ups_total"
      namespace   = local.cloudwatch_metric_prometheus_namespace
      period      = 60
      stat        = "Sum"
      dimensions = {
        ClusterName = local.cluster_name
      }
    }
  }

  metric_query {
    id          = "failed_scale_ups_total"
    expression  = "FILL(cluster_autoscaler_failed_scale_ups_total, 0)"
    label       = "Failed Scale Ups"
    return_data = "true"
  }

  tags = merge(local.default_tags, { Name = "${local.cluster_name}/cluster-autoscaler-failed-scale-up" })
}
