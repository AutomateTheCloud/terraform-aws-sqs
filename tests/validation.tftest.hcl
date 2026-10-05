# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

mock_provider "aws" {
  mock_data "aws_region" {
    defaults = { region = "us-east-1", description = "US East (N. Virginia)" }
  }
  mock_data "aws_caller_identity" {
    defaults = { account_id = "111111111111" }
  }
}

variables {
  details = { scope = "Test", purpose = "Validation", environment = "test" }
  name    = "test-queue"
}

run "details_scope_empty" {
  command = plan
  variables { details = { scope = " ", purpose = "p", environment = "e" } }
  expect_failures = [var.details]
}

run "details_purpose_empty" {
  command = plan
  variables { details = { scope = "s", purpose = "", environment = "e" } }
  expect_failures = [var.details]
}

run "details_environment_empty" {
  command = plan
  variables { details = { scope = "s", purpose = "p", environment = "" } }
  expect_failures = [var.details]
}

run "name_with_fifo_suffix" {
  command = plan
  variables { name = "test-queue.fifo" }
  expect_failures = [var.name]
}

run "name_with_invalid_characters" {
  command = plan
  variables { name = "test queue" }
  expect_failures = [var.name]
}

run "name_80_characters_ok" {
  command = plan
  variables { name = "a234567890123456789012345678901234567890123456789012345678901234567890123456789b" }
}

run "name_too_long" {
  command = plan
  variables { name = "a234567890123456789012345678901234567890123456789012345678901234567890123456789bc" }
  expect_failures = [var.name]
}

run "name_too_long_with_fifo" {
  command = plan
  variables {
    name = "a2345678901234567890123456789012345678901234567890123456789012345678901234567"
    fifo = {}
  }
  expect_failures = [var.name]
}

run "name_too_long_with_dead_letter_queue" {
  command = plan
  variables {
    name              = "a2345678901234567890123456789012345678901234567890123456789012345678901234567"
    dead_letter_queue = {}
  }
  expect_failures = [var.name]
}

run "delay_seconds_too_high" {
  command = plan
  variables { delay_seconds = 901 }
  expect_failures = [var.delay_seconds]
}

run "delay_seconds_fraction" {
  command = plan
  variables { delay_seconds = 1.5 }
  expect_failures = [var.delay_seconds]
}

run "max_message_size_too_low" {
  command = plan
  variables { max_message_size = 1023 }
  expect_failures = [var.max_message_size]
}

run "max_message_size_too_high" {
  command = plan
  variables { max_message_size = 1048577 }
  expect_failures = [var.max_message_size]
}

run "message_retention_too_low" {
  command = plan
  variables { message_retention_seconds = 59 }
  expect_failures = [var.message_retention_seconds]
}

run "message_retention_too_high" {
  command = plan
  variables { message_retention_seconds = 1209601 }
  expect_failures = [var.message_retention_seconds]
}

run "receive_wait_too_high" {
  command = plan
  variables { receive_wait_time_seconds = 21 }
  expect_failures = [var.receive_wait_time_seconds]
}

run "visibility_timeout_too_high" {
  command = plan
  variables { visibility_timeout_seconds = 43201 }
  expect_failures = [var.visibility_timeout_seconds]
}

run "visibility_timeout_negative" {
  command = plan
  variables { visibility_timeout_seconds = -1 }
  expect_failures = [var.visibility_timeout_seconds]
}

run "kms_key_empty" {
  command = plan
  variables { encryption = { kms_key_id = "" } }
  expect_failures = [var.encryption]
}

run "kms_reuse_too_low" {
  command = plan
  variables { encryption = { kms_key_id = "alias/test", kms_data_key_reuse_period_seconds = 59 } }
  expect_failures = [var.encryption]
}

run "kms_reuse_too_high" {
  command = plan
  variables { encryption = { kms_data_key_reuse_period_seconds = 86401 } }
  expect_failures = [var.encryption]
}

run "fifo_bad_deduplication_scope" {
  command = plan
  variables { fifo = { deduplication_scope = "group" } }
  expect_failures = [var.fifo]
}

run "fifo_bad_throughput_limit" {
  command = plan
  variables { fifo = { throughput_limit = "perGroup" } }
  expect_failures = [var.fifo]
}

# AWS rejects this combination at create; found by probing the API.
run "fifo_per_group_throughput_needs_group_scope" {
  command = plan
  variables { fifo = { throughput_limit = "perMessageGroupId" } }
  expect_failures = [var.fifo]
}

run "fifo_group_scope_with_queue_throughput_ok" {
  command = plan
  variables { fifo = { deduplication_scope = "messageGroup" } }
}

run "dead_letter_max_receive_count_zero" {
  command = plan
  variables { dead_letter_queue = { max_receive_count = 0 } }
  expect_failures = [var.dead_letter_queue]
}

run "dead_letter_max_receive_count_too_high" {
  command = plan
  variables { dead_letter_queue = { max_receive_count = 1001 } }
  expect_failures = [var.dead_letter_queue]
}

run "dead_letter_retention_too_high" {
  command = plan
  variables { dead_letter_queue = { message_retention_seconds = 1209601 } }
  expect_failures = [var.dead_letter_queue]
}

run "sns_topic_arn_invalid" {
  command = plan
  variables { policy = { sns_topic_arns = ["my-topic"] } }
  expect_failures = [var.policy]
}

run "s3_bucket_arn_invalid" {
  command = plan
  variables { policy = { s3_bucket_arns = ["arn:aws:s3:::bucket/prefix"] } }
  expect_failures = [var.policy]
}

run "source_policy_document_invalid" {
  command = plan
  variables { policy = { source_policy_documents = ["{}"] } }
  expect_failures = [var.policy]
}
