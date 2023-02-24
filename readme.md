# FIS Terraform Resource repository

## Development branch (how do we work together on TF code)

Developing TF code:
* create a feature branch with the name of Jira story (e.g. CMCMP-401)
* once you have your code create a PR to Development branch and add Milos Radenkovic and Filippos Gournaras as reviewers
* once development branch review is done, create a PR to master branch that will trigger the Terraform plan and apply to AWS SDL account (reviewed by FCS team)

**Table of Contents**

- [FIS Terraform Resource repository](#fis-terraform-resource-repository)
  - [Development branch (how do we work together on TF code)](#development-branch-how-do-we-work-together-on-tf-code)
  - [Project Description](#project-description)
  - [Contacts](#contacts)
    - [Primary Developer](#primary-developer)
    - [Engineering Contacts](#engineering-contacts)
  - [Dependent Modules](#dependent-modules)
  - [Using the resource](#using-the-resource)
    - [Obtaining Terraform to test locally](#obtaining-terraform-to-test-locally)
    - [Directory Structure](#directory-structure)

**Client Name:** XXXX

## Project Description

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aliquam cursus arcu nec convallis cursus. Quisque tellus diam, porttitor a diam in, volutpat vestibulum nisl. Aliquam at finibus leo, a suscipit dui. Phasellus egestas pulvinar lacus a lobortis. Cras porta arcu odio, ac finibus arcu pulvinar at. Nullam id nunc vel dolor imperdiet convallis vitae vel libero. Suspendisse id venenatis nulla. Donec nec magna nisl. Vestibulum malesuada tempus imperdiet. Sed rutrum erat quis mauris dictum aliquet. Nullam commodo velit sit amet augue elementum, sit amet vestibulum odio interdum. Nam lobortis quis nisl eget mattis.

## Contacts

### Primary Developer

*Insert Name*: <*Insert E-mail*>

### Engineering Contacts

*Insert Name*: <*Insert E-mail*>

## Dependent Modules

Module Name | Module Version | Module Location
----------- | -------------- | ---------------
n/a | n/a | n/a

## Using the resource

### Obtaining Terraform to test locally

[Download Terraform](https://www.terraform.io/downloads.html)

### Directory Structure

    .
    ├── tf              # All terraform configuration files should go in the tf directory
    │   ├── main.tf
    │   ├── outputs.tf
    │   ├── variables.tf
    │   ├── provider.tf
    │   ├── backend.tf
    ├── .gitignore
    ├── .editconfig
    ├── Jenkinsfile
    └── README.md
