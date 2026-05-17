<div align="center" id="readme-top">

<img src="images/logo.png" alt="Forge logo" width="96">

![Forge Banner][banner]

[![License][license-badge]][license]
[![Claude Code][claude-badge]][claude-code]
[![Plugin][plugin-badge]][install-url]
[![English][lang-en-badge]][lang-en]
[![简体中文][lang-zh-badge]][lang-zh]

**Router-first instruction templates for Claude Code, Codex, and multi-agent engineering workflows.**

Forge generates practical `CLAUDE.md` and `AGENTS.md` files, keeps them short, and routes work across standalone agent rules, Compound Engineering, GSD, gstack, Waza, and Revolve.

[Quick Start][quick-start] •
[Routing Model][routing-model] •
[Templates][templates] •
[Testing][testing]

</div>

<br>

<details open>
<summary><kbd>Table of Contents</kbd></summary>

- [Why Forge][why-forge]
- [Quick Start][quick-start]
- [Tiers][tiers]
- [Routing Model][routing-model]
- [Templates][templates]
- [Workflow Add-ons][workflow-add-ons]
- [Testing][testing]
- [Repository Layout][repository-layout]
- [Built With][built-with]
- [Acknowledgments][acknowledgments]
- [License][license-section]

</details>

<br>

## Why Forge

AI coding agents are powerful, but their default behavior drifts:

- They over-plan small edits and under-plan risky changes.
- They add dependencies or migrations when a local fix would do.
- They claim tests pass without fresh evidence.
- They treat every workflow tool as if it should own every task.

Forge turns your project instruction file into a **router and guardrail layer**. It tells the agent what to read, what not to introduce, when to escalate, how to verify, and which specialized workflow should handle the job.

The goal is not a giant prompt. The goal is a short instruction surface that an agent can follow under pressure.

## Quick Start

### Claude Code Plugin

```text
/plugin marketplace add https://github.com/eisen0419/forge
/plugin install forge
/forge-setup
```

The setup wizard can generate:

- `CLAUDE.md` for Claude Code
- `AGENTS.md` for Codex
- both files from the same Forge tier

### Manual Install

For Claude Code:

```bash
cp templates/full.md CLAUDE.md
```

For Codex:

```bash
cp templates/targets/codex/full.md AGENTS.md
```

Then replace the `{{VARIABLES}}` placeholders with your project details.

## Tiers

![Forge tiers and routing][tier-diagram]

| Tier | Best for | What it gives you |
|------|----------|-------------------|
| Essential | New repos, smaller projects, first-time agent setup | Context pointers, task routing, forbidden changes, verification, git and safety rules |
| Full | Multi-agent workflows and higher-risk projects | Essential plus CE/GSD/gstack/Waza routing, blast-radius checks, local instruction guidance, hooks/memory guidance, and role mapping |

Both tiers are intentionally compact. Full templates stay under roughly 200 lines.

## Routing Model

Forge does not assume one universal pipeline. It chooses the shortest route that preserves quality.

| Situation | Recommended route |
|-----------|-------------------|
| Tiny fix or one-file change | Standalone Forge rules, CE `/ce-work`, or GSD `/gsd-fast` |
| Feature shaping or product decision | CE strategy/brainstorm/plan, or Waza `/think` for a lean decision-complete plan |
| Existing GSD-managed project | GSD map/new-project/discuss/plan/execute/verify/ship loop |
| CE plan that should be executed by GSD | `/forge-run <plan>` as the CE-plan-to-GSD bridge |
| Product scope, UI quality, browser QA, release confidence | gstack office-hours, autoplan, QA, design review, DX review, or ship gates |
| Focused engineering habit | Waza `/think`, `/hunt`, `/check`, `/health`, `/read`, `/learn`, `/write`, or `/design` |
| Shared API, schema, auth, payments, CI, dependencies | Forge blast-radius check first, then targeted verification |

Waza is a **Focused engineering habit** layer. It is not a GSD-style project state machine or a gstack-style release factory. Use it when the task is narrow: root-cause debugging, diff review, release follow-through, agent health, URL/PDF reading, research, prose, or UI craft.

