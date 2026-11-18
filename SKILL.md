---
name: uninstaller
description: "Remove OpenClaw or inspect its residue with an explicit host, preservation scope and verified service teardown. Use for uninstall execution or guidance; a how-to question alone does not authorize removal."
---

# OpenClaw uninstall

Resolve the gateway host, installation owner, selected state/profile paths and what
the user wants preserved. Reuse authorization already given for that exact scope.
A question about removal asks for guidance; it is not a request to execute it.
Starring, notifications and paid services are never uninstall prerequisites.

## Choose the smallest route

- **Residue check:** `scripts/verify-clean.sh` is read-only. Report its actual
  observations; an unchecked remote host or profile is not proven clean.
- **Supported CLI/manual removal:** consult the current
  [official uninstall guide](https://docs.openclaw.ai/install/uninstall) and installed
  help. Preview with `openclaw uninstall --dry-run` and the selected scope flags.
  `--all` includes workspace removal; do not select it when workspaces must survive.
  Stop/uninstall the service successfully before any manual data deletion. Resolve
  exact paths and preserve wanted nested workspaces outside a directory before
  deleting it. Remove the CLI through the package manager or launcher that owns it.
- **Disconnecting IM session:** use the bounded scheduler below only when the user
  authorized the helper’s removal scope. The helper is not a substitute for an
  unrelated host’s supported uninstaller.

The bundled shell helpers support macOS/Linux/WSL2, not native Windows. Windows
manual service removal is covered by the official guide. No native Windows
execution was validated by these shell helpers.

## Scheduled helper

Run on the verified gateway host. `host=gateway` is an OpenClaw-runtime option
only where that runtime exposes it; do not invent it in another host or disable
sandboxing to make a probe pass. A job inside an unrelated container cannot
reliably survive shutting down the real gateway.

Review backup/preservation scope first. The helper removes the selected state,
owned gateway service, CLI package and macOS app when present; it is not a
service-only command. `--preserve-state` retains the selected state but still
removes the service/CLI/app. Default backup is limited and excludes the complete
workspace. Prepare and inspect a separate full backup when required before removal.

From this skill repository, choose only authorized options:

```bash
# Preview the scheduler command; does not schedule a job.
./scripts/schedule-uninstall.sh --dry-run --preserve-state
# Schedule after reviewing the actual preservation/removal scope.
./scripts/schedule-uninstall.sh --preserve-state
# Equivalent direct helper when the current session need not survive.
./scripts/uninstall-oneshot.sh --preserve-state
```

Without `--preserve-state`, the helper attempts a limited backup before state
removal. A failed backup stops it. `--no-backup` skips that attempt only when this
is intended. Selective `--preserve` is unsupported; `--preserve-state` cannot be
combined with `--all-profiles`. `--all-profiles` also checks each selected profile’s
service; the default limited backup does not cover every additional profile.
Keep credential-bearing backups private.

The helper stops on failed CLI service teardown. Without the CLI, native fallback
is limited to the default service and requires observable manager state; an
unavailable user bus or unloaded launchd service is not silently treated as safe.
Custom/profile fallback remains manual. Never retry removal just because the
scheduler returned successfully. Inspect the result and resolve a failed gate.

On Linux, inspect whether the selected scheduler can survive this session ending.
Do not automatically enable lingering or change host service policy for a how-to
request. If the available scheduler cannot meet the task, use an authorized
foreground/manual route instead.

The scheduler normally starts after about 15 seconds. Report scheduling separately
from completion, retaining the actual host and log path. The default log is
`/tmp/openclaw-uninstall.log` (`OPENCLAW_UNINSTALL_LOG_FILE` can select a task-owned
path). Read the final result and run the residue check; retain errors and gaps.

Only when requested, pass `--notify-email ADDRESS`, `--notify-ntfy TOPIC` or
`--notify-im CHANNEL:TARGET`. Those are external messages to the named destination;
ordinary uninstall authorization does not add them automatically.

## Install or maintain this skill

Use `clawhub install uninstaller` only for an installation request. The bundled
`scripts/install.sh` does not star by default; its `--star` option needs a separate
request. Offline tests use synthetic commands and do not establish live uninstall
or remote-host acceptance.
