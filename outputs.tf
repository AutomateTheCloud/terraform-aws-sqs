# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

output "metadata" {
  description = <<-EOT
    Everything the module created, in one object, so that other configurations need only one reference:

    - `details` - The scope, purpose and environment, each with its `name`, `abbr` (lowercase, words joined by underscores) and `machine` (lowercase letters and numbers only) forms, and the `tags` applied to every resource.
    - `aws` - The `account.id`, and the `region` `name`, `abbr` (such as `use1` for `us-east-1`) and `description`.
    - `sqs_queue` - The queue's `url` (also its `id`), `arn`, `name`, its settings, `tags` and `tags_all`. Send messages to the `url`, and grant IAM permissions on the `arn`.
    - `sqs_queue_policy` - The queue policy's `policy` JSON, `queue_url` and `region`. `null` when no policy is created.
    - `sqs_dead_letter_queue` - The same attributes as `sqs_queue`, for the dead-letter queue. `null` when there is none.
    - `sqs_dead_letter_queue_policy` - The dead-letter queue's policy. `null` when it is not created.
    - `sqs_dead_letter_queue_redrive_allow_policy` - The rule that only `sqs_queue` may send failed messages to the dead-letter queue. `null` when there is no dead-letter queue.
  EOT
  value = {
    details = {
      scope = {
        name    = local.scope.name
        abbr    = local.scope.abbr
        machine = local.scope.machine
      }
      purpose = {
        name    = local.purpose.name
        abbr    = local.purpose.abbr
        machine = local.purpose.machine
      }
      environment = {
        name    = local.environment.name
        abbr    = local.environment.abbr
        machine = local.environment.machine
      }
      tags = local.tags
    }

    aws = {
      account = {
        id = local.aws.account.id
      }
      region = {
        name        = local.aws.region.name
        abbr        = local.aws.region.abbr
        description = local.aws.region.description
      }
    }

    # One entry per resource. Resources that are not created are null.
    sqs_queue                                  = local.output_resources.sqs_queue
    sqs_queue_policy                           = local.output_resources.sqs_queue_policy
    sqs_dead_letter_queue                      = local.output_resources.sqs_dead_letter_queue
    sqs_dead_letter_queue_policy               = local.output_resources.sqs_dead_letter_queue_policy
    sqs_dead_letter_queue_redrive_allow_policy = local.output_resources.sqs_dead_letter_queue_redrive_allow_policy
  }
}

