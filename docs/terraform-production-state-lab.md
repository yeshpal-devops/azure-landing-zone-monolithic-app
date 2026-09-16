# Terraform Production State & Drift Lab

## Objective

Practice the production Terraform workflow for remote state, locking, drift detection, imports, resource-address changes, and failed applies in Azure environments.

## State model

Terraform state maps configuration/resource addresses to real infrastructure. For team-managed Azure environments, keep state in a protected remote backend rather than local developer state.

Recommended controls:

- Separate state per environment or independently managed stack.
- Restrict backend access with Azure RBAC.
- Enable storage versioning/recovery controls where supported.
- Do not commit `.tfstate` or `.tfstate.backup` to Git.
- Treat state as sensitive because resource attributes can contain sensitive values.
- Pin Terraform and provider versions through the repository's normal dependency process.

## Safe troubleshooting workflow

```text
Unexpected plan
    |
    +--> Is another Terraform operation running?
    |       |
    |       +--> Yes: wait for it
    |       +--> No: inspect stale lock carefully
    |
    +--> Compare configuration, state and Azure actual state
    |
    +--> Check resource/module address changes
    |
    +--> Check provider/variable changes
    |
    +--> Fix source configuration
    |
    +--> terraform plan
    |
    +--> Review before apply
```

Never use `terraform force-unlock` just because a lock exists. Confirm the operation is stale first. Never delete the state file to solve a locking or drift problem.

## Existing Azure resource not in state

If an Azure resource already exists but is not represented in Terraform state, Terraform may plan to create it. Verify the intended resource address and import the existing resource into state, then run `terraform plan` again.

Conceptual flow:

```bash
terraform import <resource-address> <azure-resource-id>
terraform plan
```

Import is not a substitute for writing correct configuration; the configuration should describe the desired final resource.

## Resource address changes

Renaming a resource block or changing `count`/`for_each` keys can make Terraform interpret an existing resource as removed and a new one as created. For intentional address changes, use a `moved` block or an appropriate state move so Terraform understands that the infrastructure identity did not change.

## Failed apply

Terraform is not an all-or-nothing database transaction. If an apply fails partway through, first inspect Azure's actual state and Terraform's resulting state. Then fix the root cause and generate a new plan.

```text
Apply failure
   |
   v
Check Terraform output
   |
   v
Check Azure actual resource state
   |
   v
Identify dependency/RBAC/policy/quota/network issue
   |
   v
Fix configuration or platform issue
   |
   v
terraform plan
   |
   v
Review + approved apply
```

Do not assume every resource was rolled back.

## Production CI/CD gate

```text
Pull Request
   |
   +--> fmt / validate
   +--> IaC security scan
   +--> terraform plan
   |
   v
Plan review + approval
   |
   v
Controlled apply
   |
   v
Post-deployment validation
```

Production applies should use the reviewed plan and least-privilege identity. Avoid direct Portal changes; when an emergency manual change is unavoidable, reconcile it back into Terraform so the source of truth is restored.

## Senior interview scenarios

### Drift

A developer changes an NSG rule in the Azure Portal and the next plan wants to revert it. Explain that this is configuration drift, determine whether the change was intentional, and either codify the intended change or allow Terraform to reconcile unauthorized drift.

### Unexpected destroy

If a plan proposes destruction, do not approve automatically. Inspect resource addresses, `for_each` keys, module changes, lifecycle rules, provider versions, variables and state before deciding whether replacement is actually intended.

### Stale lock

Verify no active deployment owns the lock. Only after confirming it is stale should an operator consider the controlled unlock procedure.

## Validation checklist

- [ ] Remote backend is used for team environments.
- [ ] Backend access is least privilege.
- [ ] State is treated as sensitive.
- [ ] State locking is understood and monitored.
- [ ] Drift is investigated before reconciliation.
- [ ] Existing resources are imported rather than recreated.
- [ ] Resource address changes use `moved`/state migration deliberately.
- [ ] Failed applies are followed by an actual-state check.
- [ ] Production plans are reviewed before apply.
- [ ] Emergency manual changes are reconciled into code.
