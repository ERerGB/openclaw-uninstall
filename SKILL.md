---
name: uninstaller
description: "Remove OpenClaw or inspect its residue with an explicit host, preservation scope and verified service teardown. Use for uninstall execution or guidance; a how-to question alone does not authorize removal."
---

# OpenClaw uninstall

Resolve the gateway host, installation owner, selected state/profile paths and
preservation request. Reuse authorization for that exact scope; a how-to question
asks for guidance, not execution. Notifications, starring and paid services are
never removal prerequisites.

## Choose the route

- For residue only, `scripts/verify-clean.sh` is read-only; report unchecked hosts
  and profiles explicitly.
- For CLI/manual removal, inspect installed help and the current
  [official guide](https://docs.openclaw.ai/install/uninstall). Preview with
  `openclaw uninstall --dry-run` and selected flags. `--all` includes workspace
  removal. Verify service teardown before data deletion, resolve exact paths and
  preserve wanted nested workspaces elsewhere first. Remove the CLI using its
  actual owning package manager/launcher.
- For a disconnecting IM session, use the bundled scheduler only for its authorized
  full removal scope on the verified gateway host. An unrelated container cannot
  guarantee survival of the real gateway's shutdown. `host=gateway` exists only in
  runtimes that expose it; do not invent options or disable sandboxing.

Shell helpers support macOS/Linux/WSL2, not native Windows. Use the official Windows
route where appropriate; these helpers do not establish Windows acceptance.

## Bundled helper contract

The helper removes selected state, its gateway service, CLI package and macOS app
when present. `--preserve-state` keeps state but still removes service/CLI/app.
Default backup is limited and excludes a complete workspace; inspect a separate
full backup first when required. A failed backup stops removal. `--no-backup`
intentionally skips that attempt. Selective `--preserve` is unsupported;
`--preserve-state` and `--all-profiles` cannot be combined. All-profiles checks each
selected service, but its extra state is not covered by the default limited backup.
Keep credential-bearing backups private.

From the repository, preview the helper without scheduling:
`./scripts/schedule-uninstall.sh --dry-run --preserve-state`.
After checking the actual removal/preservation scope, an authorized scheduled
execution uses `./scripts/schedule-uninstall.sh --preserve-state`; direct execution
uses `./scripts/uninstall-oneshot.sh --preserve-state` when session survival is not
needed. Choose other flags only within the requested scope.

Failed CLI stop/uninstall blocks cleanup. Missing-CLI native fallback covers only
the default service with observable manager state; an unavailable user bus/unloaded
launchd state is not silently safe. Custom/profile fallback is manual. Inspect a
failed gate; successful scheduling does not authorize blind removal retries.
On Linux verify scheduler survival; do not enable lingering or change service
policy just to answer guidance. Use an authorized foreground route if necessary.

The scheduled delay is normally about 15 seconds. Record scheduling separately
from completion, with actual host and log (`/tmp/openclaw-uninstall.log`, or the
chosen `OPENCLAW_UNINSTALL_LOG_FILE`). Read final results and rerun residue checks.
Only explicitly requested messages use `--notify-email ADDRESS`, `--notify-ntfy TOPIC`
or `--notify-im CHANNEL:TARGET`.

For an installation request use `clawhub install uninstaller`; the local installer
stars only with separately requested `--star`. Offline fixtures do not prove live
service removal or remote acceptance.
