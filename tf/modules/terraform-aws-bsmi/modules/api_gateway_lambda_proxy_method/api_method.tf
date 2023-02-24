
resource "aws_api_gateway_method" "this" {
  authorization = var.authorization
  http_method   = var.http_method
  resource_id   = var.api_gateway_resource.id
  rest_api_id   = var.api_gateway_rest_api.id
}

resource "aws_api_gateway_integration" "invoke_lambda" {
  rest_api_id = var.api_gateway_rest_api.id
  resource_id = var.api_gateway_resource.id
  type        = "AWS_PROXY"
  http_method = var.http_method

  // execution role
  credentials = var.execution_role_arn

  // lambda functions can only be invoked via POST
  integration_http_method = "POST"
  // https://docs.aws.amazon.com/lambda/latest/dg/API_Invoke.html
  // arn:{partition}:apigateway:{region}:{subdomain.service|service}:{path|action}/{service_api}
  uri = "arn:${data.aws_partition.current.id}:apigateway:${data.aws_region.current.id}:lambda:path/2015-03-31/functions/arn:${data.aws_partition.current.id}:lambda:${data.aws_region.current.id}:${data.aws_caller_identity.current.account_id}:function:${var.lambda_function_name}/invocations"
}

resource "aws_api_gateway_method_response" "ok" {
  rest_api_id = var.api_gateway_rest_api.id
  resource_id = var.api_gateway_resource.id
  http_method = var.http_method
  status_code = "200"
}