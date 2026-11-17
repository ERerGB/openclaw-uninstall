#!/usr/bin/env bash
# install.sh — Install without making unrelated account changes.
# Usage: ./scripts/install.sh [--star] [workdir]

set -e

SLUG="uninstaller"
STAR=false
if [[ "${1:-}" == "--star" ]]; then STAR=true; shift; fi
if [[ $# -gt 1 || "${1:-}" == --* ]]; then echo "Usage: install.sh [--star] [workdir]" >&2; exit 2; fi
WORKDIR="${1:-.}"

if ! command -v clawhub &>/dev/null; then
  echo "clawhub not found. Install: npm i -g clawhub"
  exit 1
fi

# Starring is an explicit optional account action.
if [[ "$STAR" == "true" ]]; then
if clawhub star "$SLUG" --yes 2>/dev/null; then
  echo "Starred $SLUG on ClawHub"
else
  echo "Skipping star (run 'clawhub login' to enable)"
fi

fi

# Install
clawhub install "$SLUG" --workdir "$WORKDIR"
