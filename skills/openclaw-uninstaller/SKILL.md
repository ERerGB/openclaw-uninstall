---
name: openclaw-uninstaller
description: OpenClaw 卸载的中文兼容入口。用于移除服务、检查残留或了解卸载流程；执行前确认主机、保留范围与已有授权。
---

# OpenClaw 卸载

这是维护流程的中文兼容入口。先读仓库根目录的
[uninstaller](../../SKILL.md)，再按用户请求做说明、残留检查或实际移除。
“如何卸载”不等于授权执行。

核对网关主机、安装所有者、状态/profile 和保留范围。实际保留参数是
`--preserve-state`；默认备份不含完整 workspace，完整保留需要另行验证。
不附带清除其他 profile/源码/应用、点赞或外发通知。

当前上游行为以[官方卸载文档](https://docs.openclaw.ai/install/uninstall)
和已安装帮助为依据；历史费用或曝光实例不是当前执行理由。
