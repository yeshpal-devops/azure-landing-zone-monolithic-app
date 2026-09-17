# CI/CD Production Release Strategy

## Purpose

This document defines a production-oriented CI/CD release model for the Azure Terraform platform and AKS workloads in this repository. The goal is to make every change traceable, validated, security-checked, promoted through environments, and recoverable.

## Release Flow

```text
Developer
   |
   v
Feature Branch
   |
   v
Pull Request + CODEOWNERS
   |
   +--> Terraform fmt / validate
   +--> Checkov / IaC security scan
   +--> Terraform plan
   +--> Application tests (where applicable)
   |
   v
Merge to main
   |
   v
Build immutable artifact
   |
   v
Dev
   |
   v
QA
   |
   v
UAT + business validation
   |
   v
Protected Production Approval
   |
   v
Production
   |
   v
Smoke tests + monitoring
```

## Core Release Principles

### 1. Build once, promote the same artifact

A release should not be rebuilt separately for QA, UAT, and Production. Build the artifact once, assign a unique version, record its digest/identifier, and promote that exact artifact.

For container workloads, prefer immutable image references such as a digest or a unique release tag rather than `latest`.

### 2. Separate validation from deployment

CI should prove that the change is syntactically valid, passes automated tests, and meets security gates. CD should consume the validated change and deploy it through controlled environments.

### 3. Production requires stronger controls

Production deployment should use:

- Protected branch and CODEOWNERS review
- Restricted pipeline/service identity
- Environment approval/checks
- Least-privilege Azure RBAC
- Deployment audit trail
- Pre-deployment validation
- Post-deployment health checks

## Terraform Release Controls

### Pull Request

```bash
terraform fmt -check -recursive
terraform init -backend=false
terraform validate
checkov -d . --framework terraform
```

The plan should be reviewed before production-impacting changes are approved.

### Deployment

```text
Plan
  |
  v
Review
  |
  v
Approval
  |
  v
Apply
  |
  v
Validate Azure resources
```

Do not treat a successful `terraform plan` as proof that deployment will succeed. Apply-time failures can still occur because of Azure RBAC, policy, quota, dependency, network, or service-side conditions.

## AKS Release Controls

Before promotion:

- Image exists in ACR
- Image vulnerability policy passes
- Deployment references the intended immutable version
- Kubernetes manifests/configuration are validated
- Resource requests/limits are appropriate
- Readiness/liveness/startup probes are configured where needed
- Rollout strategy is defined

After deployment:

```bash
kubectl rollout status deployment/<deployment>
kubectl get pods -o wide
kubectl get events --sort-by=.lastTimestamp
```

Validate application health, Service endpoints, Ingress/backend health, and monitoring signals before declaring the release successful.

## Rollback Strategy

Rollback is a mitigation action, not the root-cause analysis.

```text
Detect failure
   |
   v
Stop further promotion
   |
   v
Assess blast radius
   |
   v
Confirm previous known-good version
   |
   v
Check data/schema compatibility
   |
   v
Rollback or roll-forward
   |
   v
Smoke test + monitor
   |
   v
RCA + preventive action
```

For AKS deployments, a rollout history can be inspected before selecting a previous revision:

```bash
kubectl rollout history deployment/<deployment>
kubectl rollout undo deployment/<deployment>
kubectl rollout status deployment/<deployment>
```

A rollback must not be performed blindly when a database migration or irreversible data change is involved.

## Failure Scenarios

| Scenario | First response |
|---|---|
| Terraform validation fails | Fix configuration before merge |
| Security scan fails | Remediate or use an approved, time-bound exception |
| Terraform plan shows unexpected destroy | Stop and investigate state/configuration drift |
| Apply fails | Inspect Azure actual state and dependencies; do not assume rollback |
| AKS image pull fails | Check image reference, ACR access, identity, DNS and network |
| Pods run but traffic fails | Check readiness, Service endpoints, Ingress and backend health |
| Production error rate increases | Stop rollout, assess impact, mitigate, then investigate |

## Release Evidence

Each production release should retain enough evidence to answer:

- What commit was released?
- Which Terraform plan was approved?
- Which container/image version was deployed?
- Who approved production?
- Which environment stages passed?
- What health checks were performed?
- Was a rollback or hotfix required?

## Senior Interview Talking Point

> "I design CI/CD so that validation, security, promotion, and production deployment are separate controlled stages. I prefer immutable artifacts, environment approvals, least-privilege identities, and automated health checks. If a deployment fails, I first stop the blast radius and establish evidence, then choose rollback or roll-forward based on application and data safety. After mitigation, I complete RCA and add a preventive control."
