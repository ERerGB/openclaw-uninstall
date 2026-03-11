#!/bin/bash
# sync-copilot-skill.sh — Copy root SKILL.md to .github/skills/uninstaller for Copilot
# Run after editing SKILL.md to keep Copilot skill in sync.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$REPO_ROOT"

cp SKILL.md .github/skills/uninstaller/SKILL.md
echo "✅ Synced SKILL.md → .github/skills/uninstaller/SKILL.md"
