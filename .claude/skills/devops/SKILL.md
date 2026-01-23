---
name: devops
description: Review and design infrastructure configurations (Kubernetes, Helm, ArgoCD, Terraform, Terragrunt)
---

# DevOps

## Overview

Dispatch the devops agent to review existing infrastructure code or design and generate new configurations. The agent specializes in Kubernetes, Helm, ArgoCD, Terraform, and Terragrunt.

## When to Use

- When reviewing Kubernetes manifests or Helm charts
- When designing new infrastructure configurations
- When setting up ArgoCD applications or GitOps workflows
- When reviewing Terraform/Terragrunt modules
- When migrating or refactoring infrastructure code
- With "all" for comprehensive infrastructure audit

## Invocation Modes

### Default: `/devops`

Reviews recent infrastructure changes for best practices and issues.

```
Task tool with subagent_type="devops"
prompt: "Review recent infrastructure code changes.
Identify: Kubernetes, Helm, ArgoCD, Terraform, Terragrunt files.
Check for: security issues, best practices, reliability concerns.
Report findings with severity, location, and recommendations."
```

### Scoped: `/devops <context>`

Reviews or designs based on the provided context.

```
Task tool with subagent_type="devops"
prompt: "DevOps task for: [context]
Determine if this is a review or design request.
For review: analyze for security, best practices, reliability.
For design: generate production-ready configurations.
Provide detailed output with code examples."
```

**Context examples:**
- `/devops review k8s/` - review Kubernetes manifests
- `/devops review terraform/modules/vpc` - review Terraform module
- `/devops design helm chart for redis` - generate Helm chart
- `/devops design argocd app for microservices` - generate ArgoCD config
- `/devops review values.yaml` - review Helm values

### Comprehensive: `/devops all`

**Full infrastructure audit** of the entire repository.

**CRITICAL: Do not skip any infrastructure files. Continue until ALL are reviewed.**

#### Execution Flow

1. **Discover infrastructure files** - Find all IaC in the repository
2. **Create TodoWrite plan** - One todo item per infrastructure type/area
3. **Process sequentially** - Review each area thoroughly
4. **Mark progress** - Update todos as each section completes

#### Infrastructure Types to Review

| Type | File Patterns | What to Check |
|------|---------------|---------------|
| Kubernetes | `*.yaml`, `*.yml` in k8s/, manifests/ | Security, resources, probes, RBAC |
| Helm | `Chart.yaml`, `values.yaml`, templates/ | Structure, templating, defaults |
| ArgoCD | `Application`, `ApplicationSet` | Sync policy, health, RBAC |
| Terraform | `*.tf` | State, modules, security, variables |
| Terragrunt | `terragrunt.hcl` | DRY, dependencies, remote state |
| Kustomize | `kustomization.yaml` | Overlays, patches, resources |

## What the Agent Does

### Review Mode
- Identifies security misconfigurations (privileged containers, missing RBAC)
- Checks for best practice violations (no resource limits, missing probes)
- Finds reliability issues (no HPA, missing PDBs)
- Suggests performance optimizations
- Rates severity (CRITICAL/HIGH/MEDIUM/LOW)
- Provides specific fixes with corrected code

### Design Mode
- Generates production-ready configurations
- Follows GitOps principles
- Includes security best practices by default
- Provides clear documentation
- Creates modular, reusable patterns

## Severity Levels

| Level | Description |
|-------|-------------|
| CRITICAL | Security breach risk, data loss potential |
| HIGH | Production stability risk |
| MEDIUM | Operational issues |
| LOW | Best practice improvements |

## Output Format

### Review Output

```markdown
## DevOps Review Report

### Executive Summary
[X critical, Y high, Z medium findings]

### Findings

#### [SEVERITY] Finding Title
- **Location**: file:line
- **Category**: Security | Reliability | Performance
- **Issue**: Description
- **Fix**: Corrected code

### Summary Table
| Severity | Count |
|----------|-------|
| Critical | X |
| High | Y |
| Medium | Z |
| Low | W |
```

### Design Output

```markdown
## Infrastructure Design

### Architecture Overview
[Description of the design]

### File Structure
[Directory tree]

### Generated Files
[Code blocks for each file]

### Deployment Instructions
[Step-by-step guide]
```

## Examples

**Review recent changes:**
```
/devops
→ Reviews recent IaC changes for issues
```

**Review specific directory:**
```
/devops review terraform/
→ Deep review of Terraform configurations
```

**Design new Helm chart:**
```
/devops design helm chart for api gateway
→ Generates complete Helm chart structure
```

**Design ArgoCD setup:**
```
/devops design argocd applicationset for multi-env
→ Generates ApplicationSet for multiple environments
```

**Full infrastructure audit:**
```
/devops all
→ Comprehensive audit with TodoWrite planning
```

## Technology Coverage

| Technology | Review | Design |
|------------|--------|--------|
| Kubernetes | Security, resources, probes, RBAC, NetworkPolicies | Deployments, Services, ConfigMaps |
| Helm | Chart structure, values, templates | Complete charts with best practices |
| ArgoCD | Sync policies, health checks, RBAC | Applications, ApplicationSets |
| Terraform | State, modules, security, variables | Modules with validation |
| Terragrunt | DRY patterns, dependencies, remote state | Hierarchical configurations |
| Kustomize | Overlays, patches | Base + overlay structures |
