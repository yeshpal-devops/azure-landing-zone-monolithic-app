# Azure Identity & Access Management

## Day 4 Study Focus

Senior DevOps focus: Microsoft Entra ID, Azure RBAC, managed identities, service principals/workload identity, Key Vault access, and least-privilege design.

## Identity hierarchy

```text
Microsoft Entra ID
       |
       +-- Users / Groups
       +-- Service Principals
       +-- Managed Identities
       |
       v
Azure RBAC
       |
       v
Management Group / Subscription / Resource Group / Resource
```

## Core concepts

### Microsoft Entra ID

Microsoft Entra ID is Azure's identity platform. It authenticates identities; Azure RBAC then authorizes what an identity can do on Azure resources.

### Azure RBAC

RBAC answers: **Who can perform which action, at what scope?**

Use the narrowest practical scope and avoid broad Owner assignments.

Common built-in roles:

- Reader — read-only access
- Contributor — manage resources, but not role assignments
- Owner — full resource management including access management
- AcrPull — pull images from Azure Container Registry
- Key Vault Secrets User — read secrets when that access is required

### Managed Identity

Prefer managed identities for Azure workloads instead of storing client secrets/passwords in source code or pipeline variables.

```text
AKS / VM / Azure Workload
          |
          v
 Managed Identity
          |
          v
      Azure RBAC
       /      \
   Key Vault   ACR
```

The workload receives only the permissions required for its task.

### System-assigned vs User-assigned identity

| Type | Lifecycle | Typical use |
|---|---|---|
| System-assigned | Tied to the Azure resource | Single workload/resource identity |
| User-assigned | Independent Azure resource | Reuse one identity across multiple workloads |

### Service Principal / Workload Identity

A service principal represents an application identity in Entra ID. For CI/CD and AKS, prefer secretless authentication patterns such as federated credentials/workload identity where supported instead of long-lived client secrets.

## Key Vault access pattern

```text
Application / AKS
       |
       v
Managed Identity / Workload Identity
       |
       v
Azure RBAC
       |
       v
Key Vault
       |
       v
Secret / Certificate / Key
```

Do not place secrets directly in Git, Terraform source, container images, or plain pipeline variables.

## Terraform hands-on design

The practical exercise for this study day is to design the following resources as IaC:

1. User-assigned managed identity
2. Key Vault
3. RBAC assignment from the managed identity to Key Vault
4. ACR pull permission for an AKS/workload identity
5. Environment-specific variables for Dev and Prod

Illustrative Terraform pattern:

```hcl
resource "azurerm_user_assigned_identity" "workload" {
  name                = "uai-app-workload"
  location            = azurerm_resource_group.main.location
  resource_group_name = azurerm_resource_group.main.name
}

resource "azurerm_role_assignment" "keyvault_secrets_user" {
  scope                = azurerm_key_vault.main.id
  role_definition_name = "Key Vault Secrets User"
  principal_id         = azurerm_user_assigned_identity.workload.principal_id
}
```

For ACR:

```hcl
resource "azurerm_role_assignment" "acr_pull" {
  scope                = azurerm_container_registry.main.id
  role_definition_name = "AcrPull"
  principal_id         = azurerm_user_assigned_identity.workload.principal_id
}
```

These snippets are patterns for the lab; they are not claimed as deployed resources in this repository.

## Validation checklist

```text
Identity exists
      |
      v
RBAC assignment exists
      |
      v
Correct scope?
      |
      v
Correct role?
      |
      v
Workload uses the intended identity?
      |
      v
No static secret stored in Git?
```

Terraform validation:

```bash
terraform fmt -recursive
terraform init -backend=false
terraform validate
terraform plan
```

## Senior troubleshooting scenarios

### AKS cannot pull from ACR

Check:

1. AKS/workload identity configuration
2. `AcrPull` role assignment
3. Role-assignment scope
4. Identity principal ID
5. ACR network restrictions/private endpoint/DNS if enabled
6. Token/authentication errors

### Application cannot read Key Vault secret

Check:

1. Which identity the application is actually using
2. RBAC role and scope
3. Key Vault authorization model
4. Network/private endpoint/DNS controls
5. Secret name/version and application configuration

### Developer has too much access

Remove broad role assignments and replace them with least-privilege roles at the smallest practical scope. Review inherited permissions from Management Groups, subscriptions, and resource groups.

## Interview summary

> "I separate authentication from authorization. Microsoft Entra ID handles identity, while Azure RBAC controls access to Azure resources. For workloads I prefer managed identities or federated workload identity over long-lived secrets. I use least-privilege role assignments at the smallest practical scope and integrate Key Vault, ACR, AKS and Terraform so credentials are not embedded in source code."

## Completion record

- [x] Entra ID authentication vs Azure RBAC authorization
- [x] Reader / Contributor / Owner concepts
- [x] Managed identity lifecycle
- [x] System-assigned vs user-assigned identity
- [x] Service principal and workload identity concepts
- [x] Key Vault RBAC access pattern
- [x] AKS-to-ACR identity pattern
- [x] Terraform RBAC implementation pattern
- [x] Identity troubleshooting flow
- [ ] Deploy the identity/RBAC lab to a live Azure subscription
