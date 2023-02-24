output "lambda_security_group_id" {
  description = "Security group that should be applied to all lambdas invoked from this API"
  value       = aws_security_group.lambdas.id
}

output "api_gateway_private_url" {
  description = "The domain to use to access this api"
  value       = "https://${aws_api_gateway_deployment.this.rest_api_id}-${aws_vpc_endpoint.this.id}.execute-api.${data.aws_region.current.id}.amazonaws.com/prod"
}