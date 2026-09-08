# DevSecOps CI/CD Security — Senior DevOps Lab

## Objective

Build a practical security gate for an Azure DevOps/GitHub Actions delivery pipeline so that infrastructure and application changes are validated before deployment to AKS/Azure.

## Reference flow

```text
Developer
   |
   v
Pull Request
   |
   +--> Secret / credential scanning
   +--> SAST / dependency checks
   +--> Terraform fmt + validate + plan
   +--> IaC security scan
   +--> Container build
   +--> Image vulnerability scan
   |
   v
Approval / protected environment
   |
   v
Deploy to AKS
   |
   v
Smoke test + monitoring
```

## Security principles

- Never store Azure client secrets, passwords, kubeconfigs, or registry credentials in Git.
- Prefer GitHub Actions OIDC / Azure federated workload identity over long-lived Azure service-principal secrets.
- Keep production deployment behind a protected environment and approval where required.
- Use least-privilege Azure RBAC for the CI identity; separate plan/read permissions from deployment permissions when practical.
- Treat Terraform plan output as a review artifact, not an automatic approval to deploy.
- Scan dependencies and container images before promotion.
- Pin critical GitHub Actions to trusted versions/SHAs where the team's supply-chain policy requires it.

## Terraform gate

```bash
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
terraform plan -out=tfplan
```

For CI, the plan should be reviewed and the same approved artifact should be used for the controlled deployment path. Do not run an unrestricted `terraform apply` from an untrusted pull request.

## Container security gate

Recommended checks before pushing/promoting an image:

1. Build the image from a minimal trusted base.
2. Scan the image for known vulnerabilities.
3. Fail or quarantine the build according to severity policy.
4. Push only approved images to ACR.
5. Deploy an immutable image tag/digest to AKS.

Example:

```text
Source
  -> Build
  -> Test
  -> Scan
  -> ACR
  -> AKS
```

## OIDC / federated identity pattern

```text
GitHub Actions
      |
      | OIDC token
      v
Microsoft Entra ID
      |
Federated credential
      |
Azure RBAC
      |
Azure resources
```

The workflow receives short-lived identity credentials rather than keeping a long-lived Azure client secret in GitHub repository secrets.

## AKS deployment controls

- Use a dedicated deployment identity.
- Scope ACR permissions to the required registry.
- Separate namespaces and RBAC permissions where appropriate.
- Keep Kubernetes manifests free of plaintext secrets.
- Prefer workload identity/Key Vault integration for application secrets.
- Validate image provenance and vulnerability status before production promotion.
- Keep production deployment credentials unavailable to pull-request jobs.

## Pull-request threat model

An untrusted pull request must not be able to use production credentials simply because the repository workflow runs automatically. Separate PR validation from privileged deployment workflows and ensure privileged jobs only run after trusted review/approval.

## Senior troubleshooting scenarios

### Terraform plan suddenly shows destructive changes
Check state/backend, provider version, variable changes, resource lifecycle settings, and drift before approving. Never hide a destructive plan just to make CI green.

### CI can authenticate to GitHub but cannot access Azure
Validate OIDC permissions, Entra federated credential subject/audience, workflow environment/ref conditions, Azure RBAC scope, and the target subscription/resource group.

### AKS deployment succeeds but image pull fails
Validate ACR reachability, identity, `AcrPull` permission, image name/tag or digest, and cluster/node/workload identity configuration.

## Implementation checklist

- [ ] PR validation workflow
- [ ] Terraform fmt/validate/plan gate
- [ ] SAST/dependency scan
- [ ] IaC security scan
- [ ] Container vulnerability scan
- [ ] OIDC-based Azure authentication
- [ ] Protected production environment
- [ ] Immutable image promotion
- [ ] AKS smoke test
- [ ] Deployment audit trail

## Senior interview answer

> "I separate untrusted PR validation from privileged deployment. The PR pipeline runs tests, Terraform validation/plan, IaC and dependency checks, and container scanning. The trusted deployment workflow authenticates to Azure through OIDC/federated identity, uses least-privilege RBAC, promotes an immutable image to ACR, and deploys to a protected AKS environment with approval and post-deployment validation."
