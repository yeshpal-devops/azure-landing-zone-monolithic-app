# AKS Production Readiness Checklist

## 1. Workload health

- [ ] Deployment has explicit CPU/memory requests and limits.
- [ ] Readiness probe protects traffic from unhealthy application instances.
- [ ] Liveness probe is used only for genuine process-health failures.
- [ ] Startup probe is considered for slow-starting applications.
- [ ] Replica count is appropriate for the availability target.

## 2. Service and ingress

- [ ] Service selector matches the intended Pod labels.
- [ ] Service endpoints contain the expected healthy Pods.
- [ ] Service `port` and `targetPort` match the application listener.
- [ ] Ingress backend points to the correct Service and port.
- [ ] External entry point health is validated before declaring a release healthy.

## 3. Scaling

- [ ] HPA metric and target reflect the actual application bottleneck.
- [ ] Minimum and maximum replica limits are defined.
- [ ] Cluster Autoscaler/node capacity is sufficient for HPA scale-out.
- [ ] PodDisruptionBudget is considered for voluntary disruptions.
- [ ] Scaling behavior is tested under representative load.

## 4. Identity and secrets

- [ ] Workloads use managed identity/workload identity where supported.
- [ ] Azure RBAC follows least privilege.
- [ ] Secrets are not committed to Git or baked into images.
- [ ] Key Vault is preferred for Azure-managed application secrets.
- [ ] ACR pull permissions are scoped to the required identity.

## 5. Container supply chain

- [ ] Image is built from a maintained base image.
- [ ] Image vulnerability scanning runs before promotion.
- [ ] Production deploys an immutable image reference/tag strategy.
- [ ] Critical/high findings have a defined block or exception process.
- [ ] Image provenance and release metadata are traceable to the commit.

## 6. Network and platform

- [ ] Network access is restricted to required paths and ports.
- [ ] Private endpoints/DNS are validated when used.
- [ ] Network policies are evaluated for multi-workload clusters.
- [ ] Production workloads are isolated from unnecessary public exposure.
- [ ] Azure Monitor/logging and alerting cover nodes, Pods and ingress.

## 7. Release and rollback

- [ ] Production deployment requires the appropriate approval gate.
- [ ] Rollout status is checked after deployment.
- [ ] Previous image/version is known and rollback-tested.
- [ ] Database migrations are backward-compatible with the rollback strategy.
- [ ] Incident mitigation and root-cause analysis are treated as separate steps.

## Senior interview framing

When troubleshooting AKS, use this sequence:

`Symptom -> evidence -> failing layer -> safe mitigation -> validation -> prevention`

For a `503`, walk from the edge toward the workload: DNS/Ingress -> gateway backend health -> Service -> endpoints -> readiness -> Pod -> application/dependencies.

For `ImagePullBackOff`, start with Pod events, then verify image/tag, registry access, identity/RBAC, and private-network/DNS reachability.

For scaling incidents, distinguish HPA (Pod replicas) from Cluster Autoscaler (node capacity) and validate downstream bottlenecks before adding capacity.