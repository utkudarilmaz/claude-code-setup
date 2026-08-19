# MCP Servers

The servers declared in `.claude/mcp-servers.json` are merged into `.claude.json`
by `make update-config` or `make update-mcp`. See
[Makefile Commands](makefile.md#mcp-server-sync) for how that merge works.

| Server | Runs with | Needs |
|--------|-----------|-------|
| `build123d-mcp` | `uv tool run --python 3.12 build123d-mcp@latest` | `uv` on PATH |
| `terraform` | `docker run -i --rm hashicorp/terraform-mcp-server` | Docker, `TFE_TOKEN` |

## build123d-mcp

A persistent CAD session for build123d. It builds, measures, renders, and
exports 3D geometry across several calls instead of one shot scripts.

## terraform

HashiCorp's `terraform-mcp-server`, run in Docker. It reads runs and logs from
HCP Terraform or Terraform Enterprise (`list_runs`, `get_run_details`,
`get_plan_logs`, `get_plan_json_output`, `get_apply_logs`, workspace tools) and
searches the public Terraform registry docs.

### Environment

Docker receives both variables from the environment of the process that starts
Claude Code, so export them before you launch it.

| Variable | Required | Default |
|----------|----------|---------|
| `TFE_TOKEN` | yes | none |
| `TFE_ADDRESS` | no | `https://app.terraform.io` |

`TFE_TOKEN` is an HCP Terraform or Terraform Enterprise API token. Set
`TFE_ADDRESS` to your own host when you run Terraform Enterprise.

### Read only

`ENABLE_TF_OPERATIONS` is deliberately left unset, so the server cannot apply,
cancel, or delete anything.

### Checking the token

With a valid token the server registers 48 tools. Without one it still starts,
but registers only the 9 registry docs tools and none of the HCP Terraform
ones. Tool registration depends on an API ping at session start, so a missing
or invalid token silently drops the run and workspace tools. If you see 9
tools, fix `TFE_TOKEN` and restart Claude Code.
