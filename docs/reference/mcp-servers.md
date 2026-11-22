# MCP Servers

The repo does not install or sync MCP servers. Add the ones you want on each
machine by hand with `claude mcp add`. Claude Code stores user-scoped servers
in `.claude.json`:

- Default home: `~/.claude.json`
- Custom home (`CLAUDE_CONFIG_DIR`, for example `~/.claude-personal`):
  `<home>/.claude.json`

To add a server to a custom home, set `CLAUDE_CONFIG_DIR` on the command, for
example `CLAUDE_CONFIG_DIR=~/.claude-personal claude mcp add ...`.

| Server | Runs with | Needs |
|--------|-----------|-------|
| `terraform` | `docker run -i --rm hashicorp/terraform-mcp-server` | Docker, `TFE_TOKEN` |

## terraform

HashiCorp's `terraform-mcp-server`, run in Docker. It reads runs and logs from
HCP Terraform or Terraform Enterprise (`list_runs`, `get_run_details`,
`get_plan_logs`, `get_plan_json_output`, `get_apply_logs`, workspace tools) and
searches the public Terraform registry docs.

### Setup

1. Install Docker and start it. On macOS: `brew install --cask docker`. On
   Linux, use your distribution's Docker Engine package.
2. Pull the image:
   ```bash
   docker pull hashicorp/terraform-mcp-server
   ```
3. Add the server for your user:
   ```bash
   claude mcp add --scope user terraform -- \
     docker run -i --rm -e TFE_TOKEN -e TFE_ADDRESS hashicorp/terraform-mcp-server
   ```
4. Export `TFE_TOKEN`, and `TFE_ADDRESS` if you need it, in your shell profile,
   then start a new Claude Code session.
5. Run `/mcp` and check that `terraform` is connected.

To remove it: `claude mcp remove terraform --scope user`.

### Environment

`docker run -e NAME` with no value copies the variable from the environment of
the process that starts Claude Code, so export both before you launch it.

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
