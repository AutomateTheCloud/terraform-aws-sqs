# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

locals {
  fifo                      = var.fifo != null
  dead_letter_queue_enabled = try(var.dead_letter_queue.enabled, false)

  sqs_queue_name             = local.fifo ? "${var.name}.fifo" : var.name
  sqs_dead_letter_queue_name = local.fifo ? "${var.name}-dlq.fifo" : "${var.name}-dlq"

  # SSE-SQS unless a KMS key is given. The two settings cannot both be set.
  kms_enabled = var.encryption.kms_key_id != null

  queue_arn = aws_sqs_queue.this.arn

  # Every statement the queue policy can contain, each switched on by an input. A policy
  # is created only when at least one statement is switched on.
  sqs_queue_policy_statements = concat(
    # Require Encrypted Transport
    [for s in [{
      Sid       = "RequireEncryptedTransport"
      Effect    = "Deny"
      Principal = "*"
      Action    = "sqs:*"
      Resource  = local.queue_arn
      Condition = { Bool = { "aws:SecureTransport" = "false" } }
    }] : s if var.policy.require_encrypted_transport],

    # Amazon SNS topics
    [for s in [{
      Sid       = "AllowSNSTopics"
      Effect    = "Allow"
      Principal = { Service = "sns.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = local.queue_arn
      Condition = { ArnLike = { "aws:SourceArn" = var.policy.sns_topic_arns } }
    }] : s if length(var.policy.sns_topic_arns) > 0],

    # Amazon S3 event notifications, from buckets in the queue's own account. A bucket
    # ARN has no account ID in it, so the account is checked separately.
    [for s in [{
      Sid       = "AllowS3BucketNotifications"
      Effect    = "Allow"
      Principal = { Service = "s3.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = local.queue_arn
      Condition = {
        ArnLike      = { "aws:SourceArn" = var.policy.s3_bucket_arns }
        StringEquals = { "aws:SourceAccount" = local.aws.account.id }
      }
    }] : s if length(var.policy.s3_bucket_arns) > 0],

    # Statements from the caller's own policy documents. A statement that names no
    # resource gets the queue's ARN, which the caller cannot reference before it exists.
    [for s in flatten([for doc in var.policy.source_policy_documents : jsondecode(doc).Statement]) :
      merge(s, { for k, v in { Resource = local.queue_arn } : k => v if !contains(keys(s), "Resource") && !contains(keys(s), "NotResource") })
    ],
  )

  # Decided from the inputs alone, so the count is known at plan time.
  create_sqs_queue_policy = anytrue([
    var.policy.require_encrypted_transport,
    length(var.policy.sns_topic_arns) > 0,
    length(var.policy.s3_bucket_arns) > 0,
    length(var.policy.source_policy_documents) > 0,
  ])

  sqs_queue_policy_sids = compact([for s in local.sqs_queue_policy_statements : try(s.Sid, "")])
}
