REPO_DIR := $(shell pwd)/.claude
TARGET_DIR := $(HOME)/.claude
BACKUP_DIR := $(HOME)/.claude-backups

# Claude Code reads MCP servers from .claude.json, not from settings.json.
# For the default home it lives next to ~/.claude; for a custom home
# (CLAUDE_CONFIG_DIR, e.g. ~/.claude-personal) it lives inside the target dir.
ifeq ($(TARGET_DIR),$(HOME)/.claude)
CLAUDE_JSON := $(HOME)/.claude.json
else
CLAUDE_JSON := $(TARGET_DIR)/.claude.json
endif

GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
BLUE := \033[0;34m
NC := \033[0m  # No Color
BOLD := \033[1m

DRY_RUN ?= 0
FORCE ?= 0

# The local llama.cpp server that rewrites messages for the claudish plugin.
# The settings come from a benchmark of this model on Apple Silicon. The URL
# and the API key are written to the target settings.json only, never to the
# repo, so a machine can point at a server on another host.
LLAMA_HOST ?= 127.0.0.1
LLAMA_PORT ?= 11435
LLAMA_IDLE_SLEEP ?= 1800
LLAMA_MODEL_DIR ?= $(HOME)/models/gguf
LLAMA_MODEL_URL ?= https://huggingface.co/google/gemma-4-26B-A4B-it-qat-q4_0-gguf/resolve/main/gemma-4-26B_q4_0-it.gguf
LLAMA_MTP_URL ?= https://huggingface.co/ggml-org/gemma-4-26B-A4B-it-GGUF/resolve/main/mtp-gemma-4-26B-A4B-it-Q4_0.gguf
LLAMA_KEY_FILE ?= $(HOME)/.config/llama-server/api-key
LLAMA_LABEL := local.llama-server
LLAMA_PLIST ?= $(HOME)/Library/LaunchAgents/$(LLAMA_LABEL).plist
LLAMA_PLIST_TEMPLATE := $(shell pwd)/services/local.llama-server.plist.template
LLAMA_LOG ?= $(HOME)/Library/Logs/llama-server.log
NO_RSYNC ?=

DIFF_COLOR := $(shell diff --color=always /dev/null /dev/null > /dev/null 2>&1 && echo --color=always)

RSYNC_OPTS := -av --chmod=+x

ifeq ($(DRY_RUN),1)
	RSYNC_OPTS += --dry-run
	DRY_RUN_MSG := $(YELLOW)[DRY RUN]$(NC)
else
	DRY_RUN_MSG :=
endif

.DEFAULT_GOAL := help

# ============================================================================
# HELP
# ============================================================================

.PHONY: help
help:
	@echo "$(BOLD)Claude Code Configuration Sync$(NC)"
	@echo ""
	@echo "$(BOLD)Usage:$(NC)"
	@echo "  make <command> [DRY_RUN=1] [FORCE=1]"
	@echo ""
	@echo "$(BOLD)Update Commands$(NC) (add missing + update changed, keep extras):"
	@echo "  $(GREEN)update-all$(NC)       Update agents, skills, hooks, and config files"
	@echo "  $(GREEN)update-agents$(NC)    Update .claude/agents/ only"
	@echo "  $(GREEN)update-skills$(NC)    Update .claude/skills/ only"
	@echo "  $(GREEN)update-hooks$(NC)     Update .claude/hooks/ only"
	@echo "  $(GREEN)update-config$(NC)    Run update-settings, update-claude-md, and update-mcp"
	@echo "  $(GREEN)update-settings$(NC)  Update settings.json only (merged)"
	@echo "  $(GREEN)update-claude-md$(NC) Update CLAUDE.md only"
	@echo "  $(GREEN)update-mcp$(NC)       Update MCP servers in $(CLAUDE_JSON) only"
	@echo ""
	@echo "$(BOLD)Install Commands$(NC) (install external tools and requirements):"
	@echo "  $(GREEN)install$(NC)          Go through every registered target, asking for each"
	@echo "  $(GREEN)install sync$(NC)     Repo files synced into the target: $(INSTALL_SYNC)"
	@echo "  $(GREEN)install skills$(NC)   Skill installs: $(INSTALL_SKILLS)"
	@echo "  $(GREEN)install plugins$(NC)  Plugin requirements: $(INSTALL_PLUGINS)"
	@echo "  $(GREEN)install mcps$(NC)     MCP server requirements: $(INSTALL_MCPS)"
	@echo "  $(GREEN)install <target>$(NC) Install a single target"
	@echo ""
	@echo "$(BOLD)Remove Commands$(NC) (remove repo files from $(TARGET_DIR)):"
	@echo "  $(RED)rm-agents$(NC)      Remove matching agents"
	@echo "  $(RED)rm-skills$(NC)      Remove matching skills"
	@echo "  $(RED)rm-hooks$(NC)       Remove matching hooks"
	@echo ""
	@echo "$(BOLD)Utility Commands$(NC):"
	@echo "  $(BLUE)status$(NC)         Show sync status with colored indicators"
	@echo "  $(BLUE)diff$(NC)           Show file differences between repo and $(TARGET_DIR)"
	@echo "  $(BLUE)backup$(NC)         Create timestamped backup of $(TARGET_DIR)"
	@echo "  $(BLUE)test$(NC)           Run the test suite in tests/"
	@echo ""
	@echo "$(BOLD)Options$(NC):"
	@echo "  DRY_RUN=1    Preview changes without executing"
	@echo "  FORCE=1      Skip confirmation prompts"
	@echo "  NO_RSYNC=1   Force plain-copy fallback instead of rsync"
	@echo ""
	@echo "$(BOLD)Examples$(NC):"
	@echo "  make update-all              # Update files in $(TARGET_DIR)"
	@echo "  make install                 # Ask for each registered target"
	@echo "  make install google-maps-scraper  # Install a specific target"
	@echo "  make DRY_RUN=1 rm-agents     # Preview agent removal"
	@echo "  make FORCE=1 rm-skills       # Remove skills without confirmation"

# ============================================================================
# INSTALL TARGETS REGISTRY
# ============================================================================

# To add an install target:
#   1. Append its <name> to the matching group below
#   2. Add a matching `install-<name>` recipe in the INSTALL COMMANDS section
INSTALL_SKILLS := google-maps-scraper anatomy
INSTALL_PLUGINS := claudish claude-hud claude-pray typescript-lsp gopls-lsp
INSTALL_MCPS := terraform-mcp
INSTALL_SYNC := hooks config
INSTALL_GROUPS := sync skills plugins mcps
INSTALL_TARGETS := $(INSTALL_SYNC) $(INSTALL_SKILLS) $(INSTALL_PLUGINS) $(INSTALL_MCPS)

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

define install_brew_pkg
	@if command -v $(2) >/dev/null 2>&1; then \
		echo "Present: $(2)"; \
	elif [ "$(DRY_RUN)" = "1" ]; then \
		echo "Would ask, then install: $(1)"; \
	elif ! command -v brew >/dev/null 2>&1; then \
		echo "$(RED)Homebrew not found. Install it from https://brew.sh first.$(NC)"; \
		exit 1; \
	else \
		install=1; \
		if [ "$(FORCE)" != "1" ]; then \
			printf "$(YELLOW)Install $(1) with brew? [y/N]: $(NC)"; \
			read -r answer; \
			case "$$answer" in y|Y) ;; *) install=0;; esac; \
		fi; \
		if [ "$$install" = "1" ]; then \
			brew install $(1); \
		else \
			echo "Skipped. Run later with: brew install $(1)"; \
		fi; \
	fi
endef

define confirm
	@if [ "$(FORCE)" != "1" ] && [ "$(DRY_RUN)" != "1" ]; then \
		printf "$(YELLOW)$1 [y/N]: $(NC)"; \
		read -r answer; \
		if [ "$$answer" != "y" ] && [ "$$answer" != "Y" ]; then \
			echo "$(RED)Aborted.$(NC)"; \
			exit 1; \
		fi \
	fi
endef

define ensure_target_dir
	@mkdir -p $(TARGET_DIR)
endef

define cleanup_empty_dirs
	@find $(TARGET_DIR) -type d -empty -delete 2>/dev/null || true
endef

define sync_mcp_servers
	@echo "$(BOLD)Updating MCP servers...$(NC) $(DRY_RUN_MSG)"
	@if [ -f $(REPO_DIR)/mcp-servers.json ]; then \
		if ! command -v jq >/dev/null 2>&1; then \
			echo "$(YELLOW)Warning: jq not found, skipping MCP server sync$(NC)"; \
		elif [ ! -f $(CLAUDE_JSON) ]; then \
			if [ "$(DRY_RUN)" = "1" ]; then \
				echo "Would add: mcpServers to $(CLAUDE_JSON)"; \
			else \
				jq '{mcpServers: .mcpServers}' $(REPO_DIR)/mcp-servers.json > $(CLAUDE_JSON); \
				echo "Added: mcpServers to $(CLAUDE_JSON)"; \
			fi \
		else \
			merged=$$(jq -s '.[0] * {mcpServers: ((.[0].mcpServers // {}) + .[1].mcpServers)}' $(CLAUDE_JSON) $(REPO_DIR)/mcp-servers.json); \
			if printf '%s\n' "$$merged" | diff -q - $(CLAUDE_JSON) > /dev/null 2>&1; then \
				echo "Unchanged: mcpServers in $(CLAUDE_JSON)"; \
			elif [ "$(DRY_RUN)" = "1" ]; then \
				echo "Would merge: mcpServers into $(CLAUDE_JSON) (repo servers win, local servers kept)"; \
			else \
				printf '%s\n' "$$merged" > $(CLAUDE_JSON); \
				echo "Merged: mcpServers into $(CLAUDE_JSON) (repo servers win, local servers kept)"; \
			fi \
		fi \
	fi
endef

define sync_dir
	@echo "$(BOLD)Updating $(1)...$(NC) $(DRY_RUN_MSG)"; \
	if [ ! -d $(REPO_DIR)/$(1) ]; then \
		echo "  No $(1) directory in repo, skipping."; \
	else \
		mkdir -p $(TARGET_DIR)/$(1); \
		if [ -z "$(NO_RSYNC)" ] && command -v rsync >/dev/null 2>&1; then \
			rsync $(RSYNC_OPTS) $(REPO_DIR)/$(1)/ $(TARGET_DIR)/$(1)/; \
		else \
			for f in $(REPO_DIR)/$(1)/*; do \
				filename=$$(basename "$$f"); \
				target="$(TARGET_DIR)/$(1)/$$filename"; \
				if [ ! -e "$$target" ]; then \
					if [ "$(DRY_RUN)" = "1" ]; then \
						echo "Would add: $(1)/$$filename"; \
					else \
						cp -r "$$f" "$$target"; \
						find "$$target" -name "*.sh" -exec chmod +x {} + 2>/dev/null || true; \
						echo "Added: $(1)/$$filename"; \
					fi; \
				elif ! diff -rq "$$f" "$$target" > /dev/null 2>&1; then \
					if [ "$(DRY_RUN)" = "1" ]; then \
						echo "Would update: $(1)/$$filename"; \
					else \
						rm -rf "$$target"; \
						cp -r "$$f" "$$target"; \
						find "$$target" -name "*.sh" -exec chmod +x {} + 2>/dev/null || true; \
						echo "Updated: $(1)/$$filename"; \
					fi; \
				else \
					echo "Unchanged: $(1)/$$filename"; \
				fi; \
			done; \
		fi; \
	fi
endef

define rm_dir
	@echo "$(BOLD)Removing $(1)...$(NC) $(DRY_RUN_MSG)"; \
	if [ -d $(REPO_DIR)/$(1) ]; then \
		for f in $(REPO_DIR)/$(1)/*; do \
			filename=$$(basename "$$f"); \
			target="$(TARGET_DIR)/$(1)/$$filename"; \
			if [ -e "$$target" ]; then \
				if [ "$(DRY_RUN)" = "1" ]; then \
					echo "Would remove: $(1)/$$filename"; \
				else \
					rm -rf "$$target"; \
					echo "Removed: $(1)/$$filename"; \
				fi; \
			fi; \
		done; \
	fi
endef

define status_dir
	@echo "$(BOLD)$(2):$(NC)"; \
	if [ -d $(REPO_DIR)/$(1) ]; then \
		for f in $(REPO_DIR)/$(1)/*; do \
			filename=$$(basename "$$f"); \
			target="$(TARGET_DIR)/$(1)/$$filename"; \
			if [ ! -e "$$target" ]; then \
				printf "  $(RED)●$(NC) $$filename $(RED)(missing)$(NC)\n"; \
			elif diff -rq "$$f" "$$target" > /dev/null 2>&1; then \
				printf "  $(GREEN)●$(NC) $$filename $(GREEN)(synced)$(NC)\n"; \
			else \
				printf "  $(YELLOW)●$(NC) $$filename $(YELLOW)(differs)$(NC)\n"; \
			fi; \
		done; \
	fi; \
	if [ -d $(TARGET_DIR)/$(1) ]; then \
		for f in $(TARGET_DIR)/$(1)/*; do \
			filename=$$(basename "$$f"); \
			if [ ! -e "$(REPO_DIR)/$(1)/$$filename" ]; then \
				printf "  $(BLUE)●$(NC) $$filename $(BLUE)(extra - not in repo)$(NC)\n"; \
			fi; \
		done; \
	fi; \
	echo ""
endef

define diff_dir
	@echo "$(BOLD)$(2):$(NC)"; \
	if [ -d $(REPO_DIR)/$(1) ]; then \
		for f in $(REPO_DIR)/$(1)/*; do \
			filename=$$(basename "$$f"); \
			target="$(TARGET_DIR)/$(1)/$$filename"; \
			if [ ! -e "$$target" ]; then \
				printf "  $(GREEN)●$(NC) $$filename $(GREEN)(would add - not in $(TARGET_DIR))$(NC)\n"; \
			elif ! diff -rq "$$f" "$$target" > /dev/null 2>&1; then \
				echo "$(YELLOW)--- $$filename ---$(NC)"; \
				diff -r $(DIFF_COLOR) "$$target" "$$f"; \
				echo ""; \
			fi; \
		done; \
	fi; \
	if [ -d $(TARGET_DIR)/$(1) ]; then \
		for f in $(TARGET_DIR)/$(1)/*; do \
			filename=$$(basename "$$f"); \
			if [ ! -e "$(REPO_DIR)/$(1)/$$filename" ]; then \
				printf "  $(BLUE)●$(NC) $$filename $(BLUE)(extra - not in repo)$(NC)\n"; \
			fi; \
		done; \
	fi; \
	echo ""
endef

# ============================================================================
# UPDATE COMMANDS (add missing + update changed, keep extras)
# ============================================================================

.PHONY: update-all
update-all: update-agents update-skills update-hooks update-config
	@echo ""
	@echo "$(GREEN)Update complete!$(NC) $(DRY_RUN_MSG)"

.PHONY: update-agents
update-agents:
	$(call sync_dir,agents)

.PHONY: update-skills
update-skills:
	$(call sync_dir,skills)

.PHONY: update-hooks
update-hooks:
	$(call sync_dir,hooks)

.PHONY: update-config
update-config: update-settings update-claude-md update-mcp

.PHONY: update-settings
update-settings:
	@echo "$(BOLD)Updating settings.json...$(NC) $(DRY_RUN_MSG)"
	$(call ensure_target_dir)
	@if [ ! -f $(TARGET_DIR)/settings.json ]; then \
		if [ "$(DRY_RUN)" = "1" ]; then \
			echo "Would add: settings.json"; \
		else \
			cp $(REPO_DIR)/settings.json $(TARGET_DIR)/settings.json; \
			echo "Added: settings.json"; \
		fi \
	elif command -v jq >/dev/null 2>&1; then \
		merged=$$(jq -s '.[0] * .[1]' $(TARGET_DIR)/settings.json $(REPO_DIR)/settings.json); \
		if printf '%s\n' "$$merged" | diff -q - $(TARGET_DIR)/settings.json > /dev/null 2>&1; then \
			echo "Unchanged: settings.json"; \
		elif [ "$(DRY_RUN)" = "1" ]; then \
			echo "Would merge: settings.json (repo values win, local-only keys kept)"; \
		else \
			printf '%s\n' "$$merged" > $(TARGET_DIR)/settings.json; \
			echo "Merged: settings.json (repo values win, local-only keys kept)"; \
		fi \
	elif ! diff -q $(REPO_DIR)/settings.json $(TARGET_DIR)/settings.json > /dev/null 2>&1; then \
		if [ "$(DRY_RUN)" = "1" ]; then \
			echo "Would update: settings.json (jq not found, local-only keys will be lost)"; \
		else \
			echo "$(YELLOW)Warning: jq not found, overwriting settings.json (local-only keys lost)$(NC)"; \
			cp $(REPO_DIR)/settings.json $(TARGET_DIR)/settings.json; \
			echo "Updated: settings.json"; \
		fi \
	else \
		echo "Unchanged: settings.json"; \
	fi

.PHONY: update-claude-md
update-claude-md:
	@echo "$(BOLD)Updating CLAUDE.md...$(NC) $(DRY_RUN_MSG)"
	$(call ensure_target_dir)
	@if [ ! -f $(TARGET_DIR)/CLAUDE.md ]; then \
		if [ "$(DRY_RUN)" = "1" ]; then \
			echo "Would add: CLAUDE.md"; \
		else \
			cp $(REPO_DIR)/CLAUDE.md $(TARGET_DIR)/CLAUDE.md; \
			echo "Added: CLAUDE.md"; \
		fi \
	elif ! diff -q $(REPO_DIR)/CLAUDE.md $(TARGET_DIR)/CLAUDE.md > /dev/null 2>&1; then \
		if [ "$(DRY_RUN)" = "1" ]; then \
			echo "Would update: CLAUDE.md"; \
		else \
			cp $(REPO_DIR)/CLAUDE.md $(TARGET_DIR)/CLAUDE.md; \
			echo "Updated: CLAUDE.md"; \
		fi \
	else \
		echo "Unchanged: CLAUDE.md"; \
	fi

.PHONY: update-mcp
update-mcp:
	$(call ensure_target_dir)
	$(call sync_mcp_servers)

# ============================================================================
# INSTALL COMMANDS (install external tools and skills)
# ============================================================================

.PHONY: install
install:
	@targets="$(filter-out install,$(MAKECMDGOALS))"; \
	if [ -z "$$targets" ]; then \
		targets="all"; \
	fi; \
	expanded=""; \
	for t in $$targets; do \
		case "$$t" in \
			all) expanded="$$expanded $(addprefix ask:,$(INSTALL_TARGETS))" ;; \
			sync) expanded="$$expanded $(addprefix ask:,$(INSTALL_SYNC))" ;; \
			skills) expanded="$$expanded $(addprefix ask:,$(INSTALL_SKILLS))" ;; \
			plugins) expanded="$$expanded $(addprefix ask:,$(INSTALL_PLUGINS))" ;; \
			mcps) expanded="$$expanded $(addprefix ask:,$(INSTALL_MCPS))" ;; \
			*) expanded="$$expanded $$t" ;; \
		esac; \
	done; \
	for item in $$expanded; do \
		t="$${item#ask:}"; \
		if ! echo " $(INSTALL_TARGETS) " | grep -q " $$t "; then \
			echo "$(RED)Unknown install target: $$t$(NC)"; \
			echo "Available groups: $(INSTALL_GROUPS)"; \
			echo "Available targets: $(INSTALL_TARGETS)"; \
			exit 1; \
		fi; \
		if [ "$$item" != "$$t" ] && [ "$(FORCE)" != "1" ] && [ "$(DRY_RUN)" != "1" ]; then \
			printf "$(YELLOW)Install $$t? [y/N]: $(NC)"; \
			answer=""; \
			read -r answer || true; \
			case "$$answer" in \
				y|Y) ;; \
				*) echo "Skipped $$t. Run later with: make install $$t"; continue ;; \
			esac; \
		fi; \
		$(MAKE) --no-print-directory install-$$t; \
	done

.PHONY: install-hooks
install-hooks: update-hooks

.PHONY: install-config
install-config: update-config

.PHONY: install-google-maps-scraper
install-google-maps-scraper:
	@echo "$(BOLD)Installing google-maps-scraper...$(NC) $(DRY_RUN_MSG)"
	@if [ "$(DRY_RUN)" = "1" ]; then \
		echo "Would run: npx skills add gosom/google-maps-scraper"; \
	else \
		npx skills add gosom/google-maps-scraper; \
	fi

.PHONY: install-anatomy
install-anatomy:
	@echo "$(BOLD)Installing anatomy...$(NC) $(DRY_RUN_MSG)"
	@if [ "$(DRY_RUN)" = "1" ]; then \
		echo "Would run: CLAUDE_CONFIG_DIR=$(TARGET_DIR) npx skills add wheresryan22/anatomy -g -a claude-code"; \
	else \
		CLAUDE_CONFIG_DIR="$(TARGET_DIR)" npx skills add wheresryan22/anatomy -g -a claude-code; \
	fi

.PHONY: install-claudish
install-claudish:
	@echo "$(BOLD)Installing claudish requirements...$(NC) $(DRY_RUN_MSG)"
	@if ! command -v brew >/dev/null 2>&1; then \
		echo "$(RED)Homebrew not found. Install it from https://brew.sh first.$(NC)"; \
		exit 1; \
	fi
	@missing=""; \
	for pair in llama.cpp:llama-server jq:jq; do \
		pkg=$${pair%%:*}; cmd=$${pair##*:}; \
		if command -v $$cmd >/dev/null 2>&1; then \
			echo "Present: $$pkg"; \
		else \
			missing="$$missing $$pkg"; \
		fi; \
	done; \
	if [ -n "$$missing" ]; then \
		if [ "$(DRY_RUN)" = "1" ]; then \
			echo "Would ask, then install:$$missing"; \
		else \
			install=1; \
			if [ "$(FORCE)" != "1" ]; then \
				printf "$(YELLOW)Install$$missing with brew? [y/N]: $(NC)"; \
				read -r answer; \
				case "$$answer" in y|Y) ;; *) install=0;; esac; \
			fi; \
			if [ "$$install" = "1" ]; then \
				brew install $$missing; \
			else \
				echo "Skipped package install. Run later with: brew install$$missing"; \
			fi; \
		fi; \
	fi
	@for url in "$(LLAMA_MODEL_URL)" "$(LLAMA_MTP_URL)"; do \
		file="$(LLAMA_MODEL_DIR)/$${url##*/}"; \
		if [ -s "$$file" ]; then \
			echo "Present: $$file"; \
		elif [ "$(DRY_RUN)" = "1" ]; then \
			echo "Would ask, then download: $$url"; \
		else \
			pull=1; \
			if [ "$(FORCE)" != "1" ]; then \
				printf "$(YELLOW)Download $${url##*/} (the model is a multi-GB download)? [y/N]: $(NC)"; \
				read -r answer; \
				case "$$answer" in y|Y) ;; *) pull=0;; esac; \
			fi; \
			if [ "$$pull" = "1" ]; then \
				mkdir -p "$(LLAMA_MODEL_DIR)"; \
				curl -L --fail --retry 3 -C - -o "$$file.part" "$$url" && mv "$$file.part" "$$file"; \
			else \
				echo "Skipped download. Run later with: curl -L -o $$file $$url"; \
			fi; \
		fi; \
	done
	@if [ -s "$(LLAMA_KEY_FILE)" ]; then \
		echo "Present: API key in $(LLAMA_KEY_FILE)"; \
	elif [ "$(DRY_RUN)" = "1" ]; then \
		echo "Would write a new API key to $(LLAMA_KEY_FILE)"; \
	else \
		mkdir -p "$$(dirname "$(LLAMA_KEY_FILE)")"; \
		(umask 077; printf 'sk-local-%s\n' "$$(openssl rand -hex 24)" > "$(LLAMA_KEY_FILE)"); \
		echo "Wrote a new API key to $(LLAMA_KEY_FILE)"; \
	fi
	@alias=$$(jq -r '.env.CLAUDISH_MODEL // empty' $(REPO_DIR)/settings.json 2>/dev/null); \
	if [ "$$(uname)" != "Darwin" ]; then \
		echo "$(YELLOW)The login service is set up on macOS only. Start llama-server yourself, or point CLAUDISH_OPENAI_URL at a machine that runs it.$(NC)"; \
	elif [ -z "$$alias" ]; then \
		echo "$(YELLOW)No CLAUDISH_MODEL in $(REPO_DIR)/settings.json, skipping the login service$(NC)"; \
	elif [ -f "$(LLAMA_PLIST)" ]; then \
		echo "Present: $(LLAMA_PLIST)"; \
	elif [ "$(DRY_RUN)" = "1" ]; then \
		echo "Would ask, then write $(LLAMA_PLIST) and start the $(LLAMA_LABEL) service"; \
	elif ! command -v llama-server >/dev/null 2>&1; then \
		echo "$(YELLOW)llama-server is not installed, skipping the login service$(NC)"; \
	else \
		start=1; \
		if [ "$(FORCE)" != "1" ]; then \
			printf "$(YELLOW)Start llama-server on $(LLAMA_HOST):$(LLAMA_PORT) now and at every login? [y/N]: $(NC)"; \
			read -r answer; \
			case "$$answer" in y|Y) ;; *) start=0;; esac; \
		fi; \
		if [ "$$start" = "1" ]; then \
			mkdir -p "$$(dirname "$(LLAMA_PLIST)")" "$$(dirname "$(LLAMA_LOG)")"; \
			sed -e "s|@LABEL@|$(LLAMA_LABEL)|g" \
				-e "s|@SERVER_BIN@|$$(command -v llama-server)|g" \
				-e "s|@MODEL_FILE@|$(LLAMA_MODEL_DIR)/$(notdir $(LLAMA_MODEL_URL))|g" \
				-e "s|@MTP_FILE@|$(LLAMA_MODEL_DIR)/$(notdir $(LLAMA_MTP_URL))|g" \
				-e "s|@ALIAS@|$$alias|g" \
				-e "s|@HOST@|$(LLAMA_HOST)|g" \
				-e "s|@PORT@|$(LLAMA_PORT)|g" \
				-e "s|@KEY_FILE@|$(LLAMA_KEY_FILE)|g" \
				-e "s|@IDLE_SLEEP@|$(LLAMA_IDLE_SLEEP)|g" \
				-e "s|@LOG_FILE@|$(LLAMA_LOG)|g" \
				$(LLAMA_PLIST_TEMPLATE) > "$(LLAMA_PLIST)"; \
			echo "Wrote $(LLAMA_PLIST)"; \
			if launchctl print gui/$$(id -u)/$(LLAMA_LABEL) >/dev/null 2>&1; then \
				echo "$(YELLOW)The $(LLAMA_LABEL) service is already loaded. Stop it with: launchctl bootout gui/$$(id -u)/$(LLAMA_LABEL), then run make install claudish again$(NC)"; \
			else \
				launchctl bootstrap gui/$$(id -u) "$(LLAMA_PLIST)" && echo "Started the $(LLAMA_LABEL) service"; \
			fi; \
		else \
			echo "Skipped the login service. Run later with: make install claudish"; \
		fi; \
	fi
	@settings="$(TARGET_DIR)/settings.json"; \
	url="http://127.0.0.1:$(LLAMA_PORT)/v1"; \
	if [ ! -f "$$settings" ]; then \
		echo "$(YELLOW)$$settings not found. Run make update-settings, then make install claudish again.$(NC)"; \
	else \
		if [ -n "$$(jq -r '.env.CLAUDISH_OPENAI_URL // empty' "$$settings")" ]; then \
			echo "Present: CLAUDISH_OPENAI_URL in $$settings"; \
		elif [ "$(DRY_RUN)" = "1" ]; then \
			echo "Would set CLAUDISH_OPENAI_URL=$$url in $$settings"; \
		else \
			merged=$$(jq --arg u "$$url" '.env.CLAUDISH_OPENAI_URL = $$u' "$$settings") && printf '%s\n' "$$merged" > "$$settings"; \
			echo "Set CLAUDISH_OPENAI_URL=$$url in $$settings"; \
		fi; \
		if [ -n "$$(jq -r '.env.CLAUDISH_OPENAI_KEY // empty' "$$settings")" ]; then \
			echo "Present: CLAUDISH_OPENAI_KEY in $$settings"; \
		elif [ "$(DRY_RUN)" = "1" ]; then \
			echo "Would set CLAUDISH_OPENAI_KEY in $$settings from $(LLAMA_KEY_FILE)"; \
		elif [ ! -s "$(LLAMA_KEY_FILE)" ]; then \
			echo "$(YELLOW)No API key in $(LLAMA_KEY_FILE), skipping CLAUDISH_OPENAI_KEY$(NC)"; \
		else \
			merged=$$(jq --arg k "$$(cat "$(LLAMA_KEY_FILE)")" '.env.CLAUDISH_OPENAI_KEY = $$k' "$$settings") && printf '%s\n' "$$merged" > "$$settings"; \
			chmod 600 "$$settings"; \
			echo "Set CLAUDISH_OPENAI_KEY in $$settings"; \
		fi; \
	fi
	@echo "$(GREEN)claudish requirements done.$(NC)"

