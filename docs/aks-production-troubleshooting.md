# AKS Production Troubleshooting — Senior DevOps Lab

## Objective

Use a repeatable troubleshooting sequence for common AKS production failures instead of making changes before identifying the failing layer.

## 1. Pod Pending

Start with:

```bash
kubectl get pod <pod> -o wide
kubectl describe pod <pod>
kubectl get events --sort-by=.lastTimestamp
```

Focus on scheduler events:

- Insufficient CPU or memory
- Node taints/tolerations
- Node selector or affinity constraints
- PVC not bound
- Resource quota or admission constraints

`Pending` means the workload has not been successfully scheduled/started; do not assume the application itself has crashed.

## 2. CrashLoopBackOff

Use:

```bash
kubectl logs <pod> --previous
kubectl describe pod <pod>
kubectl get pod <pod> -o yaml
```

Investigate:

1. Application startup/exit code
2. Previous-container logs
3. Command/entrypoint
4. ConfigMap/Secret references
5. Dependency connectivity
6. Liveness/readiness probes
7. OOMKilled or resource limits

`CrashLoopBackOff` is a symptom of repeated container failures, not the root cause.

## 3. ImagePullBackOff / ACR failures

Check Pod events first:

```bash
kubectl describe pod <pod>
```

Then validate:

- Image repository and tag
- AKS kubelet/workload identity
- Required `AcrPull` RBAC assignment
- ACR network reachability
- Private Endpoint and DNS if ACR is private
- Registry/repository availability

Reference flow:

```text
AKS node/workload identity
        |
        v
   Azure RBAC
        |
        v
       ACR
        |
        v
 repository:tag
```

Do not grant broad subscription-level permissions just to fix an image-pull failure.

## 4. Pod Running but application unreachable

Trace the request path:

```text
Client
  -> DNS
  -> Ingress / Application Gateway
  -> Service
  -> Service endpoints
  -> Pod readiness
  -> Container port
  -> Application
```

Useful checks:

```bash
kubectl get svc
kubectl get endpoints
kubectl describe svc <service>
kubectl get ingress
kubectl describe ingress <ingress>
kubectl get pods -o wide
```

A common failure is a Service selector that does not match Pod labels, leaving no usable endpoints.

## 5. Readiness vs liveness

- **Readiness** controls whether a Pod should receive traffic. A failed readiness probe can keep the container running while removing it from service endpoints.
- **Liveness** determines whether the container should be restarted when it is considered unhealthy.

Do not use liveness as a substitute for readiness. Poorly designed probes can create restart storms.

## 6. Node NotReady

Start with:

```bash
kubectl get nodes
kubectl describe node <node>
kubectl get pods -A -o wide
kubectl get events --sort-by=.lastTimestamp
```

Correlate Kubernetes conditions with Azure VM/VMSS health and monitoring. Check CPU/memory/disk pressure, kubelet/networking problems, recent node events, and whether workloads can be rescheduled safely.

Decision path:

```text
Observe
  -> identify failure domain
  -> recover node if appropriate
  -> drain/replace if required
  -> verify workload rescheduling
  -> monitor recovery
```

Do not delete a production node before understanding workload disruption and PodDisruptionBudget implications.

## 7. HPA vs Cluster Autoscaler

- **HPA** changes the number of Pod replicas based on workload metrics.
- **Cluster Autoscaler** changes the number of cluster nodes when scheduling capacity is insufficient or nodes can be removed safely.

Typical flow:

```text
Traffic increases
      -> HPA increases Pods
      -> Pods cannot fit
      -> Cluster Autoscaler adds nodes
      -> Pods schedule
```

Both controls need sensible min/max bounds and monitoring.

## 8. Rollback

For a Deployment rollout:

```bash
kubectl rollout history deployment/<name>
kubectl rollout undo deployment/<name>
kubectl rollout status deployment/<name>
```

Before rollback, consider database/schema compatibility. A code rollback can be unsafe if the new release introduced an irreversible schema change.

After rollback:

- Verify readiness and application health
- Confirm error rate/latency recovery
- Stop further promotion
- Capture incident timeline
- Fix root cause before redeploying

## Senior incident framework

For any AKS incident, use:

```text
1. Observe
2. Scope impact
3. Identify failing layer
4. Check recent changes
5. Mitigate safely
6. Validate recovery
7. Root-cause analysis
8. Prevent recurrence
```

Avoid random restarts, broad RBAC changes, or disabling security controls as the first response.

## Interview talking point

> "When troubleshooting AKS, I first identify whether the failure is scheduling, container runtime, registry access, service discovery, ingress, node health, or an application dependency. I use Kubernetes events and object status to narrow the fault domain, then correlate it with Azure identity, networking and monitoring before applying the smallest safe remediation."
