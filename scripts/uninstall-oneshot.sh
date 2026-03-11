#!/usr/bin/env bash
# uninstall-oneshot.sh — Full OpenClaw uninstall. Run by one-shot or manually.
# Usage: uninstall-oneshot.sh [--notify-email EMAIL] [--notify-ntfy TOPIC]

set -e

LOG_FILE="/tmp/openclaw-uninstall.log"
NOTIFY_EMAIL=""
NOTIFY_NTFY=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --notify-email) NOTIFY_EMAIL="$2"; shift 2 ;;
    --notify-ntfy)  NOTIFY_NTFY="$2"; shift 2 ;;
    *) shift ;;
  esac
done

log() { echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*" | tee -a "$LOG_FILE"; }

log "=== OpenClaw 卸载开始 ==="

# 1. Stop gateway (if CLI available)
if command -v openclaw &>/dev/null; then
  log "停止 Gateway..."
  openclaw gateway stop 2>/dev/null || true
  log "卸载 Gateway 服务..."
  openclaw gateway uninstall 2>/dev/null || true
fi

# 2. Manual service removal (if CLI gone or as backup)
case "$(uname -s)" in
  Darwin)
    launchctl bootout "gui/$UID/ai.openclaw.gateway" 2>/dev/null || true
    rm -f ~/Library/LaunchAgents/ai.openclaw.gateway.plist
    for f in ~/Library/LaunchAgents/com.openclaw.*.plist; do
      [[ -f "$f" ]] && rm -f "$f"
    done
    ;;
  Linux)
    systemctl --user disable --now openclaw-gateway.service 2>/dev/null || true
    rm -f ~/.config/systemd/user/openclaw-gateway.service
    systemctl --user daemon-reload 2>/dev/null || true
    ;;
esac

# 3. Delete state dir
STATE_DIR="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
if [[ -d "$STATE_DIR" ]]; then
  log "删除状态目录: $STATE_DIR"
  rm -rf "$STATE_DIR"
fi

# 4. Delete profile dirs
for d in "$HOME"/.openclaw-*; do
  [[ -d "$d" ]] || continue
  log "删除 Profile 目录: $d"
  rm -rf "$d"
done

# 5. Remove CLI
for pm in npm pnpm bun; do
  if command -v "$pm" &>/dev/null; then
    if "$pm" list -g openclaw --depth=0 &>/dev/null 2>&1; then
      log "卸载 npm 包: $pm remove -g openclaw"
      "$pm" remove -g openclaw 2>/dev/null || true
      break
    fi
  fi
done

# 6. macOS app
if [[ "$(uname -s)" == "Darwin" ]] && [[ -d "/Applications/OpenClaw.app" ]]; then
  log "删除 macOS 应用"
  rm -rf /Applications/OpenClaw.app
fi

log "=== 卸载完成 ==="

# Notify
if [[ -n "$NOTIFY_EMAIL" ]]; then
  if command -v mail &>/dev/null; then
    echo "OpenClaw 已卸载。详情: $LOG_FILE" | mail -s "OpenClaw Uninstall Complete" "$NOTIFY_EMAIL" 2>/dev/null || log "邮件发送失败 (mail 不可用)"
  else
    log "邮件通知跳过 (mail 命令不可用)"
  fi
fi

if [[ -n "$NOTIFY_NTFY" ]]; then
  if command -v curl &>/dev/null; then
    curl -s -d "OpenClaw 已卸载" "https://ntfy.sh/$NOTIFY_NTFY" &>/dev/null || log "ntfy 发送失败"
  else
    log "ntfy 通知跳过 (curl 不可用)"
  fi
fi
