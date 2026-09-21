# AKS Workload Identity + Azure Key Vault Lab

## Objective

Practice a production-grade secret access pattern for AKS without placing long-lived Azure credentials inside Pods.

The target flow is:

```text
AKS Pod
  |
  | projected service-account token
  v
Microsoft Entra Workload Identity
  |
  | federated authentication
  v
Azure identity / managed identity
  |
  | Azure RBAC
  v
Key Vault
  |
  v
Secret
```

## Why this pattern

- Avoids storing Azure client secrets in Kubernetes manifests or container images.
- Gives each workload only the Azure permissions it requires.
- Makes access auditable through Azure identity and Key Vault logs.
- Separates application identity from the AKS node identity.
- Supports credential rotation without distributing a long-lived secret to every Pod.

## Production design checklist

### 1. Identity

Create a dedicated user-assigned managed identity for the workload. Do not reuse a broad platform identity across unrelated applications.

The identity should have only the required Key Vault data-plane permissions, such as reading the specific secrets needed by the application.

### 2. Federated credential

Create a federated identity credential that binds the managed identity to the expected Kubernetes service account, namespace, and OIDC issuer.

Conceptually:

```text
issuer = AKS OIDC issuer
subject = system:serviceaccount:<namespace>:<service-account>
audience = api://AzureADTokenExchange
```

Treat the namespace and service-account name as security boundaries. A change to either should be reviewed rather than silently widening trust.

### 3. Key Vault

Prefer Azure RBAC for Key Vault authorization when it matches the organization's access model. Grant the workload identity only the required data-plane role.

Avoid granting broad roles such as Owner or Contributor merely because the application needs to read a secret.

### 4. Kubernetes service account

Use a dedicated service account and enable the workload identity label/annotation required by the AKS configuration.

Example pattern:

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: app-workload
  namespace: app
  annotations:
    azure.workload.identity/client-id: "<managed-identity-client-id>"
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: app
  namespace: app
spec:
  template:
    metadata:
      labels:
        azure.workload.identity/use: "true"
    spec:
      serviceAccountName: app-workload
      containers:
        - name: app
          image: <acr>/<image>@<digest>
```

Use placeholders only. Never commit real client IDs, tokens, secrets, or Key Vault secret values.

## Troubleshooting workflow

### Symptom: Pod cannot obtain an Azure token

Check:

1. AKS OIDC issuer is enabled and reachable.
2. Workload identity webhook is installed and healthy.
3. Pod has the expected `azure.workload.identity/use: "true"` label.
4. Deployment uses the intended service account.
5. Service account contains the correct client ID.
6. Federated credential issuer, subject, and audience match exactly.
7. Pod was recreated after identity configuration changed.

Useful commands:

```bash
az aks show -g <resource-group> -n <cluster> --query oidcIssuerProfile.issuer -o tsv
kubectl get sa app-workload -n app -o yaml
kubectl get pods -n app
kubectl describe pod <pod> -n app
kubectl logs <pod> -n app
```

### Symptom: Token works but Key Vault returns 403

Separate authentication from authorization.

```text
Token acquisition succeeds
        |
        v
Azure identity is recognized
        |
        v
Key Vault authorization fails
```

Check:

- Correct managed identity/client ID.
- Key Vault RBAC assignment.
- Correct subscription/resource scope.
- Secret name and version.
- Key Vault network restrictions/private endpoint/DNS if applicable.
- Whether the RBAC assignment has propagated.

A `403` should not automatically be treated as a networking failure.

### Symptom: DNS/network timeout to Key Vault

Investigate the network path separately:

```text
Pod
 -> DNS resolution
 -> Private DNS (if private endpoint)
 -> VNet/subnet
 -> NSG/UDR/firewall
 -> Private Endpoint
 -> Key Vault
```

For private Key Vault access, verify that the correct Private DNS zone is linked to the VNet and that the hostname resolves to the expected private address.

## Security validation

Before production:

- [ ] No Azure client secret in Git.
- [ ] No secret value in Kubernetes YAML.
- [ ] Dedicated service account.
- [ ] Dedicated workload identity.
- [ ] Least-privilege Azure RBAC.
- [ ] Key Vault network controls reviewed.
- [ ] Private DNS validated when using Private Endpoint.
- [ ] Container runs as non-root where practical.
- [ ] Image is pinned to an immutable digest.
- [ ] Key Vault access is monitored/audited.

## Incident decision tree

```text
Application cannot read secret
          |
          +-- Token acquisition fails?
          |      -> Workload Identity / service account / federation
          |
          +-- Token succeeds but 403?
          |      -> Azure RBAC / Key Vault authorization
          |
          +-- Timeout / DNS failure?
                 -> Private DNS / route / NSG / firewall / endpoint
```

## Senior interview takeaway

A strong production answer separates three layers:

1. **Authentication:** Can the Pod obtain an Azure identity token?
2. **Authorization:** Does that identity have permission to read the required Key Vault secret?
3. **Connectivity:** Can the workload reach Key Vault over the required network path?

Do not troubleshoot all three layers at once. Establish evidence at each boundary, fix the smallest failing layer, then validate end-to-end access.