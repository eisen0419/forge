# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [0.5.2] - 2026-05-19

### Fixed

- **`crucible-preflight` hook: false-positive deny on feature branch pushes** — v0.5.1 fixed tag-push false positives but the same pattern persisted for any `git push -u origin <feature-branch>`. Root causes: (1) the `HIGH_RISK_REGEX` matched *all* `git push` commands rather than only pushes to protected branches; (2) the keyword-overlap grep included `correct_action` and `content` fields from failed-direction yamls — fields that describe the *solution* ("push your branch via `git push -u origin <branch>`"), not the *failure trigger*. This created a feedback loop: the yaml telling the agent to push a feature branch caused the hook to deny the agent doing exactly that. Fix: (1) `HIGH_RISK_REGEX` narrowed to `git push` targeting `main`, `master`, or `release/*` only; force-push (`-f` / `--force-with-lease`) still matched regardless of target. (2) Keyword grep now uses only `trigger` and `sample_snippet` fields (failure-describing fields), never `correct_action` or `content` (prescription fields). Sandbox 15/15 across feature-branch allow + protected-branch deny + tag exemptions + regression.
- **Live hook upgrade path without forced disable** — previous workaround required renaming the hook to `.disabled` (which triggered a user-level security hook denial). Discovered that `cp` (overwrite/upgrade) does not trigger the security hook; the installer's own `cp` pattern is the correct upgrade path.
- **Action for existing users**: re-run `scripts/install-hook.sh crucible-preflight` to upgrade the live hook. Clear any `~/.claude/crucible/.acks` entries added as v0.5.0/v0.5.1 workarounds — with this fix, neither `df53a88d1096` nor `70c826a15cec` should need to be acked for normal feature-branch push workflows.

## [0.5.1] - 2026-05-18

### Fixed

- **`crucible-preflight` hook: false-positive deny on tag pushes** — v0.5.0 hook treated `git push origin v0.5.0` (push a tag) the same as `git push origin main` (push a branch), because both share the keywords `git`, `push`, `origin` and trigger ≥ 2 keyword overlap with the protected-branch failed-direction yamls. This was caught immediately during the v0.5.0 release itself: pushing the `v0.5.0` tag was denied by fingerprint `df53a88d1096` (push to protected branch) and `70c826a15cec` (stacked PR base-deletion), forcing a `.acks` workaround.
- The hook now exits with **allow** in three additional cases, evaluated after the high-risk regex match but before the failed-direction grep:
  - **(a)** `--tags` or `--follow-tags` flag anywhere on the command line — pushing all tags is never a branch operation.
  - **(b)** Explicit `refs/tags/<name>` path — the canonical fully-qualified tag refspec is unambiguous.
  - **(c)** Last whitespace-delimited token resolves to an existing local tag (verified via `git rev-parse --verify refs/tags/<token>`) — covers the common `git tag X && git push origin X` workflow without trusting arbitrary `v*` names that might be branches.
- Non-existent tag-looking refs (e.g. `git push origin v999-does-not-exist` when no such tag exists) still hit the deny path — the hook is conservative by design.
- Sandbox: 8 scenarios pass (regression: branch / force / rm still deny; new: 4 tag-push cases now allow; edge: non-existent tag still denies).
- **Action for existing users**: re-run `scripts/install-hook.sh crucible-preflight` to upgrade the live hook in `~/.claude/hooks/`. If you ack'd `df53a88d1096` or `70c826a15cec` in `~/.claude/crucible/.acks` to work around this bug, you can now safely remove those lines.

## [0.5.0] - 2026-05-18

### Added

