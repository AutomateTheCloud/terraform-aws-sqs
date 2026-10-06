# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

resource "aws_sqs_queue" "this" {
  name                       = local.sqs_queue_name
  region                     = var.region
  delay_seconds              = var.delay_seconds
  max_message_size           = var.max_message_size
  message_retention_seconds  = var.message_retention_seconds
  receive_wait_time_seconds  = var.receive_wait_time_seconds
  visibility_timeout_seconds = var.visibility_timeout_seconds

  sqs_managed_sse_enabled           = local.kms_enabled ? null : true
  kms_master_key_id                 = var.encryption.kms_key_id
  kms_data_key_reuse_period_seconds = local.kms_enabled ? var.encryption.kms_data_key_reuse_period_seconds : null

  fifo_queue                  = local.fifo
  content_based_deduplication = local.fifo ? var.fifo.content_based_deduplication : null
  deduplication_scope         = local.fifo ? var.fifo.deduplication_scope : null
  fifo_throughput_limit       = local.fifo ? var.fifo.throughput_limit : null

  redrive_policy = local.dead_letter_queue_enabled ? jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dead_letter[0].arn
    maxReceiveCount     = var.dead_letter_queue.max_receive_count
  }) : null

  tags = local.tags
}

resource "aws_sqs_queue" "dead_letter" {
  count                     = local.dead_letter_queue_enabled ? 1 : 0
  name                      = local.sqs_dead_letter_queue_name
  region                    = var.region
  message_retention_seconds = var.dead_letter_queue.message_retention_seconds

  # The same encryption as the queue.
  sqs_managed_sse_enabled           = local.kms_enabled ? null : true
  kms_master_key_id                 = var.encryption.kms_key_id
  kms_data_key_reuse_period_seconds = local.kms_enabled ? var.encryption.kms_data_key_reuse_period_seconds : null

  # A FIFO queue's dead-letter queue must also be a FIFO queue.
  fifo_queue = local.fifo

  tags = local.tags
}
