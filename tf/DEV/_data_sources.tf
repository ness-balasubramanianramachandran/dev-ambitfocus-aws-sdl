data "aws_region" "current" {
}
data "aws_partition" "current" {
}
data "aws_vpc" "routable_vpc" {
  id = data.terraform_remote_state.dev-gateway-primary-aws.outputs.ambit_focus_vpc_id
}
data "aws_vpc" "nr_vpc" {
  id = data.terraform_remote_state.dev-gateway-primary-aws.outputs.ambit_focus_nr_vpc_id
}