- **`crucible-preflight` runtime hook** ([#15](https://github.com/eisen0419/forge/pull/15), merged in [`4d50342`](https://github.com/eisen0419/forge/commit/4d50342)) — `PreToolUse` hook (matcher: `Bash`) that closes the read-side gap left by `auto-evolve-collector`. On every Bash tool call, the hook:
  - filters by a high-risk command regex (`git push`, `git reset --hard`, `rm -rf`, `chmod -R`, `chown -R`, `terraform destroy`, `kubectl delete`, SQL `DROP TABLE` patterns)
  - greps `~/.claude/crucible/failed-directions/*.yaml` for a yaml whose `trigger` / `sample_snippet` / `content` / `correct_action` fields share ≥ 2 keywords with the command
  - on hit, returns `permissionDecision: deny` + the matching `correct_action` as `permissionDecisionReason` so the agent sees the proven recovery path **before** the destructive command executes
  - appends a JSON line to `~/.claude/crucible/surface_log.jsonl` per deny (machine-observed audit trail, independent of self-reported `retrieval_count`)
  - supports per-fingerprint opt-out via `~/.claude/crucible/.acks`
  - `templates/hooks/crucible-preflight/{hook.sh, README.md}` — 200-line bash + inline Python, design doc, install/uninstall, tuning knobs.
  - `templates/hooks/manifest.json` — new entry with `event: PreToolUse` + `matcher: Bash`.
- **Motivation**: 3-day field data on the developer's own Crucible install showed only 3 of 11 fingerprints had `retrieval_count > 0` — the honor-system reader (prose in `~/CLAUDE.md` telling the agent to grep before L3) was not reliable. Independent Codex review confirmed (a) honor-system retrieval is the documented failure mode of the v0.3.0 design, (b) the original "echo to stderr" PreToolUse design would not have worked because `additionalContext` is shown alongside the tool result, too late for destructive commands. This hook implements the correct mechanism: synchronous `deny` with `permissionDecisionReason`, which is the only PreToolUse path Claude Code shows to the agent before the command runs.
- **Anti-false-positive design**: fingerprint coarseness (`sha1(error_kind|tool_name)[:12]`) means a single fp can collapse unrelated failures under buckets like `permission denied|Bash`. The ≥ 2 keyword overlap rule (with 1-2 char tokens filtered out) prevents a `chmod` failure pattern from denying `git push` commands and vice versa. Sandboxed across 9 test cases including the explicit anti-FP scenario (`git push` does NOT match the `chmod` fingerprint).
- **Live-verified**: in a separate Claude Code session immediately after install, `git push origin main` was intercepted and denied with fingerprint `70c826a15cec` (stacked PR base-deletion recovery), and `surface_log.jsonl` incremented from 1 → 2 lines.

### Changed

- **`scripts/install-hook.sh`** ([#15](https://github.com/eisen0419/forge/pull/15)) now reads the optional `matcher` field from `manifest.json` and includes it in the `settings.json` hook registration when present. Required for `PreToolUse` / `PostToolUse` hooks (which scope by tool name); ignored for `SessionStart` / `Stop` / `SessionEnd`. Backwards-compatible: hooks without `matcher` install unchanged.
- **`scripts/install-hook.sh`** ([#15](https://github.com/eisen0419/forge/pull/15)) verification step no longer warns "empty output" when installing `PreToolUse` / `PostToolUse` hooks. Those hooks expect a JSON stdin payload; the empty-stdin smoke test should hit the "allow" path (empty stdout, exit 0) by design. The installer now reports `verify: PreToolUse hook (empty-stdin smoke test → allow path, OK)` for these event types.
- **`templates/hooks/README.md`** ([#15](https://github.com/eisen0419/forge/pull/15)) manifest schema example annotates the optional `matcher` field with usage rules.
- **README visibility** ([#16](https://github.com/eisen0419/forge/pull/16), merged in [`d659332`](https://github.com/eisen0419/forge/commit/d659332)) — surface Crucible above the fold. Banner tagline now leads with templates + Crucible joint value prop and includes a one-sentence explanation of the Stop-hook + PreToolUse-hook loop. Quick-link bar adds `Crucible` + `Runtime Hooks`. Table of Contents grows two missing entries (Runtime Hooks from PR #3, Crucible from PR #6). Why Forge section closes with a paragraph framing the three-layer story (templates + runtime hooks + Crucible). README_CN.md mirrors 1:1. No code changes.
- **`README.md` + `README_CN.md`** Runtime Hooks catalog grows a row for `crucible-preflight` (third hook).
- **GitHub repo description** updated to `"Router-first CLAUDE.md/AGENTS.md templates plus Crucible — a per-machine error-learning store with Stop-hook writer + PreToolUse-hook reader that blocks high-risk commands matching a known prior failure."` (was `"AI-Assisted Development Workflow Starter Kit for Claude Code"`).

### Notes

- This release closes the Crucible loop. From v0.3.0 (storage + writer hook), through v0.4.0 (reader prose + installer + wizard), to v0.5.0 (**enforced** reader via PreToolUse hook + visibility), the wave is now complete: a Full-tier `forge-setup` run installs the templates, the writer hook, the storage, and the synchronous reader hook in one wizard pass. `surface_log.jsonl` provides machine-observed evidence of the reader actually firing — `retrieval_count` (honor-system, model-reported) and `surface_log` (hook-observed) form two independent signals.
- SemVer minor bump (0.4.1 → 0.5.0): new top-level hook surface (`crucible-preflight`) and changed `scripts/install-hook.sh` API (now consumes optional `matcher` from manifest). Existing v0.4.x hooks are unaffected — backwards-compatible.

## [0.4.1] - 2026-05-18

### Fixed

- **Template header `{{VARIABLES}}` no longer eaten by the setup wizard** ([#2](https://github.com/eisen0419/forge/pull/2), merged in [`419312a`](https://github.com/eisen0419/forge/commit/419312a)) — the literal string `{{VARIABLES}}` in the first comment block of `templates/full.md`, `templates/essential.md`, `templates/targets/codex/full.md`, and `templates/targets/codex/essential.md` was being matched by `forge-setup` Step 5's `grep '{{'` placeholder-residue scan and replaced with the empty string, so users' generated `CLAUDE.md` / `AGENTS.md` line 3 read "Replace all  with your actual values." (note the double space). The header now uses `[VARIABLES]` instead — bracket form is clearly not a Mustache token, so the wizard leaves it alone while the hint remains readable. Zero functional change; four 1-character template edits.

## [0.4.0] - 2026-05-18

### Added

- **Pre-Flight Protocol section** ([#11](https://github.com/eisen0419/forge/pull/11), merged in [`62316db`](https://github.com/eisen0419/forge/commit/62316db)) — Full-tier templates now splice in a four-step pre-flight checklist for L3 high-risk tasks (`git push`, `rm -rf`, migrations, auth, schema, force-push, etc.): state extract → Crucible failed-directions retrieval → follow `correct_action` + bookkeep on hit → write golden case on miss. Drives the agent to actually read `~/.claude/crucible/` before acting, rather than letting the directory sit unused.
  - `templates/core/sections/18-pre-flight-protocol.md` — canonical source with full SECTION header (What / Why / Customize / Depends-on).
  - `templates/full.md` and `templates/targets/codex/full.md` now contain a tightened ~14-line version of the protocol, spliced between `## Task Routing` and `## Multi-Agent Router`. Line budget: full.md 186/200, codex/full.md 186/200 (still under).
  - Essential-tier templates intentionally unchanged — pre-flight requires Crucible, which is a Full-tier opt-in.
- **`scripts/install-crucible.sh`** + **`scripts/uninstall-crucible.sh`** ([#12](https://github.com/eisen0419/forge/pull/12), merged in [`c4ed7ef`](https://github.com/eisen0419/forge/commit/c4ed7ef)) — Crucible installer/uninstaller pair, mirroring the `install-hook.sh` / `uninstall-hook.sh` pattern.
  - `install-crucible.sh`: stages `templates/crucible/{README.md,schemas}` into `~/.claude/crucible/`, creates `failed-directions/` + `golden-cases/` subdirs, optionally seeds the worked-example yamls (`--with-seeds`), optionally inits a git repo for cross-machine sync (`--no-git` opts out). Idempotent — README + schemas refresh on every run; user-edited data is never touched.
  - `uninstall-crucible.sh`: **renames** the install dir to `~/.claude/crucible.removed.<timestamp>` rather than deleting it, because user-edited `correct_action` / `confidence` / `linked_golden_case` fields cannot be recovered if dropped by accident. Prints the restore command and the irreversible-delete command for the user to run manually.
- **`skills/forge-setup/SKILL.md` Step 4.6 + Step 6.6** ([#12](https://github.com/eisen0419/forge/pull/12)) — wizard now asks "install Crucible? (with-seeds / empty / none)" up front (Step 4.6), defers actual install to Step 6.6 (after `CLAUDE.md` / `AGENTS.md` are written so partial failures don't leave a half-configured machine), and surfaces Crucible status in the Step 8 completion report. Same Step 4.5 + 6.5 split pattern as the existing hooks flow.

### Changed

- `README.md` + `README_CN.md` Crucible install snippet now points at `scripts/install-crucible.sh` (and the rename-safe uninstall script) instead of the four-command manual `mkdir`/`cp`/`git init` recipe. Also surfaces the new `## Pre-Flight Protocol` section and the wizard's Step 4.6 + 6.6 integration so all three components (storage, hook, prose) are discoverable from the top-level README.

### Notes

- This release closes the **Crucible reverse-contribution wave** started in [0.3.0]. After [0.4.0], a Full-tier user running `forge-setup` once gets the entire system in one go: `CLAUDE.md`/`AGENTS.md` with `## Pre-Flight Protocol` spliced in (PR #11), the `auto-evolve-collector` hook installed (existing Step 4.5), and `~/.claude/crucible/` populated with README/schemas/seeds/git (PR #12 Step 4.6/6.6). The three pieces — prose, hook, store — close the loop.
- No `[Unreleased]` content is being held back for [0.5.0]; this is a clean cut.

## [0.3.0] - 2026-05-18

### Added

- **Crucible evolution-asset system** ([#6](https://github.com/eisen0419/forge/pull/6), merged in [`3109e16`](https://github.com/eisen0419/forge/commit/3109e16)) — opt-in cross-session learning store under `templates/crucible/`.
  - `templates/crucible/README.md` — design, data flow, install instructions, cost budget.
  - `templates/crucible/schemas/{failed-direction,golden-case}.schema.yaml` — authoritative field reference for both record types, with comments distinguishing hook-written / user-written / tooling-bumped fields.
  - `templates/crucible/seeds/{failed-direction,golden-case}.example.yaml` — schema-correct worked example (`push to protected branch → open a PR`), reverse-linked pair.
  - `templates/crucible/seeds/README.md` — what the seeds are and how to use them.
  - `scripts/crucible-bookkeep.sh` — maintenance helper with four subcommands: `hit <fingerprint>` (bump retrieval_count + last_retrieved), `list` (tabular stats), `validate` (required-field completeness check), `gen-fingerprint <kind> <tool>` (canonical sha1 formula, mirrors the planned auto-evolve-collector hook).
  - `docs/workflows/crucible.md` — runtime usage guide: L0–L3 task routing, the pre-flight protocol, write-back cadence, prose-to-splice for `CLAUDE.md` / `AGENTS.md`, maintenance rhythm, catchall protocol, honest failure modes.

- **`auto-evolve-collector` runtime hook** ([#8](https://github.com/eisen0419/forge/pull/8), merged in [`55fb6ba`](https://github.com/eisen0419/forge/commit/55fb6ba)) — Stop-event hook that scans each session's jsonl on session end and persists tool errors and user corrections to three sinks: a daily raw jsonl (`$EVOLVE_COLLECT_DIR`, default `~/.claude/auto-lessons/`), Crucible failed-directions yamls + sidecar occurrences.jsonl (`$EVOLVE_CRUCIBLE_FD_DIR`, default `~/.claude/crucible/failed-directions/`), and an **opt-in** Obsidian digest (`$EVOLVE_OBSIDIAN_DIR`, default empty / disabled).
  - `templates/hooks/auto-evolve-collector/hook.sh` — bash wrapper + inline Python; pure machine work, no LLM, < 5 s budget, failure never blocks session end.
  - `templates/hooks/auto-evolve-collector/README.md` — sink table, env overrides, install/uninstall, skip conditions, what it does NOT do.
  - `templates/hooks/manifest.json` — registers the hook under `Stop` event with `marker: forge-auto-evolve-collector` and `language: en` (jsonl/yaml outputs are machine-readable; correction-keyword scan remains bilingual: `不对 / 错了 / 别 / 不要 / wrong / no, don't / stop`).
  - `templates/hooks/README.md` — catalog row added.

### Notes

- Crucible is **opt-in and standalone** — no template, hook, or script in the existing Forge surface depends on it without explicit opt-in. The auto-evolve-collector hook is also opt-in (install via `scripts/install-hook.sh auto-evolve-collector`); installing it does not turn on the Obsidian digest unless `EVOLVE_OBSIDIAN_DIR` is also set.
- **Fingerprint formula is the contract** across three artifacts: `templates/hooks/auto-evolve-collector/hook.sh`, `scripts/crucible-bookkeep.sh gen-fingerprint`, and `templates/crucible/schemas/failed-direction.schema.yaml`. End-to-end sandbox test verifies the hook's output yaml passes `crucible-bookkeep.sh validate` and that all three artifacts compute `df53a88d1096` for `(permission denied, Bash)`.

### Changed

- CHANGELOG entries for `[0.2.0]` now carry inline links to the originating PRs and merge commits ([#5](https://github.com/eisen0419/forge/pull/5), merged in [`a48e787`](https://github.com/eisen0419/forge/commit/a48e787)) — same convention now applied to this `[0.3.0]` release.
- `templates/crucible/README.md` and `docs/workflows/crucible.md` no longer describe the `auto-evolve-collector` hook as "planned, separate PR" — the hook landed in this same release. `templates/crucible/schemas/failed-direction.schema.yaml` now documents the implicit ASCII-only contract on `error_kind` that keeps the fingerprint formula identical between the Python hook and the bash bookkeep script ([#9](https://github.com/eisen0419/forge/pull/9), merged in [`5a90781`](https://github.com/eisen0419/forge/commit/5a90781)).

## [0.2.0] - 2026-05-17

Released as commit [`6aec147`](https://github.com/eisen0419/forge/commit/6aec147).

### Added

- **Runtime hooks infrastructure** ([#3](https://github.com/eisen0419/forge/pull/3), merged in [`e602c0d`](https://github.com/eisen0419/forge/commit/e602c0d)) — manifest-driven hook system that installs Claude Code lifecycle hooks globally into `~/.claude/hooks/` and registers them in `~/.claude/settings.json`.
  - `templates/hooks/manifest.json` (schema v1.1) — single source of truth.
  - `templates/hooks/project-context/hook.sh` — first hook. Forces the agent to emit `Project: <X>. Current stage: <Y>.` at the top of every first reply. Adaptive zh/en at runtime via CJK density scan of `CLAUDE.md`/`AGENTS.md`/`~/.claude/rules/*.md`; override with `FORGE_HOOK_LANG=zh|en`.
  - `scripts/install-hook.sh` / `scripts/uninstall-hook.sh` — jq-driven, backs up `settings.json`, deduplicates, verifies. Uninstall leaves other hooks/events/fields untouched.
  - `templates/hooks/README.md` — manifest schema + "how to add a new hook" guide.
- **Coding Standards section** ([#4](https://github.com/eisen0419/forge/pull/4), merged in [`882153d`](https://github.com/eisen0419/forge/commit/882153d)) — `templates/core/sections/17-coding-standards.md` with an explicit threshold-exception protocol: soft targets (function ≤ 50 lines, file ≤ 300, nesting ≤ 3, complexity ≤ 10) plus a 3-step escape hatch so agents don't mechanically fragment state machines, dispatch tables, or fixtures. Mirrored into `templates/full.md`, `templates/essential.md`, `templates/targets/codex/full.md`, `templates/targets/codex/essential.md`.
- **Self-Improvement Loop** ([#4](https://github.com/eisen0419/forge/pull/4), merged in [`882153d`](https://github.com/eisen0419/forge/commit/882153d)) — `tasks/lessons.md` persistence pattern. When the user corrects the agent, append correction + reason to `tasks/lessons.md`; re-read at every session start; graduate recurring lessons to `docs/solutions/` or `CLAUDE.md`. Added to `templates/core/sections/13-knowledge-compounding.md`, plus the `Hooks And Memory` section in both full templates and the `Task Management` section in both essential templates.

### Changed

- `skills/forge-setup/SKILL.md` ([#3](https://github.com/eisen0419/forge/pull/3)) — added Step 4.5 (optional hook install during wizard) and Step 6.5 (defers actual install until after `CLAUDE.md`/`AGENTS.md` are written, so partial failure never leaves a half-configured machine).

### Notes

- Both PRs ([#3](https://github.com/eisen0419/forge/pull/3) hooks infrastructure, [#4](https://github.com/eisen0419/forge/pull/4) rules reverse-contribution) merged via merge commits on 2026-05-17.
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