`/forge-run` is deliberately narrow too. It is only the bridge from an existing CE plan into GSD execution. It should not become the default for every medium or large task.

## Templates

Forge templates are router-first instruction files, not architecture dumps.

| Section | Essential | Full | Purpose |
|---------|-----------|------|---------|
| Context Pointers | Yes | Yes | Point to README, architecture docs, decisions, solutions, and `.planning/` only when needed |
| Task Routing | Yes | Yes | Keep small tasks light and risky tasks structured |
| Do Not Introduce | Yes | Yes | Block unapproved dependencies, package managers, CI, schema, migrations, and secret-bearing state |
| Verification Rules | Yes | Yes | Prevent unsupported "done" claims |
| Coding Standards | Yes | Yes | Soft size/complexity targets with an explicit escape hatch for inherent-size code (state machines, dispatch tables, fixtures) |
| Multi-Agent Router | No | Yes | Choose across Forge, CE, GSD, gstack, Waza, and Revolve |
| Blast Radius | No | Yes | Search callers and dependents before touching shared interfaces |
| Local Instruction Files | No | Yes | Add short local guardrails for auth, payments, infra, migrations, generated SDKs |
| Hooks And Memory | No | Yes | Keep hooks objective; persist `tasks/lessons.md` self-improvement loop; store durable learning in `docs/` |

Recommended local files:

- Root `CLAUDE.md` or `AGENTS.md`: routing, guardrails, verification
- Local `CLAUDE.md` / `AGENTS.md` in sensitive subtrees: local risks and required checks
- `docs/solutions/`: reusable fixes and lessons
- `docs/decisions/`: architecture decisions
- `.planning/`: GSD project state when GSD owns execution

## Runtime Hooks

Templates encode static rules. Hooks encode **runtime behaviour** — actual scripts the agent runtime executes at lifecycle events (`SessionStart`, future others).

Forge ships a manifest-driven hook system:

```bash
# Install one hook (globally into ~/.claude/hooks + ~/.claude/settings.json)
scripts/install-hook.sh project-context

# Install everything in the manifest
scripts/install-hook.sh all

# Uninstall
scripts/uninstall-hook.sh project-context
```

| Hook ID | Event | Language | What it does |
|---------|-------|----------|--------------|
| [`project-context`](./templates/hooks/project-context/) | `SessionStart` | Adaptive (CJK density scan) | Before every first reply, makes the agent emit one line: `Project: <X>. Current stage: <Y>.` using a 4-step fallback chain (README → manifest description → `tasks/todo.md` → recent commits). Override language with `FORGE_HOOK_LANG=zh|en`. |

The `forge-setup` wizard offers optional hook installation at Step 4.5. See [`templates/hooks/README.md`](./templates/hooks/README.md) for the manifest schema and the three-step recipe for adding your own hook.

## Workflow Add-ons

Forge works alone, but Full tier can route to these systems when they are installed.

| Add-on | Install for Claude Code | Install for Codex | Best fit |
|--------|-------------------------|-------------------|----------|
| [Compound Engineering][ce-plugin] | `/plugin marketplace add EveryInc/compound-engineering-plugin` then `/plugin install compound-engineering` | `codex plugin marketplace add EveryInc/compound-engineering-plugin`, then `bunx @every-env/compound-plugin install compound-engineering --to codex` | Strategy, ideation, planning, review, product pulse, knowledge compounding |
| [GSD][gsd-repo] | `npx get-shit-done-cc@latest` | `npx get-shit-done-cc@latest` and choose Codex | Durable `.planning/`, codebase mapping, phase execution, verification, shipping |
| [gstack][gstack-repo] | `git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack && cd ~/.claude/skills/gstack && ./setup` | `git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/gstack && cd ~/gstack && ./setup --host codex` | Product challenge, UI/design/DX review, browser QA, release confidence |
| [Waza][waza-repo] | `npx skills add tw93/Waza -a claude-code -g -y` or `/plugin marketplace add tw93/Waza` then `/plugin install waza@waza` | `npx skills add tw93/Waza -a codex -g -y` | Focused habits: think, hunt, check, health, read, learn, write, design |
| [Revolve][revolve-repo] | `/plugin marketplace add https://github.com/eisen0419/revolve` then `/plugin install revolve` | Use the repo directly as a companion workflow | Research pipeline and instruction evolution |