locals {
  # Each resource's attributes are listed one by one. Referencing a whole resource, or
  # iterating over it, would also reference any deprecated attributes, and every
  # caller's plan would print deprecation warnings.
  output_resources = {
    # The queues leave out `policy`, and the dead-letter queue `redrive_allow_policy`:
    # the separate policy resources set them after the queue is read, so the next plan
    # would show them changing. They are in the policy entries instead.
    sqs_queue = {
      arn                               = aws_sqs_queue.this.arn
      content_based_deduplication       = aws_sqs_queue.this.content_based_deduplication
      deduplication_scope               = aws_sqs_queue.this.deduplication_scope
      delay_seconds                     = aws_sqs_queue.this.delay_seconds
      fifo_queue                        = aws_sqs_queue.this.fifo_queue
      fifo_throughput_limit             = aws_sqs_queue.this.fifo_throughput_limit
      id                                = aws_sqs_queue.this.id
      kms_data_key_reuse_period_seconds = aws_sqs_queue.this.kms_data_key_reuse_period_seconds
      kms_master_key_id                 = aws_sqs_queue.this.kms_master_key_id
      max_message_size                  = aws_sqs_queue.this.max_message_size
      message_retention_seconds         = aws_sqs_queue.this.message_retention_seconds
      name                              = aws_sqs_queue.this.name
      name_prefix                       = aws_sqs_queue.this.name_prefix
      receive_wait_time_seconds         = aws_sqs_queue.this.receive_wait_time_seconds
      redrive_allow_policy              = aws_sqs_queue.this.redrive_allow_policy
      redrive_policy                    = aws_sqs_queue.this.redrive_policy
      region                            = aws_sqs_queue.this.region
      sqs_managed_sse_enabled           = aws_sqs_queue.this.sqs_managed_sse_enabled
      tags                              = aws_sqs_queue.this.tags
      tags_all                          = aws_sqs_queue.this.tags_all
      url                               = aws_sqs_queue.this.url
      visibility_timeout_seconds        = aws_sqs_queue.this.visibility_timeout_seconds
    }

    sqs_queue_policy = length(aws_sqs_queue_policy.this) == 0 ? null : {
      id        = aws_sqs_queue_policy.this[0].id
      policy    = aws_sqs_queue_policy.this[0].policy
      queue_url = aws_sqs_queue_policy.this[0].queue_url
      region    = aws_sqs_queue_policy.this[0].region
    }

    sqs_dead_letter_queue = length(aws_sqs_queue.dead_letter) == 0 ? null : {
      arn                               = aws_sqs_queue.dead_letter[0].arn
      content_based_deduplication       = aws_sqs_queue.dead_letter[0].content_based_deduplication
      deduplication_scope               = aws_sqs_queue.dead_letter[0].deduplication_scope
      delay_seconds                     = aws_sqs_queue.dead_letter[0].delay_seconds
      fifo_queue                        = aws_sqs_queue.dead_letter[0].fifo_queue
      fifo_throughput_limit             = aws_sqs_queue.dead_letter[0].fifo_throughput_limit
      id                                = aws_sqs_queue.dead_letter[0].id
      kms_data_key_reuse_period_seconds = aws_sqs_queue.dead_letter[0].kms_data_key_reuse_period_seconds
      kms_master_key_id                 = aws_sqs_queue.dead_letter[0].kms_master_key_id
      max_message_size                  = aws_sqs_queue.dead_letter[0].max_message_size
      message_retention_seconds         = aws_sqs_queue.dead_letter[0].message_retention_seconds
      name                              = aws_sqs_queue.dead_letter[0].name
      name_prefix                       = aws_sqs_queue.dead_letter[0].name_prefix
      receive_wait_time_seconds         = aws_sqs_queue.dead_letter[0].receive_wait_time_seconds
      redrive_policy                    = aws_sqs_queue.dead_letter[0].redrive_policy
      region                            = aws_sqs_queue.dead_letter[0].region
      sqs_managed_sse_enabled           = aws_sqs_queue.dead_letter[0].sqs_managed_sse_enabled
      tags                              = aws_sqs_queue.dead_letter[0].tags
      tags_all                          = aws_sqs_queue.dead_letter[0].tags_all
      url                               = aws_sqs_queue.dead_letter[0].url
      visibility_timeout_seconds        = aws_sqs_queue.dead_letter[0].visibility_timeout_seconds
    }

    sqs_dead_letter_queue_policy = length(aws_sqs_queue_policy.dead_letter) == 0 ? null : {
      id        = aws_sqs_queue_policy.dead_letter[0].id
      policy    = aws_sqs_queue_policy.dead_letter[0].policy
      queue_url = aws_sqs_queue_policy.dead_letter[0].queue_url
      region    = aws_sqs_queue_policy.dead_letter[0].region
    }

    sqs_dead_letter_queue_redrive_allow_policy = length(aws_sqs_queue_redrive_allow_policy.dead_letter) == 0 ? null : {
      id                   = aws_sqs_queue_redrive_allow_policy.dead_letter[0].id
      queue_url            = aws_sqs_queue_redrive_allow_policy.dead_letter[0].queue_url
      redrive_allow_policy = aws_sqs_queue_redrive_allow_policy.dead_letter[0].redrive_allow_policy
      region               = aws_sqs_queue_redrive_allow_policy.dead_letter[0].region
    }
  }
}
