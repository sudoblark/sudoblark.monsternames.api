output "cloudwatch_role_name" {
  description = "Name of the role API Gateway assumes to write execution logs"
  value       = aws_iam_role.cloudwatch.name
}

output "cloudwatch_role_arn" {
  description = "ARN of the role API Gateway assumes to write execution logs"
  value       = aws_api_gateway_account.account.cloudwatch_role_arn
}
