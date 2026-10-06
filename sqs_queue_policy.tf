# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

resource "aws_sqs_queue_policy" "this" {
  count     = local.create_sqs_queue_policy ? 1 : 0
  queue_url = aws_sqs_queue.this.id
  region    = var.region
  policy = jsonencode({
    Version   = "2012-10-17"
    Statement = local.sqs_queue_policy_statements
  })

  lifecycle {
    precondition {
      condition     = length(local.sqs_queue_policy_sids) == length(distinct(local.sqs_queue_policy_sids))
      error_message = "Queue policy statement IDs (Sid) must be unique. Check policy.source_policy_documents against the module's own statements: ${join(", ", local.sqs_queue_policy_sids)}."
    }
  }
}

# The dead-letter queue gets only the encrypted-transport rule: nothing but the queue
# itself sends messages to it.
resource "aws_sqs_queue_policy" "dead_letter" {
  count     = local.dead_letter_queue_enabled && var.policy.require_encrypted_transport ? 1 : 0
  queue_url = aws_sqs_queue.dead_letter[0].id
  region    = var.region
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "RequireEncryptedTransport"
      Effect    = "Deny"
      Principal = "*"
      Action    = "sqs:*"
      Resource  = aws_sqs_queue.dead_letter[0].arn
      Condition = { Bool = { "aws:SecureTransport" = "false" } }
    }]
  })
}
