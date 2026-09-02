# High-Level Design

## Objective

Provision a repeatable Azure foundation for a monolithic application using Terraform modules and isolated environment configurations.

## Logical architecture

```text
Azure Subscription
        |
        +-- Resource Group
        |     |
        |     +-- Storage Account
        |     +-- Virtual Network
        |           +-- Subnets
        |
        +-- Additional application modules
              (environment-specific)

Terraform
   |
   +-- Reusable modules
   +-- Environment configuration
   +-- AzureRM remote state
   +-- Azure DevOps CI/CD
```

## Environment model

Each environment has its own Terraform working directory and state key. Changes are promoted through Dev, QA, UAT and Production with production protected by approval/checks.

## Security

Credentials are supplied through Azure DevOps service connections/secret variables. Terraform state must be stored in a protected Azure Storage account with appropriate RBAC and locking.
