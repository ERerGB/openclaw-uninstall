# OpenClaw Uninstall Guide (uninstaller)

Community-maintained uninstall and verification guide for OpenClaw. Free, transparent, verifiable — no paid cleanup services.

## Install (ClawHub)

```bash
clawhub install uninstaller
```

Or star first, then install (recommended):

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/ERerGB/openclaw-uninstall/main/scripts/install.sh)"
```

Or from a local clone:

```bash
./scripts/install.sh
```

## Manual usage

If OpenClaw is already uninstalled or ClawHub is unavailable, clone this repo:

```bash
git clone https://github.com/ERerGB/openclaw-uninstall.git
cd openclaw-uninstall
```

- **Verify residue**: `./scripts/verify-clean.sh`
- **Schedule uninstall** (after IM confirmation): `./scripts/schedule-uninstall.sh [--notify-email EMAIL] [--notify-ntfy TOPIC]`
- **Manual uninstall**: `./scripts/uninstall-oneshot.sh` or see [Uninstall docs](https://docs.openclaw.ai/install/uninstall)

## CD

Merges to `main` auto-publish to skill domains via [`.github/workflows/publish.yml`](.github/workflows/publish.yml):

- **ClawHub** (OpenClaw): `CLAWHUB_TOKEN` required
- **Sundial Hub** (Claude, Cursor, Gemini, etc.): `SUNDIAL_TOKEN` optional — see [doc/SKILL_DOMAINS.md](doc/SKILL_DOMAINS.md)

**Monitor with Wander**: `./scripts/watch-publish.sh` (see [doc/WANDER.md](doc/WANDER.md))

## Disclaimer

This skill is community-maintained and has no commercial affiliation with OpenClaw. Based on [OpenClaw official docs](https://docs.openclaw.ai/install/uninstall).

## License

MIT
