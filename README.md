# Terraform module for Amazon SQS queues

Creates an Amazon Simple Queue Service (SQS) queue, which holds messages from the parts of an application that produce them until the parts that process them are ready, with its queue policy and an optional dead-letter queue.

The defaults are the settings most queues should have. A queue created with only the required inputs is encrypted, refuses any request not made over HTTPS, and can be used only by its own account, through its IAM policies.

## What it configures

| Setting | Default | Input |
|---|---|---|
| Queue type | Standard: at-least-once delivery, roughly in order | `fifo` |
| Encryption at rest | On, with keys Amazon SQS manages (SSE-SQS) | `encryption` |
| Requests not made over HTTPS | Denied by the queue policy | `policy.require_encrypted_transport` |
| Access for AWS services and other accounts | None | `policy` |
| Dead-letter queue | None | `dead_letter_queue` |
| Visibility timeout | 30 seconds | `visibility_timeout_seconds` |
| Message retention | 4 days | `message_retention_seconds` |
| Long polling | Off (short polling) | `receive_wait_time_seconds` |
| Delivery delay | None | `delay_seconds` |
| Largest message | 256 KiB | `max_message_size` |

## Usage

```hcl
module "sqs" {
  source  = "AutomateTheCloud/sqs/aws"
  version = "~> 1.0"

  details = {
    scope       = "Automate the Cloud"
    purpose     = "Order Processing"
    environment = "Production"
  }

  name = "orders"

  receive_wait_time_seconds = 20
  dead_letter_queue         = { max_receive_count = 5 }
}
```

`details` and `name` are the only required inputs. `details` sets the `Scope`, `Purpose` and `Environment` tags on every resource.

Send messages to the URL in `module.sqs.metadata.sqs_queue.url`, and grant IAM permissions on the ARN in `module.sqs.metadata.sqs_queue.arn`.

The module uses your default `aws` provider and creates everything in that provider's Region. To create the queue somewhere else without configuring another provider, set `region`:

```hcl
module "sqs_us_west_2" {
  source  = "AutomateTheCloud/sqs/aws"
  version = "~> 1.0"

  region  = "us-west-2"
  details = { scope = "Automate the Cloud", purpose = "Order Processing", environment = "Production" }
  name    = "orders"
}
```

Because `region` is an ordinary input, one module block can create a queue in each of several Regions with `for_each`.

To use a provider configured for another account, pass it explicitly with `providers = { aws = aws.other_account }`.

## The `details` input

Most modules ask only for what the resource itself needs. This one also requires `details`: three names that say what the queue belongs to, what it is for, and which environment it is in. Every Automate the Cloud module takes the same input, and requiring it is deliberate.

```hcl
details = {
  scope       = "Automate the Cloud" # what it belongs to: an organization, team or project
  purpose     = "Web Site"           # what it is for
  environment = "Production"         # which environment
}
```

**Every resource can be traced.** The three names become the `Scope`, `Purpose` and `Environment` tags on every resource the module creates. Months later, anyone looking at a queue in the AWS console, or at a line on the bill, can see who it belongs to and why it exists. With cost allocation tags turned on in AWS Billing, the same tags split your bill by project and environment. Because the input is required and checked, no resource can be created without them.

**One definition for a whole stack.** Write `details` once and pass the same value to every module, so the queue, the services that send to and read from it, and everything else are tagged alike. Tags you want everywhere, such as a cost center or the Terraform workspace, go in `additional_tags`:

```hcl
locals {
  details = {
    scope           = "Automate the Cloud"
    purpose         = "Web Site"
    environment     = "Production"
    additional_tags = { CostCenter = "1234", IaC = "true" }
  }
}

module "orders_queue" {
  source  = "AutomateTheCloud/sqs/aws"
  version = "~> 1.0"

  details = local.details
  name    = "web-site-orders"
}
```

**Consistent names.** The module turns each name into two short forms other resources can be named with: `abbr`, lowercase with words joined by underscores (`Web Site` becomes `web_site`), and `machine`, lowercase letters and numbers only (`website`), for resources that allow no underscores. It also works out a short form of the Region, such as `use1` for `us-east-1`. Every module derives these the same way, so names stay consistent across a stack. To choose your own short forms, set `scope_abbr`, `purpose_abbr` or `environment_abbr`, for example `environment_abbr = "prd"`.

