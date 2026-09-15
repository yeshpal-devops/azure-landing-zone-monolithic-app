# AKS NetworkPolicy Security Lab

## Objective

Practice restricting Pod-to-Pod traffic in AKS without relying on broad subnet rules. The exercise complements the Azure networking lab by separating Azure network controls from Kubernetes workload-level controls.

## Security model

```text
Internet
   |
   v
Front Door / Application Gateway
   |
   v
AKS ingress namespace
   |
   v
frontend Pods  ----X----> unrelated namespaces
   |
   v
backend Pods
   |
   v
managed Azure services via private connectivity
```

Use a default-deny posture for application namespaces, then explicitly allow only required flows.

## Example policy pattern

The following is a reference pattern, not a production-ready manifest. Adjust namespace labels, ports and DNS requirements to the actual application.

```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-default-deny
  namespace: app
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
    - Ingress
    - Egress
---
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-allow-frontend
  namespace: app
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
    - Ingress
  ingress:
    - from:
        - podSelector:
            matchLabels:
              app: frontend
      ports:
        - protocol: TCP
          port: 8080
```

## Validation workflow

1. Confirm the AKS networking implementation supports NetworkPolicy.
2. Identify the namespaces and application labels.
3. Apply the policy in a non-production namespace first.
4. Test an allowed frontend -> backend request.
5. Test an intentionally denied request from an unrelated workload.
6. Check application logs and network-policy/CNI observability.
7. Confirm DNS and required egress paths still work.
8. Roll back the policy if the blast radius is larger than expected.

Useful commands:

```bash
kubectl get networkpolicy -A
kubectl describe networkpolicy -n app backend-default-deny
kubectl get pods -n app --show-labels
kubectl get svc,endpoints -n app
```

## Important troubleshooting distinction

- **NetworkPolicy** controls Kubernetes Pod traffic according to the selected policy/CNI behavior.
- **NSG/UDR/Firewall** controls Azure network traffic and routing.
- **RBAC** controls who can perform Kubernetes/Azure API actions.
- **Workload Identity + Azure RBAC** controls a workload's access to Azure data-plane resources.

A 403 from Key Vault is not fixed by changing NetworkPolicy, and a Pod-to-Pod connection blocked by NetworkPolicy is not fixed by granting Azure RBAC.

## Production checklist

- [ ] Start with least privilege rather than allow-all rules.
- [ ] Define required ingress and egress flows before enforcing default deny.
- [ ] Account for DNS egress when applications need name resolution.
- [ ] Test health probes and service discovery after policy changes.
- [ ] Roll out namespace-by-namespace.
- [ ] Keep an emergency rollback procedure documented.
- [ ] Monitor denied traffic and application error rates.

## Senior interview framework

When asked why an AKS connection fails, first identify whether the traffic is **Pod-to-Pod, Pod-to-Service, Pod-to-Azure PaaS, or external ingress**. Then choose the matching control plane: Kubernetes NetworkPolicy, Service/Ingress, Azure routing/security, or identity/RBAC.
