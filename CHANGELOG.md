# Changelog

All notable changes to this module are listed here. The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/), and the module uses [semantic versioning](https://semver.org/): a new major version means callers must change their code.

## [Unreleased]

## [1.0.0] - 2026-10-05

Initial release.

### Added

- An Amazon SQS queue with secure defaults: encrypted with SSE-SQS, requests not made over HTTPS denied, and no access for other accounts or services.
- Standard and FIFO queues, including FIFO high throughput and content-based deduplication.
- Encryption with a customer managed AWS KMS key, for the queue and its dead-letter queue.
- An optional dead-letter queue that only the queue can send to.
- A queue policy with grants for Amazon SNS topics and Amazon S3 event notifications, and your own statements through `policy.source_policy_documents`.
- Validation at plan time of every setting AWS limits.
- `region`, to create the queue in a Region other than the provider's.
- A `metadata` output with everything the module created.
- Offline tests, and examples for a basic queue, an SNS subscription, an EventBridge target, and most options together.

[Unreleased]: https://github.com/AutomateTheCloud/terraform-aws-sqs/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/AutomateTheCloud/terraform-aws-sqs/releases/tag/v1.0.0