**One output to reach everything.** All of it comes back in the `metadata` output, along with everything the module created, so a configuration needs only one reference: `module.orders_queue.metadata.sqs_queue.url` for the queue's URL, or `module.orders_queue.metadata.aws.region.abbr` for the Region's short form.

## Examples

Each example is a complete configuration you can run with `terraform init` and `terraform apply`.

- [Basic queue](https://github.com/AutomateTheCloud/terraform-aws-sqs/tree/main/examples/basic): a private, encrypted queue with long polling and a dead-letter queue.
- [SNS subscription](https://github.com/AutomateTheCloud/terraform-aws-sqs/tree/main/examples/sns-subscription): an Amazon SNS topic that delivers its messages to the queue.
- [EventBridge target](https://github.com/AutomateTheCloud/terraform-aws-sqs/tree/main/examples/eventbridge): an Amazon EventBridge rule that sends events to the queue, through a policy statement of your own.
- [Complete](https://github.com/AutomateTheCloud/terraform-aws-sqs/tree/main/examples/complete): most of the module's options in one FIFO queue, encrypted with a customer managed KMS key.

## Things to know

### Access for AWS services and other accounts

By default the only access to the queue is through IAM policies in its own account. The queue policy the module creates only denies requests that are not made over HTTPS.

- `policy.sns_topic_arns` lets the given Amazon SNS topics send messages to the queue. Subscribe the queue to each topic as well; see the [SNS subscription example](https://github.com/AutomateTheCloud/terraform-aws-sqs/tree/main/examples/sns-subscription).
- `policy.s3_bucket_arns` lets Amazon S3 event notifications from the given buckets send messages to the queue. Because a bucket's ARN does not name its account, the statement also requires the bucket to be in the queue's own account. For a bucket in another account, write the statement yourself.
- `policy.source_policy_documents` adds statements of your own, for anything else: another AWS service, or another account. A statement with no `Resource` is given the queue's ARN. Limit each grant to one source with an `aws:SourceArn` or `aws:SourceAccount` condition, as the [EventBridge example](https://github.com/AutomateTheCloud/terraform-aws-sqs/tree/main/examples/eventbridge) does.

### Encryption

Messages are always encrypted at rest. By default the queue uses keys Amazon SQS manages (SSE-SQS), which cost nothing extra and need no key policy. With `encryption.kms_key_id`, it uses an AWS Key Management Service (KMS) key instead. Everything that sends to or receives from the queue then needs permission to use the key. AWS services such as Amazon SNS, Amazon S3 and Amazon EventBridge need `kms:GenerateDataKey` and `kms:Decrypt` in the key's key policy, and the key policy of the AWS managed key `alias/aws/sqs` cannot be changed ([AWS documentation](https://docs.aws.amazon.com/AWSSimpleQueueService/latest/SQSDeveloperGuide/sqs-key-management.html)), so use a customer managed key for a queue those services send to.

Encryption can be changed on an existing queue, between SSE-SQS and a KMS key, without replacing it. After such a switch, the next plan shows the encryption attributes in `metadata` changing, though nothing in AWS changes: the AWS provider does not let the module set the unused setting explicitly, and it reads the new values back only on the next refresh. Apply that plan once, which changes no resources, and the difference goes away.

### Dead-letter queue

With `dead_letter_queue`, the module creates a second queue, `<name>-dlq`, and moves a message there after it has been received `max_receive_count` times without being deleted. Watch the dead-letter queue: a message there is one your consumers could not process. The dead-letter queue uses the same encryption and the same HTTPS rule as the queue, and a redrive allow policy lets only this queue send to it.

For a standard queue, a message's retention time counts from when it was first sent, not from when it was moved to the dead-letter queue, so keep the dead-letter queue's `message_retention_seconds` (14 days by default) longer than the queue's.

### FIFO queues

Set `fifo` to make a FIFO queue, which delivers each message once, in the order sent within each message group. The module adds the `.fifo` suffix AWS requires to the queue's name, and to the dead-letter queue's: a FIFO queue's dead-letter queue must also be a FIFO queue. Every message sent to a FIFO queue needs a message group ID, and a deduplication ID unless `content_based_deduplication` is on.

### Replacing a queue

Changing `name`, or switching between a standard and a FIFO queue, replaces the queue: Terraform deletes it, with every message in it, and creates an empty one with a new URL. Drain the queue first, or create the new queue alongside the old one and move your producers and consumers across. AWS also refuses to create a queue with the name of one deleted less than 60 seconds earlier.

### Visibility timeout

When a consumer receives a message, the message is hidden from other consumers for `visibility_timeout_seconds`. If the consumer does not delete it in that time, the message becomes visible again and another consumer receives it. Set the timeout longer than processing takes. For an AWS Lambda function triggered by the queue, AWS recommends at least six times the function's timeout.

### Message size

`max_message_size` can be up to 1 MiB (1048576 bytes). Values above 256 KiB (262144) need AWS provider 6.8.0 or later; earlier versions reject them at plan time.

## Contributing

Contributions are welcome, after review. Read [CONTRIBUTING.md](https://github.com/AutomateTheCloud/terraform-aws-sqs/blob/main/CONTRIBUTING.md) before opening a pull request, and report security problems as described in [SECURITY.md](https://github.com/AutomateTheCloud/terraform-aws-sqs/blob/main/SECURITY.md).

## Testing

The tests in `tests/` run offline against mocked AWS providers, so they need no AWS account:

```shell
terraform init
terraform test
```

## Reference

The sections below are generated from the code by [terraform-docs](https://terraform-docs.io). To update them, run `terraform-docs .`.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (>= 6.0)

### Required Inputs

The following input variables are required:

#### <a name="input_details"></a> [details](#input_details)

Description: Names and tags shared by every resource in the module. `scope`, `purpose` and `environment` become the `Scope`, `Purpose` and `Environment` tags, and are converted to abbreviations that other modules can use in resource names (see the `metadata` output). [The `details` input](https://github.com/AutomateTheCloud/terraform-aws-sqs#the-details-input) explains why it is required.

- `scope` - (Required) What the resource belongs to, such as an organization or project: `Automate the Cloud`.
- `purpose` - (Required) What the resource is for: `Web Site`.
- `environment` - (Required) The environment: `Production`.
- `scope_abbr`, `purpose_abbr`, `environment_abbr` - (Optional) Abbreviations to use instead of the generated ones, which are lowercase with words joined by underscores (`Web Site` becomes `web_site`).
- `additional_tags` - (Optional) More tags for every resource, such as `{ CostCenter = "1234" }`.

Type:

```hcl
object({
    scope            = string
    scope_abbr       = optional(string)
    purpose          = string
    purpose_abbr     = optional(string)
    environment      = string
    environment_abbr = optional(string)
    additional_tags  = optional(map(string), {})
  })
```

#### <a name="input_name"></a> [name](#input_name)

Description: The name of the queue, unique within the account and Region: letters, numbers, hyphens and underscores. Leave off the `.fifo` suffix; the module adds it for a FIFO queue. The full name, with `.fifo` and the dead-letter queue's `-dlq`, must fit in 80 characters. Changing the name replaces the queue, and every message in it is lost.

Type: `string`

### Optional Inputs

The following input variables are optional (have default values):

#### <a name="input_dead_letter_queue"></a> [dead_letter_queue](#input_dead_letter_queue)

Description: A dead-letter queue: a second queue that receives each message the queue's consumers have failed to process `max_receive_count` times, so one bad message cannot be retried until it expires. `null`, the default, creates none.

The dead-letter queue is named `<name>-dlq` (`<name>-dlq.fifo` for a FIFO queue), uses the same encryption and the same encrypted-transport rule as the queue, and accepts messages from this queue only.

- `enabled` - (Optional) Defaults to `true` when `dead_letter_queue` is set.
- `max_receive_count` - (Optional) How many times a message is received without being deleted before it is moved to the dead-letter queue: 1 to 1000. Defaults to `5`.
- `message_retention_seconds` - (Optional) How long the dead-letter queue keeps a message, in seconds: 60 (1 minute) to 1209600 (14 days). Defaults to `1209600`. For a standard queue, the time counts from when the message was first sent to the queue, not from when it was moved, so keep this longer than the queue's own `message_retention_seconds`.

Type:

```hcl
object({
    enabled                   = optional(bool, true)
    max_receive_count         = optional(number, 5)
    message_retention_seconds = optional(number, 1209600)
  })
```

Default: `null`

#### <a name="input_delay_seconds"></a> [delay_seconds](#input_delay_seconds)

Description: How long every new message stays invisible to consumers after it is sent, in seconds: 0 to 900 (15 minutes). Defaults to `0`.

Type: `number`

Default: `0`

#### <a name="input_encryption"></a> [encryption](#input_encryption)

Description: Encryption at rest. Messages are always encrypted. Without changes, the queue uses keys Amazon SQS manages (SSE-SQS), which costs nothing extra and needs no key policy.

- `kms_key_id` - (Optional) Encrypt with an AWS Key Management Service (KMS) key instead: a key ID, key ARN, alias name (`alias/my-key`) or alias ARN. Every sender and receiver then needs permission to use the key, including AWS services such as Amazon SNS and Amazon S3, which need `kms:GenerateDataKey` and `kms:Decrypt` in the key policy. The key policy of the AWS managed key `alias/aws/sqs` cannot be changed, so use a customer managed key for a queue those services send to.
- `kms_data_key_reuse_period_seconds` - (Optional) How long Amazon SQS reuses a data key before it calls KMS again, in seconds: 60 to 86400 (24 hours). Applies only with `kms_key_id`. Defaults to `300`. A longer period means fewer, cheaper KMS calls.

Type:

```hcl
object({
    kms_key_id                        = optional(string)
    kms_data_key_reuse_period_seconds = optional(number, 300)
  })
```

Default: `{}`

#### <a name="input_fifo"></a> [fifo](#input_fifo)

Description: Make the queue a FIFO (first-in, first-out) queue, which delivers each message exactly once and in the order it was sent, within each message group. `null`, the default, creates a standard queue, which delivers at least once and in roughly the order sent.

The queue's name gets the `.fifo` suffix that AWS requires. A queue cannot be changed between standard and FIFO: changing this input replaces the queue, and every message in it is lost.

- `content_based_deduplication` - (Optional) Use a SHA-256 hash of each message's body as its deduplication ID, so senders need not set one. Defaults to `false`.
- `deduplication_scope` - (Optional) Whether duplicates are detected across the whole `queue` (the default) or within each `messageGroup`.
- `throughput_limit` - (Optional) Whether the throughput quota applies to the whole queue, `perQueue` (the default), or to each message group, `perMessageGroupId`. `perMessageGroupId` requires `deduplication_scope = "messageGroup"`; set both for high throughput.

Type:

```hcl
object({
    content_based_deduplication = optional(bool, false)
    deduplication_scope         = optional(string, "queue")
    throughput_limit            = optional(string, "perQueue")
  })
```

Default: `null`

#### <a name="input_max_message_size"></a> [max_message_size](#input_max_message_size)

Description: The largest message the queue accepts, in bytes: 1024 (1 KiB) to 1048576 (1 MiB). Defaults to `262144` (256 KiB). Values above 262144 need AWS provider 6.8.0 or later.

Type: `number`

Default: `262144`

#### <a name="input_message_retention_seconds"></a> [message_retention_seconds](#input_message_retention_seconds)

Description: How long the queue keeps a message that nobody deletes, in seconds: 60 (1 minute) to 1209600 (14 days). Defaults to `345600` (4 days).

Type: `number`

Default: `345600`

#### <a name="input_policy"></a> [policy](#input_policy)

Description: The queue policy, which lets AWS services and other accounts use the queue. A policy is created when any option below grants or denies access. The default creates one with only the encrypted-transport rule. The queue's own account can always use the queue through its IAM policies.

- `require_encrypted_transport` - (Optional) Deny every request not made over HTTPS, on the queue and its dead-letter queue. Defaults to `true`.
- `sns_topic_arns` - (Optional) Amazon SNS topics that may send messages to the queue, by ARN. Wildcards (`*`) are allowed in the topic name.
- `s3_bucket_arns` - (Optional) Amazon S3 buckets in the queue's own account whose event notifications may send messages to the queue, by ARN. For a bucket in another account, write the statement yourself in `source_policy_documents`.
- `source_policy_documents` - (Optional) JSON policy documents whose statements are added to the policy, for anything the options above do not cover, such as Amazon EventBridge rules or another account. A statement with no `Resource` or `NotResource` is given the queue's ARN. Statement IDs (`Sid`) must be unique across the whole policy. See the [EventBridge example](https://github.com/AutomateTheCloud/terraform-aws-sqs/tree/main/examples/eventbridge).

Type:

```hcl
object({
    require_encrypted_transport = optional(bool, true)
    sns_topic_arns              = optional(list(string), [])
    s3_bucket_arns              = optional(list(string), [])
    source_policy_documents     = optional(list(string), [])
  })
```

Default: `{}`

#### <a name="input_receive_wait_time_seconds"></a> [receive_wait_time_seconds](#input_receive_wait_time_seconds)

Description: How long a request to receive messages waits for one to arrive when the queue is empty, in seconds: 0 to 20. Defaults to `0`, which returns at once (short polling). Any value above 0 turns on long polling, which means fewer empty responses and a lower bill for consumers that poll often.

Type: `number`

Default: `0`

#### <a name="input_region"></a> [region](#input_region)

Description: The AWS Region to create the queue and its dead-letter queue in, such as `us-west-2`. Defaults to the Region of the AWS provider passed to the module.

Type: `string`

Default: `null`

#### <a name="input_visibility_timeout_seconds"></a> [visibility_timeout_seconds](#input_visibility_timeout_seconds)

Description: How long a message stays hidden from other consumers after one consumer receives it, in seconds: 0 to 43200 (12 hours). Defaults to `30`. Set it longer than your consumers take to process a message, or another consumer receives it too and it is processed twice. For an AWS Lambda trigger, AWS recommends at least six times the function's timeout.

Type: `number`

Default: `30`

### Outputs

The following outputs are exported:

#### <a name="output_metadata"></a> [metadata](#output_metadata)

Description: Everything the module created, in one object, so that other configurations need only one reference:

- `details` - The scope, purpose and environment, each with its `name`, `abbr` (lowercase, words joined by underscores) and `machine` (lowercase letters and numbers only) forms, and the `tags` applied to every resource.
- `aws` - The `account.id`, and the `region` `name`, `abbr` (such as `use1` for `us-east-1`) and `description`.
- `sqs_queue` - The queue's `url` (also its `id`), `arn`, `name`, its settings, `tags` and `tags_all`. Send messages to the `url`, and grant IAM permissions on the `arn`.
- `sqs_queue_policy` - The queue policy's `policy` JSON, `queue_url` and `region`. `null` when no policy is created.
- `sqs_dead_letter_queue` - The same attributes as `sqs_queue`, for the dead-letter queue. `null` when there is none.
- `sqs_dead_letter_queue_policy` - The dead-letter queue's policy. `null` when it is not created.
- `sqs_dead_letter_queue_redrive_allow_policy` - The rule that only `sqs_queue` may send failed messages to the dead-letter queue. `null` when there is no dead-letter queue.
<!-- END_TF_DOCS -->

## License

This module is licensed under the [Apache License 2.0](https://github.com/AutomateTheCloud/terraform-aws-sqs/blob/main/LICENSE). See [NOTICE](https://github.com/AutomateTheCloud/terraform-aws-sqs/blob/main/NOTICE) for the copyright notice.

The Automate the Cloud name and logo are not covered by this license.

---

Maintained by [Automate the Cloud](https://automatethe.cloud), a Kentucky 501(c)(3) that teaches cloud infrastructure and helps nonprofits run theirs.
