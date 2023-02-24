<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.9 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.15.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_api_gateway_integration.invoke_lambda](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_integration) | resource |
| [aws_api_gateway_method.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method) | resource |
| [aws_api_gateway_method_response.ok](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/api_gateway_method_response) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_api_gateway_resource"></a> [api\_gateway\_resource](#input\_api\_gateway\_resource) | aws\_api\_gateway\_resource which proxies to the lambda | <pre>object({<br>    id   = string<br>    path = string<br>  })</pre> | n/a | yes |
| <a name="input_api_gateway_rest_api"></a> [api\_gateway\_rest\_api](#input\_api\_gateway\_rest\_api) | aws\_api\_gateway\_rest\_api containing the resource | <pre>object({<br>    id            = string<br>    name          = string<br>    execution_arn = string<br>  })</pre> | n/a | yes |
| <a name="input_authorization"></a> [authorization](#input\_authorization) | n/a | `string` | n/a | yes |
| <a name="input_execution_role_arn"></a> [execution\_role\_arn](#input\_execution\_role\_arn) | role used to invoke the lambda | `string` | n/a | yes |
| <a name="input_fis_tags"></a> [fis\_tags](#input\_fis\_tags) | tags added to each resource created by this module | <pre>object({<br>    BUC             = string<br>    SupportGroup    = string<br>    AppGroupEmail   = string<br>    EnvironmentType = string<br>    CustomerCRMID   = string<br>  })</pre> | n/a | yes |
| <a name="input_http_method"></a> [http\_method](#input\_http\_method) | api method GET/POST/etc. for the api interface | `string` | n/a | yes |
| <a name="input_lambda_function_name"></a> [lambda\_function\_name](#input\_lambda\_function\_name) | proxied lambda function name | `string` | n/a | yes |

## Outputs

No outputs.
<!-- END_TF_DOCS -->