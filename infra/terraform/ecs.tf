resource "aws_ecs_cluster" "this" {
  name = "checkpoint-assignment-cluster"
}

resource "aws_cloudwatch_log_group" "producer" {
  name              = "/ecs/checkpoint-assignment/producer"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "consumer" {
  name              = "/ecs/checkpoint-assignment/consumer"
  retention_in_days = 7
}

resource "aws_ecs_task_definition" "producer" {
  family                   = "checkpoint-assignment-producer"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.producer_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "producer"
      image     = var.producer_image
      essential = true
      portMappings = [
        { containerPort = 8080, hostPort = 8080, protocol = "tcp" }
      ]
      environment = [
        { name = "AWS_REGION",           value = var.aws_region },
        { name = "SQS_QUEUE_URL",        value = module.sqs.queue_url },
        { name = "SSM_TOKEN_PARAM_NAME", value = module.ssm.parameter_name }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.producer.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_task_definition" "consumer" {
  family                   = "checkpoint-assignment-consumer"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "256"
  memory                   = "512"

  execution_role_arn = aws_iam_role.ecs_task_execution_role.arn
  task_role_arn      = aws_iam_role.consumer_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "consumer"
      image     = var.consumer_image
      essential = true
      environment = [
        { name = "AWS_REGION",     value = var.aws_region },
        { name = "SQS_QUEUE_URL",  value = module.sqs.queue_url },
        { name = "S3_BUCKET",      value = module.s3.bucket_name },
        { name = "S3_PREFIX",      value = "events" },
        { name = "POLL_INTERVAL_SECONDS", value = "5" }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.consumer.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

resource "aws_ecs_service" "producer" {
  name            = "checkpoint-assignment-producer-svc"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.producer.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default_vpc_subnets.ids
    security_groups  = [aws_security_group.producer_sg.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.producer_tg.arn
    container_name   = "producer"
    container_port   = 8080
  }

  depends_on = [aws_lb_listener.http]
}

resource "aws_ecs_service" "consumer" {
  name            = "checkpoint-assignment-consumer-svc"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.consumer.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = data.aws_subnets.default_vpc_subnets.ids
    security_groups  = [aws_security_group.consumer_sg.id]
    assign_public_ip = true
  }
}