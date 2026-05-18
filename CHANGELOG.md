# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- **Crucible evolution-asset system** — opt-in cross-session learning store under `templates/crucible/`.
  - `templates/crucible/README.md` — design, data flow, install instructions, cost budget.
  - `templates/crucible/schemas/{failed-direction,golden-case}.schema.yaml` — authoritative field reference for both record types, with comments distinguishing hook-written / user-written / tooling-bumped fields.
  - `templates/crucible/seeds/{failed-direction,golden-case}.example.yaml` — schema-correct worked example (`push to protected branch → open a PR`), reverse-linked pair.
  - `templates/crucible/seeds/README.md` — what the seeds are and how to use them.
  - `scripts/crucible-bookkeep.sh` — maintenance helper with four subcommands: `hit <fingerprint>` (bump retrieval_count + last_retrieved), `list` (tabular stats), `validate` (required-field completeness check), `gen-fingerprint <kind> <tool>` (canonical sha1 formula, mirrors the planned auto-evolve-collector hook).
  - `docs/workflows/crucible.md` — runtime usage guide: L0–L3 task routing, the pre-flight protocol, write-back cadence, prose-to-splice for `CLAUDE.md` / `AGENTS.md`, maintenance rhythm, catchall protocol, honest failure modes.

### Notes

- Crucible is **opt-in and standalone** — no template, hook, or script in the existing Forge surface depends on it. The schema is the contract; the auto-evolve-collector hook that auto-populates `failed-directions/` will land in a follow-up PR.
- Fingerprint formula is `sha1(f"{error_kind[:30].lower()}|{tool_name or 'unknown'}").hexdigest()[:12]` and is the same in `scripts/crucible-bookkeep.sh gen-fingerprint` as it will be in the future hook — verified end-to-end in a sandbox.

## [0.2.0] - 2026-05-17

### Added

- **Runtime hooks infrastructure** — manifest-driven hook system that installs Claude Code lifecycle hooks globally into `~/.claude/hooks/` and registers them in `~/.claude/settings.json`.
  - `templates/hooks/manifest.json` (schema v1.1) — single source of truth.
  - `templates/hooks/project-context/hook.sh` — first hook. Forces the agent to emit `Project: <X>. Current stage: <Y>.` at the top of every first reply. Adaptive zh/en at runtime via CJK density scan of `CLAUDE.md`/`AGENTS.md`/`~/.claude/rules/*.md`; override with `FORGE_HOOK_LANG=zh|en`.
  - `scripts/install-hook.sh` / `scripts/uninstall-hook.sh` — jq-driven, backs up `settings.json`, deduplicates, verifies. Uninstall leaves other hooks/events/fields untouched.
  - `templates/hooks/README.md` — manifest schema + "how to add a new hook" guide.
- **Coding Standards section** (`templates/core/sections/17-coding-standards.md`) with an explicit threshold-exception protocol: soft targets (function ≤ 50 lines, file ≤ 300, nesting ≤ 3, complexity ≤ 10) plus a 3-step escape hatch so agents don't mechanically fragment state machines, dispatch tables, or fixtures. Mirrored into `templates/full.md`, `templates/essential.md`, `templates/targets/codex/full.md`, `templates/targets/codex/essential.md`.
- **Self-Improvement Loop** — `tasks/lessons.md` persistence pattern. When the user corrects the agent, append correction + reason to `tasks/lessons.md`; re-read at every session start; graduate recurring lessons to `docs/solutions/` or `CLAUDE.md`. Added to `templates/core/sections/13-knowledge-compounding.md`, plus the `Hooks And Memory` section in both full templates and the `Task Management` section in both essential templates.

### Changed

- `skills/forge-setup/SKILL.md` — added Step 4.5 (optional hook install during wizard) and Step 6.5 (defers actual install until after `CLAUDE.md`/`AGENTS.md` are written, so partial failure never leaves a half-configured machine).

### Notes

- Both PRs (#3 hooks infrastructure, #4 rules reverse-contribution) merged via merge commits on 2026-05-17.
- All template line budgets respected: `full.md` 175/200, `essential.md` 163/180, `codex/full.md` 175/200, `codex/essential.md` 173/180.
- `node scripts/test-forge-routing.mjs` passes with no regression.

## [0.1.0] - 2026-04-XX

### Added

- Initial project scaffold with plugin metadata
- 17 section template fragments in `templates/core/sections/`
- Essential tier template (`templates/essential.md`)
- Full tier template (`templates/full.md`)
- Codex target templates for `AGENTS.md`
- Target-aware `/forge-setup` flow for Claude Code, Codex, or both

### Changed

- Updated Compound Engineering command references from legacy `/ce:*` style to current `/ce-*` style
- Renamed Forge's CE-to-GSD bridge from `ce:run` to `forge-run`
- Replaced stale `/gsd-session-report` reference with `/gsd-stats`
- Aligned marketplace metadata version with plugin version

### Fixed

- Fixed marketplace `source` path so `claude plugin validate .` passes
