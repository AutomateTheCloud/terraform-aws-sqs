# Basic queue

A private standard queue with the module's defaults: encrypted with keys Amazon SQS manages (SSE-SQS), and a queue policy that refuses any request not made over HTTPS. Only the queue's own account can use it, through its IAM policies.

It adds long polling, so consumers wait up to 20 seconds for a message instead of getting an empty response, and a dead-letter queue, `example-basic-queue-dlq`, which receives any message that has been received five times without being deleted.

## Run it

```shell
terraform init
terraform apply
```

Send and receive a message with the AWS CLI:

```shell
aws sqs send-message --queue-url <url> --message-body "hello"
aws sqs receive-message --queue-url <url> --wait-time-seconds 20
```

Remove it with `terraform destroy`. Any messages still in the queues are deleted with them.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (~> 6.0)

### Outputs

The following outputs are exported:

#### <a name="output_queue"></a> [queue](#output_queue)

Description: URL and ARN of the queue and its dead-letter queue
<!-- END_TF_DOCS -->
