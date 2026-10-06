# Copyright 2026 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

variable "dead_letter_queue" {
  description = <<-EOT
    A dead-letter queue: a second queue that receives each message the queue's consumers have failed to process `max_receive_count` times, so one bad message cannot be retried until it expires. `null`, the default, creates none.

    The dead-letter queue is named `<name>-dlq` (`<name>-dlq.fifo` for a FIFO queue), uses the same encryption and the same encrypted-transport rule as the queue, and accepts messages from this queue only.

    - `enabled` - (Optional) Defaults to `true` when `dead_letter_queue` is set.
    - `max_receive_count` - (Optional) How many times a message is received without being deleted before it is moved to the dead-letter queue: 1 to 1000. Defaults to `5`.
    - `message_retention_seconds` - (Optional) How long the dead-letter queue keeps a message, in seconds: 60 (1 minute) to 1209600 (14 days). Defaults to `1209600`. For a standard queue, the time counts from when the message was first sent to the queue, not from when it was moved, so keep this longer than the queue's own `message_retention_seconds`.
  EOT
  type = object({
    enabled                   = optional(bool, true)
    max_receive_count         = optional(number, 5)
    message_retention_seconds = optional(number, 1209600)
  })
  default = null

  validation {
    condition     = var.dead_letter_queue == null || (try(var.dead_letter_queue.max_receive_count, 0) >= 1 && try(var.dead_letter_queue.max_receive_count, 0) <= 1000 && floor(try(var.dead_letter_queue.max_receive_count, 0)) == try(var.dead_letter_queue.max_receive_count, 0))
    error_message = "dead_letter_queue.max_receive_count must be a whole number from 1 to 1000."
  }

  validation {
    condition     = var.dead_letter_queue == null || (try(var.dead_letter_queue.message_retention_seconds, 0) >= 60 && try(var.dead_letter_queue.message_retention_seconds, 0) <= 1209600 && floor(try(var.dead_letter_queue.message_retention_seconds, 0)) == try(var.dead_letter_queue.message_retention_seconds, 0))
    error_message = "dead_letter_queue.message_retention_seconds must be a whole number from 60 to 1209600 (14 days)."
  }
}

variable "delay_seconds" {
  description = <<-EOT
    How long every new message stays invisible to consumers after it is sent, in seconds: 0 to 900 (15 minutes). Defaults to `0`.
  EOT
  type        = number
  default     = 0
  nullable    = false

  validation {
    condition     = var.delay_seconds >= 0 && var.delay_seconds <= 900 && floor(var.delay_seconds) == var.delay_seconds
    error_message = "delay_seconds must be a whole number from 0 to 900."
  }
}

