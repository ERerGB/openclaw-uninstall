#!/bin/bash
# install-personal.sh — Symlink repo to Cursor skills (SSOT: repo → personal index)
# Run from openclaw-uninstall repo. Creates ~/.cursor/skills/uninstaller → repo.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
CURSOR_SKILLS="${CURSOR_SKILLS:-$HOME/.cursor/skills}"
SKILL_LINK="$CURSOR_SKILLS/uninstaller"

mkdir -p "$CURSOR_SKILLS"
if [ -L "$SKILL_LINK" ]; then
  RESOLVED="$(cd "$SKILL_LINK" 2>/dev/null && pwd -P)" || RESOLVED=""
  if [ "$RESOLVED" = "$REPO_ROOT" ]; then
    echo "✅ Cursor skill already linked: $SKILL_LINK → $REPO_ROOT"
  else
    rm "$SKILL_LINK"
    ln -sf "$REPO_ROOT" "$SKILL_LINK"
    echo "✅ Updated Cursor skill symlink: $SKILL_LINK → $REPO_ROOT"
  fi
elif [ -e "$SKILL_LINK" ]; then
  BACKUP_PATH="${SKILL_LINK}.bak.$(date +%Y%m%d-%H%M%S).$$"
  if [[ -e "$BACKUP_PATH" || -L "$BACKUP_PATH" ]]; then
    echo "Backup destination already exists: $BACKUP_PATH" >&2
    exit 1
  fi
  echo "⚠️  $SKILL_LINK exists (not a symlink). Backing up to $BACKUP_PATH"
  mv "$SKILL_LINK" "$BACKUP_PATH"
  ln -sf "$REPO_ROOT" "$SKILL_LINK"
  echo "✅ Created Cursor skill symlink: $SKILL_LINK → $REPO_ROOT"
else
  ln -sf "$REPO_ROOT" "$SKILL_LINK"
  echo "✅ Created Cursor skill symlink: $SKILL_LINK → $REPO_ROOT"
fi
