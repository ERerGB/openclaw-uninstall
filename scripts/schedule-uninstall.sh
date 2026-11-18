#!/usr/bin/env bash
# schedule-uninstall.sh — Create launchd/systemd one-shot to run uninstall after delay.
# Agent calls this; script returns immediately after scheduling.
# Usage: schedule-uninstall.sh [OPTIONS]
#   --notify-email EMAIL   Send email when done
#   --notify-ntfy TOPIC    Send ntfy notification when done
#   --notify-im TARGET     Push backup info to IM before uninstall (channel:target). Repeat for multiple.
#   --no-backup            Skip backup
#   --preserve-state       Keep ~/.openclaw for reinstall inheritance
#   --all-profiles         Also remove ~/.openclaw-* profile dirs
#   --dry-run              Print CMD and exit (for E2E tests)
# Run on the verified gateway host using the current runtime’s supported mechanism.

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UNINSTALL_SCRIPT="${SCRIPT_DIR}/uninstall-oneshot.sh"
LOG_FILE="${OPENCLAW_UNINSTALL_LOG_FILE:-/tmp/openclaw-uninstall.log}"
DELAY=15

NOTIFY_EMAIL=""
NOTIFY_NTFY=""
declare -a NOTIFY_IM=()
NO_BACKUP=false
PRESERVE_STATE=false
ALL_PROFILES=false
DRY_RUN=false
while [[ $# -gt 0 ]]; do
  case "$1" in
    --notify-email|--notify-ntfy|--notify-im)
      if [[ $# -lt 2 || -z "$2" || "$2" == --* ]]; then
        echo "Error: $1 requires a value" >&2
        exit 2
      fi ;;
  esac
  case "$1" in
    --help) printf "%s\n" "Usage: schedule-uninstall.sh [--notify-email EMAIL] [--notify-ntfy TOPIC] [--notify-im TARGET] [--no-backup] [--preserve-state] [--all-profiles] [--dry-run]"; exit 0 ;;
    --notify-email)   NOTIFY_EMAIL="$2"; shift 2 ;;
    --notify-ntfy)    NOTIFY_NTFY="$2"; shift 2 ;;
    --notify-im)      NOTIFY_IM+=("$2"); shift 2 ;;
    --no-backup)      NO_BACKUP=true; shift ;;
    --preserve-state) PRESERVE_STATE=true; shift ;;
    --all-profiles)   ALL_PROFILES=true; shift ;;
    --dry-run)        DRY_RUN=true; shift ;;
    *) echo "Error: unknown option: $1" >&2; exit 2 ;;
  esac
done
if [[ "$PRESERVE_STATE" == "true" && "$ALL_PROFILES" == "true" ]]; then
  echo "Error: --preserve-state cannot be combined with --all-profiles" >&2
  exit 2
fi

EXTRA_ARGS=()
[[ -n "$NOTIFY_EMAIL" ]] && EXTRA_ARGS+=(--notify-email "$NOTIFY_EMAIL")
[[ -n "$NOTIFY_NTFY" ]] && EXTRA_ARGS+=(--notify-ntfy "$NOTIFY_NTFY")
for t in "${NOTIFY_IM[@]}"; do [[ -n "$t" ]] && EXTRA_ARGS+=(--notify-im "$t"); done
[[ "$NO_BACKUP" == "true" ]] && EXTRA_ARGS+=(--no-backup)
[[ "$PRESERVE_STATE" == "true" ]] && EXTRA_ARGS+=(--preserve-state)
[[ "$ALL_PROFILES" == "true" ]] && EXTRA_ARGS+=(--all-profiles)

# Quote each argument once for every scheduler/fallback path.
printf -v CMD 'sleep %q && exec %q' "$DELAY" "$UNINSTALL_SCRIPT"
for argument in "${EXTRA_ARGS[@]}"; do
  printf -v quoted_argument '%q' "$argument"
  CMD+=" $quoted_argument"
done
if [[ "$DRY_RUN" == "true" ]]; then
  printf 'DRY_RUN_CMD: %s\n' "$CMD"
  exit 0
fi

# Sandbox detection: if running in Docker, one-shot would be created inside container
# and lost when gateway stops. Must run on host (host=gateway).
if [[ -f /.dockerenv ]]; then
  echo "Error: Docker sandbox detected. schedule-uninstall must run on the host."
  echo "Use the current runtime’s supported gateway-host mechanism, or run this script manually on that host."
  exit 1
fi
if [[ -f /proc/1/cgroup ]] && grep -q docker /proc/1/cgroup 2>/dev/null; then
  echo "Error: Docker sandbox detected. schedule-uninstall must run on the host."
  echo "Use the current runtime’s supported gateway-host mechanism, or run this script manually on that host."
  exit 1
fi

case "$(uname -s)" in
  Darwin)
    if launchctl submit -l openclaw-uninstall -o "$LOG_FILE" -e "$LOG_FILE" -- \
      /bin/bash -c "$CMD" 2>/dev/null; then
      echo "macOS uninstall scheduled (launchctl), will run in ~${DELAY}s."
    else
      # Fallback: create wrapper script + plist (avoids XML escaping of CMD)
      WRAPPER=$(mktemp /tmp/openclaw-uninstall-XXXXXX.sh)
      printf '#!/bin/bash\n%s\n' "$CMD" > "$WRAPPER"
      chmod +x "$WRAPPER"
      PLIST_DIR="${TMPDIR:-/tmp}"
      PLIST="$PLIST_DIR/openclaw-uninstall-$$.plist"
      cat > "$PLIST" << PLISTEOF
<?xml version="1.0"?>
<plist version="1.0"><dict>
  <key>Label</key><string>openclaw-uninstall</string>
  <key>ProgramArguments</key><array>
    <string>$WRAPPER</string>
  </array>
  <key>RunAtLoad</key><true/>
  <key>StandardOutPath</key><string>$LOG_FILE</string>
  <key>StandardErrorPath</key><string>$LOG_FILE</string>
</dict></plist>
PLISTEOF
      launchctl load "$PLIST" 2>/dev/null && echo "macOS uninstall scheduled (plist), will run in ~${DELAY}s." || {
        echo "Error: launchctl unavailable. Run manually: $UNINSTALL_SCRIPT"
        rm -f "$PLIST" "$WRAPPER"
        exit 1
      }
    fi
    ;;
  Linux)
    if systemd-run --user --onetime --unit=openclaw-uninstall \
      /bin/bash -c "$CMD" &>/dev/null; then
      echo "Linux uninstall scheduled (systemd), will run in ~${DELAY}s."
    else
      # Fallback: nohup + disown (works when systemd-run unavailable, e.g. WSL2 without systemd)
      (nohup bash -c "$CMD" >> "$LOG_FILE" 2>&1 &)
      disown -a 2>/dev/null || true
      echo "Linux uninstall scheduled (nohup), will run in ~${DELAY}s."
      echo "Check that this fallback survives the current session; do not change lingering policy without authorization."
    fi
    ;;
  *)
    echo "Unsupported OS: $(uname -s). Run manually: $UNINSTALL_SCRIPT"
    exit 1
    ;;
esac