The Full template explicitly names CE/GSD/gstack/Waza so the agent can pick the right tool instead of stacking all of them.

## Testing

Forge includes a routing-system regression test:

```bash
node scripts/test-forge-routing.mjs
```

The test validates:

- README and README_CN add-on parity
- CE/GSD/gstack/Waza route coverage
- `/forge-run` boundaries
- template size budgets
- plugin metadata
- rendered `CLAUDE.md` and `AGENTS.md` artifacts

The test plan lives at [docs/forge-routing-system-test.md](docs/forge-routing-system-test.md).

## Repository Layout

```text
.
├── templates/
│   ├── essential.md
│   ├── full.md
│   └── targets/codex/
├── skills/
│   ├── forge-setup/
│   └── forge-run/
├── docs/
│   └── forge-routing-system-test.md
├── scripts/
│   └── test-forge-routing.mjs
└── images/
```

## Built With

| Project | Role in Forge |
|---------|---------------|
| [Claude Code][claude-code] | Runtime for `CLAUDE.md` and plugin skills |
| [Codex](https://openai.com/codex/) | Runtime for `AGENTS.md` |
| [Compound Engineering][ce-plugin] | Strategy, planning, review, and knowledge-compounding reference |
| [GSD][gsd-repo] | Durable execution and phase-planning companion |
| [gstack][gstack-repo] | Product, design, DX, browser QA, and release gate companion |
| [Waza][waza-repo] | Focused engineering habit companion |
| [Revolve][revolve-repo] | Research and instruction-evolution companion |

## Acknowledgments

- [Kieran Klaassen](https://github.com/kieranklaassen) and [Every](https://every.to) for [Compound Engineering][ce-plugin]
- [Tw93](https://github.com/tw93) for [Waza][waza-repo]
- [Anthropic](https://anthropic.com) for Claude Code and the `CLAUDE.md` instruction layer
- [Othneil Drew](https://github.com/othneildrew) for [Best-README-Template][readme-template]
- [EverMind AI](https://github.com/EverMind-AI) for README visual inspiration from EverMemOS

## License

[MIT][license]

<!-- Navigation -->
[readme-top]: #readme-top
[why-forge]: #why-forge
[quick-start]: #quick-start
[tiers]: #tiers
[routing-model]: #routing-model
[templates]: #templates
[workflow-add-ons]: #workflow-add-ons
[testing]: #testing
[repository-layout]: #repository-layout
[built-with]: #built-with
[acknowledgments]: #acknowledgments
[license-section]: #license

<!-- Images -->
[banner]: images/banner.png
[tier-diagram]: images/tiers.png

<!-- Badges -->
[license-badge]: https://img.shields.io/badge/License-MIT-blue?style=flat-square
[claude-badge]: https://img.shields.io/badge/Claude_Code-Plugin-7C3AED?style=flat-square
[plugin-badge]: https://img.shields.io/badge/Install-Plugin-F97316?style=flat-square
[lang-en-badge]: https://img.shields.io/badge/English-lightgrey?style=flat-square
[lang-zh-badge]: https://img.shields.io/badge/简体中文-lightgrey?style=flat-square

<!-- Links -->
[license]: LICENSE
[claude-code]: https://claude.ai/code
[install-url]: https://github.com/eisen0419/forge
[lang-en]: README.md
[lang-zh]: README_CN.md
[ce-plugin]: https://github.com/EveryInc/compound-engineering-plugin
[gsd-repo]: https://github.com/gsd-build/get-shit-done
[gstack-repo]: https://github.com/garrytan/gstack
[waza-repo]: https://github.com/tw93/Waza
[revolve-repo]: https://github.com/eisen0419/revolve
[readme-template]: https://github.com/othneildrew/Best-README-Template
