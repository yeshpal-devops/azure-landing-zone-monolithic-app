# Low-Level Design

## Repository layout

| Path | Responsibility |
|---|---|
| `environments/dev` | Development Terraform root module and state configuration |
| `environments/qa` | QA environment configuration |
| `environments/uat` | UAT environment configuration |
| `environments/prod` | Production environment configuration |
| `modules/` | Reusable Azure resource modules |
| `azure-pipelines/` | Azure DevOps CI/CD definitions |
| `security/` | Security configuration and guidance |
| `scripts/` | Helper and operational scripts |

## Terraform standards

- Pin the AzureRM provider version per environment.
- Run `terraform fmt` and `terraform validate` in CI.
- Use an AzureRM backend for remote state.
- Keep state isolated by environment and never commit `.tfstate` files.
- Keep secrets out of `.tfvars` files stored in Git.

## Authentication

Azure DevOps should authenticate to Azure through an Azure Resource Manager service connection. The service connection should use least-privilege RBAC appropriate for the target environment.

## Production controls

Production deployments should require:

- reviewed pull request
- successful CI validation
- reviewed Terraform plan
- protected Azure DevOps environment
- manual approval/checks
