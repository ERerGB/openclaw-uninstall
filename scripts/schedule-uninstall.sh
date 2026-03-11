#!/usr/bin/env bash
# schedule-uninstall.sh — Create launchd/systemd one-shot to run uninstall after delay.
# Agent calls this; script returns immediately after scheduling.
# Usage: schedule-uninstall.sh [--notify-email EMAIL] [--notify-ntfy TOPIC]
# Requires: host=gateway (must run on host, not in sandbox)

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

# Sandbox detection: if running in Docker, one-shot would be created inside container
# and lost when gateway stops. Must run on host (host=gateway).
if [[ -f /.dockerenv ]]; then
  echo "错误: 检测到 Docker 沙盒环境。schedule-uninstall 必须在宿主机执行。"
  echo "请确保 Agent 调用 exec 时使用 host=gateway，或手动在宿主机执行此脚本。"
  exit 1
fi
if [[ -f /proc/1/cgroup ]] && grep -q docker /proc/1/cgroup 2>/dev/null; then
  echo "错误: 检测到 Docker 沙盒环境。schedule-uninstall 必须在宿主机执行。"
  echo "请确保 Agent 调用 exec 时使用 host=gateway，或手动在宿主机执行此脚本。"
  exit 1
fi

# Build command string for one-shot
ARG_STR=""
for a in "${EXTRA_ARGS[@]}"; do
  ARG_STR="$ARG_STR '$a'"
done
CMD="sleep $DELAY && '$UNINSTALL_SCRIPT' $ARG_STR"

case "$(uname -s)" in
  Darwin)
    if launchctl submit -l openclaw-uninstall -o "$LOG_FILE" -e "$LOG_FILE" -- \
      /bin/bash -c "$CMD" 2>/dev/null; then
      echo "已安排 macOS 卸载任务 (launchctl)，约 ${DELAY} 秒后执行。"
    else
      # Fallback: create wrapper script + plist (avoids XML escaping of CMD)
      WRAPPER=$(mktemp /tmp/openclaw-uninstall-XXXXXX.sh)
      EXEC_LINE="exec '$UNINSTALL_SCRIPT'"
      for a in "${EXTRA_ARGS[@]}"; do
        safe=$(printf '%s' "$a" | sed "s/'/'\\\\''/g")
        EXEC_LINE="$EXEC_LINE '$safe'"
      done
      cat > "$WRAPPER" << WRAPEOF
#!/bin/bash
sleep $DELAY
$EXEC_LINE
WRAPEOF
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
      launchctl load "$PLIST" 2>/dev/null && echo "已安排 macOS 卸载任务 (plist)，约 ${DELAY} 秒后执行。" || {
        echo "错误: launchctl 不可用。请手动执行: $UNINSTALL_SCRIPT"
        rm -f "$PLIST" "$WRAPPER"
        exit 1
      }
    fi
    ;;
  Linux)
    if systemd-run --user --onetime --unit=openclaw-uninstall \
      /bin/bash -c "$CMD" &>/dev/null; then
      echo "已安排 Linux 卸载任务 (systemd)，约 ${DELAY} 秒后执行。"
    else
      # Fallback: nohup + disown (works when systemd-run unavailable, e.g. WSL2 without systemd)
      (nohup bash -c "$CMD" >> "$LOG_FILE" 2>&1 &)
      disown -a 2>/dev/null || true
      echo "已安排 Linux 卸载任务 (nohup)，约 ${DELAY} 秒后执行。"
      echo "若 systemd 未启用，请确保已执行: loginctl enable-linger \$USER"
    fi
    ;;
  *)
    echo "不支持的系统: $(uname -s)。请手动执行: $UNINSTALL_SCRIPT"
    exit 1
    ;;
esac
