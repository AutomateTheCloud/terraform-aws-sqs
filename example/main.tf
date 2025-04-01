terraform {
  required_version = "~> 1.11.0"
}

##-----------------------------------------------------------------------------
# Providers
provider "aws" {
  alias  = "example"
  region = "us-east-1"
}

##-----------------------------------------------------------------------------
# Module: SQS
module "sqs" {
  source    = "../"
  providers = { aws.this = aws.example }

  details = {
    scope               = "Demo"
    purpose             = "SQS"
    environment         = "dev"
    additional_tags = {
      "Project"         = "Project Name"
      "ProjectID"       = "123456789"
      "Contact"         = "David Singer - david.singer@example.com"
    }
  }

  name                = "test-sqs"
  
  # fifo_queue = false
  # content_based_deduplication = false

  # kms_master_key_id = null
  # kms_data_key_reuse_period_seconds = 300

  dead_letter_queue = {
    enabled                   = true
    message_retention_seconds = 1209600
    redrive_max_receive_count = 6
  }
  
  policy_sns = [
    "arn:aws:sns:us-east-1:123456789:*"
  ]
  
  # policy_s3 = []

  max_message_size                  = 262144
  message_retention_seconds         = 300
  receive_wait_time_seconds         = 10
  visibility_timeout_seconds        = 120
}

##-----------------------------------------------------------------------------
# Resource: SNS Subscription
# resource "aws_sns_topic_subscription" "test" {
  # topic_arn = "arn:aws:sns:us-east-1:123456789:sns_topic_name"
  # protocol  = "sqs"
  # endpoint  = module.sqs.metadata.sqs.queue.arn
  # provider  = aws.example
# }

##-----------------------------------------------------------------------------
# Outputs
output "metadata" {
  description = "Metadata"
  value = module.sqs.metadata
}
