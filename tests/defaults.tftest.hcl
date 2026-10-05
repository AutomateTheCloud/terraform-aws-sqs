# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# Offline tests: every provider is mocked, so no AWS account is used.
mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-east-1", description = "US East (N. Virginia)" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111" }
  }
  mock_resource "aws_sqs_queue" {
    defaults = {
      arn = "arn:aws:sqs:us-east-1:111111111111:test-queue"
      id  = "https://sqs.us-east-1.amazonaws.com/111111111111/test-queue"
    }
  }
}

variables {
  details = { scope = "Test", purpose = "Defaults", environment = "test" }
  name    = "test-queue"
}

run "defaults_are_secure" {
  command = apply

  assert {
    condition     = aws_sqs_queue.this.sqs_managed_sse_enabled == true && aws_sqs_queue.this.kms_master_key_id == null
    error_message = "The queue must be encrypted with SSE-SQS by default."
  }
  assert {
    condition = jsondecode(aws_sqs_queue_policy.this[0].policy).Statement == [{
      Sid       = "RequireEncryptedTransport"
      Effect    = "Deny"
      Principal = "*"
      Action    = "sqs:*"
      Resource  = "arn:aws:sqs:us-east-1:111111111111:test-queue"
      Condition = { Bool = { "aws:SecureTransport" = "false" } }
    }]
    error_message = "Only the encrypted-transport statement is expected by default."
  }
  assert {
    condition     = aws_sqs_queue.this.name == "test-queue" && aws_sqs_queue.this.fifo_queue == false
    error_message = "A standard queue with the given name is expected."
  }
  assert {
    condition = alltrue([
      length(aws_sqs_queue.dead_letter) == 0,
      length(aws_sqs_queue_policy.dead_letter) == 0,
      length(aws_sqs_queue_redrive_allow_policy.dead_letter) == 0,
    ])
    error_message = "No dead-letter queue is expected by default."
  }
  assert {
    condition = alltrue([
      output.metadata.sqs_dead_letter_queue == null,
      output.metadata.sqs_dead_letter_queue_policy == null,
      output.metadata.sqs_dead_letter_queue_redrive_allow_policy == null,
      output.metadata.sqs_queue.arn == "arn:aws:sqs:us-east-1:111111111111:test-queue",
      output.metadata.sqs_queue_policy != null,
    ])
    error_message = "metadata entries do not match what was created."
  }
}

# The settings the module passes, with only the required inputs. The provider would fill
# in the same values, but the module sets them so the plan shows them.
run "default_settings" {
  command = plan

  assert {
    condition = alltrue([
      aws_sqs_queue.this.delay_seconds == 0,
      aws_sqs_queue.this.max_message_size == 262144,
      aws_sqs_queue.this.message_retention_seconds == 345600,
      aws_sqs_queue.this.receive_wait_time_seconds == 0,
      aws_sqs_queue.this.visibility_timeout_seconds == 30,
    ])
    error_message = "Unexpected default settings."
  }
  assert {
    condition     = aws_sqs_queue.this.tags == tomap({ Scope = "Test", Purpose = "Defaults", Environment = "test" })
    error_message = "details tags are missing."
  }
}

# The module works with only the default provider: no providers block in any run here.
run "no_providers_block" {
  command = plan
  assert {
    condition     = output.metadata.aws.account.id == "111111111111"
    error_message = "Expected the mocked account."
  }
}
