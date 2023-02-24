/**
 * File provided as part of base bitbucket scaffolding
 * this file should contain input variables.
 */


## FIS Cloud Services

variable "USER" {
  type        = string
  description = "User for AMBIT-FOCUS-PPSCRIPT"
  default     = null
}
variable "PASSWORD" {
  type        = string
  description = "Password for AMBIT-FOCUS-PPSCRIPT"
  default     = null
}

variable "vault_approle_role_id" {
  sensitive = true
}

variable "vault_approle_secret_id" {
  sensitive = true
}