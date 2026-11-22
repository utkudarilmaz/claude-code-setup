REPO_DIR := $(shell pwd)/.claude
TARGET_DIR := $(HOME)/.claude
BACKUP_DIR := $(HOME)/.claude-backups

GREEN := \033[0;32m
YELLOW := \033[0;33m
RED := \033[0;31m
BLUE := \033[0;34m
NC := \033[0m  # No Color
BOLD := \033[1m

DRY_RUN ?= 0
FORCE ?= 0
PRUNE ?=

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
	@echo "  $(GREEN)update-config$(NC)    Run update-settings and update-claude-md"
	@echo "  $(GREEN)update-settings$(NC)  Update settings.json only (merged)"
	@echo "  $(GREEN)update-claude-md$(NC) Update CLAUDE.md only"
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
	@echo "  PRUNE=\"k ..\" With update-settings, clear stale leaves under these top-level keys (never env)"
	@echo ""
	@echo "$(BOLD)Examples$(NC):"
	@echo "  make update-all              # Update files in $(TARGET_DIR)"
	@echo "  make DRY_RUN=1 rm-agents     # Preview agent removal"
	@echo "  make FORCE=1 rm-skills       # Remove skills without confirmation"

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
update-config: update-settings update-claude-md

.PHONY: update-settings
update-settings:
	@echo "$(BOLD)Updating settings.json...$(NC) $(DRY_RUN_MSG)"
	$(call ensure_target_dir)
	@DRY_RUN="$(DRY_RUN)" PRUNE="$(PRUNE)" bash scripts/apply-settings.sh "$(REPO_DIR)/settings.json" "$(TARGET_DIR)"

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
	@if [ ! -f $(TARGET_DIR)/settings.json ]; then \
		printf "  $(RED)●$(NC) settings.json $(RED)(missing)$(NC)\n"; \
	elif bash scripts/apply-settings.sh --check $(REPO_DIR)/settings.json $(TARGET_DIR); then \
		printf "  $(GREEN)●$(NC) settings.json $(GREEN)(synced)$(NC)\n"; \
	else \
		printf "  $(YELLOW)●$(NC) settings.json $(YELLOW)(differs)$(NC)\n"; \
	fi
	@if [ ! -f $(TARGET_DIR)/CLAUDE.md ]; then \
		printf "  $(RED)●$(NC) CLAUDE.md $(RED)(missing)$(NC)\n"; \
	elif diff -q $(REPO_DIR)/CLAUDE.md $(TARGET_DIR)/CLAUDE.md > /dev/null 2>&1; then \
		printf "  $(GREEN)●$(NC) CLAUDE.md $(GREEN)(synced)$(NC)\n"; \
	else \
		printf "  $(YELLOW)●$(NC) CLAUDE.md $(YELLOW)(differs)$(NC)\n"; \
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
	@DRY_RUN=1 bash scripts/apply-settings.sh $(REPO_DIR)/settings.json $(TARGET_DIR)
	@if [ ! -f $(TARGET_DIR)/CLAUDE.md ]; then \
		printf "  $(GREEN)●$(NC) CLAUDE.md $(GREEN)(would add - not in $(TARGET_DIR))$(NC)\n"; \
	elif ! diff -q $(REPO_DIR)/CLAUDE.md $(TARGET_DIR)/CLAUDE.md > /dev/null 2>&1; then \
		echo "$(YELLOW)--- CLAUDE.md ---$(NC)"; \
		diff $(DIFF_COLOR) $(TARGET_DIR)/CLAUDE.md $(REPO_DIR)/CLAUDE.md; \
		echo ""; \
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
