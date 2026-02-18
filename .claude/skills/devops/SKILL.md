---
name: devops
description: This skill should be used when the user asks to "review infrastructure", "design helm chart", "check kubernetes manifests", "review terraform", "review terragrunt", "create argocd application", "audit infrastructure", or "/devops". Covers Kubernetes, Helm, ArgoCD, Terraform, and Terragrunt review and design.
---

# DevOps Skill

## Purpose

Dispatch the devops agent to review existing infrastructure code or design and generate new configurations. The agent specializes in Kubernetes, Helm, ArgoCD, Terraform, and Terragrunt, operating in review mode (analyze existing IaC) or design mode (generate new configurations).

## When to Invoke

Invoke this skill:

- When reviewing Kubernetes manifests or Helm charts
- When designing new infrastructure configurations
- When setting up ArgoCD applications or GitOps workflows
- When reviewing Terraform/Terragrunt modules
- When migrating or refactoring infrastructure code
- For comprehensive infrastructure audit with "all"

## Invocation Modes

### Default: `/devops`

Review recent infrastructure changes for best practices and issues.

```
Task tool with subagent_type="devops"
prompt: "Review recent infrastructure code changes.
Identify: Kubernetes, Helm, ArgoCD, Terraform, Terragrunt files.
Check for: security issues, best practices, reliability concerns.
Report findings with severity, location, and recommendations."
```

### Scoped: `/devops <context>`

Review or design based on the provided context.

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

### Comprehensive: `/devops all`

Perform a full infrastructure audit of the entire repository.

```
Task tool with subagent_type="devops"
prompt: "Perform comprehensive infrastructure audit of the entire repository.
Create a TodoWrite plan with one item per infrastructure type, then process sequentially.
Consult references/comprehensive-mode.md for the infrastructure types checklist and execution flow."
```

For the full infrastructure types checklist and example plan, consult **`references/comprehensive-mode.md`**.

## Usage Examples

```
/devops                                # Review recent IaC changes
/devops review terraform/              # Review Terraform configurations
/devops design helm chart for api      # Generate Helm chart
/devops design argocd applicationset   # Generate ArgoCD config
/devops all                            # Full infrastructure audit
```

## Additional Resources

### Reference Files

For detailed mode execution flows, consult:
- **`references/comprehensive-mode.md`** - Full audit execution flow, infrastructure types checklist, example TodoWrite plan
