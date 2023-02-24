# Contributing to dev-ambitfocus-aws-sdl

## Development Requirements

* [Terraform v1.0.9](https://releases.hashicorp.com/terraform/1.0.9/)
* [terraform-docs v0.16.0](https://github.com/terraform-docs/terraform-docs/)
  
## Terraform naming conventions
Please write your TF code in accordance with naming conventions described here:
https://www.terraform-best-practices.com/naming

## Change Process

1. Pull the latest Development branch from BitBucket
   
2. From Development branch create a feature branch named as the related Jira story (e.g git checkout -b CMCMP-633)
   
3. Work on your TF code:
   1. Incorporate your TF code in local module ./tf/modules/terraform-aws-bsmi
   Within the terraform-aws-bsmi module your code can either be placed in distinct file(s) named after the system component being managed (e.g. aws-rds-sql.tf) or in its own submodule under ./tf/modules/terraform-aws-bsmi/modules (e.g. terraform-aws-rdssql)
   2. Declare your required variables in ./tf/modules/terraform-aws-bsmi/_variables 
   3. Edit the invocation of terraform-aws-bsmi module in ./tf/DEV/main.tf by putting in the local variables required by your code
   4. Edit the ./tf/DEV/_locals.tf with the actual values for your variables
   
4. Login to TFE and verify your code:
   1. terraform login vlmaztform01.fisdev.local
   2. terraform plan
   
5. Run formatter and documentation generators:

    ```
    .\pre-commit.ps1
    ```

6. Commit changes, push the branch to Bitbucket and submit a PR to Development branch. Add Milos Radenkovic and Filippos Gournaras as reviewers

7. Once the feature branch is merged to Development branch, create a PR to Master branch which will be reviewed and approved by FCS team.