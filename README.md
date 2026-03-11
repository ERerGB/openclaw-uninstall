# OpenClaw 卸载指南 (openclaw-uninstall)

社区维护的 OpenClaw（龙虾）卸载与验证指南。免费、透明、可验证，无需付费清理服务。

## 安装（ClawHub）

```bash
clawhub install openclaw-uninstall
```

## 手动使用

若已卸载 OpenClaw 或无法使用 ClawHub，可从本仓库获取脚本：

```bash
git clone https://github.com/YOUR_USERNAME/openclaw-uninstall.git
cd openclaw-uninstall
```

- **验证残留**：`./scripts/verify-clean.sh`
- **手动卸载**：参见 SKILL.md 或 OpenClaw 官方 [Uninstall](https://docs.openclaw.ai/install/uninstall) 文档

## 声明

本 skill 由社区维护，与 OpenClaw 官方无商业关联。基于 [OpenClaw 官方文档](https://docs.openclaw.ai/install/uninstall) 整理。

## License

MIT
