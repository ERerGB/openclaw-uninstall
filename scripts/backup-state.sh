#!/usr/bin/env bash
# Back up the documented limited scope; never remove source state.
set -eu
umask 077
[[ $# -eq 2 ]] || { echo "Usage: backup-state.sh STATE_DIR BACKUP_DIR" >&2; exit 2; }
state_dir="$1"
backup_dir="$2"
[[ -d "$state_dir" && ! -e "$backup_dir" ]] || {
  echo "State must exist and backup destination must be new" >&2; exit 1;
}
mkdir -p "$backup_dir"
if command -v openclaw >/dev/null 2>&1; then
  if openclaw backup create --output "$backup_dir" --no-include-workspace >&2; then
    for archive in "$backup_dir"/*.tar.gz; do
      if [[ -s "$archive" ]]; then printf '%s\n' "$archive"; exit 0; fi
    done
    echo "Backup command succeeded but no nonempty archive was found" >&2
    exit 1
  fi
  echo "Native backup failed; trying the documented limited manual copy" >&2
fi
for item in skills sessions openclaw.json credentials; do
  if [[ -e "$state_dir/$item" || -L "$state_dir/$item" ]]; then
    cp -R "$state_dir/$item" "$backup_dir/" || {
      echo "Manual backup failed for $item; source is unchanged" >&2; exit 1;
    }
  fi
done
printf '%s\n' "$backup_dir"
