variable "api_gateway_rest_api" {
  type = object({
    id            = string
    name          = string
    execution_arn = string
  })
  description = "aws_api_gateway_rest_api containing the resource"
}

variable "api_gateway_resource" {
  type = object({
    id   = string
    path = string
  })
  description = "aws_api_gateway_resource which proxies to the lambda"
}

variable "lambda_function_name" {
  type        = string
  description = "proxied lambda function name"
}

variable "http_method" {
  type        = string
  description = "api method GET/POST/etc. for the api interface"
}

variable "authorization" {
  type = string
}

variable "execution_role_arn" {
  type        = string
  description = "role used to invoke the lambda"
}

variable "fis_tags" {
  description = "tags added to each resource created by this module"
  type = object({
    BUC             = string
    SupportGroup    = string
    AppGroupEmail   = string
    EnvironmentType = string
    CustomerCRMID   = string
  })
}
