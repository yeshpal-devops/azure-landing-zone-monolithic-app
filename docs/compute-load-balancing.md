# Azure Compute & Load Balancing — Senior DevOps Lab

## Objective

Design a production-oriented Azure compute tier for a web workload with high availability, health-based traffic distribution, controlled inbound access, and a clear path to autoscaling.

## Reference architecture

```text
Internet
   |
Public IP
   |
Application Gateway + WAF
   |
Backend pool
   |---- VM / VMSS instance 1
   |---- VM / VMSS instance 2
   `---- VM / VMSS instance 3
          |
       Application
```

## VM vs VMSS

- Azure VM is an individual compute instance.
- VM Scale Sets manage a group of similar VMs and support centralized configuration, scaling, and distribution across failure domains.
- Prefer VMSS for stateless application tiers that need horizontal scaling.

## Load Balancer vs Application Gateway

| Capability | Azure Load Balancer | Application Gateway |
|---|---|---|
| Layer | L4 | L7 |
| Traffic | TCP/UDP | HTTP/HTTPS |
| Path routing | No | Yes |
| Host routing | No | Yes |
| TLS termination | Not the primary role | Yes |
| WAF | No | Yes |

## Availability design

For production, spread instances across Availability Zones where the selected region/workload supports it. Use health probes so unhealthy backends stop receiving traffic. Combine this with VMSS autoscaling and Azure Monitor for resilient operations.

## Autoscaling

Use minimum/maximum instance counts and scale rules based on workload signals. CPU can be useful, but application-specific metrics may be a better scaling signal. Avoid aggressive scale-in that causes instability.

## Troubleshooting: unhealthy Application Gateway backend

Check in this order:

1. Application Gateway health probe protocol, host, path, and port.
2. Backend listener is actually listening on the expected port.
3. NSG rules between gateway and backend.
4. UDR/effective routes and any firewall/NVA path.
5. Guest OS firewall.
6. Application response/status code.
7. TLS certificate/SNI mismatch when HTTPS is used.
8. DNS resolution where hostname-based probing is involved.

## Troubleshooting: VM CPU stays above 90%

Do not immediately resize the VM. First correlate CPU with memory, disk IOPS/throughput, network, process-level utilization, request volume, and downstream dependencies. Then choose scale-up, scale-out, caching, query/application optimization, or a combination.

## Secure inbound pattern

Avoid direct public IP exposure for application VMs when an application gateway/load-balancing tier can provide the public entry point. Keep backend access restricted to the required ports and sources through NSGs and, for HTTP/HTTPS workloads, use WAF where appropriate.

## Terraform implementation checklist

- [ ] VM/VMSS module
- [ ] Application Gateway module
- [ ] Backend pool and health probe
- [ ] NSG with least-privilege rules
- [ ] Availability Zone placement where supported
- [ ] Autoscale configuration
- [ ] Diagnostic settings and Azure Monitor alerts
- [ ] Private backend connectivity

## Senior interview answer

> "For a production web tier I would separate the public entry point from compute, use Application Gateway/WAF for HTTP-aware routing, place stateless instances in a VM Scale Set across availability zones where appropriate, use health probes to remove unhealthy instances, and use autoscaling plus monitoring to respond to workload changes. Troubleshooting starts with probe configuration and backend reachability before changing VM size or network rules." 
