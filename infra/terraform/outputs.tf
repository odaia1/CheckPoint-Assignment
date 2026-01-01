output "queue_url" {
  value = module.sqs.queue_url
}

output "queue_arn" {
  value = module.sqs.queue_arn
}

output "data_bucket_name" {
  value = module.s3.bucket_name
}

output "data_bucket_arn" {
  value = module.s3.bucket_arn
}

output "token_param_name" {
  value = module.ssm.parameter_name
}

output "token_param_arn" {
  value = module.ssm.parameter_arn
}

output "producer_ecr_repo_url" {
  value = module.ecr_producer.repository_url
}

output "consumer_ecr_repo_url" {
  value = module.ecr_consumer.repository_url
}