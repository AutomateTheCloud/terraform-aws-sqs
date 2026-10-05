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
  details = { scope = "Test", purpose = "Features", environment = "test" }
  name    = "test-queue"
}

# Bug fix: receive_wait_time_seconds was set from delay_seconds.
run "receive_wait_time_is_its_own_setting" {
  command = plan
  variables {
    receive_wait_time_seconds = 20
    delay_seconds             = 5
  }
  assert {
    condition     = aws_sqs_queue.this.receive_wait_time_seconds == 20 && aws_sqs_queue.this.delay_seconds == 5
    error_message = "receive_wait_time_seconds and delay_seconds must be set independently."
  }
}

run "settings_pass_through" {
  command = plan
  variables {
    max_message_size           = 2048
    message_retention_seconds  = 60
    visibility_timeout_seconds = 43200
  }
  assert {
    condition = alltrue([
      aws_sqs_queue.this.max_message_size == 2048,
      aws_sqs_queue.this.message_retention_seconds == 60,
      aws_sqs_queue.this.visibility_timeout_seconds == 43200,
    ])
    error_message = "Settings were not passed to the queue."
  }
}

# Bug fix: a FIFO queue's dead-letter queue was named .fifo but was not a FIFO queue,
# which AWS rejects.
run "fifo_with_dead_letter_queue" {
  command = plan
  variables {
    fifo              = { content_based_deduplication = true }
    dead_letter_queue = {}
  }
  assert {
    condition = alltrue([
      aws_sqs_queue.this.name == "test-queue.fifo",
      aws_sqs_queue.this.fifo_queue == true,
      aws_sqs_queue.this.content_based_deduplication == true,
      aws_sqs_queue.this.deduplication_scope == "queue",
      aws_sqs_queue.this.fifo_throughput_limit == "perQueue",
      aws_sqs_queue.dead_letter[0].name == "test-queue-dlq.fifo",
      aws_sqs_queue.dead_letter[0].fifo_queue == true,
    ])
    error_message = "FIFO queue and dead-letter queue are not set up as FIFO."
  }
}

run "fifo_high_throughput" {
  command = plan
  variables {
    fifo = { deduplication_scope = "messageGroup", throughput_limit = "perMessageGroupId" }
  }
  assert {
    condition     = aws_sqs_queue.this.deduplication_scope == "messageGroup" && aws_sqs_queue.this.fifo_throughput_limit == "perMessageGroupId" && aws_sqs_queue.this.content_based_deduplication == false
    error_message = "High-throughput FIFO settings were not passed."
  }
}

run "dead_letter_queue" {
  command = apply
  variables {
    dead_letter_queue = { max_receive_count = 3, message_retention_seconds = 86400 }
  }
  assert {
    condition = jsondecode(aws_sqs_queue.this.redrive_policy) == {
      deadLetterTargetArn = aws_sqs_queue.dead_letter[0].arn
      maxReceiveCount     = 3
    }
    error_message = "The queue does not redrive to its dead-letter queue."
  }
  assert {
    condition = alltrue([
      aws_sqs_queue.dead_letter[0].name == "test-queue-dlq",
      aws_sqs_queue.dead_letter[0].fifo_queue == false,
      aws_sqs_queue.dead_letter[0].message_retention_seconds == 86400,
    ])
    error_message = "Unexpected dead-letter queue settings."
  }
  assert {
    condition = jsondecode(aws_sqs_queue_redrive_allow_policy.dead_letter[0].redrive_allow_policy) == {
      redrivePermission = "byQueue"
      sourceQueueArns   = [aws_sqs_queue.this.arn]
    }
    error_message = "Only the queue may use the dead-letter queue."
  }
  assert {
    condition     = jsondecode(aws_sqs_queue_policy.dead_letter[0].policy).Statement[0].Sid == "RequireEncryptedTransport" && length(jsondecode(aws_sqs_queue_policy.dead_letter[0].policy).Statement) == 1
    error_message = "The dead-letter queue needs only the encrypted-transport rule."
  }
  assert {
    condition     = output.metadata.sqs_dead_letter_queue.name == "test-queue-dlq" && output.metadata.sqs_dead_letter_queue_redrive_allow_policy != null
    error_message = "metadata is missing the dead-letter queue."
  }
}

run "dead_letter_queue_defaults" {
  command = plan
  variables {
    dead_letter_queue = {}
  }
  assert {
    condition     = aws_sqs_queue.dead_letter[0].message_retention_seconds == 1209600
    error_message = "The dead-letter queue keeps messages for 14 days by default."
  }
}

run "dead_letter_queue_disabled" {
  command = plan
  variables {
    dead_letter_queue = { enabled = false }
  }
  assert {
    condition     = length(aws_sqs_queue.dead_letter) == 0 && length(aws_sqs_queue_redrive_allow_policy.dead_letter) == 0
    error_message = "enabled = false must create no dead-letter queue."
  }
}

