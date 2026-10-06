# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# An Amazon SNS topic that delivers every message it receives to an SQS queue. The
# queue policy lets only this topic send to the queue.

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

module "sqs" {
  source = "../../"

  details = {
    scope       = "Example"
    purpose     = "SNS Subscription"
    environment = "Development"
  }

  name = "example-sns-subscription"

  policy = {
    sns_topic_arns = [aws_sns_topic.orders.arn]
  }
}

# The topic is encrypted with the AWS managed key for SNS, which keeps the example to one
# purpose. A customer managed key would also need its own key policy. Either way, SNS
# decrypts each message before it delivers it to the queue.
#trivy:ignore:AWS-0136
resource "aws_sns_topic" "orders" {
  name              = "example-sns-subscription-orders"
  kms_master_key_id = "alias/aws/sns"
}

resource "aws_sns_topic_subscription" "orders" {
  topic_arn = aws_sns_topic.orders.arn
  protocol  = "sqs"
  endpoint  = module.sqs.metadata.sqs_queue.arn

  # Deliver the message as it was published, without the SNS envelope around it.
  raw_message_delivery = true
}

output "topic_arn" {
  description = "Publish to this topic"
  value       = aws_sns_topic.orders.arn
}

output "queue_url" {
  description = "Receive from this queue"
  value       = module.sqs.metadata.sqs_queue.url
}
