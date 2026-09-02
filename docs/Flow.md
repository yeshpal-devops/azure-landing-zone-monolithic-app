# Terraform Delivery Flow

```text
Developer
   |
   v
Pull Request
   |
   v
Terraform CI
   +-- fmt check
   +-- init (backend disabled)
   +-- validate
   |
   v
Merge to main
   |
   v
Terraform CD
   |
   +--> Plan Dev --> Apply Dev
   |
   +--> QA
   |
   +--> UAT
   |
   +--> Production
          |
          +--> Manual approval / checks
          |
          +--> Apply
```

## Operational rules

1. Review the Terraform plan before apply.
2. Keep state separate for each environment.
3. Do not commit credentials or state files.
4. Use Azure DevOps service connections for Azure authentication.
5. Protect Production with environment approvals and branch policies.
