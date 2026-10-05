# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# Inputs that come from resources created in the same run are unknown at plan. The
# module must still plan, with the same resources it creates for known inputs.
mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-east-1", description = "US East (N. Virginia)" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111" }
  }
}
mock_provider "random" {}

run "same_run_inputs_plan" {
  command   = plan
  providers = { aws = aws, random = random }
  module {
    source = "./tests/fixtures/same_run"
  }
  assert {
    condition = alltrue([
      length(module.sqs.metadata.sqs_queue_policy[*]) == 1,
      length(module.sqs.metadata.sqs_dead_letter_queue_policy[*]) == 1,
      length(module.sqs.metadata.sqs_dead_letter_queue_redrive_allow_policy[*]) == 1,
    ])
    error_message = "Unknown inputs must not change which resources are created."
  }
}

run "same_run_inputs_apply" {
  command   = apply
  providers = { aws = aws, random = random }
  module {
    source = "./tests/fixtures/same_run"
  }
  assert {
    condition     = output.metadata.sqs_queue.kms_master_key_id == output.kms_key_arn && output.metadata.sqs_dead_letter_queue.kms_master_key_id == output.kms_key_arn
    error_message = "Both queues must use the same-run key."
  }
}