# Bug fix: the dead-letter queue was never given the queue's SSE-SQS setting.
run "dead_letter_queue_encrypted_like_the_queue" {
  command = plan
  variables {
    dead_letter_queue = {}
  }
  assert {
    condition     = aws_sqs_queue.dead_letter[0].sqs_managed_sse_enabled == true
    error_message = "The dead-letter queue must use SSE-SQS like the queue."
  }
}

run "kms_encryption" {
  command = plan
  variables {
    encryption        = { kms_key_id = "alias/test", kms_data_key_reuse_period_seconds = 3600 }
    dead_letter_queue = {}
  }
  assert {
    condition = alltrue([
      aws_sqs_queue.this.kms_master_key_id == "alias/test",
      aws_sqs_queue.this.kms_data_key_reuse_period_seconds == 3600,
      aws_sqs_queue.dead_letter[0].kms_master_key_id == "alias/test",
      aws_sqs_queue.dead_letter[0].kms_data_key_reuse_period_seconds == 3600,
    ])
    error_message = "The KMS key was not passed to both queues."
  }
}

run "policy_grants" {
  command = apply
  variables {
    policy = {
      sns_topic_arns = ["arn:aws:sns:us-east-1:111111111111:topic", "arn:aws:sns:us-east-1:111111111111:other-*"]
      s3_bucket_arns = ["arn:aws:s3:::test-bucket"]
      source_policy_documents = [jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Sid       = "EventBridge"
            Effect    = "Allow"
            Principal = { Service = "events.amazonaws.com" }
            Action    = "sqs:SendMessage"
          },
          {
            Sid       = "Explicit"
            Effect    = "Allow"
            Principal = { AWS = "arn:aws:iam::222222222222:root" }
            Action    = "sqs:ReceiveMessage"
            Resource  = "arn:aws:sqs:us-east-1:111111111111:somewhere-else"
          },
        ]
      })]
    }
  }
  assert {
    condition = [for s in jsondecode(aws_sqs_queue_policy.this[0].policy).Statement : s.Sid] == [
      "RequireEncryptedTransport", "AllowSNSTopics", "AllowS3BucketNotifications", "EventBridge", "Explicit",
    ]
    error_message = "Unexpected statements."
  }
  assert {
    condition     = jsondecode(aws_sqs_queue_policy.this[0].policy).Statement[1].Condition == { ArnLike = { "aws:SourceArn" = ["arn:aws:sns:us-east-1:111111111111:topic", "arn:aws:sns:us-east-1:111111111111:other-*"] } }
    error_message = "SNS statement must be limited to the given topics."
  }
  assert {
    condition = jsondecode(aws_sqs_queue_policy.this[0].policy).Statement[2].Condition == {
      ArnLike      = { "aws:SourceArn" = ["arn:aws:s3:::test-bucket"] }
      StringEquals = { "aws:SourceAccount" = "111111111111" }
    }
    error_message = "S3 statement must be limited to the given buckets in the queue's account."
  }
  assert {
    condition     = jsondecode(aws_sqs_queue_policy.this[0].policy).Statement[3].Resource == aws_sqs_queue.this.arn
    error_message = "A statement with no Resource must get the queue's ARN."
  }
  assert {
    condition     = jsondecode(aws_sqs_queue_policy.this[0].policy).Statement[4].Resource == "arn:aws:sqs:us-east-1:111111111111:somewhere-else"
    error_message = "A statement's own Resource must be kept."
  }
}

run "no_policy_when_nothing_granted" {
  command = plan
  variables {
    policy            = { require_encrypted_transport = false }
    dead_letter_queue = {}
  }
  assert {
    condition     = length(aws_sqs_queue_policy.this) == 0 && length(aws_sqs_queue_policy.dead_letter) == 0
    error_message = "No queue policy is expected when nothing is granted or denied."
  }
}

run "duplicate_sid_fails" {
  command = plan
  variables {
    policy = {
      source_policy_documents = [jsonencode({
        Version   = "2012-10-17"
        Statement = [{ Sid = "RequireEncryptedTransport", Effect = "Allow", Principal = "*", Action = "sqs:SendMessage" }]
      })]
    }
  }
  expect_failures = [aws_sqs_queue_policy.this]
}

run "details_abbreviations" {
  command = plan
  variables {
    details = { scope = "Automate the Cloud", purpose = "Order Processing", environment = "Production", environment_abbr = "prd", additional_tags = { CostCenter = "1234" } }
  }
  assert {
    condition = alltrue([
      output.metadata.details.scope.abbr == "automate_the_cloud",
      output.metadata.details.purpose.machine == "orderprocessing",
      output.metadata.details.environment.abbr == "prd",
      aws_sqs_queue.this.tags.CostCenter == "1234",
    ])
    error_message = "Unexpected details forms or tags."
  }
}
