variable "vpc_access" {
  type = object({
    id         = string
    arn        = string
    cidr_block = string
    cidr_block_associations = set(object({
      cidr_block = string
    }))
  })
  description = "vpc which should be able to access the private orchestration api"
}

variable "nr_vpc" {
  type = object({
    id         = string
    arn        = string
    cidr_block = string
    cidr_block_associations = set(object({
      cidr_block = string
    }))
  })
  description = "vpc to deploy the orchestration api into"
}

variable "name_prefix" {
  description = "name_prefix for resource names and Name tags"
}

variable "subnet_ids" {
  type        = set(string)
  description = "the specific vpc subnets to deploy the orchestration resources into"
}

variable "orchestration_lambda_role_name" {
  type        = string
  description = "Name of the IAM role to execute the orchestration Lambdas"
}

variable "step_function_name" {
  type        = string
  description = "name of step function that the orchestration api will start"
}
variable "step_function_arn" {
  type        = string
  description = "step function that the orchestration api will start"
}

variable "eks_cluster_name" {
  type        = string
  description = "the name of the EKS cluster that will be orchestrated"
}
variable "eks_cluster_arn" {
  type        = string
  description = "the EKS cluster ARN"
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
