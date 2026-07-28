# Makefile for Claude Code Configuration Sync
# Manages synchronization between repo's .claude/ and ~/.claude

# Configuration
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

# Colors
GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
BLUE := \033[0;34m
NC := \033[0m  # No Color
BOLD := \033[1m

# Feature flags
DRY_RUN ?= 0
FORCE ?= 0
# Set NO_RSYNC=1 to force the plain-copy fallback path even when rsync exists
NO_RSYNC ?=

# Use colored diff output when the local diff supports it
DIFF_COLOR := $(shell diff --color=always /dev/null /dev/null > /dev/null 2>&1 && echo --color=always)

# Rsync base options (used when rsync is available)
RSYNC_OPTS := -av --chmod=+x

ifeq ($(DRY_RUN),1)
	RSYNC_OPTS += --dry-run
	DRY_RUN_MSG := $(YELLOW)[DRY RUN]$(NC)
else
	DRY_RUN_MSG :=
endif

# Default target
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
	@echo "  $(GREEN)update-config$(NC)    Update settings.json (merged), CLAUDE.md, and MCP servers"
	@echo ""
	@echo "$(BOLD)Install Commands$(NC) (install external tools and skills):"
	@echo "  $(GREEN)install$(NC)          Install all registered targets"
	@echo "  $(GREEN)install all$(NC)      Install all registered targets"
	@echo "  $(GREEN)install <target>$(NC) Install a specific target"
	@echo "  $(BLUE)Targets:$(NC) $(INSTALL_TARGETS)"
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
	@echo "  make install                 # Install all registered targets"
	@echo "  make install google-maps-scraper  # Install a specific target"
	@echo "  make DRY_RUN=1 rm-agents     # Preview agent removal"
	@echo "  make FORCE=1 rm-skills       # Remove skills without confirmation"

# ============================================================================
# INSTALL TARGETS REGISTRY
# ============================================================================

# Registry of installable targets. To add a new one:
#   1. Append its <name> to INSTALL_TARGETS below
#   2. Add a matching `install-<name>` recipe in the INSTALL COMMANDS section
INSTALL_TARGETS := google-maps-scraper

# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

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

# Sync one directory (agents, skills, hooks) from repo to target.
# $(1) = directory name under .claude/
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

# Remove repo-managed files of one directory from the target.
# $(1) = directory name under .claude/
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

# Print sync status for one directory.
# $(1) = directory name under .claude/, $(2) = display label
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

# Print detailed differences for one directory.
# $(1) = directory name under .claude/, $(2) = display label
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
update-config:
	@echo "$(BOLD)Updating config files...$(NC) $(DRY_RUN_MSG)"
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

# ============================================================================
# INSTALL COMMANDS (install external tools and skills)
# ============================================================================

.PHONY: install
install:
	@targets="$(filter-out install,$(MAKECMDGOALS))"; \
	if [ -z "$$targets" ] || [ "$$targets" = "all" ]; then \
		targets="$(INSTALL_TARGETS)"; \
	fi; \
	for t in $$targets; do \
		if echo " $(INSTALL_TARGETS) " | grep -q " $$t "; then \
			$(MAKE) --no-print-directory install-$$t; \
		else \
			echo "$(RED)Unknown install target: $$t$(NC)"; \
			echo "Available targets: $(INSTALL_TARGETS)"; \
			exit 1; \
		fi \
	done

.PHONY: install-google-maps-scraper
install-google-maps-scraper:
	@echo "$(BOLD)Installing google-maps-scraper...$(NC)"
	npx skills add gosom/google-maps-scraper

# Absorb install target names passed as extra goals so Make does not error
# (e.g. `make install all` / `make install google-maps-scraper`). The real
# work is done by the `install` target above; these are no-ops.
.PHONY: all $(INSTALL_TARGETS)
all $(INSTALL_TARGETS):
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
