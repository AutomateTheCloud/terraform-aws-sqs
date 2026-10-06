# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# Only this module's queue may use the dead-letter queue. Without it, any queue in the
# account could send its failed messages there.
resource "aws_sqs_queue_redrive_allow_policy" "dead_letter" {
  count     = local.dead_letter_queue_enabled ? 1 : 0
  queue_url = aws_sqs_queue.dead_letter[0].id
  region    = var.region
  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.this.arn]
  })
}
