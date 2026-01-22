# Makefile for Claude Code Configuration Sync
# Manages synchronization between repo's .claude/ and ~/.claude

# Configuration
REPO_DIR := $(shell pwd)/.claude
TARGET_DIR := $(HOME)/.claude
BACKUP_DIR := $(HOME)/.claude-backups

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

# Check for rsync availability
RSYNC := $(shell command -v rsync 2>/dev/null)

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
	@echo "  $(GREEN)update-all$(NC)       Update agents, skills, and config files"
	@echo "  $(GREEN)update-agents$(NC)    Update .claude/agents/ only"
	@echo "  $(GREEN)update-skills$(NC)    Update .claude/skills/ only"
	@echo "  $(GREEN)update-config$(NC)    Update settings.json and CLAUDE.md"
	@echo ""
	@echo "$(BOLD)Remove Commands$(NC) (remove repo files from ~/.claude):"
	@echo "  $(RED)rm-agents$(NC)      Remove matching agents"
	@echo "  $(RED)rm-skills$(NC)      Remove matching skills"
	@echo ""
	@echo "$(BOLD)Utility Commands$(NC):"
	@echo "  $(BLUE)status$(NC)         Show sync status with colored indicators"
	@echo "  $(BLUE)diff$(NC)           Show file differences between repo and ~/.claude"
	@echo "  $(BLUE)backup$(NC)         Create timestamped backup of ~/.claude"
	@echo ""
	@echo "$(BOLD)Options$(NC):"
	@echo "  DRY_RUN=1    Preview changes without executing"
	@echo "  FORCE=1      Skip confirmation prompts"
	@echo ""
	@echo "$(BOLD)Examples$(NC):"
	@echo "  make update-all              # Update files in ~/.claude"
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

# ============================================================================
# UPDATE COMMANDS (add missing + update changed, keep extras)
# ============================================================================

.PHONY: update-all
update-all: update-agents update-skills update-config
	@echo ""
	@echo "$(GREEN)Update complete!$(NC) $(DRY_RUN_MSG)"

.PHONY: update-agents
update-agents:
	@echo "$(BOLD)Updating agents...$(NC) $(DRY_RUN_MSG)"
	$(call ensure_target_dir)
	@mkdir -p $(TARGET_DIR)/agents
ifdef RSYNC
	@rsync $(RSYNC_OPTS) $(REPO_DIR)/agents/ $(TARGET_DIR)/agents/
