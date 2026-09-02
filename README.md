# Azure Landing Zone – Monolithic Application

Terraform-based Azure infrastructure project demonstrating reusable modules, environment isolation, remote state, and CI/CD with Azure DevOps.

## Architecture

The repository is organized around separate environments and reusable Terraform modules:

- `environments/dev` – development deployment
- `environments/qa` – QA deployment scaffold
- `environments/uat` – UAT deployment scaffold
- `environments/prod` – production deployment scaffold
- `modules/` – reusable Azure resource modules
- `azure-pipelines/` – Terraform CI/CD pipelines
- `docs/` – architecture and design documentation
- `security/` – security-related configuration and guidance
- `scripts/` – operational/helper scripts

## Terraform workflow

```text
terraform fmt
terraform init
terraform validate
terraform plan
terraform apply
```

Remote state is configured per environment using the AzureRM backend. Credentials and deployment secrets should be supplied through the Azure DevOps service connection/secret variables rather than committed to Git.

## CI/CD

The intended promotion flow is:

```text
Pull Request → Validate → Plan → Dev → QA → UAT → Production
                                      └─ manual approval before Prod
```

The pipeline definitions are kept in `azure-pipelines/terraform-ci.yml` and `azure-pipelines/terraform-cd.yml`.

## Security practices

- Never commit passwords, client secrets, certificates, or Terraform state.
- Use Azure DevOps secret variables/service connections for credentials.
- Use least-privilege Azure RBAC.
- Protect production with approvals and branch policies.
- Review Terraform plans before applying infrastructure changes.

## Local development

Run Terraform from the target environment directory, for example:

```bash
cd environments/dev
terraform init
terraform fmt -recursive
terraform validate
terraform plan
```

Do not commit generated `.terraform` directories, state files, plans, or local secret files.
