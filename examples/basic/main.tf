# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# A private standard queue, encrypted with SSE-SQS, that only HTTPS requests can reach,
# with a dead-letter queue for messages that fail five times. A sensible starting point
# for most queues.

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
    purpose     = "Basic Queue"
    environment = "Development"
  }

  name = "example-basic-queue"

  # Wait up to 20 seconds for a message instead of returning at once (long polling).
  receive_wait_time_seconds = 20

  dead_letter_queue = {
    max_receive_count = 5
  }
}

output "queue" {
  description = "URL and ARN of the queue and its dead-letter queue"
  value = {
    url                   = module.sqs.metadata.sqs_queue.url
    arn                   = module.sqs.metadata.sqs_queue.arn
    dead_letter_queue_url = module.sqs.metadata.sqs_dead_letter_queue.url
  }
}
