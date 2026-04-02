<div align="center" id="readme-top">

<!-- BANNER: 替换为你的 banner 图片 -->
![Forge Banner][banner]

[![License][license-badge]][license]
[![Claude Code][claude-badge]][claude-code]
[![Plugin][plugin-badge]][install-url]

**AI-Assisted Development Workflow Starter Kit for Claude Code**

Battle-tested CLAUDE.md templates — task routing, error recovery, quality gates, and knowledge compounding.

[Quick Start][quick-start] •
[What's Inside][whats-inside] •
[Customization][customization]

[![English][lang-en-badge]][lang-en]

</div>

<br>

<details open>
<summary><kbd>Table of Contents</kbd></summary>

- [Why Forge?][why-forge]
- [Two Tiers][two-tiers]
- [Quick Start][quick-start]
- [What's Inside][whats-inside]
- [Works With][works-with]
- [Customization][customization]
- [Contributing][contributing]
- [License][license-section]

</details>

<br>

## Why Forge?

CLAUDE.md is powerful, but building one from scratch takes months of trial and error. Most users never discover patterns like circuit breakers, blast radius protocols, or compact recovery discipline.

Forge gives you the skeleton. You grow the muscle through real use.

### Why Not Just Copy Someone's CLAUDE.md?

| Random CLAUDE.md | Forge |
|-----------------|-------|
| Mixes methodology with personal config | Extracts universal patterns only |
| One-size-fits-all | Two tiers: Essential (newcomers) + Full (power users) |
| Copy and hope | `/forge-setup` asks your stack, generates customized output |
| Unexplained rules | Every rule has inline comments explaining **why** |

<div align="right">

[![][back-to-top]][readme-top]

</div>

## Two Tiers

<!-- TIER COMPARISON: 替换为你的对比图 -->
![Tier Comparison][tier-diagram]

| | Essential | Full |
|---|-----------|------|
| **For** | Newcomers to Claude Code | Power users with multi-plugin setups |
| **Sections** | 10 core sections | All 17 sections |
| **Includes** | Task routing, quality gates, verification, git, safety | Everything in Essential + circuit breaker, role system, peer review, subagent strategy, blast radius, knowledge compounding |
| **Setup time** | ~5 min | ~10 min |

<div align="right">

[![][back-to-top]][readme-top]

</div>

## Quick Start

### With Plugin (Recommended)

```bash
claude plugin marketplace add https://github.com/eisen0419/forge
claude plugin install forge
```

Then run `/forge-setup` in any project.

### Without Plugin

1. Copy `templates/essential.md` or `templates/full.md` to your project as `CLAUDE.md`
2. Replace all `{{VARIABLES}}` with your actual values
3. Done

<div align="right">

[![][back-to-top]][readme-top]

</div>

## What's Inside

| Section | Tier | What it does |
|---------|------|-------------|
| Decision Framework | Both | Three questions before any change — cut scope creep early |
| Task Routing | Both | Route tasks to right workflow — skip ceremony for trivial changes |
| Error Recovery | Full | Circuit breaker: same approach fails twice → must re-plan |
| Compact Recovery | Full | What to do when Claude's context gets compressed mid-session |
| Quality Gates | Both | Testing strategy tied to blast radius, not dogma |
| Verification | Both | Delivery gate — no claiming done without evidence |
| Blast Radius | Full | Assess impact before touching exported interfaces |
| Role System | Full | Map abstract roles (designer, reviewer) to AI providers |
| Peer Review | Full | Plan review + code review checkpoints |
| Subagent Strategy | Full | When to spawn subagents, model selection by complexity |
| Knowledge Compounding | Full | Extract lessons worth keeping into `docs/solutions/` |
| Git Conventions | Both | Branch naming, commit format, hard prohibitions |
| Safety Rules | Both | No destructive commands, no hardcoded secrets |
| Task Management | Both | `tasks/todo.md` discipline: plan before code, track as you go |

<div align="right">

[![][back-to-top]][readme-top]

</div>

## Works With

| Tool | Status | What it adds |
|------|--------|-------------|
| Standalone | Works | No plugins needed — methodology lives in CLAUDE.md |
| [Compound Engineering][ce-plugin] | Enhanced | `/ce:plan`, `/ce:work`, `/ce:review`, `/ce:compound` |
| gstack | Enhanced | Browser QA, CEO/eng plan review |
| [Revolve][revolve-repo] | Enhanced | Research pipeline + CLAUDE.md auto-evolution |

<div align="right">

[![][back-to-top]][readme-top]

</div>

## Customization

Edit any section. Remove what you don't need. Add project-specific rules. The inline comments explain each section's purpose so you know what you're trading off.

**Recommended path:** Start with Essential. Promote to Full when you feel the gaps.

<div align="right">

[![][back-to-top]][readme-top]

</div>

## Contributing

Issues, feature requests, and PRs welcome.

<div align="right">

[![][back-to-top]][readme-top]

</div>

## License

[MIT][license]

<!-- Navigation -->
[readme-top]: #readme-top
[why-forge]: #why-forge
[two-tiers]: #two-tiers
[quick-start]: #quick-start
[whats-inside]: #whats-inside
[works-with]: #works-with
[customization]: #customization
[contributing]: #contributing
[license-section]: #license

<!-- Images — 替换为你的实际图片 URL -->
[banner]: images/logo.jpg
[tier-diagram]: images/tiers.jpg
[back-to-top]: https://img.shields.io/badge/-Back_to_top-gray?style=flat-square

<!-- Badges -->
[license-badge]: https://img.shields.io/badge/License-MIT-blue?style=flat-square
[claude-badge]: https://img.shields.io/badge/Claude_Code-Plugin-7C3AED?style=flat-square
[plugin-badge]: https://img.shields.io/badge/Install-Plugin-F97316?style=flat-square
[lang-en-badge]: https://img.shields.io/badge/English-lightgrey?style=flat-square

<!-- Links -->
[license]: LICENSE
[claude-code]: https://claude.ai/code
[install-url]: https://github.com/eisen0419/forge
[lang-en]: README.md
[ce-plugin]: https://github.com/EveryInc/compound-engineering-plugin
[revolve-repo]: https://github.com/eisen0419/revolve
