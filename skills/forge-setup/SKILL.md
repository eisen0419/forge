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
> - **Full** — Power users. Complete methodology: circuit breaker error recovery, role system (designer/reviewer/executor/inspiration), knowledge compounding via `/ce-compound`, peer review framework, subagent strategy, and testing discipline.
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

## Step 7: Recommend Enhancements

Print the following (do **NOT** install anything automatically):

```
Recommended plugins to enhance your workflow:

For Claude Code:
Compound Engineering (CE) — AI-powered planning, review, and knowledge management:
  claude plugin marketplace add https://github.com/EveryInc/compound-engineering-plugin
  claude plugin install compound-engineering

Revolve — Research pipeline + CLAUDE.md auto-evolution:
  claude plugin marketplace add https://github.com/eisen0419/revolve
  claude plugin install revolve

For Codex:
  Use the generated AGENTS.md as the project instruction entrypoint.
  Add project-local Codex skills later if you want command-like workflows.
```

## Step 8: Completion

Report success:

> Forge setup complete!
>
> - File(s) written: [`./CLAUDE.md` and/or `./AGENTS.md`]
> - Target: [Claude Code / Codex / Both]
> - Tier: [Essential / Full]
>
> **Next steps:**
> 1. Review the generated instruction file(s) and adjust any preferences
> 2. Install recommended plugins above if desired
> 3. Start a new agent session so it reads the new instructions
