# AGENTS.md — openclaw-uninstall

## Overview

Community-maintained uninstall skill for OpenClaw. Scripts: `install.sh`, `schedule-uninstall.sh`, `uninstall-oneshot.sh`, `verify-clean.sh`.

## Offline contract tests

`./tests/run-e2e.sh` is the historical entrypoint for `tests/test_offline.py`.
It checks installation account actions, strict argument handling, shell quoting,
state-path dry runs and limited-backup success/failure with temporary fixtures and
stub commands. It does not schedule or execute a live uninstall, contact ClawHub,
operate launchd/systemd, or replace the process HOME.

Run:

```bash
./tests/run-e2e.sh
for script in scripts/*.sh tests/*.sh tests/helpers/*.sh; do bash -n "$script" || exit; done
```

`tests/run-lifecycle.sh` is a separate live, destructive lifecycle exercise. It
installs a global CLI, starts a gateway and uninstalls real state; never include
it in offline CI or treat these fixtures as proof that live lifecycle passed.

Keep new fixture data under a task-specific temporary directory. Use
`OPENCLAW_UNINSTALL_LOG_FILE` to isolate logs and dry-run validation against a
nonexistent user-owned state path; do not create fixtures directly in HOME.

## Script options

- **schedule-uninstall**: `--notify-email`, `--notify-ntfy`, `--notify-im`, `--no-backup`, `--preserve-state`, `--all-profiles`, `--dry-run`
- **uninstall-oneshot**: `--notify-email`, `--notify-ntfy`, `--notify-im`, `--no-backup`, `--preserve-state`, `--all-profiles`, `--dry-run`

## CI

`.github/workflows/offline-tests.yml` runs the isolated contract tests and shell syntax checks on pull requests. Publishing remains a separate main-branch workflow.
