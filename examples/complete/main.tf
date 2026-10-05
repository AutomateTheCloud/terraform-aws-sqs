# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# Most of the module's options together: a FIFO queue with high throughput and
# content-based deduplication, encrypted with a customer managed KMS key, with a
# dead-letter queue, long polling and longer timeouts.

terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

# The queue's KMS key. Its default key policy lets IAM policies in this account grant
# its use. AWS services that send to the queue, such as Amazon SNS, would also need
# kms:GenerateDataKey and kms:Decrypt in the key policy.
resource "aws_kms_key" "sqs" {
  description             = "Example complete SQS queue"
  deletion_window_in_days = 7
  enable_key_rotation     = true
}

module "sqs" {
  source = "../../"

  details = {
    scope           = "Example"
    purpose         = "Complete Queue"
    environment     = "Development"
    additional_tags = { CostCenter = "1234" }
  }

  name = "example-complete-queue"

  fifo = {
    content_based_deduplication = true
    deduplication_scope         = "messageGroup"
    throughput_limit            = "perMessageGroupId"
  }

  encryption = {
    kms_key_id                        = aws_kms_key.sqs.arn
    kms_data_key_reuse_period_seconds = 3600
  }

  dead_letter_queue = {
    max_receive_count         = 3
    message_retention_seconds = 1209600
  }

  delay_seconds              = 0
  max_message_size           = 262144
  message_retention_seconds  = 604800
  receive_wait_time_seconds  = 20
  visibility_timeout_seconds = 300
}

output "metadata" {
  description = "Everything the module created"
  value       = module.sqs.metadata
}
