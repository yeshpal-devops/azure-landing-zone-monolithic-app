# Azure Hub-Spoke & Private Connectivity Lab

## Objective

Document a production-oriented Azure networking design for consolidating workloads into **Hub, Non-Prod, and Prod** VNets while preserving private access, controlled routing, DNS, and a safe migration path.

This lab is intentionally architecture-first: dependency discovery and validation happen before moving workloads.

## Target Architecture

```text
                              Internet
                                  |
                         Azure Firewall / WAF
                                  |
                           +--------------+
                           |     HUB      |
                           |--------------|
                           | VPN Gateway  |
                           | Bastion      |
                           | Shared DNS   |
                           | Firewall     |
                           +------+-------+
                                  |
                         VNet Peering / Routes
                       +----------+-----------+
                       |                      |
                +------+-------+       +------+-------+
                |   NON-PROD  |       |     PROD     |
                |-------------|       |--------------|
                | Dev         |       | Applications |
                | Test        |       | AKS / VMs    |
                | Pre-Prod    |       | Data         |
                +-------------+       +--------------+
                       |
                 Private access
                       |
                PostgreSQL / PaaS
```

## Design Principles

### 1. Production isolation

Production is a separate VNet from Dev/Test/Pre-Prod. This reduces blast radius and allows stricter routing, RBAC, firewall, and change controls.

### 2. Hub for shared connectivity

The Hub hosts shared network services such as:

- Point-to-Site VPN Gateway
- Azure Firewall where required
- Bastion for administrative access
- Shared Private DNS architecture
- Centralized routing controls

### 3. Private-first access

VMs, databases, and platform services should not require public IP exposure when a private connectivity option is available.

Preferred access path:

```text
Engineer
   |
 P2S VPN
   |
VPN Gateway
   |
 Hub VNet
   |
 Peering
   |
Non-Prod VNet
   |
Private VM / PostgreSQL / API
```

### 4. Explicit routing and least privilege

VNet peering provides connectivity, but access should still be constrained with NSGs, Azure Firewall rules, route tables, and service-level authorization.

## P2S VPN Design

For developer/Postman access to private Non-Prod APIs and PostgreSQL:

1. Deploy VPN Gateway in the Hub.
2. Use an address pool that does not overlap with VNet or on-premises CIDRs.
3. Configure the selected authentication mechanism.
4. Advertise required private routes.
5. Configure Private DNS resolution where required.
6. Allow only the required destination ports through NSGs/firewall rules.
7. Validate VM/API/PostgreSQL connectivity from a VPN client.
8. Remove unnecessary public exposure only after private-path validation succeeds.

### Validation checklist

```text
[ ] VPN client receives an address
[ ] Hub routes are present
[ ] Non-Prod VNet is reachable
[ ] Private DNS resolves correctly
[ ] NSG allows required traffic
[ ] Firewall rules allow required traffic
[ ] API responds privately
[ ] PostgreSQL accepts private connection
[ ] Public access is no longer required
```

## Private Endpoint vs Service Endpoint

| Capability | Private Endpoint | Service Endpoint |
|---|---|---|
| Private IP in VNet | Yes | No |
| Azure Private Link | Yes | No |
| PaaS service uses private path | Yes | Uses service endpoint over Azure backbone |
| Private DNS commonly required | Yes | Not normally for service-endpoint routing |
| Public endpoint exposure | Can be disabled | Service remains public endpoint based |

For sensitive production data services, evaluate Private Endpoint when the service and application architecture support it.

## DNS Design

Private connectivity is incomplete without DNS.

```text
Client / Pod / VM
       |
Private DNS resolution
       |
Private Endpoint IP
       |
Azure PaaS service
```

Before migration validate:

- Private DNS zones
- VNet links
- DNS forwarding requirements
- Application hostnames
- PostgreSQL hostname resolution
- AKS private endpoint dependencies

## Migration Dependency Map

Before moving an existing VM/VNet workload, inventory:

- VM NICs and IPs
- Subnets
- NSGs
- Route tables / UDRs
- Public IPs
- Load balancers
- Application Gateway
- AKS dependencies
- Private endpoints
- Service endpoints
- Private DNS zones
- PostgreSQL dependencies
- Key Vault dependencies
- Monitoring/agents
- Automation jobs
- External API integrations

### Safe migration sequence

```text
Current-state discovery
        |
        v
CIDR / subnet validation
        |
        v
Dependency mapping
        |
        v
Target HLD + LLD
        |
        v
Build Hub + Non-Prod + Prod
        |
        v
Validate routing + DNS + security
        |
        v
Pilot workload
        |
        v
Application validation
        |
        v
Production migration
        |
        v
Decommission old connectivity
```

## Troubleshooting Decision Tree

### Application cannot reach PostgreSQL

```text
1. Is DNS resolving to the expected address?
       |
       +-- No -> Check Private DNS / resolver / VNet links
       |
       +-- Yes
             |
2. Is the route present?
       |
       +-- No -> Check peering / UDR / gateway routes
       |
       +-- Yes
             |
3. Is traffic blocked?
       |
       +-- Yes -> Check NSG / Firewall
       |
       +-- No
             |
4. Does PostgreSQL allow the source?
       |
       +-- No -> Check PostgreSQL networking/auth rules
       |
       +-- Yes -> Check authentication / database health
```

## CIDR Planning Rules

Never start consolidation with overlapping address spaces.

Example:

```text
Hub       10.0.0.0/16
Non-Prod  10.10.0.0/16
Prod      10.20.0.0/16
VPN Pool  10.250.0.0/24
```

The exact ranges are examples only. Actual CIDRs must account for existing networks, future expansion, AKS requirements, on-premises ranges, and VPN pools.

## Senior Interview Talking Points

### Why Hub-Spoke?

> Centralize shared connectivity and security services while keeping application environments independently controlled and isolated.

### Why not immediately remove public IPs?

> Public exposure may hide undocumented dependencies. I first identify consumers, establish the private replacement path, validate it, then remove unnecessary public access.

### How do you approach VNet consolidation?

> Discover dependencies first, design the target address space and routing model, build and validate the target network, pilot a low-risk workload, then migrate incrementally with rollback criteria.

### What is the key production risk?

> Network changes can break dependencies that are not visible from the VM itself. DNS, routing, private endpoints, application gateways, AKS components, databases, automation, and external integrations all need to be mapped before migration.

## Production Readiness Checklist

- [ ] Non-overlapping CIDRs
- [ ] Hub routing validated
- [ ] VNet peering validated
- [ ] P2S VPN validated
- [ ] Private DNS validated
- [ ] NSGs reviewed
- [ ] Firewall rules reviewed
- [ ] Public IP dependencies documented
- [ ] PostgreSQL private connectivity tested
- [ ] AKS dependencies mapped
- [ ] Monitoring/alerting validated
- [ ] Pilot migration completed
- [ ] Rollback procedure tested
- [ ] Production change approval obtained
