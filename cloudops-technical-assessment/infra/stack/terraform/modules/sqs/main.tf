resource "aws_sqs_queue" "orders" {
  name                       = "${var.environment}-orders-queue"
  visibility_timeout_seconds = 1
  message_retention_seconds  = 345600
}
