# External Tools

Some plugins and skills enabled in `settings.json` need programs that Claude
Code does not install. The Makefile does not install them either. Set up the
ones you use on each machine with the steps below.

| Used by | Needs | Check |
|---------|-------|-------|
| claude-hud and claude-pray status line | Node.js | `command -v node` |
| typescript-lsp plugin | `typescript-language-server` | `command -v typescript-language-server` |
| gopls-lsp plugin | `gopls` | `command -v gopls` |
| claudish-to-english plugin | a local model server | `/claudish` in Claude Code |
| terraform MCP server | Docker | see [MCP Servers](../reference/mcp-servers.md) |
| stripe plugin | Stripe CLI | `command -v stripe` |
| google-maps-scraper skill | Node.js (`npx`) | `ls ~/.claude/skills` |
| anatomy skill | Node.js (`npx`) | `ls ~/.claude/skills` |

## Node.js

The status line runs the claude-hud and claude-pray plugins with `node`.

- macOS: `brew install node`
- Linux: your distribution's `nodejs` package, or a version manager such as nvm

## Language Servers

The LSP plugins only connect Claude Code to a language server. Install the
server itself:

```bash
npm install -g typescript-language-server typescript
go install golang.org/x/tools/gopls@latest
```

On macOS, `brew install typescript-language-server gopls` works too.

## Stripe CLI

`stripe agent setup` installs the stripe plugin, so you need the CLI to use
that path. The plugin's skills also use it, for example `stripe listen` to
forward webhooks to a local server. The plugin and its MCP server are set up
in [MCP Servers](../reference/mcp-servers.md#stripe).

- macOS: `brew install stripe/stripe-cli/stripe`
- Linux: the `.deb` or `.rpm` package, or the release tarball, from
  [docs.stripe.com/stripe-cli](https://docs.stripe.com/stripe-cli)

Then run `stripe login` once.

## Third-Party Skills

These skills come from other repositories and are installed with the
`skills` CLI:

```bash
npx skills add gosom/google-maps-scraper
npx skills add wheresryan22/anatomy -g -a claude-code
```

For a custom home, set `CLAUDE_CONFIG_DIR` on the second command, for example
`CLAUDE_CONFIG_DIR=~/.claude-personal npx skills add ...`. The repo
`settings.json` turns `anatomy` off in `skillOverrides`, so turn it on there if
you want it.

## Claudish Plugin

The claudish-to-english plugin rewrites each message in plain English with a
model server. The repo `settings.json` sets `CLAUDISH_PROVIDER=openai`, the
OpenAI API format, and `CLAUDISH_MODEL=gemma4-26b`. These steps use
`llama-server` from llama.cpp on macOS.

1. Install the tools:
   ```bash
   brew install llama.cpp jq
   ```
2. Download the model and its helper file (14.7 GB together):
   ```bash
   mkdir -p ~/models/gguf && cd ~/models/gguf
   curl -L -O https://huggingface.co/google/gemma-4-26B-A4B-it-qat-q4_0-gguf/resolve/main/gemma-4-26B_q4_0-it.gguf
   curl -L -O https://huggingface.co/ggml-org/gemma-4-26B-A4B-it-GGUF/resolve/main/mtp-gemma-4-26B-A4B-it-Q4_0.gguf
   ```
3. Create an API key that only you can read:
   ```bash
   mkdir -p ~/.config/llama-server
   (umask 077; printf 'sk-local-%s\n' "$(openssl rand -hex 24)" > ~/.config/llama-server/api-key)
   chmod 600 ~/.config/llama-server/api-key
   ```
4. Start the server. The alias must match `CLAUDISH_MODEL`. Thinking is off
   because the plugin does not turn it off for this kind of server:
   ```bash
   llama-server -m ~/models/gguf/gemma-4-26B_q4_0-it.gguf --alias gemma4-26b \
     --host 127.0.0.1 --port 11435 -c 16384 -ngl 99 --parallel 1 \
     --jinja --reasoning off --temp 0.3 --top-k 64 --top-p 0.95 \
     --spec-type draft-mtp,ngram-mod \
     --spec-draft-model ~/models/gguf/mtp-gemma-4-26B-A4B-it-Q4_0.gguf \
     --api-key-file ~/.config/llama-server/api-key
   ```
5. Add the server URL and the key to the `env` block of `~/.claude/settings.json`:
   ```json
   "CLAUDISH_OPENAI_URL": "http://127.0.0.1:11435/v1",
   "CLAUDISH_OPENAI_KEY": "<the key from step 3>"
   ```
   Then make the file readable only by you with
   `chmod 600 ~/.claude/settings.json`. Never add the key to the repo's
   `config/settings.json`, which is public.
6. Start a new Claude Code session and run `/claudish` to check the provider
   and the model.

The URL and the key are not in the repo, so `make update-settings` keeps them.
A machine without its own server can set `CLAUDISH_OPENAI_URL` to another host
that runs the server. On that host, set `--host` to an address on a private
network you trust, such as a VPN address, not `0.0.0.0`. The server speaks
plain HTTP, so the key and every message cross the network unencrypted.
