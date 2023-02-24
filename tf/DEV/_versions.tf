terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
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
    vault = {
      source  = "hashicorp/vault"
      version = "~> 3.6.0"
    }
    #    kubernetes = {
    #      source  = "hashicorp/kubernetes"
    #      version = "~> 2.7.1"
    #    }
    #    helm = {
    #      source  = "hashicorp/helm"
    #      version = "~> 2.4.1"
    #    }
    #    http = {
    #      source  = "terraform-aws-modules/http"
    #      version = "2.4.1"
    #    }
  }
  required_version = "1.0.9"
}
