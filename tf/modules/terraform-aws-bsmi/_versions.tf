terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      version               = "~> 4.0"
      configuration_aliases = [aws, aws.cluster_creator]
    }
    vault = {
      source                = "hashicorp/vault"
      version               = "~> 3.6.0"
      configuration_aliases = [vault.bsmi]
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.2"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.1"
    }
    artifactory = {
      source  = "jfrog/artifactory"
      version = "~> 6.9.3"
    }
  }
  required_version = ">= 1.0.9"
}