.PHONY: install-claude-hud
install-claude-hud:
	@echo "$(BOLD)Installing claude-hud requirements...$(NC) $(DRY_RUN_MSG)"
	$(call install_brew_pkg,node,node)
	@echo "$(GREEN)claude-hud requirements done.$(NC)"

.PHONY: install-claude-pray
install-claude-pray:
	@echo "$(BOLD)Installing claude-pray requirements...$(NC) $(DRY_RUN_MSG)"
	$(call install_brew_pkg,node,node)
	@echo "$(GREEN)claude-pray requirements done.$(NC)"

.PHONY: install-typescript-lsp
install-typescript-lsp:
	@echo "$(BOLD)Installing typescript-lsp requirements...$(NC) $(DRY_RUN_MSG)"
	$(call install_brew_pkg,typescript-language-server,typescript-language-server)
	@echo "$(GREEN)typescript-lsp requirements done.$(NC)"

.PHONY: install-gopls-lsp
install-gopls-lsp:
	@echo "$(BOLD)Installing gopls-lsp requirements...$(NC) $(DRY_RUN_MSG)"
	$(call install_brew_pkg,gopls,gopls)
	@echo "$(GREEN)gopls-lsp requirements done.$(NC)"

.PHONY: install-terraform-mcp
install-terraform-mcp:
	@echo "$(BOLD)Installing terraform-mcp requirements...$(NC) $(DRY_RUN_MSG)"
	@if command -v docker >/dev/null 2>&1; then \
		echo "Present: docker"; \
	elif [ "$(DRY_RUN)" = "1" ]; then \
		echo "Would ask, then install: docker (brew cask)"; \
	elif ! command -v brew >/dev/null 2>&1; then \
		echo "$(RED)Homebrew not found. Install it from https://brew.sh first.$(NC)"; \
		exit 1; \
	else \
		install=1; \
		if [ "$(FORCE)" != "1" ]; then \
			printf "$(YELLOW)Install Docker Desktop with brew (--cask docker)? [y/N]: $(NC)"; \
			read -r answer; \
			case "$$answer" in y|Y) ;; *) install=0;; esac; \
		fi; \
		if [ "$$install" = "1" ]; then \
			brew install --cask docker; \
		else \
			echo "Skipped. Run later with: brew install --cask docker"; \
		fi; \
	fi
	@if ! command -v docker >/dev/null 2>&1; then \
		:; \
	elif ! docker info >/dev/null 2>&1; then \
		echo "$(YELLOW)Docker is not running. Start it, then rerun to pull the server image.$(NC)"; \
	elif docker image inspect hashicorp/terraform-mcp-server >/dev/null 2>&1; then \
		echo "Present: hashicorp/terraform-mcp-server image"; \
	elif [ "$(DRY_RUN)" = "1" ]; then \
		echo "Would ask, then pull: hashicorp/terraform-mcp-server"; \
	else \
		pull=1; \
		if [ "$(FORCE)" != "1" ]; then \
			printf "$(YELLOW)Pull the hashicorp/terraform-mcp-server image? [y/N]: $(NC)"; \
			read -r answer; \
			case "$$answer" in y|Y) ;; *) pull=0;; esac; \
		fi; \
		if [ "$$pull" = "1" ]; then \
			docker pull hashicorp/terraform-mcp-server; \
		else \
			echo "Skipped. Run later with: docker pull hashicorp/terraform-mcp-server"; \
		fi; \
	fi
	@if [ -n "$$TFE_TOKEN" ]; then \
		echo "Present: TFE_TOKEN"; \
	else \
		echo "$(YELLOW)TFE_TOKEN is not set. Export it before launching Claude Code or the HCP Terraform tools stay hidden.$(NC)"; \
	fi
	@echo "$(GREEN)terraform-mcp requirements done.$(NC)"

