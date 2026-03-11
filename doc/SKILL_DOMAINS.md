# Skill Distribution Domains — Pipeline Registry

High-weight domains for skill distribution, beyond ClawHub. Used by the auto-publish/auto-update pipeline.

## Domain Registry

| Domain | Weight | Publish Method | CI Secret | Status |
|--------|--------|----------------|-----------|--------|
| **ClawHub** | P0 | `clawhub publish .` | `CLAWHUB_TOKEN` | ✅ Active |
| **Sundial Hub** | P0 | `npx sundial-hub push .` | `SUNDIAL_TOKEN` (if supported) | 🔲 Pending |
| **SkillCreator.ai** | P1 | Registry / `skr push` | TBD | 🔲 Pending |
| **skr (OCI)** | P1 | `skr build` + `skr push` to ghcr.io | `GITHUB_TOKEN` | 🔲 Pending |
| **SkillsMP** | P2 | Discovery/crawl (no direct publish) | — | Info only |

## Details

### ClawHub (clawhub.ai)
- **Target**: OpenClaw users
- **CLI**: `clawhub publish . --slug uninstaller --name "Uninstaller"`
- **Auth**: `clawhub login --token $CLAWHUB_TOKEN --no-browser`
- **Docs**: https://docs.openclaw.ai/clawhub

### Sundial Hub (sundialhub.com)
- **Target**: Claude Code, Cursor, Gemini, Codex CLI, ChatGPT, Copilot, Windsurf
- **Format**: SKILL.md (open standard, compatible)
- **CLI**: `npx sundial-hub auth login && npx sundial-hub push .`
- **Docs**: https://sundialhub.com/docs
- **Note**: CI auth TBD; may require `SUNDIAL_TOKEN` or OAuth flow

### SkillCreator.ai
- **Target**: Claude, Copilot, Cursor, Codex, Gemini CLI, 10+ runtimes
- **Format**: Agent Skills standard (SKILL.md)
- **CLI**: `npx ai-agent-skills` or `skr` (OCI)
- **Docs**: https://www.skillcreator.ai/

### skr (OCI Registry)
- **Target**: Any agent using OCI registries (ghcr.io, Docker Hub)
- **Action**: `andrewhowdencom/skr@main`
- **Auth**: `GITHUB_TOKEN` for ghcr.io
- **Docs**: https://github.com/andrewhowdencom/skr

### SkillsMP (skillsmp.com)
- **Target**: Discovery/search; aggregates from other sources
- **Publish**: No direct publish; skills may be indexed from GitHub/Sundial
- **Use**: Ensure skill is on ClawHub/Sundial for discoverability

## Pipeline Checklist

- [x] ClawHub: workflow job, CLAWHUB_TOKEN
- [ ] Sundial: add job when token/CI auth available
- [ ] skr/OCI: optional ghcr.io publish for OCI consumers
- [ ] SkillCreator: add when publish API/CLI documented

## Changelog

| Date | Change |
|------|--------|
| 2026-03-11 | Initial registry: ClawHub, Sundial, SkillCreator, skr, SkillsMP |
