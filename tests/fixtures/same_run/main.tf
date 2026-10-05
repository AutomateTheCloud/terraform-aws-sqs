# Copyright 2025 Automate the Cloud Inc.
# SPDX-License-Identifier: Apache-2.0

# A KMS key, an SNS topic and an S3 bucket whose ARNs are not known until apply, as
# when they are created in the same run as the queue. A random suffix stands in for
# them, so the fixture creates no unprotected resource that a security scan would flag.

terraform {
  required_version = ">= 1.9"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.0"
    }
    random = {
      source  = "hashicorp/random"
      version = ">= 3.0"
    }
  }
}

resource "random_id" "this" {
  byte_length = 4
}

locals {
  kms_key_arn   = "arn:aws:kms:us-east-1:111111111111:key/${random_id.this.hex}"
  sns_topic_arn = "arn:aws:sns:us-east-1:111111111111:topic-${random_id.this.hex}"
  s3_bucket_arn = "arn:aws:s3:::bucket-${random_id.this.hex}"
}

module "sqs" {
  source = "../../.."

  details           = { scope = "Test", purpose = "Same Run", environment = "test" }
  name              = "same-run-queue"
  dead_letter_queue = {}
  encryption        = { kms_key_id = local.kms_key_arn }

  policy = {
    sns_topic_arns = [local.sns_topic_arn]
    s3_bucket_arns = [local.s3_bucket_arn]
  }
}

output "kms_key_arn" {
  value = local.kms_key_arn
}

output "metadata" {
  value = module.sqs.metadata
}
