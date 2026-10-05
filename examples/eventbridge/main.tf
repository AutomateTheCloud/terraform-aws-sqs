# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# An Amazon EventBridge rule that sends matching events to an SQS queue. The module has
# no option for EventBridge, so the grant is a statement of your own in
# policy.source_policy_documents, limited to this one rule. A statement with no
# Resource is given the queue's ARN.

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
    purpose     = "EventBridge Target"
    environment = "Development"
  }

  name = "example-eventbridge-target"

  policy = {
    source_policy_documents = [jsonencode({
      Version = "2012-10-17"
      Statement = [{
        Sid       = "AllowEventBridgeRule"
        Effect    = "Allow"
        Principal = { Service = "events.amazonaws.com" }
        Action    = "sqs:SendMessage"
        Condition = { ArnEquals = { "aws:SourceArn" = aws_cloudwatch_event_rule.example.arn } }
      }]
    })]
  }
}

# Matches events that you send yourself with source "example.orders", so applying the
# example sends nothing on its own.
resource "aws_cloudwatch_event_rule" "example" {
  name        = "example-eventbridge-target"
  description = "Send example.orders events to SQS"
  event_pattern = jsonencode({
    source = ["example.orders"]
  })
}

resource "aws_cloudwatch_event_target" "example" {
  rule = aws_cloudwatch_event_rule.example.name
  arn  = module.sqs.metadata.sqs_queue.arn
}

output "queue_url" {
  description = "Receive the events from this queue"
  value       = module.sqs.metadata.sqs_queue.url
}
