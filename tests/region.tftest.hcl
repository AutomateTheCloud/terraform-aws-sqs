# Copyright 2026 Automate the Cloud Inc.
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
  details = { scope = "Test", purpose = "Region", environment = "test" }
  name    = "test-queue"
}

run "provider_region_by_default" {
  command = plan
  assert {
    condition     = output.metadata.aws.region.name == "us-east-1"
    error_message = "Expected the provider's Region."
  }
}

run "region_reaches_every_resource" {
  command = apply
  variables {
    region            = "us-west-2"
    dead_letter_queue = {}
  }
  assert {
    condition = alltrue([
      data.aws_region.this.region == "us-west-2",
      aws_sqs_queue.this.region == "us-west-2",
      aws_sqs_queue.dead_letter[0].region == "us-west-2",
      aws_sqs_queue_policy.this[0].region == "us-west-2",
      aws_sqs_queue_policy.dead_letter[0].region == "us-west-2",
      aws_sqs_queue_redrive_allow_policy.dead_letter[0].region == "us-west-2",
      output.metadata.aws.region.name == "us-west-2",
    ])
    error_message = "region was not passed through to every resource."
  }
}

# Any Region plans, including ones missing from the old module's table (bug fix).
run "region_not_in_old_table" {
  command = plan
  variables { region = "mx-central-1" }
  assert {
    condition     = output.metadata.aws.region.abbr == "mxc1"
    error_message = "Unexpected abbreviation."
  }
}

run "region_abbreviation_new_region" {
  command = plan
  variables { region = "ap-southeast-7" }
  assert {
    condition     = output.metadata.aws.region.abbr == "apse7"
    error_message = "Unexpected abbreviation."
  }
}

run "region_abbreviation_override" {
  command = plan
  variables { region = "us-gov-west-1" }
  assert {
    condition     = output.metadata.aws.region.abbr == "ugw1"
    error_message = "Unexpected abbreviation."
  }
}
