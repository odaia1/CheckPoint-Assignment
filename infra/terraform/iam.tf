data "aws_iam_policy_document" "ecs_task_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "ecs_task_execution_role" {
  name               = "checkpoint-assignment-ecs-exec"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

resource "aws_iam_role_policy_attachment" "ecs_exec_attach" {
  role      = aws_iam_role.ecs_task_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

resource "aws_iam_role" "producer_task_role" {
  name               = "checkpoint-assignment-producer-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

data "aws_iam_policy_document" "producer_policy" {
  statement {
    actions   = ["ssm:GetParameter"]
    resources = [module.ssm.parameter_arn]
  }

  statement {
    actions   = ["sqs:SendMessage"]
    resources = [module.sqs.queue_arn]
  }
}

resource "aws_iam_role_policy" "producer_inline" {
  name   = "checkpoint-assignment-producer-inline"
  role   = aws_iam_role.producer_task_role.id
  policy = data.aws_iam_policy_document.producer_policy.json
}

resource "aws_iam_role" "consumer_task_role" {
  name               = "checkpoint-assignment-consumer-task"
  assume_role_policy = data.aws_iam_policy_document.ecs_task_assume_role.json
}

data "aws_iam_policy_document" "consumer_policy" {
  statement {
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ChangeMessageVisibility"
    ]
    resources = [module.sqs.queue_arn]
  }

  statement {
    actions   = ["s3:PutObject"]
    resources = ["${module.s3.bucket_arn}/*"]
  }
}

resource "aws_iam_role_policy" "consumer_inline" {
  name   = "checkpoint-assignment-consumer-inline"
  role   = aws_iam_role.consumer_task_role.id
  policy = data.aws_iam_policy_document.consumer_policy.json
}

output "ecs_task_execution_role_arn" {
  value = aws_iam_role.ecs_task_execution_role.arn
}

output "producer_task_role_arn" {
  value = aws_iam_role.producer_task_role.arn
}

output "consumer_task_role_arn" {
  value = aws_iam_role.consumer_task_role.arn
}