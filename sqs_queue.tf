resource "aws_sqs_queue" "this" {
  name                              = local.sqs_queue_name
  visibility_timeout_seconds        = var.visibility_timeout_seconds
  message_retention_seconds         = var.message_retention_seconds
  max_message_size                  = var.max_message_size
  delay_seconds                     = var.delay_seconds
  receive_wait_time_seconds         = var.delay_seconds
  kms_master_key_id                 = var.kms_master_key_id
  kms_data_key_reuse_period_seconds = try(var.kms_master_key_id, null) != null ? var.kms_data_key_reuse_period_seconds : null
  sqs_managed_sse_enabled           = var.sse_enabled ? true : null
  policy                            = data.aws_iam_policy_document.sqs.json
  redrive_policy                    = try(var.dead_letter_queue.enabled, false) ? "{\"deadLetterTargetArn\":\"${aws_sqs_queue.this-dlq[0].arn}\",\"maxReceiveCount\":${try(var.dead_letter_queue.redrive_max_receive_count, 5)}}" : null
  fifo_queue                        = var.fifo_queue
  content_based_deduplication       = var.fifo_queue ? var.content_based_deduplication : null
  tags                              = local.tags
  provider                          = aws.this
}

resource "aws_sqs_queue" "this-dlq" {
  count                             = try(var.dead_letter_queue.enabled, false) ? 1 : 0
  name                              = local.sqs_dlq_name
  message_retention_seconds         = try(var.dead_letter_queue.message_retention_seconds, 1209600)
  kms_master_key_id                 = var.kms_master_key_id
  kms_data_key_reuse_period_seconds = try(var.kms_master_key_id, null) != null ? var.kms_data_key_reuse_period_seconds : null
  tags                              = local.tags
  provider                          = aws.this
}

data "aws_iam_policy_document" "sqs" {
  statement {
    effect = "Allow"
    principals {
      type        = "AWS"
      identifiers = ["arn:aws:iam::${local.aws.account.id}:root"]
    }
    actions = [
      "sqs:*"
    ]
    resources = [
      "arn:aws:sqs:${local.aws.region.name}:${local.aws.account.id}:${local.sqs_queue_name}"
    ]
  }

  dynamic "statement" {
    for_each = var.policy_sns
    content {
      effect = "Allow"
      principals {
        type        = "Service"
        identifiers = ["sns.amazonaws.com"]
      }
      actions = [
        "sqs:SendMessage"
      ]
      resources = [
        "arn:aws:sqs:${local.aws.region.name}:${local.aws.account.id}:${local.sqs_queue_name}"
      ]
      condition {
        test     = "ArnEquals"
        variable = "aws:SourceArn"
        values   = [statement.value]
      }
    }
  }

  dynamic "statement" {
    for_each = var.policy_s3
    content {
      effect = "Allow"
      principals {
        type        = "Service"
        identifiers = ["s3.amazonaws.com"]
      }
      actions = [
        "sqs:SendMessage"
      ]
      resources = [
        "arn:aws:sqs:${local.aws.region.name}:${local.aws.account.id}:${local.sqs_queue_name}"
      ]
      condition {
        test     = "ArnEquals"
        variable = "aws:SourceArn"
        values   = [statement.value]
      }
    }
  }
  provider = aws.this
}
