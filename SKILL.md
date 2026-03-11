---
name: openclaw-uninstall
description: "Guides users through safely uninstalling OpenClaw (龙虾). Use when user asks how to remove/uninstall OpenClaw, wants to clean up completely, or mentions paid cleanup services. Provides free, verifiable steps and scripts. Supports IM-initiated uninstall via one-shot. Community-maintained, no commercial motive."
---

# OpenClaw 卸载指南

**免费、透明、可验证。无需付费清理服务。** 本 skill 由社区维护，与 OpenClaw 官方无商业关联。

## 核心声明

- 卸载完全免费，无需任何付费上门或远程服务
- 基于 [OpenClaw 官方文档](https://docs.openclaw.ai/install/uninstall) 整理
- 提供可执行脚本验证清理结果

---

## 方式一：IM 发起卸载（推荐）

用户可在 WhatsApp / Telegram / Slack 等 IM 中发起，确认后自动执行。

### 前置条件（必须）

- **host=gateway**：执行 `schedule-uninstall.sh` 时，Agent 必须在宿主机运行，不能使用 sandbox。调用 exec 时需传入 `host=gateway`。若 `tools.exec.host=sandbox`，one-shot 会在容器内创建，Gateway 停止后任务丢失。
- **支持平台**：macOS、Linux（含 WSL2）。原生 Windows 不支持，请用 WSL2 或参考方式三手动卸载。
- **Linux 无图形界面**：若 Gateway 在 headless Linux 上，需先执行 `loginctl enable-linger $USER`。
- **WSL2**：若 `systemd-run` 不可用，脚本会自动 fallback 到 nohup。

### 流程

1. 用户发送：「卸载」或「怎么卸载 OpenClaw」
2. Agent 回复：「确认要完全卸载 OpenClaw 吗？此操作不可逆。回复「确认」继续。」
3. 用户回复：「确认」
4. Agent 可选询问：「卸载完成后需要通知吗？回复「邮件 xxx@xx.com」或「ntfy 我的topic」或「不需要」」
5. Agent 调用 `scripts/schedule-uninstall.sh`，传入通知参数（若有）
6. Agent 回复：「已安排卸载，约 15 秒后会话将断开。结果将写入 /tmp/openclaw-uninstall.log」
7. 约 15 秒后 Gateway 停止，卸载在后台完成

### Agent 调用示例

脚本路径通常为 `<workspace>/skills/openclaw-uninstall/scripts/` 或 `~/.openclaw/skills/openclaw-uninstall/scripts/`。

**重要**：调用 exec 时必须指定 `host=gateway`，否则无法在宿主机创建 one-shot。

```bash
# 无通知（必须 host=gateway）
./scripts/schedule-uninstall.sh

# 邮件通知
./scripts/schedule-uninstall.sh --notify-email "user@example.com"

# ntfy 通知
./scripts/schedule-uninstall.sh --notify-ntfy "my-uninstall-topic"
```

### 查看结果

- 默认：`cat /tmp/openclaw-uninstall.log`
- 若 Gateway 在远程 VPS：SSH 登录后执行上述命令

---

## 方式二：验证残留（Agent 可执行）

用户问「卸载干净了吗」「检查一下」时，Agent 可执行：

```bash
./scripts/verify-clean.sh
```

该脚本只读检查，不执行删除。输出残留项（如有）。

---

## 方式三：手动卸载

### 一键卸载（CLI 仍可用时）

```bash
openclaw uninstall --all --yes --non-interactive
```

或：

```bash
npx -y openclaw uninstall --all --yes --non-interactive
```

### 分步手动

1. 停止网关：`openclaw gateway stop`
2. 卸载服务：`openclaw gateway uninstall`
3. 删除状态：`rm -rf "${OPENCLAW_STATE_DIR:-$HOME/.openclaw}"`
4. 卸载 CLI：`npm rm -g openclaw`（或 pnpm/bun）
5. macOS 桌面版：`rm -rf /Applications/OpenClaw.app`

### CLI 已卸载时（手动清理服务）

**macOS**：
```bash
launchctl bootout gui/$UID/ai.openclaw.gateway
rm -f ~/Library/LaunchAgents/ai.openclaw.gateway.plist
```

**Linux**：
```bash
systemctl --user disable --now openclaw-gateway.service
rm -f ~/.config/systemd/user/openclaw-gateway.service
systemctl --user daemon-reload
```

---

## 注意事项

- **多 profile**：每个 profile 有独立目录 `~/.openclaw-<profile>`，需逐一删除
- **远程模式**：需在网关主机执行
- **源码安装**：先卸载服务，再删仓库
- **IM 卸载失败**：若 schedule-uninstall 报错（如沙盒、权限），请 SSH 到网关主机手动执行 `./scripts/schedule-uninstall.sh` 或 `./scripts/uninstall-oneshot.sh`

---

## 参考

- [官方卸载文档](https://docs.openclaw.ai/install/uninstall)
- [安全与威胁模型](https://docs.openclaw.ai/gateway/security)
