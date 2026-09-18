# DevSecOps CI/CD Incident Drill

## Objective

Practice a production incident where a CI/CD release passes build and security gates but the AKS workload fails after promotion. The drill connects pipeline evidence, ACR, Kubernetes rollout state, application health, and rollback decisions.

## Scenario

A new container image passes CI, Terraform validation, and IaC security checks. The image is pushed to ACR and promoted to AKS. Shortly after deployment, application errors increase and some requests return HTTP 503.

## Investigation flow

```text
Release commit / pipeline run
        |
        v
Artifact identity + image digest
        |
        v
AKS rollout status
        |
        +--> Pods Ready? ---- no --> describe/events/logs
        |
        v
Service endpoints
        |
        v
Ingress / Application Gateway backend health
        |
        v
Application metrics + logs
        |
        v
Dependencies (DB / Key Vault / APIs)
```

### Evidence to collect

```bash
kubectl rollout status deployment/<deployment> -n <namespace>
kubectl get deployment,rs,pods -n <namespace> -o wide
kubectl describe pod <pod> -n <namespace>
kubectl logs <pod> -n <namespace>
kubectl logs <pod> -n <namespace> --previous
kubectl get svc,endpoints -n <namespace>
kubectl get events -n <namespace> --sort-by=.lastTimestamp
```

Record the pipeline run, Git commit, image tag/digest, deployment revision, first failure time, affected environment, and observed error rate.

## Decision tree

### 1. Pods are not Ready

Check readiness/startup probes, configuration, secrets, resource pressure, container logs, and dependency connectivity.

### 2. Pods are Ready but Service has no usable endpoints

Check selectors, labels, Service `targetPort`, namespace, and EndpointSlice state.

### 3. Service has endpoints but external traffic returns 503

Check Ingress/Application Gateway backend health, health-probe path/status, TLS/host-header behavior, routing, and network controls.

### 4. Application is healthy but dependency calls fail

Check DNS, private endpoint/private DNS, NSG/firewall/routing, identity/RBAC, and downstream service health.

## Rollback decision

Rollback is appropriate when the previous version is known-good and reverting the application is safe for the current database/schema state.

```bash
kubectl rollout history deployment/<deployment> -n <namespace>
kubectl rollout undo deployment/<deployment> -n <namespace>
kubectl rollout status deployment/<deployment> -n <namespace>
```

Do not blindly roll back an application after an irreversible database migration. In that case, stabilize traffic, assess data compatibility, and choose a safe roll-forward or compensating change.

## DevSecOps prevention controls

- Build once and promote the same immutable artifact.
- Prefer image digests or unique release tags over `latest`.
- Keep security gates before artifact promotion.
- Require protected production approvals.
- Use least-privilege deployment identities.
- Require readiness and health validation before declaring success.
- Monitor error rate, latency, saturation, and dependency health after release.
- Preserve release evidence for audit and RCA.

## Senior interview drill

Explain the incident in this order:

**Symptom -> Scope -> Evidence -> Isolation -> Root cause -> Mitigation -> Validation -> Prevention**

A strong answer should distinguish Kubernetes `Running` from application `Ready`, distinguish network failures from authorization failures, and explain why rollback depends on data/schema compatibility.
