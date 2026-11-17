# Discord 可转发指令 — OpenClaw 卸载

用于在 Discord channel 发布，让 Agent 自动找到 uninstaller skill 并完成卸载。

---

## 指令文本（复制到 Discord）

```
@Agent 卸载 OpenClaw 时请使用 uninstaller skill：

Skill: uninstaller
Install: clawhub install uninstaller
Repo: https://github.com/ERerGB/openclaw-uninstall

流程：
1. 核对卸载主机、保留范围与已有授权；仅询问“如何卸载”时不执行。
2. 具体卸载范围已授权后，在已核实的网关主机执行：
   ./scripts/schedule-uninstall.sh --preserve-state
3. 回复："卸载已调度，约 15 秒后断开。日志: /tmp/openclaw-uninstall.log"

--preserve-state：保留 ~/.openclaw，重装后自动继承配置。
```

---

## 精简版（适合快速转发）

```
OpenClaw 卸载：clawhub install uninstaller
执行：./scripts/schedule-uninstall.sh --preserve-state（在已核实的网关主机）
仅补齐尚缺的具体授权；不要重复要求已授权范围的 confirm。
```

---

## Agent 解析要点

| 字段 | 值 |
|------|-----|
| skill name | uninstaller |
| install | `clawhub install uninstaller` |
| schedule | `./scripts/schedule-uninstall.sh --preserve-state` |
| exec host | 当前宿主支持的网关执行方式；host=gateway 只用于支持该参数的 OpenClaw runtime |
| 前置确认 | 具体卸载范围已有用户授权 |
| 可选 | `--notify-im discord:channel:ID` 推送结果到 Discord |
