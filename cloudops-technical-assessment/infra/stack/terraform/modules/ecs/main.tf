resource "aws_ecs_cluster" "main" {
  name = "${var.environment}-cluster"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }
}

resource "aws_cloudwatch_log_group" "order_api" {
  name = "/ecs/${var.environment}-order-api"
}

resource "aws_cloudwatch_log_group" "order_processor" {
  name = "/ecs/${var.environment}-order-processor"
}

resource "aws_cloudwatch_log_group" "order_history" {
  name = "/ecs/${var.environment}-order-history"
}

locals {
  order_history_database_env = var.use_secrets_manager ? [] : [
    { name = "DATABASE_URL", value = "postgresql://${var.rds_db_username}:${var.rds_db_password}@${var.rds_endpoint}:${var.rds_port}/${var.rds_db_name}" }
  ]

  order_history_database_secret = var.use_secrets_manager ? [
    { name = "DATABASE_URL", valueFrom = var.rds_database_url_secret_arn }
  ] : []
}

resource "aws_ecs_task_definition" "order_api" {
  family                   = "${var.environment}-order-api"
  requires_compatibilities = ["EC2"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.ecs_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "order-api"
      image     = var.order_api_image
      essential = true
      portMappings = [
        {
          containerPort = 8000
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "DYNAMODB_TABLE", value = var.orders_table_name },
        # Internal service call via Cloud Map private DNS.
        # NOTE: Current baseline uses HTTP; true mTLS requires a service mesh path.
        { name = "ORDER_PROCESSOR_URL", value = "http://order-processor.${var.environment}.internal:8000" },
        { name = "SQS_QUEUE_URL", value = var.sqs_orders_queue_url }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.order_api.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "order_processor" {
  family                   = "${var.environment}-order-processor"
  requires_compatibilities = ["EC2"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.ecs_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "order-processor"
      image     = var.processor_image
      essential = true
      portMappings = [
        {
          containerPort = 8000
          protocol      = "tcp"
        }
      ]
      environment = [
        { name = "DYNAMODB_TABLE", value = var.inventory_table_name },
        # Internal service call via Cloud Map private DNS.
        # NOTE: Current baseline uses HTTP; true mTLS requires a service mesh path.
        { name = "ORDER_HISTORY_URL", value = "http://order-history-service.${var.environment}.internal:8000" },
        { name = "SQS_QUEUE_URL", value = var.sqs_orders_queue_url }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.order_processor.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "order_history" {
  family                   = "${var.environment}-order-history"
  requires_compatibilities = ["EC2"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"
  execution_role_arn       = var.ecs_execution_role_arn
  task_role_arn            = var.ecs_task_role_arn

  container_definitions = jsonencode([
    {
      name      = "order-history-service"
      image     = var.order_history_image
      essential = true
      portMappings = [
        {
          containerPort = 8000
          protocol      = "tcp"
        }
      ]
      environment = concat([
        { name = "DEFAULT_PAGE_SIZE", value = "20" },
        { name = "SQS_QUEUE_URL", value = var.sqs_orders_queue_url }
      ], local.order_history_database_env)
      secrets = local.order_history_database_secret
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.order_history.name
          awslogs-region        = data.aws_region.current.name
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "order_api" {
  name            = "${var.environment}-order-api"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.order_api.arn
  desired_count   = 1
  launch_type     = "EC2"

  network_configuration {
    security_groups  = [var.ecs_security_group_id]
    subnets          = var.private_subnets
    assign_public_ip = false
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.order_api.arn
    container_name   = "order-api"
    container_port   = 8000
  }

  service_registries {
    registry_arn = aws_service_discovery_service.order_api.arn
  }
}

resource "aws_ecs_service" "order_processor" {
  name            = "${var.environment}-order-processor"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.order_processor.arn
  desired_count   = 1
  launch_type     = "EC2"

  network_configuration {
    security_groups  = [var.ecs_security_group_id]
    subnets          = var.private_subnets
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.order_processor.arn
  }
}

resource "aws_ecs_service" "order_history" {
  name            = "${var.environment}-order-history"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.order_history.arn
  desired_count   = 1
  launch_type     = "EC2"

  network_configuration {
    security_groups  = [var.ecs_security_group_id]
    subnets          = var.private_subnets
    assign_public_ip = false
  }

  service_registries {
    registry_arn = aws_service_discovery_service.order_history.arn
  }
}
