# Comprehensive Mode: `/devops all`

Perform a full infrastructure audit of the entire repository.

**Do not skip any infrastructure files. Continue until ALL are reviewed.**

## Execution Flow

1. **Discover infrastructure files** - Find all IaC in the repository
2. **Create TodoWrite plan** - One todo item per infrastructure type/area
3. **Process sequentially** - Review each area thoroughly
4. **Mark progress** - Update todos as each section completes

## Infrastructure Types to Review

| Type | File Patterns | What to Check |
|------|---------------|---------------|
| Kubernetes | `*.yaml`, `*.yml` in k8s/, manifests/ | Security, resources, probes, RBAC |
| Helm | `Chart.yaml`, `values.yaml`, templates/ | Structure, templating, defaults |
| ArgoCD | `Application`, `ApplicationSet` | Sync policy, health, RBAC |
| Terraform | `*.tf` | State, modules, security, variables |
| Terragrunt | `terragrunt.hcl` | DRY, dependencies, remote state |
| Kustomize | `kustomization.yaml` | Overlays, patches, resources |

## Example TodoWrite Plan

When `/devops all` is invoked, create todos such as:

- [ ] Discover all infrastructure files in repository
- [ ] Review Kubernetes manifests (security, resources, probes)
- [ ] Review Helm charts (structure, values, templates)
- [ ] Review ArgoCD applications (sync policies, RBAC)
- [ ] Review Terraform configurations (state, modules, security)
- [ ] Review Terragrunt configurations (DRY, dependencies)
- [ ] Review Kustomize overlays (patches, resources)
- [ ] Compile findings into DevOps Review Report

Dispatch the devops agent for each area sequentially, marking each complete as it finishes.
