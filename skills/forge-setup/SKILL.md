---
name: forge-setup
description: "This skill should be used when the user asks to 'set up Forge', 'configure Forge workflow', or 'forge setup'. Interactive wizard that generates customized CLAUDE.md and/or AGENTS.md files from battle-tested workflow templates."
argument-hint: "(no arguments)"
---

You are running the **Forge Setup Wizard**. Guide the user step-by-step to generate customized agent instruction files from Forge templates.

## Step 1: Agent Target

Ask the user via AskUserQuestion:

> Which agent target would you like to configure?
>
> - **Claude Code** — generate `CLAUDE.md`
> - **Codex** — generate `AGENTS.md`
> - **Both** — generate both files from the same Forge tier
>
> Which target? (Claude Code / Codex / Both)

Store answer as `TARGET`.

## Step 2: Experience Level

Ask the user via AskUserQuestion:

> Which Forge tier would you like?
>
> - **Essential** — Newcomers. Core rules only: coding standards, task management, git conventions, safety rules. Minimal overhead, easy to start.
> - **Full** — Power users. Router-first methodology under ~200 lines: context pointers, do-not-introduce guardrails, CE/GSD/gstack/Waza routing, blast radius checks, local instruction files, hooks/memory guidance, and role mapping.
>
> Which tier? (Essential / Full)

Store answer as `TIER`.

## Step 3: Basic Info

Ask each question **one at a time** via AskUserQuestion:

1. "What's your name? (used to personalize the generated instruction file)"
2. "What's your primary platform? (macOS / Linux / Windows+WSL)"
3. "Preferred output language for agent responses? (English / Chinese / other — specify)"
4. "Git commit style? (Press Enter for default: conventional commits — e.g. `feat(scope): summary`)"

Meanwhile, auto-detect environment via Bash (run in parallel with questions where possible):
- Shell: `echo $SHELL`
- Editor: check `code --version` → VS Code, else `vim --version`, else "unspecified"
- Package managers: check `which npm`, `which pip`, `which brew`, combine detected ones

## Step 4: Full Tier Additional Questions

Skip this step if TIER is Essential.

Ask via AskUserQuestion:

1. "Default testing strategy level?
   - 0: Targeted verification (small, low-risk changes)
   - 1: Regression tests (local behavior changes)
   - 2: TDD (new features, shared logic, high risk)
   - 3: Code review via /ce-code-review
   - 4: Completion verification + delivery gate
   (Enter a number 0–4, default: 1)"

2. "Set up the role system? This maps AI roles (designer/reviewer/executor/inspiration) to providers.
   Default: all roles → claude.
   Type 'yes' to customize, or Enter to use defaults."

   If user types 'yes', ask:
   - "Provider for `designer` role? (claude / codex / gemini, default: claude)"
   - "Provider for `reviewer` role? (claude / codex / gemini, default: codex)"
   - "Provider for `executor` role? (claude / codex / gemini, default: claude)"
   - "Provider for `inspiration` role? (claude / codex / gemini, default: gemini)"

## Step 4.5: Optional Runtime Hooks (Full tier only)

Skip this step if TIER is Essential.

Forge ships installable shell hooks that run at agent lifecycle events. They live in `${CLAUDE_PLUGIN_ROOT}/templates/hooks/` and install **globally** into `~/.claude/hooks/` + `~/.claude/settings.json`. See `templates/hooks/README.md` for the full catalog.

First, list available hooks by reading the manifest:

```bash
jq -r '.hooks[] | "- " + .id + " (" + .event + ") — " + (.description.en)' \
  "${CLAUDE_PLUGIN_ROOT}/templates/hooks/manifest.json"
```

Then ask via AskUserQuestion:

> Install runtime hooks into `~/.claude/`? These run on every Claude Code / Codex session globally.
>
> Available now:
> - **project-context** — forces a "Project / Current stage" line at the top of every first reply (4-step fallback: README → manifest → tasks/todo → commits)
>
> What to install?
> - **all** — install every hook in the manifest
> - **project-context** — just the one above
> - **none** — skip (you can run `scripts/install-hook.sh` later)

