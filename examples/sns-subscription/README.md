# SNS subscription

An Amazon Simple Notification Service (SNS) topic that delivers every message published to it to an SQS queue. This is the usual way to send one event to several consumers: each consumer gets its own queue, subscribed to the same topic.

The module's `policy.sns_topic_arns` adds a queue policy statement that lets only this topic send to the queue. The subscription uses raw message delivery, so the queue receives the message as it was published, without the JSON envelope SNS otherwise wraps around it.

The queue uses the default encryption, with keys Amazon SQS manages. With a customer managed KMS key instead, the key policy must also let `sns.amazonaws.com` use the key, or SNS cannot deliver.

## Run it

```shell
terraform init
terraform apply
aws sns publish --topic-arn <topic_arn> --message "hello"
aws sqs receive-message --queue-url <queue_url> --wait-time-seconds 20
```

Remove it with `terraform destroy`.

<!-- BEGIN_TF_DOCS -->
### Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement_terraform) (>= 1.9)

- <a name="requirement_aws"></a> [aws](#requirement_aws) (~> 6.0)

### Outputs

The following outputs are exported:

#### <a name="output_queue_url"></a> [queue_url](#output_queue_url)

Description: Receive from this queue

#### <a name="output_topic_arn"></a> [topic_arn](#output_topic_arn)

Description: Publish to this topic
<!-- END_TF_DOCS -->