# `make install claudish` also makes `claudish` a goal of its own; these
# no-op rules stop Make failing with "No rule to make target".
.PHONY: all $(INSTALL_GROUPS) $(INSTALL_TARGETS)
all $(INSTALL_GROUPS) $(INSTALL_TARGETS):
	@:

# ============================================================================
# REMOVE COMMANDS (remove repo files from ~/.claude)
# ============================================================================

.PHONY: rm-agents
rm-agents:
	$(call confirm,This will remove matching agents from $(TARGET_DIR). Continue?)
	$(call rm_dir,agents)
	$(call cleanup_empty_dirs)

.PHONY: rm-skills
rm-skills:
	$(call confirm,This will remove matching skills from $(TARGET_DIR). Continue?)
	$(call rm_dir,skills)
	$(call cleanup_empty_dirs)

.PHONY: rm-hooks
rm-hooks:
	$(call confirm,This will remove matching hooks from $(TARGET_DIR). Continue?)
	$(call rm_dir,hooks)
	$(call cleanup_empty_dirs)

# ============================================================================
# UTILITY COMMANDS
# ============================================================================

.PHONY: status
status:
	@echo "$(BOLD)Sync Status: $(REPO_DIR) → $(TARGET_DIR)$(NC)"
	@echo ""
	$(call status_dir,agents,Agents)
	$(call status_dir,skills,Skills)
	$(call status_dir,hooks,Hooks)
	@echo "$(BOLD)Config Files:$(NC)"
	@for f in settings.json CLAUDE.md; do \
		if [ ! -f $(TARGET_DIR)/$$f ]; then \
			printf "  $(RED)●$(NC) $$f $(RED)(missing)$(NC)\n"; \
		elif diff -q $(REPO_DIR)/$$f $(TARGET_DIR)/$$f > /dev/null 2>&1; then \
			printf "  $(GREEN)●$(NC) $$f $(GREEN)(synced)$(NC)\n"; \
		else \
			printf "  $(YELLOW)●$(NC) $$f $(YELLOW)(differs)$(NC)\n"; \
		fi \
	done
	@echo ""
	@echo "$(BOLD)MCP Servers ($(CLAUDE_JSON)):$(NC)"
	@if [ ! -f $(REPO_DIR)/mcp-servers.json ]; then \
		echo "  No mcp-servers.json in repo."; \
	elif ! command -v jq >/dev/null 2>&1; then \
		echo "  jq not found, cannot inspect MCP servers."; \
	else \
		for s in $$(jq -r '.mcpServers | keys[]' $(REPO_DIR)/mcp-servers.json); do \
			repo=$$(jq -c ".mcpServers[\"$$s\"]" $(REPO_DIR)/mcp-servers.json); \
			installed=$$(jq -c ".mcpServers[\"$$s\"] // empty" $(CLAUDE_JSON) 2>/dev/null); \
			if [ -z "$$installed" ]; then \
				printf "  $(RED)●$(NC) $$s $(RED)(missing)$(NC)\n"; \
			elif [ "$$repo" = "$$installed" ]; then \
				printf "  $(GREEN)●$(NC) $$s $(GREEN)(synced)$(NC)\n"; \
			else \
				printf "  $(YELLOW)●$(NC) $$s $(YELLOW)(differs)$(NC)\n"; \
			fi; \
		done; \
	fi
	@echo ""
	@echo "$(BOLD)Legend:$(NC) $(GREEN)●$(NC) synced  $(YELLOW)●$(NC) differs  $(RED)●$(NC) missing  $(BLUE)●$(NC) extra"

