# Azure Management & Governance

## Purpose

This document defines the management and governance controls for the Azure landing-zone-style project. The goal is to keep infrastructure secure, compliant, traceable, and cost-controlled across Dev, QA, UAT, and Production.

## Governance hierarchy

```text
Management Group
      |
      +-- Production Subscription
      |       +-- Resource Groups
      |               +-- Azure Resources
      |
      +-- Non-Production Subscription(s)
              +-- Resource Groups
                      +-- Azure Resources
```

Governance policies applied at a higher scope can be inherited by child subscriptions and resources.

## Core controls

| Control | Purpose | Example |
|---|---|---|
| Management Groups | Organize subscriptions | Separate production and non-production governance |
| Azure Policy | Enforce configuration/compliance | Restrict regions; require tags |
| Azure RBAC | Control who can perform actions | Least-privilege role assignments |
| Managed Identity | Remove application credentials | AKS/VM access to Key Vault or ACR |
| Resource Locks | Prevent accidental changes/deletion | Protect critical production resources |
| Tags | Ownership/cost classification | `environment`, `owner`, `costCenter` |
| Activity Log | Audit control-plane operations | Investigate resource changes |
| Cost Management | Track and control spend | Budgets and cost analysis |
| Azure Advisor | Optimization recommendations | Cost, security, reliability and performance guidance |

## Azure Policy

Use policy-as-code to define guardrails rather than relying on manual review.

Recommended baseline policies:

- Allowed Azure regions
- Required `environment` tag
- Required `owner` tag
- Required `costCenter` tag
- Deny or audit public network exposure where appropriate
- Require secure transport/TLS settings where supported
- Restrict unsupported resource SKUs or resource types where appropriate

Typical effects to understand:

- **Deny** — blocks a non-compliant deployment/change.
- **Audit** — records non-compliance without blocking deployment.
- **Modify** — changes resource properties or tags where supported.
- **DeployIfNotExists** — deploys supporting configuration when a required resource/configuration is missing.

## RBAC model

Prefer least privilege and assign roles at the narrowest practical scope.

```text
Reader       -> view only
Contributor  -> manage resources, not access assignments
Owner        -> full resource management including access management
```

Avoid using `Owner` as a default DevOps role. Use resource-specific or custom roles where the built-in roles provide more permission than required.

## Managed Identity

Prefer managed identities over storing service-principal secrets in source code or pipeline variables when Azure workloads need to authenticate to Azure services.

Example:

```text
AKS workload / VM
       |
       v
Managed Identity
       |
       v
Azure RBAC
       |
       v
Key Vault / ACR / Azure Resource
```

The identity receives only the permissions required for its workload.

## Resource Locks

Use locks selectively on critical production resources. A `CanNotDelete` lock is useful when the resource must remain manageable but accidental deletion must be prevented.

Locks are a protection layer, not a replacement for RBAC, Policy, backups, or change-management controls.

## Tagging standard

Recommended baseline:

```text
environment = dev|qa|uat|prod
owner       = team-or-owner
costCenter  = business-cost-center
application = application-name
managedBy   = terraform
```

Tags should be enforced through Azure Policy where appropriate and should remain consistent across environments.

## Terraform implementation strategy

Governance should be managed as code wherever practical:

```text
Terraform
   |
   +-- Azure Policy definitions / assignments
   +-- RBAC assignments
   +-- Resource locks
   +-- Tags
   +-- Managed identities
   +-- Infrastructure resources
```

CI should run formatting, initialization, validation, plan and security checks before apply. Production applies should use protected environments and explicit approvals.

## Production governance flow

```text
Pull Request
     |
     v
Terraform fmt / validate / security scan
     |
     v
Terraform plan
     |
     v
Code review
     |
     v
Approved CI/CD stage
     |
     v
Production approval
     |
     v
Terraform apply
     |
     v
Azure Activity Log / Monitor
```

## Troubleshooting checklist

### Unauthorized resource deployment

1. Check the deployment error and Azure Policy compliance result.
2. Identify the policy assignment and scope.
3. Check whether the resource violates an allowed-region, tag, SKU, or security policy.
4. Correct the Terraform configuration rather than bypassing the guardrail.

### User cannot modify a resource

1. Confirm Entra identity.
2. Check RBAC assignments at subscription, resource group, and resource scope.
3. Check deny assignments and Azure Policy.
4. Confirm whether a resource lock is preventing the operation.

### Unexpected production change

1. Review Activity Log.
2. Identify the caller and operation.
3. Check RBAC assignment and pipeline/service connection identity.
4. Review recent Terraform plan/apply and pull requests.
5. Remediate permissions and document the change.

## Senior interview summary

> Azure governance is about controlling what can be deployed and how resources must be configured, while RBAC controls who is authorized to perform actions. In an enterprise environment I would use Management Groups for subscription-level organization, Azure Policy for preventive/detective guardrails, least-privilege RBAC and managed identities for access, locks for critical-resource protection, tags and Cost Management for accountability, and Terraform plus CI/CD to keep governance repeatable and auditable.

## Status

- [x] Governance hierarchy documented
- [x] Azure Policy controls documented
- [x] RBAC model documented
- [x] Managed Identity pattern documented
- [x] Resource Locks documented
- [x] Tagging standard documented
- [x] Terraform governance workflow documented
- [ ] Implement policy assignments in Terraform
- [ ] Implement production RBAC assignments in Terraform
- [ ] Add policy/security scanning to CI
- [ ] Add centralized diagnostics and monitoring
