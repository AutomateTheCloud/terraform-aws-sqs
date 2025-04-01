variable "content_based_deduplication" {
  description = "Enables content-based deduplication for FIFO queues"
  type        = bool
  default     = false
}

variable "delay_seconds" {
  description = "Time in seconds that the delivery of all messages in the queue will be delayed (0 to 900)"
  type        = number
  default     = 0
}

variable "dead_letter_queue" {
  description = "Dead Letter Queue"
  type        = any
  default     = null
}

variable "fifo_queue" {
  description = "Boolean designating a FIFO queue"
  type        = bool
  default     = false
}

variable "kms_master_key_id" {
  description = "The ID of an AWS-managed customer master key (CMK) for Amazon SQS or a custom CMK"
  type        = string
  default     = null
}

variable "kms_data_key_reuse_period_seconds" {
  description = "The length of time, in seconds, for which Amazon SQS can reuse a data key to encrypt or decrypt messages before calling AWS KMS again. An integer representing seconds, between 60 seconds (1 minute) and 86,400 seconds (24 hours)"
  type        = number
  default     = 300
}

variable "max_message_size" {
  description = "Limit of how many bytes a message can contain before Amazon SQS rejects it (1024 to 262144)"
  type        = number
  default     = 262144
}

variable "message_retention_seconds" {
  description = "Number of seconds Amazon SQS retains a message (60 to 1209600)"
  type        = number
  default     = 345600
}

variable "name" {
  description = "SQS Queue Name"
  type        = string
  default     = null
}

variable "policy_s3" {
  description = "SQS Policy - S3 Bucket ARN List"
  type        = list(any)
  default     = []
}

variable "policy_sns" {
  description = "SQS Policy - SNS Topic ARN List"
  type        = list(any)
  default     = []
}

variable "receive_wait_time_seconds" {
  description = "Time for which a ReceiveMessage call will wait for a message to arrive (long polling) before returning (0 to 20)"
  type        = number
  default     = 0
}

variable "sse_enabled" {
  description = "SSE Enabled"
  type        = bool
  default     = false
}

variable "visibility_timeout_seconds" {
  description = "Visibility timeout for the queue (0 to 43200)"
  type        = number
  default     = 30
}