else
	@for f in $(REPO_DIR)/agents/*; do \
		filename=$$(basename "$$f"); \
		target="$(TARGET_DIR)/agents/$$filename"; \
		if [ ! -e "$$target" ]; then \
			if [ "$(DRY_RUN)" = "1" ]; then \
				echo "Would add: agents/$$filename"; \
			else \
				cp -r "$$f" "$$target"; \
				echo "Added: agents/$$filename"; \
			fi \
		elif ! diff -q "$$f" "$$target" > /dev/null 2>&1; then \
			if [ "$(DRY_RUN)" = "1" ]; then \
				echo "Would update: agents/$$filename"; \
			else \
				cp -r "$$f" "$$target"; \
				echo "Updated: agents/$$filename"; \
			fi \
		else \
			echo "Unchanged: agents/$$filename"; \
		fi \
	done
endif

.PHONY: update-skills
update-skills:
	@echo "$(BOLD)Updating skills...$(NC) $(DRY_RUN_MSG)"
	$(call ensure_target_dir)
	@mkdir -p $(TARGET_DIR)/skills
ifdef RSYNC
	@rsync $(RSYNC_OPTS) $(REPO_DIR)/skills/ $(TARGET_DIR)/skills/
else
	@for f in $(REPO_DIR)/skills/*; do \
		filename=$$(basename "$$f"); \
		target="$(TARGET_DIR)/skills/$$filename"; \
		if [ ! -e "$$target" ]; then \
			if [ "$(DRY_RUN)" = "1" ]; then \
				echo "Would add: skills/$$filename"; \
			else \
				cp -r "$$f" "$$target"; \
				chmod -R +x "$$target"/*.sh 2>/dev/null || true; \
				echo "Added: skills/$$filename"; \
			fi \
		elif ! diff -rq "$$f" "$$target" > /dev/null 2>&1; then \
			if [ "$(DRY_RUN)" = "1" ]; then \
				echo "Would update: skills/$$filename"; \
			else \
				rm -rf "$$target"; \
				cp -r "$$f" "$$target"; \
				chmod -R +x "$$target"/*.sh 2>/dev/null || true; \
				echo "Updated: skills/$$filename"; \
			fi \
		else \
			echo "Unchanged: skills/$$filename"; \
		fi \
	done
endif

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
	elif ! diff -q $(REPO_DIR)/settings.json $(TARGET_DIR)/settings.json > /dev/null 2>&1; then \
		if [ "$(DRY_RUN)" = "1" ]; then \
			echo "Would update: settings.json"; \
		else \
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

# ============================================================================
# REMOVE COMMANDS (remove repo files from ~/.claude)
# ============================================================================

.PHONY: rm-agents
rm-agents:
	$(call confirm,This will remove matching agents from ~/.claude. Continue?)
	@echo "$(BOLD)Removing agents...$(NC) $(DRY_RUN_MSG)"
	@if [ -d $(REPO_DIR)/agents ]; then \
		for f in $(REPO_DIR)/agents/*; do \
			filename=$$(basename "$$f"); \
			target="$(TARGET_DIR)/agents/$$filename"; \
			if [ -e "$$target" ]; then \
				if [ "$(DRY_RUN)" = "1" ]; then \
					echo "Would remove: agents/$$filename"; \
				else \
					rm -rf "$$target"; \
					echo "Removed: agents/$$filename"; \
				fi \
			fi \
		done \
	fi
	$(call cleanup_empty_dirs)

.PHONY: rm-skills
rm-skills:
	$(call confirm,This will remove matching skills from ~/.claude. Continue?)
	@echo "$(BOLD)Removing skills...$(NC) $(DRY_RUN_MSG)"
	@if [ -d $(REPO_DIR)/skills ]; then \
		for f in $(REPO_DIR)/skills/*; do \
			filename=$$(basename "$$f"); \
			target="$(TARGET_DIR)/skills/$$filename"; \
			if [ -e "$$target" ]; then \
				if [ "$(DRY_RUN)" = "1" ]; then \
					echo "Would remove: skills/$$filename"; \
				else \
					rm -rf "$$target"; \
					echo "Removed: skills/$$filename"; \
				fi \
			fi \
		done \
	fi
	$(call cleanup_empty_dirs)

# ============================================================================
# UTILITY COMMANDS
# ============================================================================

.PHONY: status
status:
	@echo "$(BOLD)Sync Status: $(REPO_DIR) → $(TARGET_DIR)$(NC)"
	@echo ""
	@echo "$(BOLD)Agents:$(NC)"
	@if [ -d $(REPO_DIR)/agents ]; then \
		for f in $(REPO_DIR)/agents/*; do \
			filename=$$(basename "$$f"); \
			target="$(TARGET_DIR)/agents/$$filename"; \
			if [ ! -e "$$target" ]; then \
				printf "  $(RED)●$(NC) $$filename $(RED)(missing)$(NC)\n"; \
			elif diff -q "$$f" "$$target" > /dev/null 2>&1; then \
				printf "  $(GREEN)●$(NC) $$filename $(GREEN)(synced)$(NC)\n"; \
			else \
				printf "  $(YELLOW)●$(NC) $$filename $(YELLOW)(differs)$(NC)\n"; \
			fi \
		done \
	fi
	@if [ -d $(TARGET_DIR)/agents ]; then \
		for f in $(TARGET_DIR)/agents/*; do \
			filename=$$(basename "$$f"); \
			source="$(REPO_DIR)/agents/$$filename"; \
			if [ ! -e "$$source" ]; then \
				printf "  $(BLUE)●$(NC) $$filename $(BLUE)(extra - not in repo)$(NC)\n"; \
			fi \
		done \
	fi
	@echo ""
	@echo "$(BOLD)Skills:$(NC)"
	@if [ -d $(REPO_DIR)/skills ]; then \
		for f in $(REPO_DIR)/skills/*; do \
			filename=$$(basename "$$f"); \
			target="$(TARGET_DIR)/skills/$$filename"; \
			if [ ! -e "$$target" ]; then \
				printf "  $(RED)●$(NC) $$filename $(RED)(missing)$(NC)\n"; \
			elif diff -rq "$$f" "$$target" > /dev/null 2>&1; then \
				printf "  $(GREEN)●$(NC) $$filename $(GREEN)(synced)$(NC)\n"; \
			else \
				printf "  $(YELLOW)●$(NC) $$filename $(YELLOW)(differs)$(NC)\n"; \
			fi \
		done \
	fi
	@if [ -d $(TARGET_DIR)/skills ]; then \
		for f in $(TARGET_DIR)/skills/*; do \
			filename=$$(basename "$$f"); \
			source="$(REPO_DIR)/skills/$$filename"; \
			if [ ! -e "$$source" ]; then \
				printf "  $(BLUE)●$(NC) $$filename $(BLUE)(extra - not in repo)$(NC)\n"; \
			fi \
		done \
	fi
	@echo ""
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
	@echo "$(BOLD)Legend:$(NC) $(GREEN)●$(NC) synced  $(YELLOW)●$(NC) differs  $(RED)●$(NC) missing  $(BLUE)●$(NC) extra"

.PHONY: diff
diff:
	@echo "$(BOLD)Differences: $(REPO_DIR) vs $(TARGET_DIR)$(NC)"
	@echo ""
	@echo "$(BOLD)Agents:$(NC)"
	@if [ -d $(REPO_DIR)/agents ]; then \
		for f in $(REPO_DIR)/agents/*; do \
			filename=$$(basename "$$f"); \
			target="$(TARGET_DIR)/agents/$$filename"; \
			if [ ! -e "$$target" ]; then \
				printf "  $(GREEN)●$(NC) $$filename $(GREEN)(would add - not in ~/.claude)$(NC)\n"; \
			elif ! diff -q "$$f" "$$target" > /dev/null 2>&1; then \
				echo "$(YELLOW)--- $$filename ---$(NC)"; \
				diff --color=always "$$f" "$$target" 2>/dev/null || diff "$$f" "$$target"; \
				echo ""; \
			fi \
		done \
	fi
	@if [ -d $(TARGET_DIR)/agents ]; then \
		for f in $(TARGET_DIR)/agents/*; do \
			filename=$$(basename "$$f"); \
			source="$(REPO_DIR)/agents/$$filename"; \
			if [ ! -e "$$source" ]; then \
				printf "  $(BLUE)●$(NC) $$filename $(BLUE)(extra - not in repo)$(NC)\n"; \
			fi \
		done \
	fi
	@echo ""
	@echo "$(BOLD)Skills:$(NC)"
	@if [ -d $(REPO_DIR)/skills ]; then \
		for f in $(REPO_DIR)/skills/*; do \
			filename=$$(basename "$$f"); \
			target="$(TARGET_DIR)/skills/$$filename"; \
			if [ ! -e "$$target" ]; then \
				printf "  $(GREEN)●$(NC) $$filename $(GREEN)(would add - not in ~/.claude)$(NC)\n"; \
			elif [ -d "$$f" ]; then \
				if ! diff -rq "$$f" "$$target" > /dev/null 2>&1; then \
					echo "$(YELLOW)--- $$filename ---$(NC)"; \
					diff -r --color=always "$$f" "$$target" 2>/dev/null || diff -r "$$f" "$$target"; \
					echo ""; \
				fi \
			fi \
		done \
	fi
	@if [ -d $(TARGET_DIR)/skills ]; then \
		for f in $(TARGET_DIR)/skills/*; do \
			filename=$$(basename "$$f"); \
			source="$(REPO_DIR)/skills/$$filename"; \
			if [ ! -e "$$source" ]; then \
				printf "  $(BLUE)●$(NC) $$filename $(BLUE)(extra - not in repo)$(NC)\n"; \
			fi \
		done \
	fi
	@echo ""
	@echo "$(BOLD)Config Files:$(NC)"
	@for f in settings.json CLAUDE.md; do \
		if [ ! -f $(TARGET_DIR)/$$f ]; then \
			printf "  $(GREEN)●$(NC) $$f $(GREEN)(would add - not in ~/.claude)$(NC)\n"; \
		elif ! diff -q $(REPO_DIR)/$$f $(TARGET_DIR)/$$f > /dev/null 2>&1; then \
			echo "$(YELLOW)--- $$f ---$(NC)"; \
			diff --color=always $(REPO_DIR)/$$f $(TARGET_DIR)/$$f 2>/dev/null || diff $(REPO_DIR)/$$f $(TARGET_DIR)/$$f; \
			echo ""; \
		fi \
	done

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
		echo "$(YELLOW)No ~/.claude directory to backup$(NC)"; \
	fi
