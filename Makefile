CONFIG_DIR := $(CURDIR)/config
PLUGIN_DIR := $(CURDIR)/plugins/core
TARGET_DIR := $(HOME)/.claude
BACKUP_DIR := $(HOME)/.claude-backups

GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
BLUE := \033[0;34m
NC := \033[0m
BOLD := \033[1m

DRY_RUN ?= 0
FORCE ?= 0
PRUNE ?=

DIFF_COLOR := $(shell diff --color=always /dev/null /dev/null > /dev/null 2>&1 && echo --color=always)

ifeq ($(DRY_RUN),1)
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
	@echo "Agents, skills and hooks ship as the core plugin and update themselves."
	@echo "These commands sync settings.json and CLAUDE.md into $(TARGET_DIR)."
	@echo ""
	@echo "$(BOLD)Usage:$(NC)"
	@echo "  make <command> [TARGET_DIR=<home>] [DRY_RUN=1] [FORCE=1]"
	@echo ""
	@echo "$(BOLD)Sync Commands$(NC):"
	@echo "  $(GREEN)update-config$(NC)    Run update-settings and update-claude-md"
	@echo "  $(GREEN)update-settings$(NC)  Merge the base settings.json with the home's own keys and overrides"
	@echo "  $(GREEN)update-claude-md$(NC) Copy CLAUDE.md"
	@echo "  $(GREEN)migrate$(NC)          Back up, then remove copies left by the old file sync"
	@echo ""
	@echo "$(BOLD)Utility Commands$(NC):"
	@echo "  $(BLUE)status$(NC)           Show whether the home matches the repo"
	@echo "  $(BLUE)diff$(NC)             Show what update-config would change"
	@echo "  $(BLUE)backup$(NC)           Create a timestamped backup of $(TARGET_DIR)"
	@echo "  $(BLUE)test$(NC)             Run the test suite in tests/"
	@echo ""
	@echo "$(BOLD)Options$(NC):"
	@echo "  DRY_RUN=1    Preview changes without writing"
	@echo "  FORCE=1      Skip confirmation prompts"
	@echo "  PRUNE=\"k ..\" Clear stale settings.json leaves under these top-level keys (never env)"
	@echo ""
	@echo "$(BOLD)Examples$(NC):"
	@echo "  make update-config                                  # Sync $(TARGET_DIR)"
	@echo "  make update-config TARGET_DIR=\$$HOME/.claude-personal # Sync a second home"
	@echo "  make migrate DRY_RUN=1                              # Preview the old copy cleanup"

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
	@mkdir -p "$(TARGET_DIR)"
endef

# ============================================================================
# SYNC COMMANDS
# ============================================================================

.PHONY: update-config
update-config: update-settings update-claude-md

.PHONY: update-settings
update-settings:
	@echo "$(BOLD)Updating settings.json...$(NC) $(DRY_RUN_MSG)"
	$(call ensure_target_dir)
	@DRY_RUN="$(DRY_RUN)" PRUNE="$(PRUNE)" bash scripts/apply-settings.sh "$(CONFIG_DIR)/settings.json" "$(TARGET_DIR)"

.PHONY: update-claude-md
update-claude-md:
	@echo "$(BOLD)Updating CLAUDE.md...$(NC) $(DRY_RUN_MSG)"
	$(call ensure_target_dir)
	@if [ ! -f "$(TARGET_DIR)/CLAUDE.md" ]; then \
		if [ "$(DRY_RUN)" = "1" ]; then \
			echo "Would add: CLAUDE.md"; \
		else \
			cp "$(CONFIG_DIR)/CLAUDE.md" "$(TARGET_DIR)/CLAUDE.md"; \
			echo "Added: CLAUDE.md"; \
		fi \
	elif ! diff -q "$(CONFIG_DIR)/CLAUDE.md" "$(TARGET_DIR)/CLAUDE.md" > /dev/null 2>&1; then \
		if [ "$(DRY_RUN)" = "1" ]; then \
			echo "Would update: CLAUDE.md"; \
		else \
			cp "$(CONFIG_DIR)/CLAUDE.md" "$(TARGET_DIR)/CLAUDE.md"; \
			echo "Updated: CLAUDE.md"; \
		fi \
	else \
		echo "Unchanged: CLAUDE.md"; \
	fi

.PHONY: migrate
migrate:
	$(call confirm,Back up $(TARGET_DIR) and remove its old copies of the plugin files?)
	@if [ "$(DRY_RUN)" != "1" ]; then $(MAKE) --no-print-directory backup TARGET_DIR="$(TARGET_DIR)"; fi
	@echo "$(BOLD)Removing old copies...$(NC) $(DRY_RUN_MSG)"
	@DRY_RUN="$(DRY_RUN)" bash scripts/migrate.sh "$(PLUGIN_DIR)" "$(TARGET_DIR)"

# ============================================================================
# UTILITY COMMANDS
# ============================================================================

.PHONY: status
status:
	@echo "$(BOLD)Sync Status: $(CURDIR) → $(TARGET_DIR)$(NC)"
	@echo ""
	@if [ ! -f "$(TARGET_DIR)/settings.json" ]; then \
		printf "  $(RED)●$(NC) settings.json $(RED)(missing)$(NC)\n"; \
	elif bash scripts/apply-settings.sh --check "$(CONFIG_DIR)/settings.json" "$(TARGET_DIR)"; then \
		printf "  $(GREEN)●$(NC) settings.json $(GREEN)(synced)$(NC)\n"; \
	else \
		printf "  $(YELLOW)●$(NC) settings.json $(YELLOW)(differs)$(NC)\n"; \
	fi
	@if [ ! -f "$(TARGET_DIR)/CLAUDE.md" ]; then \
		printf "  $(RED)●$(NC) CLAUDE.md $(RED)(missing)$(NC)\n"; \
	elif diff -q "$(CONFIG_DIR)/CLAUDE.md" "$(TARGET_DIR)/CLAUDE.md" > /dev/null 2>&1; then \
		printf "  $(GREEN)●$(NC) CLAUDE.md $(GREEN)(synced)$(NC)\n"; \
	else \
		printf "  $(YELLOW)●$(NC) CLAUDE.md $(YELLOW)(differs)$(NC)\n"; \
	fi
	@if DRY_RUN=1 bash scripts/migrate.sh "$(PLUGIN_DIR)" "$(TARGET_DIR)" | grep -q .; then \
		printf "  $(YELLOW)●$(NC) old copies of plugin files $(YELLOW)(run make migrate)$(NC)\n"; \
	fi
	@echo ""
	@echo "$(BOLD)Legend:$(NC) $(GREEN)●$(NC) synced  $(YELLOW)●$(NC) differs  $(RED)●$(NC) missing"

.PHONY: diff
diff:
	@echo "$(BOLD)Differences: $(TARGET_DIR) vs $(CURDIR)$(NC)"
	@echo "$(GREEN)+$(NC) lines are what update-config would add, $(RED)-$(NC) lines what it would remove"
	@echo ""
	@DRY_RUN=1 bash scripts/apply-settings.sh "$(CONFIG_DIR)/settings.json" "$(TARGET_DIR)"
	@if [ ! -f "$(TARGET_DIR)/CLAUDE.md" ]; then \
		printf "  $(GREEN)●$(NC) CLAUDE.md $(GREEN)(would add - not in $(TARGET_DIR))$(NC)\n"; \
	elif ! diff -q "$(CONFIG_DIR)/CLAUDE.md" "$(TARGET_DIR)/CLAUDE.md" > /dev/null 2>&1; then \
		echo "$(YELLOW)--- CLAUDE.md ---$(NC)"; \
		diff $(DIFF_COLOR) "$(TARGET_DIR)/CLAUDE.md" "$(CONFIG_DIR)/CLAUDE.md"; \
		echo ""; \
	fi

.PHONY: backup
backup:
	@echo "$(BOLD)Creating backup...$(NC)"
	@if [ -d "$(TARGET_DIR)" ]; then \
		mkdir -p "$(BACKUP_DIR)"; \
		timestamp=$$(date +%Y%m%d_%H%M%S); \
		backup_path="$(BACKUP_DIR)/claude_$$timestamp"; \
		if [ "$(DRY_RUN)" = "1" ]; then \
			echo "Would create backup at: $$backup_path"; \
		else \
			cp -RH "$(TARGET_DIR)" "$$backup_path" && \
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
