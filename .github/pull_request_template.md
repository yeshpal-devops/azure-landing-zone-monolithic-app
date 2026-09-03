## Summary

<!-- Describe the infrastructure or pipeline change. -->

## Change type

- [ ] Terraform infrastructure
- [ ] CI/CD pipeline
- [ ] Security
- [ ] Documentation
- [ ] Bug fix

## Validation

- [ ] `terraform fmt -check -recursive`
- [ ] `terraform init -backend=false`
- [ ] `terraform validate`
- [ ] `terraform plan` reviewed

## Security checklist

- [ ] No secrets/passwords committed
- [ ] No Terraform state or plan files committed
- [ ] RBAC/service connection permissions reviewed
- [ ] Production changes have required approval

## Notes

<!-- Add rollout, rollback, or dependency notes if applicable. -->
