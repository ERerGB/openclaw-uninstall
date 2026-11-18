#!/usr/bin/env bash
# Historical entrypoint: runs offline contract fixtures, not a live uninstall E2E.
set -eu
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
exec python3 -m unittest discover -s "$script_dir" -p 'test_*.py' -v
