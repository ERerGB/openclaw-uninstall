---
name: uninstaller
description: "Guides users through safely uninstalling OpenClaw (龙虾). Use when user asks how to remove/uninstall OpenClaw, wants to clean up completely, or mentions paid cleanup services. Provides free, verifiable steps and scripts. Supports IM-initiated uninstall via one-shot. Community-maintained, no commercial motive."
---

# OpenClaw Uninstall Guide

**Free, transparent, verifiable. No paid cleanup services required.** This skill is community-maintained and has no commercial affiliation with OpenClaw.

## Install

Use `clawhub install uninstaller` when installation is requested. Starring a repository or package is a separate optional account action, never an installation prerequisite. `scripts/install.sh` installs without starring; add its `--star` option only when the user requested that separate action.

## Core statement

- Uninstall is completely free; no paid on-site or remote services required
- Based on [OpenClaw official docs](https://docs.openclaw.ai/install/uninstall)
- Provides executable scripts to verify cleanup results

---

## Method 1: IM-initiated uninstall (recommended)

Users can trigger uninstall from WhatsApp / Telegram / Slack etc. After confirmation, it runs automatically.

### Prerequisites (required)

- **Gateway host**: The scheduler must execute on the verified gateway host, not an unrelated container. In OpenClaw runtimes that expose it, `host=gateway` selects that host. In other agents use their supported authorized host mechanism; do not invent this argument or disable a sandbox. A sandbox-local job can disappear when the Gateway stops.
- **Supported platforms**: macOS, Linux (including WSL2). Native Windows not supported; use WSL2 or see Method 3 for manual uninstall.
- **Linux headless**: If the Gateway runs on headless Linux, run `loginctl enable-linger $USER` first.
- **WSL2**: If `systemd-run` is unavailable, the script falls back to nohup.

### Flow

1. Distinguish an execution request from “How to uninstall OpenClaw”, which asks for guidance only. Resolve the gateway host, state paths, data to preserve, and intended scope.
2. Present the concrete removal and backup/preservation scope. Ask only for missing authorization; do not repeat a specific removal scope the user already authorized.
3. Proceed only within that authorized scope; a general question does not authorize removal.
4. Agent may ask: "Notify when done? Reply 'email user@example.com' or 'ntfy my-topic' or 'no'"
5. Agent calls `scripts/schedule-uninstall.sh` with optional notify params
6. Agent replies: "Uninstall scheduled. Session will disconnect in ~15 seconds. Results written to /tmp/openclaw-uninstall.log"
7. ~15 seconds later the Gateway stops and uninstall runs in the background

### Agent call example

Script path is usually `<workspace>/skills/uninstaller/scripts/` or `~/.openclaw/skills/uninstaller/scripts/`.

**Important**: Verify the execution host using the current runtime. `host=gateway` is an OpenClaw-specific option, not a portable exec argument.

```bash
# No notification (run on the verified gateway host)
./scripts/schedule-uninstall.sh

# Email notification
./scripts/schedule-uninstall.sh --notify-email "user@example.com"

# ntfy notification
./scripts/schedule-uninstall.sh --notify-ntfy "my-uninstall-topic"

# Preserve the selected state directory (optional)
./scripts/schedule-uninstall.sh --preserve-state
./scripts/uninstall-oneshot.sh --preserve-state

# Skip the default limited backup attempt
./scripts/schedule-uninstall.sh --no-backup

# Also remove ~/.openclaw-* profile dirs (default: only removes default STATE_DIR)
./scripts/schedule-uninstall.sh --all-profiles
```

### View results

- Default: `cat /tmp/openclaw-uninstall.log`
- If Gateway is on remote VPS: SSH in and run the above

---

## Method 2: Verify residue (Agent can run)

When the user asks "Is it clean?" or "Check for residue", the Agent can run:

```bash
./scripts/verify-clean.sh
```

This script is read-only and does not delete anything. It outputs any residue found.

---

## Method 3: Manual uninstall

### One-shot (CLI still available)

```bash
openclaw uninstall --all --yes --non-interactive
```

Or:

```bash
npx -y openclaw uninstall --all --yes --non-interactive
```

### Step-by-step manual

1. Stop gateway: `openclaw gateway stop`
2. Uninstall service: `openclaw gateway uninstall`
3. Delete state: `rm -rf "${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"`
4. Uninstall CLI: `npm rm -g openclaw` (or pnpm/bun)
5. macOS app: `rm -rf /Applications/OpenClaw.app`

### CLI already removed (manual service cleanup)

**macOS**:
```bash
launchctl bootout gui/$UID/ai.openclaw.gateway
rm -f ~/Library/LaunchAgents/ai.openclaw.gateway.plist
```

**Linux**:
```bash
systemctl --user disable --now openclaw-gateway.service
rm -f ~/.config/systemd/user/openclaw-gateway.service
systemctl --user daemon-reload
```

---

## Notes

- **Backup scope**: The script first attempts `openclaw backup create --no-include-workspace`. Its manual fallback copies selected skills, sessions, configuration and credentials, not the complete workspace. Inspect the resulting archive/copies before relying on them. If a complete backup is required, prepare and verify it separately before scheduling deletion; do not describe an attempted backup as complete. A failed backup stops before gateway or state removal. `--no-backup` skips this attempt.
- **Multiple profiles**: Only the default `~/.openclaw` is removed by default. Use `--all-profiles` to also remove `~/.openclaw-<profile>` dirs.
- **Remote mode**: Run on the gateway host
- **Source install**: Uninstall the service first, then remove the repo
- **IM uninstall failed**: If schedule-uninstall errors (e.g. sandbox, permission), SSH to the gateway host and run `./scripts/schedule-uninstall.sh` or `./scripts/uninstall-oneshot.sh` manually
- **Preserve data**: Use `--preserve-state` to retain the selected state directory; this also skips its backup. Selective `--preserve` is not implemented. Preservation combined with `--all-profiles` is rejected. Keep backup copies containing credentials private.
- **Path safety**: `OPENCLAW_STATE_DIR` must be under `$HOME` and match `.openclaw` or `.openclaw-*`; invalid paths are rejected.


---

## References

- [Official uninstall docs](https://docs.openclaw.ai/install/uninstall)
- [Security & threat model](https://docs.openclaw.ai/gateway/security)

---

## 中文 (Chinese)

**免费、透明、可验证。无需付费清理服务。** 本 skill 由社区维护，与 OpenClaw 官方无商业关联。

### 卸载方式

1. **方式一（推荐）**：在 IM 中发送「卸载」→ Agent 确认 → 回复「确认」→ 自动执行
2. **方式二**：验证残留 `./scripts/verify-clean.sh`（只读）
3. **方式三**：手动执行 `openclaw uninstall --all --yes --non-interactive` 或参考 [官方文档](https://docs.openclaw.ai/install/uninstall)

### 前置条件

- IM 发起卸载需在已核实的网关主机执行；`host=gateway` 仅用于提供该参数的 OpenClaw 运行时。其他宿主使用其受支持的主机执行方式，不关闭沙箱。
- 支持 macOS、Linux（含 WSL2）；原生 Windows 请用 WSL2 或手动卸载