variable "details" {
  description = <<-EOT
    Names and tags shared by every resource in the module. `scope`, `purpose` and `environment` become the `Scope`, `Purpose` and `Environment` tags, and are converted to abbreviations that other modules can use in resource names (see the `metadata` output). [The `details` input](https://github.com/AutomateTheCloud/terraform-aws-sqs#the-details-input) explains why it is required.

    - `scope` - (Required) What the resource belongs to, such as an organization or project: `Automate the Cloud`.
    - `purpose` - (Required) What the resource is for: `Web Site`.
    - `environment` - (Required) The environment: `Production`.
    - `scope_abbr`, `purpose_abbr`, `environment_abbr` - (Optional) Abbreviations to use instead of the generated ones, which are lowercase with words joined by underscores (`Web Site` becomes `web_site`).
    - `additional_tags` - (Optional) More tags for every resource, such as `{ CostCenter = "1234" }`.
  EOT
  type = object({
    scope            = string
    scope_abbr       = optional(string)
    purpose          = string
    purpose_abbr     = optional(string)
    environment      = string
    environment_abbr = optional(string)
    additional_tags  = optional(map(string), {})
  })
  nullable = false

  validation {
    condition     = trimspace(var.details.scope) != ""
    error_message = "Scope not specified."
  }

  validation {
    condition     = trimspace(var.details.purpose) != ""
    error_message = "Purpose not specified."
  }

  validation {
    condition     = trimspace(var.details.environment) != ""
    error_message = "Environment not specified."
  }
}

variable "encryption" {
  description = <<-EOT
    Encryption at rest. Messages are always encrypted. Without changes, the queue uses keys Amazon SQS manages (SSE-SQS), which costs nothing extra and needs no key policy.

    - `kms_key_id` - (Optional) Encrypt with an AWS Key Management Service (KMS) key instead: a key ID, key ARN, alias name (`alias/my-key`) or alias ARN. Every sender and receiver then needs permission to use the key, including AWS services such as Amazon SNS and Amazon S3, which need `kms:GenerateDataKey` and `kms:Decrypt` in the key policy. The key policy of the AWS managed key `alias/aws/sqs` cannot be changed, so use a customer managed key for a queue those services send to.
    - `kms_data_key_reuse_period_seconds` - (Optional) How long Amazon SQS reuses a data key before it calls KMS again, in seconds: 60 to 86400 (24 hours). Applies only with `kms_key_id`. Defaults to `300`. A longer period means fewer, cheaper KMS calls.
  EOT
  type = object({
    kms_key_id                        = optional(string)
    kms_data_key_reuse_period_seconds = optional(number, 300)
  })
  default  = {}
  nullable = false

  validation {
    condition     = try(trimspace(var.encryption.kms_key_id) != "", true)
    error_message = "encryption.kms_key_id must not be empty. Leave it unset to use SSE-SQS."
  }

  validation {
    condition     = var.encryption.kms_data_key_reuse_period_seconds >= 60 && var.encryption.kms_data_key_reuse_period_seconds <= 86400 && floor(var.encryption.kms_data_key_reuse_period_seconds) == var.encryption.kms_data_key_reuse_period_seconds
    error_message = "encryption.kms_data_key_reuse_period_seconds must be a whole number from 60 to 86400."
  }
}

variable "fifo" {
  description = <<-EOT
    Make the queue a FIFO (first-in, first-out) queue, which delivers each message exactly once and in the order it was sent, within each message group. `null`, the default, creates a standard queue, which delivers at least once and in roughly the order sent.

    The queue's name gets the `.fifo` suffix that AWS requires. A queue cannot be changed between standard and FIFO: changing this input replaces the queue, and every message in it is lost.

    - `content_based_deduplication` - (Optional) Use a SHA-256 hash of each message's body as its deduplication ID, so senders need not set one. Defaults to `false`.
    - `deduplication_scope` - (Optional) Whether duplicates are detected across the whole `queue` (the default) or within each `messageGroup`.
    - `throughput_limit` - (Optional) Whether the throughput quota applies to the whole queue, `perQueue` (the default), or to each message group, `perMessageGroupId`. `perMessageGroupId` requires `deduplication_scope = "messageGroup"`; set both for high throughput.
  EOT
  type = object({
    content_based_deduplication = optional(bool, false)
    deduplication_scope         = optional(string, "queue")
    throughput_limit            = optional(string, "perQueue")
  })
  default = null

  validation {
    condition     = var.fifo == null || contains(["queue", "messageGroup"], try(var.fifo.deduplication_scope, ""))
    error_message = "fifo.deduplication_scope must be \"queue\" or \"messageGroup\"."
  }

  validation {
    condition     = var.fifo == null || contains(["perQueue", "perMessageGroupId"], try(var.fifo.throughput_limit, ""))
    error_message = "fifo.throughput_limit must be \"perQueue\" or \"perMessageGroupId\"."
  }

  validation {
    condition     = try(var.fifo.throughput_limit, "") != "perMessageGroupId" || try(var.fifo.deduplication_scope, "") == "messageGroup"
    error_message = "fifo.throughput_limit = \"perMessageGroupId\" requires deduplication_scope = \"messageGroup\"."
  }
}

variable "max_message_size" {
  description = <<-EOT
    The largest message the queue accepts, in bytes: 1024 (1 KiB) to 1048576 (1 MiB). Defaults to `262144` (256 KiB). Values above 262144 need AWS provider 6.8.0 or later.
  EOT
  type        = number
  default     = 262144
  nullable    = false

  validation {
    condition     = var.max_message_size >= 1024 && var.max_message_size <= 1048576 && floor(var.max_message_size) == var.max_message_size
    error_message = "max_message_size must be a whole number from 1024 to 1048576."
  }
}

variable "message_retention_seconds" {
  description = <<-EOT
    How long the queue keeps a message that nobody deletes, in seconds: 60 (1 minute) to 1209600 (14 days). Defaults to `345600` (4 days).
  EOT
  type        = number
  default     = 345600
  nullable    = false

  validation {
    condition     = var.message_retention_seconds >= 60 && var.message_retention_seconds <= 1209600 && floor(var.message_retention_seconds) == var.message_retention_seconds
    error_message = "message_retention_seconds must be a whole number from 60 to 1209600."
  }
}

variable "name" {
  description = <<-EOT
    The name of the queue, unique within the account and Region: letters, numbers, hyphens and underscores. Leave off the `.fifo` suffix; the module adds it for a FIFO queue. The full name, with `.fifo` and the dead-letter queue's `-dlq`, must fit in 80 characters. Changing the name replaces the queue, and every message in it is lost.
  EOT
  type        = string
  nullable    = false

  validation {
    condition     = can(regex("^[A-Za-z0-9_-]+$", var.name))
    error_message = "name must be letters, numbers, hyphens and underscores only, without the .fifo suffix (set fifo instead)."
  }

  validation {
    condition     = length(var.name) + (var.fifo != null ? 5 : 0) + (try(var.dead_letter_queue.enabled, false) ? 4 : 0) <= 80
    error_message = "name is too long: with .fifo for a FIFO queue, and -dlq for the dead-letter queue, queue names must be at most 80 characters."
  }
}

variable "policy" {
  description = <<-EOT
    The queue policy, which lets AWS services and other accounts use the queue. A policy is created when any option below grants or denies access. The default creates one with only the encrypted-transport rule. The queue's own account can always use the queue through its IAM policies.

    - `require_encrypted_transport` - (Optional) Deny every request not made over HTTPS, on the queue and its dead-letter queue. Defaults to `true`.
    - `sns_topic_arns` - (Optional) Amazon SNS topics that may send messages to the queue, by ARN. Wildcards (`*`) are allowed in the topic name.
    - `s3_bucket_arns` - (Optional) Amazon S3 buckets in the queue's own account whose event notifications may send messages to the queue, by ARN. For a bucket in another account, write the statement yourself in `source_policy_documents`.
    - `source_policy_documents` - (Optional) JSON policy documents whose statements are added to the policy, for anything the options above do not cover, such as Amazon EventBridge rules or another account. A statement with no `Resource` or `NotResource` is given the queue's ARN. Statement IDs (`Sid`) must be unique across the whole policy. See the [EventBridge example](https://github.com/AutomateTheCloud/terraform-aws-sqs/tree/main/examples/eventbridge).
  EOT
  type = object({
    require_encrypted_transport = optional(bool, true)
    sns_topic_arns              = optional(list(string), [])
    s3_bucket_arns              = optional(list(string), [])
    source_policy_documents     = optional(list(string), [])
  })
  default  = {}
  nullable = false

  validation {
    condition     = alltrue([for arn in var.policy.sns_topic_arns : can(regex("^arn:aws[a-z-]*:sns:[a-z0-9-]+:[0-9]{12}:[A-Za-z0-9_*?.-]+$", arn))])
    error_message = "policy.sns_topic_arns must contain SNS topic ARNs (arn:aws:sns:<region>:<account ID>:<topic name>)."
  }

  validation {
    condition     = alltrue([for arn in var.policy.s3_bucket_arns : can(regex("^arn:aws[a-z-]*:s3:::[a-z0-9.*?-]+$", arn))])
    error_message = "policy.s3_bucket_arns must contain S3 bucket ARNs (arn:aws:s3:::<bucket name>)."
  }

  validation {
    condition     = alltrue([for doc in var.policy.source_policy_documents : can(jsondecode(doc).Statement[0])])
    error_message = "Each of policy.source_policy_documents must be a JSON policy document with a non-empty Statement list."
  }
}

variable "receive_wait_time_seconds" {
  description = <<-EOT
    How long a request to receive messages waits for one to arrive when the queue is empty, in seconds: 0 to 20. Defaults to `0`, which returns at once (short polling). Any value above 0 turns on long polling, which means fewer empty responses and a lower bill for consumers that poll often.
  EOT
  type        = number
  default     = 0
  nullable    = false

  validation {
    condition     = var.receive_wait_time_seconds >= 0 && var.receive_wait_time_seconds <= 20 && floor(var.receive_wait_time_seconds) == var.receive_wait_time_seconds
    error_message = "receive_wait_time_seconds must be a whole number from 0 to 20."
  }
}

variable "region" {
  description = <<-EOT
    The AWS Region to create the queue and its dead-letter queue in, such as `us-west-2`. Defaults to the Region of the AWS provider passed to the module.
  EOT
  type        = string
  default     = null
}

variable "visibility_timeout_seconds" {
  description = <<-EOT
    How long a message stays hidden from other consumers after one consumer receives it, in seconds: 0 to 43200 (12 hours). Defaults to `30`. Set it longer than your consumers take to process a message, or another consumer receives it too and it is processed twice. For an AWS Lambda trigger, AWS recommends at least six times the function's timeout.
  EOT
  type        = number
  default     = 30
  nullable    = false

  validation {
    condition     = var.visibility_timeout_seconds >= 0 && var.visibility_timeout_seconds <= 43200 && floor(var.visibility_timeout_seconds) == var.visibility_timeout_seconds
    error_message = "visibility_timeout_seconds must be a whole number from 0 to 43200."
  }
}
