# Azure Networking + AKS Connectivity — Senior DevOps Lab

## Objective

Practice designing and troubleshooting a secure Azure network path for an AKS-hosted application. The goal is to reason from traffic flow and evidence rather than changing security rules blindly.

## Reference architecture

```text
Internet
   |
   v
Front Door / Application Gateway + WAF
   |
   v
AKS ingress
   |
   +--> Application Pods
   |
   +--> Internal services
   |
   +--> Private connectivity
           |
           +--> ACR
           +--> Key Vault
           +--> Storage

Private DNS --> private endpoint name resolution
NSG / UDR / Firewall --> network controls
Azure Monitor --> logs, metrics and alerts
```

## Network layers to reason about

1. **VNet/subnet** — defines the address space and workload boundaries.
2. **NSG** — filters subnet/NIC traffic with explicit allow/deny rules.
3. **UDR/route table** — determines the next hop and can force traffic through a firewall/NVA.
4. **Azure Firewall** — centralized stateful network security and controlled egress where required.
5. **Private Endpoint** — gives supported Azure PaaS services a private IP in the VNet.
6. **Private DNS** — makes the service hostname resolve to the private endpoint from linked VNets.
7. **Kubernetes networking** — Service selectors, endpoints, ingress and NetworkPolicy determine Pod-level reachability.

## AKS egress troubleshooting

When a Pod cannot reach an external dependency, collect evidence in this order:

```text
Pod
 -> DNS resolution
 -> Node/subnet
 -> Route / UDR
 -> NSG / Firewall
 -> NAT / egress path
 -> Destination TCP port
 -> Application protocol
```

Useful checks:

```bash
kubectl get pod -o wide
kubectl describe pod <pod>
kubectl get nodes -o wide
kubectl get networkpolicy -A
kubectl get svc,endpoints -A
```

Then validate DNS, routing and TCP connectivity from an appropriate diagnostic workload. Do not start by opening `0.0.0.0/0` in an NSG.

## Private Endpoint + Private DNS troubleshooting

If AKS cannot reach a private Key Vault/ACR/Storage endpoint:

```text
Private Endpoint
      |
      +--> Private IP exists
      |
Private DNS Zone
      |
      +--> VNet is linked
      |
DNS query
      |
      +--> hostname resolves to private IP
      |
Routing / NSG / Firewall
      |
      +--> TCP connectivity
      |
Identity / RBAC
      |
      +--> authorized request
```

Keep **network failure** and **authorization failure** separate. A working TCP path can still produce HTTP 401/403 because the workload identity lacks the required Azure RBAC permissions.

## Application Gateway 502/503 runbook

For an external application returning 502/503, isolate the layer:

1. Confirm DNS resolves to the expected entry point.
2. Check Application Gateway listener and backend health.
3. Validate health-probe protocol, host header, path, port and expected status code.
4. Confirm the backend Service has endpoints.
5. Confirm Pod readiness and application listener port.
6. Validate NSG/route/firewall reachability between gateway and backend.
7. Check TLS/certificate configuration if HTTPS is used between hops.
8. Compare the failure timestamp with recent deployment, ingress, DNS, certificate or network-policy changes.

## Senior interview scenarios

### Scenario A — Private Key Vault returns 403

First prove DNS and network connectivity. If the private hostname resolves correctly and the TCP path works, inspect the workload identity, RBAC role and Key Vault data-plane permission. Do not solve an authorization problem by changing NSGs.

### Scenario B — AKS Pods cannot reach the internet

Check whether the cluster is expected to have public egress, then inspect DNS, routes/UDRs, NSGs, firewall rules and NAT/egress configuration. Validate the destination and port before changing policy.

### Scenario C — Application Gateway reports unhealthy AKS backends

Trace `App Gateway -> backend IP/port -> Service/endpoints -> Pod readiness -> application`. A running Pod is not sufficient; the readiness state determines whether it should receive traffic.

## Design checklist

- [ ] Separate ingress and workload network boundaries where appropriate.
- [ ] Minimize public exposure of internal Azure services.
- [ ] Use private endpoints for supported sensitive PaaS dependencies when the design requires private access.
- [ ] Configure and link the required private DNS zones.
- [ ] Apply least-privilege NSG and Azure Firewall rules.
- [ ] Define an intentional egress path.
- [ ] Use Kubernetes NetworkPolicy where Pod-to-Pod restrictions are required.
- [ ] Validate Application Gateway probes against the real application behavior.
- [ ] Monitor DNS, gateway backend health, node/network metrics and application logs.
- [ ] Document RTO/RPO and regional failover requirements for production.

## Interview answer framework

For any Azure networking incident, answer in this sequence:

**Traffic flow -> failing layer -> evidence -> least-risk mitigation -> validation -> prevention**

This demonstrates Senior DevOps troubleshooting instead of tool-name memorization.
