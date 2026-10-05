# EventBridge target

An Amazon EventBridge rule that sends matching events to an SQS queue.

The module has no option for EventBridge. Instead, the example passes its own policy statement in `policy.source_policy_documents`, which lets `events.amazonaws.com` send messages only on behalf of this one rule (`aws:SourceArn`). The statement has no `Resource`, so the module fills in the queue's ARN, which the configuration cannot reference before the queue exists. Use the same pattern for any other AWS service that sends to a queue.

The rule matches only events with the source `example.orders`, which nothing in AWS sends, so the queue stays empty until you send one yourself.

## Run it

```shell
terraform init
terraform apply
aws events put-events --entries '[{"Source":"example.orders","DetailType":"Order","Detail":"{\"id\":\"1\"}"}]'
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

Description: Receive the events from this queue
<!-- END_TF_DOCS -->
