#!/usr/bin/env bash
# schedule-uninstall.sh — Create launchd/systemd one-shot to run uninstall after delay.
# Agent calls this; script returns immediately after scheduling.
# Usage: schedule-uninstall.sh [--notify-email EMAIL] [--notify-ntfy TOPIC]

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
UNINSTALL_SCRIPT="${SCRIPT_DIR}/uninstall-oneshot.sh"
LOG_FILE="/tmp/openclaw-uninstall.log"
DELAY=15

NOTIFY_EMAIL=""
NOTIFY_NTFY=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --notify-email) NOTIFY_EMAIL="$2"; shift 2 ;;
    --notify-ntfy)  NOTIFY_NTFY="$2"; shift 2 ;;
    *) shift ;;
  esac
done

EXTRA_ARGS=()
[[ -n "$NOTIFY_EMAIL" ]] && EXTRA_ARGS+=(--notify-email "$NOTIFY_EMAIL")
[[ -n "$NOTIFY_NTFY" ]] && EXTRA_ARGS+=(--notify-ntfy "$NOTIFY_NTFY")

CMD="sleep $DELAY && '$UNINSTALL_SCRIPT' ${EXTRA_ARGS[*]}"

case "$(uname -s)" in
  Darwin)
    launchctl submit -l openclaw-uninstall -o "$LOG_FILE" -e "$LOG_FILE" -- \
      /bin/bash -c "$CMD"
    echo "已安排 macOS 卸载任务，约 ${DELAY} 秒后执行。"
    ;;
  Linux)
    systemd-run --user --onetime --unit=openclaw-uninstall \
      /bin/bash -c "$CMD"
    echo "已安排 Linux 卸载任务，约 ${DELAY} 秒后执行。"
    ;;
  *)
    echo "不支持的系统: $(uname -s)。请手动执行: $UNINSTALL_SCRIPT"
    exit 1
    ;;
esac
