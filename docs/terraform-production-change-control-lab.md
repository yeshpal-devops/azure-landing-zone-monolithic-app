# Terraform Production Change-Control Lab

## Purpose

This lab turns the Terraform production workflow into an evidence-driven change-control process suitable for Azure infrastructure managed by CI/CD.

The goal is not simply to run `terraform apply`, but to prove that the proposed change is understood, authorized, reversible where possible, and validated after deployment.

## 1. Production workflow

```text
Pull Request
    |
    v
Format + Validate
    |
    v
IaC Security Scan
    |
    v
Terraform Plan
    |
    v
Plan Review
    |
    +---- unexpected destroy/change? ----> STOP + investigate
    |
    v
Protected Environment Approval
    |
    v
Apply Approved Change
    |
    v
Post-Apply Validation
    |
    v
Evidence + Audit Record
```

## 2. Plan review checklist

Before approving a production plan, inspect:

- Resources to add, change, and destroy.
- Any replacement operations (`-/+`).
- Changes to networking, NSGs, routes, private endpoints, DNS, AKS, databases, and identity.
- Changes to resource names or Terraform addresses.
- Provider/module version changes.
- State/backend configuration changes.
- Sensitive-value changes.
- Unexpected drift.
- Dependency changes that could affect application availability.
- Whether the plan was generated from the intended commit and environment.

A large plan is not automatically unsafe, but every destructive or replacement operation must have an understood reason.

## 3. Safe commands

### Local validation

```bash
terraform fmt -check -recursive
terraform init
terraform validate
terraform plan
```

### CI validation without touching remote state

```bash
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
```

For a production deployment, the pipeline should use the protected remote backend and an identity with only the permissions required for the deployment.

## 4. Unexpected plan scenario

Example:

```text
Plan: 37 to add, 24 to change, 8 to destroy
```

Do not approve this automatically.

Investigation sequence:

1. Confirm the target subscription and environment.
2. Confirm the Terraform commit that generated the plan.
3. Review the Git diff.
4. Review provider and module changes.
5. Inspect state/backend configuration.
6. Identify every destroy/replace operation.
7. Check for manual Azure changes and drift.
8. Compare with the previous successful plan if available.
9. Determine whether the change is expected.
10. Test in a lower environment when practical.
11. Obtain production approval.
12. Apply only after the risk is understood.

## 5. Drift handling

```text
Azure resource changed manually
            |
            v
Terraform plan detects difference
            |
       +----+----+
       |         |
       v         v
Expected     Unexpected
change       change
       |         |
       v         v
Update       Investigate
code/state   owner + reason
       |         |
       +----+----+
            |
            v
      Re-run plan
```

Never edit `terraform.tfstate` manually as the first response to drift. Treat state as a critical source of infrastructure metadata and use Terraform/provider-supported workflows.

## 6. Importing existing Azure infrastructure

When infrastructure was created manually:

```text
Existing Azure resource
        |
        v
Terraform import
        |
        v
Terraform state
        |
        v
Write matching .tf configuration
        |
        v
terraform plan
        |
        v
Reconcile differences
```

Importing does not mean the resource is automatically production-ready under Terraform. The configuration still needs to represent the desired lifecycle, dependencies, tags, security settings, and environment conventions.

## 7. Production guardrails

Recommended controls:

- Remote Azure Storage backend.
- State locking/concurrency protection.
- Separate production state from lower environments.
- Protected production environment in CI/CD.
- Manual approval for production changes.
- Least-privilege deployment identity.
- No secrets in Git.
- IaC security scanning.
- Pull-request review/CODEOWNERS.
- Immutable build/plan evidence tied to the reviewed commit.
- Post-deployment validation.
- State backup/recovery controls.

## 8. Post-apply validation

Validation should prove both infrastructure health and application impact.

Examples:

```text
Terraform apply
   |
   +--> terraform output
   +--> Azure resource health
   +--> Network connectivity
   +--> AKS node/pod health
   +--> Application smoke test
   +--> Monitoring/alerts
```

For an AKS-related change, validate at minimum:

```bash
kubectl get nodes
kubectl get pods -A
kubectl get svc -A
```

Then verify application-specific health checks and relevant Azure Monitor signals.

## 9. Rollback thinking

Terraform does not provide a universal one-command production rollback.

The correct recovery depends on the resource and failure mode:

- Revert the Git change and generate a new plan.
- Restore the previous known-good configuration/version.
- Reapply the reviewed configuration.
- Use Azure-native recovery where applicable.
- Restore data from a validated backup for data-layer failures.

For databases and destructive infrastructure changes, recovery must be designed before deployment.

## 10. Senior interview answer

> “For production Terraform, I treat the plan as a change-control artifact. I validate and scan the configuration, generate the plan from the intended commit, inspect all creates/updates/destroys and especially replacements, investigate drift, then use a protected environment with least-privilege identity and approval before apply. After deployment I validate Azure resources and application health. If something fails, I revert the desired configuration or use the resource-specific recovery mechanism rather than assuming Terraform has a generic rollback command.”

## 11. Practice scenarios

### Scenario A — Unexpected destroy

A plan wants to destroy an NSG attached to an AKS subnet.

**Expected response:** stop, inspect dependencies and Terraform addresses/state, determine why Terraform wants replacement/removal, and do not apply until the network impact is understood.

### Scenario B — Manual production change

An administrator changes an NSG rule in Azure Portal.

**Expected response:** identify the change and business reason, decide whether code should adopt it or Terraform should reconcile it, then produce and review a new plan.

### Scenario C — Existing VM migration

A manually created VM must become Terraform-managed.

**Expected response:** discover dependencies, import the resource, create matching configuration, plan until differences are understood, then manage it through the normal PR/CI/CD workflow.
