# Complete

Most of the module's options in one queue:

- A FIFO queue, `example-complete-queue.fifo`, with content-based deduplication and high throughput (deduplication and the throughput quota per message group).
- Encryption with a customer managed AWS Key Management Service (KMS) key that the example creates, with automatic key rotation.
- A FIFO dead-letter queue, `example-complete-queue-dlq.fifo`, which receives a message after three failed receives and keeps it for 14 days.
- Long polling, a 5-minute visibility timeout and 7-day message retention.
- An extra `CostCenter` tag on every resource.

AWS charges a monthly fee for the KMS key; see [AWS KMS pricing](https://aws.amazon.com/kms/pricing/). `terraform destroy` schedules the key for deletion after 7 days, the shortest waiting period AWS allows.

## Run it

```shell
terraform init
terraform apply
aws sqs send-message --queue-url <url> --message-group-id orders --message-body "hello"
```

Remove it with `terraform destroy`.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (~> 6.0)

### Outputs

The following outputs are exported:

#### <a name="output_metadata"></a> [metadata](#output_metadata)

Description: Everything the module created
<!-- END_TF_DOCS -->