.PHONY: diff
diff:
	@echo "$(BOLD)Differences: $(TARGET_DIR) vs $(REPO_DIR)$(NC)"
	@echo "$(GREEN)green$(NC) = added by update  $(RED)red$(NC) = removed by update"
	@echo ""
	$(call diff_dir,agents,Agents)
	$(call diff_dir,skills,Skills)
	$(call diff_dir,hooks,Hooks)
	@echo "$(BOLD)Config Files:$(NC)"
	@for f in settings.json CLAUDE.md; do \
		if [ ! -f $(TARGET_DIR)/$$f ]; then \
			printf "  $(GREEN)●$(NC) $$f $(GREEN)(would add - not in $(TARGET_DIR))$(NC)\n"; \
		elif ! diff -q $(REPO_DIR)/$$f $(TARGET_DIR)/$$f > /dev/null 2>&1; then \
			echo "$(YELLOW)--- $$f ---$(NC)"; \
			diff $(DIFF_COLOR) $(TARGET_DIR)/$$f $(REPO_DIR)/$$f; \
			echo ""; \
		fi \
	done
	@echo ""
	@echo "$(BOLD)MCP Servers ($(CLAUDE_JSON)):$(NC)"
	@if [ -f $(REPO_DIR)/mcp-servers.json ] && command -v jq >/dev/null 2>&1; then \
		for s in $$(jq -r '.mcpServers | keys[]' $(REPO_DIR)/mcp-servers.json); do \
			repo=$$(jq ".mcpServers[\"$$s\"]" $(REPO_DIR)/mcp-servers.json); \
			installed=$$(jq ".mcpServers[\"$$s\"] // empty" $(CLAUDE_JSON) 2>/dev/null); \
			if [ -z "$$installed" ]; then \
				printf "  $(GREEN)●$(NC) $$s $(GREEN)(would add - not in $(CLAUDE_JSON))$(NC)\n"; \
			elif [ "$$repo" != "$$installed" ]; then \
				echo "$(YELLOW)--- $$s ---$(NC)"; \
				tmp_local=$$(mktemp); tmp_repo=$$(mktemp); \
				printf '%s\n' "$$installed" > "$$tmp_local"; printf '%s\n' "$$repo" > "$$tmp_repo"; \
				diff $(DIFF_COLOR) "$$tmp_local" "$$tmp_repo" || true; \
				rm -f "$$tmp_local" "$$tmp_repo"; \
				echo ""; \
			fi; \
		done; \
	fi

.PHONY: backup
backup:
	@echo "$(BOLD)Creating backup...$(NC)"
	@if [ -d $(TARGET_DIR) ]; then \
		mkdir -p $(BACKUP_DIR); \
		timestamp=$$(date +%Y%m%d_%H%M%S); \
		backup_path="$(BACKUP_DIR)/claude_$$timestamp"; \
		if [ "$(DRY_RUN)" = "1" ]; then \
			echo "Would create backup at: $$backup_path"; \
		else \
			cp -r $(TARGET_DIR) "$$backup_path"; \
			echo "$(GREEN)Backup created:$(NC) $$backup_path"; \
		fi \
	else \
		echo "$(YELLOW)No $(TARGET_DIR) directory to backup$(NC)"; \
	fi

.PHONY: test
test:
	@for t in tests/*.test.sh; do \
		echo "$(BOLD)Running $$t...$(NC)"; \
		bash "$$t" || exit 1; \
		echo ""; \
	done