Store answer as `HOOKS_CHOICE`.

If `HOOKS_CHOICE` is not "none", confirm before mutating the user's settings:

> About to run: `scripts/install-hook.sh ${HOOKS_CHOICE}`
>
> This will:
> 1. Copy hook script(s) to `~/.claude/hooks/`
> 2. Back up `~/.claude/settings.json` (timestamped)
> 3. Register the hook(s) under their declared event
>
> Hooks pick their output language at runtime by scanning your CLAUDE.md and `~/.claude/rules/` for CJK density — no install-time choice needed. To force a language later, export `FORGE_HOOK_LANG=zh` or `=en`.
>
> Proceed? (yes / no)

If user declines → set `HOOKS_CHOICE=none` and continue.

Defer actual installation to Step 6.5 (after files are written, so partial failures don't leave a half-configured machine).

## Step 4.6: Optional Crucible Install (Full tier only)

Skip this step if TIER is Essential.

Crucible is Forge's evolution-asset system. It installs at `~/.claude/crucible/` and gives the agent a place to record recurring errors (`failed-directions/<fp>.yaml`) and validated success flows (`golden-cases/<gc_id>.yaml`). See `templates/crucible/README.md` for the full design.

Pre-Flight Protocol (Section 18) only pays off once Crucible is installed — without the store, the agent's pre-flight grep finds nothing and the protocol degrades to "state extract only".

Ask via AskUserQuestion:

> Install Crucible into `~/.claude/crucible/`? Pairs with the `auto-evolve-collector` hook (Step 4.5). If you installed that hook and skip this step, the hook will create the directory on first error anyway — but without README, schemas, or example yamls.
>
> Options:
> - **with seeds** — install README + schemas + the worked-example pair (`failed-direction` `df53a88d1096` ⇄ `golden-case` `gc_example_001`). Best if you want a populated reference.
> - **empty** — install README + schemas only, no example data. Best if you prefer a clean slate.
> - **none** — skip. You can run `scripts/install-crucible.sh` later.

Store answer as `CRUCIBLE_CHOICE` (values: `"with-seeds"`, `"empty"`, or `"none"`).

If `CRUCIBLE_CHOICE` is not `"none"`, confirm before mutating the user's filesystem:

> About to run: `scripts/install-crucible.sh [--with-seeds]`
>
> This will:
> 1. Create `~/.claude/crucible/{failed-directions,golden-cases,schemas}/`
> 2. Copy `templates/crucible/README.md` and `templates/crucible/schemas/*.yaml`
> 3. (with-seeds only) Copy the worked-example yamls into the matching subdirs
> 4. Initialize git in the install dir + first commit (so lessons survive machine moves)
>
> Idempotent: README and schemas refresh on every run; user-edited data is never touched.
>
> Proceed? (yes / no)

If user declines → set `CRUCIBLE_CHOICE=none` and continue.

Defer actual installation to Step 6.6.

## Step 5: Generate Instruction File(s)

1. Determine output files based on TARGET:
   - Claude Code: generate `./CLAUDE.md`
   - Codex: generate `./AGENTS.md`
   - Both: generate both `./CLAUDE.md` and `./AGENTS.md`

2. Determine template path based on TARGET and TIER:
   - Claude Code Essential: `${CLAUDE_PLUGIN_ROOT}/templates/essential.md`
   - Claude Code Full: `${CLAUDE_PLUGIN_ROOT}/templates/full.md`
   - Codex Essential: `${CLAUDE_PLUGIN_ROOT}/templates/targets/codex/essential.md`
   - Codex Full: `${CLAUDE_PLUGIN_ROOT}/templates/targets/codex/full.md`

3. Read each required template file via the Read tool.

4. Replace all `{{VARIABLES}}` with collected values:
   - `{{USER_NAME}}` → user's name
   - `{{PLATFORM}}` → platform answer or auto-detected
   - `{{SHELL}}` → auto-detected shell (e.g. zsh, bash)
   - `{{PACKAGE_MANAGERS}}` → comma-separated detected tools (e.g. npm / pip / brew)
   - `{{EDITOR}}` → auto-detected or "unspecified"
   - `{{LANGUAGE_PREFERENCE}}` → language preference
   - `{{BRANCH_PREFIX}}` → `feature/` (default, unless user specified otherwise)
   - For Full tier also replace:
     - `{{DEFAULT_TEST_LEVEL}}` → chosen level (0–4)
     - `{{ROLE_DESIGNER}}` → designer provider
     - `{{ROLE_REVIEWER}}` → reviewer provider
     - `{{ROLE_EXECUTOR}}` → executor provider
     - `{{ROLE_INSPIRATION}}` → inspiration provider

5. **Verify**: scan each output for any remaining `{{`. If found, replace with sensible defaults or empty string, and note which variables were unresolved.

## Step 6: Write Instruction File(s)

For each output file (`CLAUDE.md` and/or `AGENTS.md`):

1. Check if the file exists in the current working directory.

2. If it **exists**: show a brief summary of what will change, then ask via AskUserQuestion:
   > `<file>` already exists. What would you like to do?
   > - **overwrite** — replace it directly
   > - **backup** — copy existing to `<file>.backup`, then write new
   > - **cancel** — abort without changes

   - If "cancel": skip this file and continue with any other selected target.
   - If "backup": copy `./<file>` → `./<file>.backup` via Bash, then write new file.
   - If "overwrite": write directly.

3. Write generated content via the Write tool.

4. If write fails: save to `./<file>.forge` instead and tell user:
   > Write failed. Content saved to `./<file>.forge`. Please copy it manually:
   > `cp ./<file>.forge ./<file>`

## Step 6.5: Install Selected Hooks

Skip this step if `HOOKS_CHOICE` from Step 4.5 is "none" or unset.

Run the installer via Bash:

```bash
"${CLAUDE_PLUGIN_ROOT}/scripts/install-hook.sh" "${HOOKS_CHOICE}"
```

Capture stdout/stderr. The installer prints one line per hook (`✓ installed: ...`, `✓ registered: ...`, plus a `verify:` line showing the first stdout line the hook will actually produce in this user's environment — useful sanity check on the runtime language detection).

Report to the user:

> Installed runtime hook(s):
> - `<id>` → `~/.claude/hooks/<marker>.sh`
>
> Settings backup at `~/.claude/settings.json.bak.<timestamp>`.
> Start a new agent session for the hook(s) to take effect.
>
> Language is detected at runtime. To force a language, export `FORGE_HOOK_LANG=zh` or `=en` in your shell profile before launching the agent.

If the installer exits non-zero:

> ⚠ Hook installation failed. The instruction file(s) were still written successfully.
>
> Common causes:
> - `jq` not installed → `brew install jq` (macOS) or your distro's package manager, then re-run:
>   `${CLAUDE_PLUGIN_ROOT}/scripts/install-hook.sh ${HOOKS_CHOICE}`
> - Permission denied on `~/.claude/` → check ownership
>
> To uninstall later: `${CLAUDE_PLUGIN_ROOT}/scripts/uninstall-hook.sh <id>`

## Step 6.6: Install Crucible

Skip this step if `CRUCIBLE_CHOICE` from Step 4.6 is `"none"` or unset.

Run the installer via Bash:

```bash
CRUCIBLE_FLAGS=""
if [[ "${CRUCIBLE_CHOICE}" == "with-seeds" ]]; then
  CRUCIBLE_FLAGS="--with-seeds"
fi
"${CLAUDE_PLUGIN_ROOT}/scripts/install-crucible.sh" ${CRUCIBLE_FLAGS}
```

Capture stdout/stderr. The installer prints:
- `✓ README.md + schemas/ refreshed`
- `✓ failed-directions/example.yaml seeded` and `✓ golden-cases/gc_example.yaml seeded` (only with `--with-seeds`)
- `✓ git initialized at ~/.claude/crucible` (unless `--no-git` or git missing)
- A `Next:` block with the splice + auto-evolve-collector pairing reminder

Report to the user:

> Installed Crucible at `~/.claude/crucible/`:
> - `README.md` + `schemas/` (always refreshed on rerun)
> - `failed-directions/example.yaml`, `golden-cases/gc_example.yaml` (only if seeded)
> - Git initialized — your accumulated lessons can be synced across machines via this repo.
>
> The Pre-Flight Protocol section in your generated `CLAUDE.md` / `AGENTS.md` already tells the agent to read this directory before high-risk work. Nothing further needed for the read path.
>
> For automatic write-back, install the `auto-evolve-collector` hook (if you didn't pick it in Step 4.5):
>
> `${CLAUDE_PLUGIN_ROOT}/scripts/install-hook.sh auto-evolve-collector`

If the installer exits non-zero:

> ⚠ Crucible installation failed. The instruction file(s) were still written successfully.
>
> Common causes:
> - Permission denied on `~/.claude/` → check ownership
> - `templates/crucible/` missing → re-clone the forge repo, then re-run:
>   `${CLAUDE_PLUGIN_ROOT}/scripts/install-crucible.sh [--with-seeds]`
>
> To uninstall (rename, not delete — preserves user data): `${CLAUDE_PLUGIN_ROOT}/scripts/uninstall-crucible.sh`

## Step 7: Recommend Enhancements

Print the following (do **NOT** install anything automatically):

```
Recommended workflow add-ons:

For Claude Code:
Compound Engineering (CE) — strategy, brainstorming, planning, review, product pulse, and knowledge compounding:
  /plugin marketplace add EveryInc/compound-engineering-plugin
  /plugin install compound-engineering

GSD — .planning state, codebase mapping, phase execution, verification, and shipping:
  npx get-shit-done-cc@latest

gstack — product/engineering/design/DX review, browser QA, Codex second opinion, and release gates:
  git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack
  cd ~/.claude/skills/gstack && ./setup

Waza — focused engineering habits: think, hunt, check, health, read, learn, write, and design:
  npx skills add tw93/Waza -a claude-code -g -y

Revolve — Research pipeline + CLAUDE.md auto-evolution:
  /plugin marketplace add https://github.com/eisen0419/revolve
  /plugin install revolve

For Codex:
Compound Engineering (CE) — install marketplace, agents, then activate in Codex TUI:
  codex plugin marketplace add EveryInc/compound-engineering-plugin
  bunx @every-env/compound-plugin install compound-engineering --to codex
  codex
  # inside Codex: run /plugins, install compound-engineering, then restart Codex

GSD — choose Codex when the installer asks for runtime. Codex CLI 0.130.0+ is recommended:
  npx get-shit-done-cc@latest

gstack — install Codex skills:
  git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/gstack
  cd ~/gstack && ./setup --host codex

Waza — focused engineering habits:
  npx skills add tw93/Waza -a codex -g -y

Route selection:
  - Small fixes: standalone Forge rules, CE ce-work, or GSD gsd-fast
  - CE-native work: ce-brainstorm -> ce-plan -> ce-work -> ce-code-review -> ce-compound
  - GSD-managed projects: gsd-map-codebase -> gsd-new-project -> discuss -> plan -> execute -> verify -> ship
  - Existing CE plan into GSD: forge-run <plan> as a bridge
  - Product/UI/DX/browser/release risk: add gstack office-hours/autoplan/qa/review gates
  - Focused habits: Waza think/hunt/check/health/read/learn/write/design
```

## Step 8: Completion

Report success:

> Forge setup complete!
>
> - File(s) written: [`./CLAUDE.md` and/or `./AGENTS.md`]
> - Target: [Claude Code / Codex / Both]
> - Tier: [Essential / Full]
> - Runtime hooks installed: [`<comma-separated ids>` / none]   ← omit this line if HOOKS_CHOICE was "none"
> - Crucible: [`installed at ~/.claude/crucible/ (with-seeds | empty)` / none]   ← omit this line if CRUCIBLE_CHOICE was "none"
>
> **Next steps:**
> 1. Review the generated instruction file(s) and adjust any preferences
> 2. Install recommended plugins above if desired
> 3. Start a new agent session so it reads the new instructions (and triggers any installed hooks)
