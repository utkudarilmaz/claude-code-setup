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
| `stripe` | remote HTTP, `https://mcp.stripe.com` | a Stripe account, signs in with OAuth |

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
   Keep `-e TFE_TOKEN` without a value. `-e TFE_TOKEN=<token>` would store the
   token in plain text in `.claude.json`.
4. Put the token in a file only you can read, then load it from your shell
   profile. Shell profiles are often readable by others or kept in a dotfiles
   repo, so do not write the token there:
   ```bash
   mkdir -p ~/.config/terraform-mcp
   (umask 077; printf 'TFE_TOKEN: '; stty -echo; read -r t; stty echo; echo
    printf "export TFE_TOKEN='%s'\n" "$t" > ~/.config/terraform-mcp/env)
   chmod 600 ~/.config/terraform-mcp/env
   ```
   Add `[ -f ~/.config/terraform-mcp/env ] && . ~/.config/terraform-mcp/env` to
   your shell profile. Export `TFE_ADDRESS` there too if you need it. Then start
   a new Claude Code session.
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

## stripe

Stripe's remote MCP server at `https://mcp.stripe.com`. It lets Claude read and
change objects in a Stripe account, such as customers, products, prices,
payment links, invoices, and refunds, and search the Stripe docs. It signs in
with OAuth, so no API key is stored on the machine.

There are two ways to add it. Pick one. With both, the server shows up twice.

### With the Stripe plugin

The `stripe` plugin ships this server together with Stripe skills such as
`stripe-best-practices` and `upgrade-stripe`. Two marketplaces carry it:

| Plugin ID | Install with |
|-----------|--------------|
| `stripe@anthropic-plugin-directory` | `stripe agent setup` |
| `stripe@claude-plugins-official` | `settings.overrides.json` |

Turn on only one of them. With both, the skills and the server load twice.

#### With `stripe agent setup`

This needs the [Stripe CLI](../guides/external-tools.md#stripe-cli).

1. Check what is installed. This changes nothing:
   ```bash
   stripe agent setup --status --client claude-code
   ```
2. Install the plugin:
   ```bash
   stripe agent setup --client claude-code
   ```
   It runs `claude plugin install stripe@anthropic-plugin-directory`. That
   marketplace is built into Claude Code, so there is nothing to add first.
   For a custom home, put `CLAUDE_CONFIG_DIR=<home>` in front of the command.
3. Start a new Claude Code session. Run `/mcp`, pick `plugin:stripe:stripe`, and
   choose Authenticate. Sign in to Stripe in the browser and pick the account.
4. Run `/mcp` again and check that the server is connected.

The repo `settings.json` does not set this plugin ID, so `make update-settings`
keeps it.

To remove it: `claude plugin uninstall stripe@anthropic-plugin-directory`.

#### With `settings.overrides.json`

The repo `settings.json` lists `stripe@claude-plugins-official` but turns it
off, so turning it on in `/plugin` gets undone by the next
`make update-settings`.

1. Turn it on in the home's `settings.overrides.json`:
   ```json
   {
     "enabledPlugins": {
       "stripe@claude-plugins-official": true
     }
   }
   ```
   See [Per-Machine Overrides](makefile.md#per-machine-overrides).
2. Run `make update-settings`, or `make update-settings TARGET_DIR=<home>` for a
   custom home.
3. Sign in from `/mcp` as in steps 3 and 4 above.

To remove it, set the value back to `false` in `settings.overrides.json` and
run `make update-settings`.

#### Telemetry

The plugin sends the name of each Stripe skill you use to Stripe. Set
`DISABLE_TELEMETRY=1` or `DO_NOT_TRACK=1` to stop it. At session start it also
checks for a newer Stripe CLI and may suggest installing it, but it never
installs anything.

### Server only

Add the server without the skills:

```bash
claude mcp add --scope user --transport http stripe https://mcp.stripe.com
```

Then run `/mcp`, pick `stripe`, and choose Authenticate.

To remove it: `claude mcp remove stripe --scope user`.

### Test mode first

The server can create, change, and refund live objects. Pick a sandbox or test
mode account when you sign in, and switch to a live account only when you need
it.
