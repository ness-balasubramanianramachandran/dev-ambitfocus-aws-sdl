resource "aws_sqs_queue" "CreateDeployment" {
    name = "CreateDeployment"
    delay_seconds = 0
    max_message_size = 2048
    message_retention_seconds = 172800
    receive_wait_time_seconds = 5
    kms_master_key_id = aws_kms_key.sqs_dlq.key_id
    kms_data_key_reuse_period_seconds = 300
    tags = merge(local.default_tags, { "Name" = "CreateDeployment" }) 
}

resource "aws_sqs_queue" "CreateNamespace" {
    name = "CreateNamespace"
    delay_seconds = 0
    max_message_size = 2048
    message_retention_seconds = 172800
    receive_wait_time_seconds = 5
    kms_master_key_id = aws_kms_key.sqs_dlq.key_id
    kms_data_key_reuse_period_seconds = 300
    tags = merge(local.default_tags, { "Name" = "CreateNamespace" }) 
}

resource "aws_sqs_queue" "GetNamespace" {
    name = "GetNamespace"
    delay_seconds = 0
    max_message_size = 2048
    message_retention_seconds = 172800
    receive_wait_time_seconds = 5
    kms_master_key_id = aws_kms_key.sqs_dlq.key_id
    kms_data_key_reuse_period_seconds = 300
    tags = merge(local.default_tags, { "Name" = "GetNamespace" }) 
}

resource "aws_sqs_queue" "GetPodStatus" {
    name = "GetPodStatus"
    delay_seconds = 0
    max_message_size = 2048
    message_retention_seconds = 172800
    receive_wait_time_seconds = 5
    kms_master_key_id = aws_kms_key.sqs_dlq.key_id
    kms_data_key_reuse_period_seconds = 300
    tags = merge(local.default_tags, { "Name" = "GetPodStatus" }) 
}

resource "aws_sqs_queue" "DeleteNamespace" {
    name = "DeleteNamespace"
    delay_seconds = 0
    max_message_size = 2048
    message_retention_seconds = 172800
    receive_wait_time_seconds = 5
    kms_master_key_id = aws_kms_key.sqs_dlq.key_id
    kms_data_key_reuse_period_seconds = 300
    tags = merge(local.default_tags, { "Name" = "DeleteNamespace" }) 
}