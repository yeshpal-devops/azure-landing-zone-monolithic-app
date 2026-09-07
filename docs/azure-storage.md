# Azure Storage — Senior DevOps Study Lab

## Scope

This lab covers Azure Storage account design, Blob Storage tiers, redundancy, private access, lifecycle management, and Terraform patterns for production environments.

## Core concepts

### Storage account
Use a Standard General Purpose v2 (`StorageV2`) account for most general-purpose workloads. Keep workload boundaries, networking, access control, and redundancy decisions explicit rather than using a single unrestricted account for everything.

### Blob access tiers
- **Hot** — frequently accessed data; higher storage cost, lower access/transaction cost.
- **Cool** — infrequently accessed data; lower storage cost and higher access cost.
- **Cold** — rarely accessed online data; lower storage cost and higher access cost.
- **Archive** — lowest storage cost but offline access; rehydration can take hours.

Use lifecycle management to transition data between tiers or expire data according to age/access rules.

### Redundancy
- **LRS** — replicas within one datacenter; lowest-cost option.
- **ZRS** — synchronous replication across availability zones in the primary region.
- **GRS / RA-GRS** — asynchronous replication to a secondary region; RA-GRS provides read access to the secondary.
- **GZRS / RA-GZRS** — zone redundancy in the primary region plus geo-replication; RA-GZRS provides read access to the secondary.

Choose redundancy from the workload's availability and DR requirements rather than cost alone.

## Production security pattern

```text
Application / AKS
       |
       | Private DNS
       v
 Private Endpoint
       |
       v
 Azure Storage
       |
       +--> RBAC / Managed Identity
       +--> Encryption
       +--> Lifecycle Policy
       +--> Logging / Monitoring
```

Prefer private endpoints for sensitive storage workloads and use identity-based access instead of distributing account keys. Scope RBAC permissions to the narrowest practical resource.

## Terraform practice

```hcl
resource "azurerm_storage_account" "app" {
  name                     = var.storage_account_name
  resource_group_name      = var.resource_group_name
  location                 = var.location
  account_tier             = "Standard"
  account_replication_type = "ZRS"

  min_tls_version           = "TLS1_2"
  https_traffic_only_enabled = true

  tags = var.tags
}

resource "azurerm_storage_management_policy" "app" {
  storage_account_id = azurerm_storage_account.app.id

  rule {
    name    = "tier-and-expire-old-data"
    enabled = true

    filters {
      blob_types   = ["blockBlob"]
      prefix_match = ["logs/"]
    }

    actions {
      base_blob {
        tier_to_cool_after_days_since_modification_greater_than    = 30
        tier_to_archive_after_days_since_modification_greater_than = 90
        delete_after_days_since_modification_greater_than          = 365
      }
    }
  }
}
```

> Validate the exact provider argument names against the pinned `azurerm` provider version before applying.

## Hands-on checklist

1. Create a StorageV2 account through Terraform.
2. Choose ZRS for a regional high-availability example.
3. Create a private endpoint and corresponding private DNS configuration for a sensitive workload.
4. Apply a lifecycle policy for application logs.
5. Assign only the required data-plane RBAC role to the workload identity.
6. Run `terraform fmt`, `terraform init`, `terraform validate`, and `terraform plan`.
7. Review the plan for public network exposure, replication choice, lifecycle behavior, and least-privilege access.

## Senior interview scenarios

### Scenario: production logs are growing rapidly
Use lifecycle management to move older data to cooler tiers and eventually expire it according to retention requirements. Do not treat lifecycle policy as a backup mechanism.

### Scenario: regional outage
Use ZRS for zone failure protection and GRS/GZRS when regional disaster recovery is required. RA variants are relevant when read access from the secondary region is required.

### Scenario: application cannot access private storage
Check DNS resolution first, then private endpoint state, private DNS zone/VNet link, network rules/NSG, and workload identity/RBAC.

## Revision points

- LRS vs ZRS vs GRS vs GZRS
- RA-GRS / RA-GZRS read behavior
- Blob access tiers and archive rehydration
- Lifecycle policy vs backup/DR
- Private Endpoint + Private DNS
- Storage RBAC and managed identity
