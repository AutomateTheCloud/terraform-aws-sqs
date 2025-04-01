locals {
  sqs_queue_name = var.fifo_queue ? "${var.name}.fifo" : var.name
  sqs_dlq_name   = var.fifo_queue ? "${var.name}-dlq.fifo" : "${var.name}-dlq"
}
