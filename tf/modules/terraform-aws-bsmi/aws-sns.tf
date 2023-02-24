// Create SNS topics for EKS alarm actions

resource "aws_sns_topic" "eks_alarms" {
  name              = local.cluster_name
  kms_master_key_id = aws_kms_key.sns_eks_cmk.arn
}
resource "aws_sns_topic_subscription" "email" {
  topic_arn = aws_sns_topic.eks_alarms.arn
  protocol  = "email"
  endpoint  = var.infrastructure_dependencies.monitoring.eks_alarms_email_subscription
}
