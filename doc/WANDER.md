# Wander Integration — CI Monitor

Use [Wander](https://github.com/ERerGB/wander) to monitor the Publish to ClawHub workflow without polling.

## Prerequisites

- `gh` CLI installed and authenticated
- Wander cloned (e.g. `~/code/wander` or sibling of this repo)
- macOS (for notifications)

## Quick usage

```bash
# 1. Push (triggers publish workflow)
git push

# 2. Monitor in background (from this repo)
../wander/watch-workflow-bg.sh publish.yml
# Or if Wander is elsewhere:
# /path/to/wander/watch-workflow-bg.sh publish.yml
```

You'll get a macOS notification when the workflow completes.

## Modes

| Mode | Command | Use case |
|------|---------|----------|
| Foreground | `../wander/watch-workflow.sh publish.yml` | Wait for result |
| Background | `../wander/watch-workflow-bg.sh publish.yml` | Continue working, notify when done |
| Detached | `../wander/watch-workflow-detached.sh publish.yml` | Close terminal, log to `~/.wander_logs/` |

## Alias (optional)

```bash
alias wfbg='../wander/watch-workflow-bg.sh'
# Then: git push && wfbg publish.yml
```
