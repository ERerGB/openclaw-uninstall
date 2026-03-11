#!/usr/bin/env bash
# verify-clean.sh — Read-only check for OpenClaw residue. Safe for Agent to run.
# Does NOT delete anything.

set -e

STATE_DIR="${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"
FOUND=0

echo "=== OpenClaw 残留检查 (只读) ==="
echo ""

# 1. State directory
if [[ -d "$STATE_DIR" ]]; then
  echo "[残留] 状态目录: $STATE_DIR"
  FOUND=1
else
  echo "[通过] 状态目录已删除"
fi

# 2. Profile directories
PROFILE_FOUND=0
for d in "$HOME"/.openclaw-*; do
  [[ -d "$d" ]] || continue
  echo "[残留] Profile 目录: $d"
  FOUND=1
  PROFILE_FOUND=1
done
if (( ! PROFILE_FOUND )); then
  echo "[通过] 无 Profile 残留"
fi

# 3. macOS launchd
if [[ "$(uname -s)" == "Darwin" ]]; then
  if launchctl print "gui/$UID/ai.openclaw.gateway" &>/dev/null; then
    echo "[残留] launchd 服务: ai.openclaw.gateway"
    FOUND=1
  elif [[ -f "$HOME/Library/LaunchAgents/ai.openclaw.gateway.plist" ]]; then
    echo "[残留] launchd plist: ~/Library/LaunchAgents/ai.openclaw.gateway.plist"
    FOUND=1
  else
    echo "[通过] macOS launchd 已清理"
  fi
fi

# 4. Linux systemd
if [[ "$(uname -s)" == "Linux" ]]; then
  if systemctl --user is-active openclaw-gateway.service &>/dev/null || \
     [[ -f "$HOME/.config/systemd/user/openclaw-gateway.service" ]]; then
    echo "[残留] systemd 服务: openclaw-gateway.service"
    FOUND=1
  else
    echo "[通过] systemd 已清理"
  fi
fi

# 5. npm global
if command -v npm &>/dev/null && npm list -g openclaw --depth=0 &>/dev/null; then
  echo "[残留] npm 全局包: openclaw"
  FOUND=1
else
  echo "[通过] npm 全局包已移除"
fi

# 6. Processes (pgrep or ps fallback)
if command -v pgrep &>/dev/null; then
  if pgrep -f "openclaw" &>/dev/null; then
    echo "[残留] 运行中的 openclaw 进程"
    pgrep -af "openclaw" 2>/dev/null || true
    FOUND=1
  else
    echo "[通过] 无 openclaw 进程"
  fi
else
  if ps aux 2>/dev/null | grep -v grep | grep -q openclaw; then
    echo "[残留] 运行中的 openclaw 进程"
    ps aux 2>/dev/null | grep -v grep | grep openclaw || true
    FOUND=1
  else
    echo "[通过] 无 openclaw 进程"
  fi
fi

# 7. macOS app
if [[ "$(uname -s)" == "Darwin" ]] && [[ -d "/Applications/OpenClaw.app" ]]; then
  echo "[残留] macOS 应用: /Applications/OpenClaw.app"
  FOUND=1
elif [[ "$(uname -s)" == "Darwin" ]]; then
  echo "[通过] macOS 应用已删除"
fi

echo ""
if (( FOUND )); then
  echo "结论: 存在残留，请参考 SKILL.md 手动清理或执行 uninstall-oneshot.sh"
  exit 1
else
  echo "结论: 已彻底清理"
  exit 0
fi
