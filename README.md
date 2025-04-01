# AWS - SQS - Terraform Module
Terraform module to create an SQS Queue (AutomateTheCloud model)

***

## Usage
```hcl
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
```

***

## Inputs
| Name | Description | Type | Default |
|------|-------------|:----:|:-------:|
| `content_based_deduplication` | Enables content-based deduplication for FIFO queues | `bool` | `false` |
| `delay_seconds` | Time in seconds that the delivery of all messages in the queue will be delayed (0 to 900) | `number` | `0` |
| `dead_letter_queue` | Dead Letter Queue | `any` | |
| `fifo_queue` | Boolean designating a FIFO queue | `bool` | `false` |
| `kms_master_key_id` | The ID of an AWS-managed customer master key (CMK) for Amazon SQS or a custom CMK | `string` | `null` |
| `kms_data_key_reuse_period_seconds` | The length of time, in seconds, for which Amazon SQS can reuse a data key to encrypt or decrypt messages before calling AWS KMS again. An integer representing seconds, between 60 seconds (1 minute) and 86,400 seconds (24 hours) | `number` | `300` |
| `max_message_size` | The limit of how many bytes a message can contain before Amazon SQS rejects it (`1024` to `262144`) | `number` | `262144` |
| `message_retention_seconds` | The number of seconds Amazon SQS retains a message (`60` to `1209600`) | `number` | `345600` |
| `name` | SQS Queue Name | `string` | |
| `policy_s3` | SQS Policy - S3 Bucket ARN List | `list` | `[]` |
| `policy_sns` | SQS Policy - SNS Topic ARN List | `list` | `[]` |
| `receive_wait_time_seconds` | The time for which a ReceiveMessage call will wait for a message to arrive (long polling) before returning (`0` to `20`) | `number` | `0` |
| `sse_enabled` | SSE Enabled | `bool` | `false` |
| `visibility_timeout_seconds` | The visibility timeout for the queue (0 to 43200) | `number` | `30` |

## Inputs (Details)
| Name | Description | Type | Default |
|------|-------------|:----:|:-------:|
| `details.scope` | (Required) Scope Name - What does this object belong to? (Organization Name, Project, etc) | `string` | |
| `details.scope_abbr` | (Optional) Scope [Abbreviation](#Abbreviations) Override | `string` | |
| `details.purpose` | (Required) Purpose Name - What is the purpose or function of this object, or what does this object server? | `string` | |
| `details.purpose_abbr` | (Optional) Purpose [Abbreviation](#Abbreviations) Override | `string` | |
| `details.environment` | (Required) Environment Name | `string` | |
| `details.environment_abbr` | (Optional) Environment [Abbreviation](#Abbreviations) Override | `string` | |
| `details.additional_tags` | (Optional) [Additional Tags](#Additional-Tags) for resources | `map` | `[]` |

***

## Outputs
All outputs from this module are mapped to a single output named `metadata` to make it easier to capture all of the relevant metadata that would be useful when referenced by other stacks (requires only a single output reference in your code, instead of dozens!)

| Name | Description |
|:-----|:------------|
| `details.scope.name` | Scope name |
| `details.scope.abbr` | Scope abbreviation |
| `details.scope.machine` | Scope machine-friendly abbreviation |
| `details.purpose.name` | Purpose name |
| `details.purpose.abbr` | Purpose abbreviation |
| `details.purpose.machine` | Purpose machine-friendly abbreviation |
| `details.environment.name` | Environment name |
| `details.environment.abbr` | Environment abbreviation |
| `details.environment.machine` | Environment machine-friendly abbreviation |
| `details.tags` | Map of tags applied to all resources |
| `aws.account.id` | AWS Account ID |
| `aws.region.name` | AWS Region name, example: `us-east-1` |
| `aws.region.abbr` | AWS Region four letter abbreviation, example: `use1` |
| `aws.region.description` | AWS Region description, example: `US East (N. Virginia)` |
| `sqs.queue` | SQS (Queue)|
| `sqs.queue_dlq` | SQS (Dead Letter Queue) |

***

## Notes

### Abbreviations
* When generating resource names, the module converts each identifier to a more 'machine-friendly' abbreviated format, removing all special characters, replacing spaces with underscores (_), and converting to lowercase. Example: 'Demo - Module' => 'demo_module'
* Not all resource names allow underscores. When those are encountered, the detail identifier will have the underscore removed (test_example => testexample) automatically. This machine-friendly abbreviation is referred to as 'machine' within the module.
* The abbreviations can be overridden by suppling the abbreviated names (ie: scope_abbr). This is useful when you have a long name and need the created resource names to be shorter. Some resources in AWS have shorter name constraints than others, or you may just prefer it shorter. NOTE: If specifying the Abbreviation, be sure to follow the convention of no spaces and no special characters (except for underscore), otherwise resoure creation may fail.

### Additional Tags
* You can specify additional tags for resources by adding to the `details.additional_tags` map.
```
additional_tags = {
  "Example"         = "Extra Tag"
  "Project"         = "Project Name"
  "CostCenter"      = "123456"
}
```

***

## Terraform Versions
Terraform ~> 1.11.0 is supported.

## Provider Versions
| Name | Version |
|------|---------|
| aws | `~> 5.93` |
