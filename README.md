<div align="center" id="readme-top">

![Forge Banner][banner]

[![License][license-badge]][license]
[![Claude Code][claude-badge]][claude-code]
[![Plugin][plugin-badge]][install-url]

**AI-Assisted Development Workflow Starter Kit for Claude Code and Codex**

Battle-tested agent instruction templates -- `CLAUDE.md`, `AGENTS.md`, task routing, context pointers, quality gates, and knowledge compounding.

[Quick Start][quick-start] •
[Usage Examples][usage-examples] •
[What's Inside][whats-inside] •
[Customization][customization]

Sister project: **[Revolve][revolve-repo]** -- self-evolving AI research architecture

[![English][lang-en-badge]][lang-en]
[![简体中文][lang-zh-badge]][lang-zh]

</div>

<br>

<details open>
<summary><kbd>Table of Contents</kbd></summary>

- [Why Forge?][why-forge]
- [Two Tiers][two-tiers]
- [Quick Start][quick-start]
- [Usage Examples][usage-examples]
- [What's Inside][whats-inside]
- [Works With][works-with]
- [Customization][customization]
- [Built With][built-with]
- [Acknowledgments][acknowledgments]
- [Contributing][contributing]
- [License][license-section]

</details>

<br>

## Why Forge?

**Without Forge:** You ask Claude to refactor a module. It modifies 3 exported functions without checking callers. Tests pass locally, but 2 downstream services break in production. You spend an hour debugging what went wrong.

**With Forge:** Claude reads your CLAUDE.md blast radius protocol: *"Before modifying any exported function, grep all callers and assess impact."* It finds 2 callers, adds them to the verification list, and tests everything before claiming done.

That's one rule. Forge gives you a compact set of battle-tested patterns -- extracted from hundreds of real sessions, not invented in a vacuum.

Agent instruction files are powerful, but building a good one from scratch takes months of trial and error. Most developers never discover patterns like context pointers, do-not-introduce guardrails, local instruction files, objective hooks, or blast radius protocols. Forge gives you the skeleton. You grow the muscle through real use.

### Why Not Just Copy Someone's Instruction File?

| Random instruction file | Forge |
|-----------------|-------|
| Mixes methodology with personal config | Extracts universal patterns only |
| One-size-fits-all | Two tiers: Essential (newcomers) + Full (power users) |
| Copy and hope | `/forge-setup` asks your stack, generates customized output |
| Unexplained rules | Short, operational rules with pointers to deeper docs |

<div align="right">

[![][back-to-top]][readme-top]

</div>

## Two Tiers

![Tier Comparison][tier-diagram]

| | Essential | Full |
|---|-----------|------|
| **For** | Newcomers to Claude Code | Power users with multi-plugin setups |
| **Shape** | Compact guardrails | Router-first, under ~200 lines |
| **Includes** | Task routing, context pointers, do-not-introduce list, verification, git, safety | Everything in Essential + multi-agent routing, specialized flow priority, blast radius, local instruction files, hooks/memory guidance |
| **Setup time** | ~5 min | ~10 min |

<div align="right">

[![][back-to-top]][readme-top]

</div>

## Quick Start

### With Plugin (Recommended)

Inside Claude Code:

```text
/plugin marketplace add https://github.com/eisen0419/forge
/plugin install forge
```

Then run `/forge-setup` in any project. The wizard can generate `CLAUDE.md`, `AGENTS.md`, or both:

```
> /forge-setup

? Which agent target would you like to configure?
  - Claude Code — generate CLAUDE.md
  - Codex — generate AGENTS.md
  - Both — generate both files
> Both

? Which Forge tier would you like?
  - Essential — Core rules only: coding standards, task management, git, safety
  - Full — Router-first methodology: context pointers, forbidden changes, multi-agent routes
> Essential

? What's your name?
> Alice

? What's your primary platform? (macOS / Linux / Windows+WSL)
> macOS

? Preferred output language for agent responses?
> English

? Git commit style? (default: conventional commits)
> [Enter]

Detecting environment... zsh, npm, VS Code

Generating Essential instruction files...
Written to ./CLAUDE.md and ./AGENTS.md

Recommended plugins to enhance your workflow:
  /plugin marketplace add EveryInc/compound-engineering-plugin
  /plugin install compound-engineering
```

### Without Plugin

For Claude Code:

1. Copy `templates/essential.md` or `templates/full.md` to your project as `CLAUDE.md`
2. Replace all `{{VARIABLES}}` with your actual values
3. Done

For Codex:

1. Copy `templates/targets/codex/essential.md` or `templates/targets/codex/full.md` to your project as `AGENTS.md`
2. Replace all `{{VARIABLES}}` with your actual values
3. Done

### Optional workflow add-ons

Forge works without add-ons, but Full tier can route to these systems when installed:

| Add-on | Claude Code | Codex |
|--------|-------------|-------|
| CE | Run `/plugin marketplace add EveryInc/compound-engineering-plugin`, then `/plugin install compound-engineering` inside Claude Code | Run `codex plugin marketplace add EveryInc/compound-engineering-plugin`, then `bunx @every-env/compound-plugin install compound-engineering --to codex`, then install `compound-engineering` from Codex `/plugins` |
| GSD | Run `npx get-shit-done-cc@latest` and choose Claude Code | Run `npx get-shit-done-cc@latest` and choose Codex. Codex CLI 0.130.0+ is recommended |
| gstack | `git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/.claude/skills/gstack && cd ~/.claude/skills/gstack && ./setup` | `git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git ~/gstack && cd ~/gstack && ./setup --host codex` |

<div align="right">

[![][back-to-top]][readme-top]

</div>

## Usage Examples

### Starting a new project

You just initialized a new repo and want Claude to follow consistent patterns from day one.

```
> /forge-setup
```

Pick Essential tier. In 2 minutes you have a `CLAUDE.md` or `AGENTS.md` with task routing, git conventions, and safety rules. Your agent immediately starts routing tasks correctly -- small fixes go straight to implementation, multi-step features get a plan first.

### Junior developer with Essential tier

You're new to AI coding agents and don't want to be overwhelmed. Essential gives you a compact set of rules that cover the fundamentals:

- **Task routing** prevents agents from over-engineering a typo fix
- **Verification discipline** stops agents from claiming "tests pass" without running them
- **Safety rules** block destructive commands like `rm -rf` or `git push --force`
- **Git conventions** enforce consistent commit messages across the team

No plugins required. Just a `CLAUDE.md` or `AGENTS.md` file in your repo.

### Power user with Full tier + plugins

You're running Claude Code or Codex with a multi-agent workflow. Full tier adds:

- **Context pointers** -- point agents to docs only when needed, instead of loading every architectural detail upfront
- **Do-not-introduce list** -- prevent unapproved dependencies, frameworks, schemas, CI, or secret-bearing state
- **Role system** -- map abstract roles (designer, reviewer) to AI providers
- **Blast radius protocol** -- before touching any exported function, the agent greps all callers and adds them to the verification list
- **Local instruction guidance** -- put extra guardrails in sensitive subtrees such as auth, payments, infra, or migrations
- **Hooks and memory guidance** -- keep hooks objective and store long-term learning in project artifacts
- **Knowledge compounding** -- hard-won debugging lessons get saved to `docs/solutions/` so future sessions don't repeat the same mistakes

This tier works standalone, and it can also route work across CE, GSD, and gstack. Use CE for strategy, brainstorming, planning, review, and knowledge compounding; use GSD when a project needs durable `.planning/` state and phase-based execution; use gstack when product scope, design quality, DX, browser QA, or release confidence matter.

<div align="right">

[![][back-to-top]][readme-top]

</div>

## What's Inside

| Section | Tier | What it does |
|---------|------|-------------|
| Context Pointers | Both | Keep instruction files short by pointing to docs only when needed |
| Decision Framework | Both | Three questions before any change -- cut scope creep early |
| Task Routing | Both | Route tasks to right workflow -- skip ceremony for trivial changes |
| Do Not Introduce | Both | Block unapproved dependencies, frameworks, CI, schema, and secret-bearing changes |
| Multi-Agent Workflow Router | Full | Choose the right route across CE, GSD, gstack, or standalone Forge |
| Specialized Flow Priority | Full | Prefer CE/GSD/gstack for debug, TDD, verification, and review; use Superpowers only as fallback |
| Verification | Both | Delivery gate -- no claiming done without evidence |
| Blast Radius | Full | Assess impact before touching exported interfaces |
| Local Instruction Files | Full | Add local `CLAUDE.md` / `AGENTS.md` guardrails for sensitive subtrees |
| Hooks And Memory | Full | Use hooks for objective checks and docs for durable memory |
| Role System | Full | Map abstract roles (designer, reviewer) to AI providers |
| Knowledge Compounding | Full | Extract lessons worth keeping into `docs/solutions/` |
| Git Conventions | Both | Branch naming, commit format, hard prohibitions |
| Safety Rules | Both | No destructive commands, no hardcoded secrets |

### Multi-Agent Route Matrix

Forge no longer assumes one universal pipeline. Pick the shortest route that matches the work:

| Situation | Recommended route |
|-----------|-------------------|
| Small fix or one-file change | Standalone Forge rules, CE `/ce-work`, or GSD `/gsd-fast` |
| Standard feature with CE installed | `/ce-strategy` if needed → `/ce-brainstorm` → `/ce-plan` → `/ce-work` → `/ce-code-review` → `/ce-compound` |
| Existing larger codebase managed by GSD | `/gsd-map-codebase` → `/gsd-new-project` → `/gsd-discuss-phase` → `/gsd-plan-phase` → `/gsd-execute-phase` → `/gsd-verify-work` → `/gsd-ship` |
| Existing CE plan that should run through GSD | `/ce-plan` → `/forge-run <plan>` → `/gsd-verify-work` → `/ce-code-review` or `/gsd-code-review` |
| Product, UI, DX, browser QA, or release risk | gstack `/office-hours` or `/autoplan` before implementation; `/qa`, `/design-review`, `/devex-review`, or `/ship` before release |

`/forge-run` is intentionally narrow: it is the CE-plan-to-GSD bridge. It is useful when you already have a CE plan and want GSD's native phase planning and wave execution, but it is not the default path for every medium or large task.

### Instruction File Best Practices

Forge templates follow a router-first style:

| Practice | How Forge applies it |
|----------|----------------------|
| Keep it short | Full templates stay under ~200 lines and avoid long architecture dumps |
| Make rules testable | Rules say what to run, what not to change, or what evidence is required |
| Use pointers | Architecture, decisions, solutions, and GSD state live in docs, not in the instruction file |
| Name forbidden changes | `Do Not Introduce` blocks unapproved dependencies, frameworks, CI, schema, and secret-bearing state |
| Use local guardrails | Add local `CLAUDE.md` / `AGENTS.md` files for auth, billing, payments, infra, migrations, or generated SDKs |
| Keep hooks objective | Use hooks for dependency/schema/CI warnings and verification prompts, not subjective judgment |
| Store memory in artifacts | Prefer `docs/solutions/`, `docs/decisions/`, `.planning/`, and CE compound notes over a giant instruction file |

### Key Rules in Practice

**Task Routing** automatically matches effort to task size:

```
You: "fix the typo in the footer"
Claude: [routes as Lightweight -- direct fix, no planning overhead]

You: "add user authentication with OAuth"
Claude: [routes as Medium/Large -- starts with /ce-plan, identifies 6 subtasks,
         asks which OAuth provider before writing a line of code]
```

**Do Not Introduce** prevents surprise stack drift:

```
You: "add a small CSV export"
Claude: [checks Do Not Introduce]
  No new CSV library without approval.
  Uses existing stdlib / project helper instead.
```

Without this rule, agents often add "helpful" dependencies, test runners, or build tools that do not fit the project.

**Verification Discipline** eliminates phantom success claims:

```
Without Forge:
  Claude: "Tests pass!" (never actually ran tests)

With Forge:
  Claude: runs `npm test`
  Output: 47 passed, 0 failed, 2 skipped
  Claude: "47 tests passed. 2 skipped tests are unrelated date-formatting
           tests marked as platform-specific. Safe to commit."
```

**Blast Radius Protocol** catches breaking changes before they ship:

```
You: "rename the getUserById function to findUser"

Claude: [greps callers first]
  Found 4 callers:
    - src/api/routes/users.ts:23
    - src/api/routes/admin.ts:41
    - src/services/auth.ts:87
    - tests/integration/user.test.ts:12

  Updating all 4 call sites + the function definition.
  Running tests for affected modules...
```

<div align="right">

[![][back-to-top]][readme-top]

</div>

## Works With

| Tool | Status | What it adds |
|------|--------|-------------|
| Standalone | Works | No plugins needed -- methodology lives in `CLAUDE.md` or `AGENTS.md` |
| Codex | Works | Use `templates/targets/codex/*` to generate an `AGENTS.md` workflow file |
| [Compound Engineering][ce-plugin] | Enhanced | Strategy, ideation, brainstorming, planning, execution, review, product pulse, and knowledge compounding |
| [GSD][gsd-repo] | Enhanced | Codebase mapping, `.planning/` state, phase planning/execution, workstreams, verification, and shipping |
| [gstack][gstack-repo] | Enhanced | Product and scope challenge, engineering/design/DX review, browser QA, Codex second opinion, and release gates |
| [Revolve][revolve-repo] | Enhanced | Research pipeline + CLAUDE.md auto-evolution |

<div align="right">

[![][back-to-top]][readme-top]

</div>

## Customization

Every section in the generated CLAUDE.md or AGENTS.md is independent. Remove what you don't need, adjust thresholds, and add project-specific rules. Keep the main file short; use pointers to deeper docs.

### Remove a section

Just delete it. The other sections don't depend on it. If you do not use CE, GSD, or gstack, remove those route rows and keep the standalone Forge workflow.

### Adjust thresholds

Task routing defaults to "3+ steps" as the trigger for full planning. If you want less ceremony, change it:

```markdown
| **Medium/Large** | 5+ steps, architecture decisions | Plan -> implement -> review |
```

The `Do Not Introduce` list is intentionally generic. Add project-specific forbidden choices:

```markdown
- Do not add Redux; this app uses Zustand.
- Do not add Jest; this repo uses Vitest.
- Do not create new migrations without explicit approval.
```

### Add project-specific rules

Add your own sections anywhere in the file:

```markdown
## API Conventions
- All endpoints return `{ data, error, meta }` envelope
- Use cursor-based pagination for list endpoints
- Rate limit: 100 req/min per API key, return 429 with Retry-After header

## Database Rules
- All migrations must be reversible
- No raw SQL in application code -- use the query builder
- Index any column used in WHERE or JOIN clauses
```

### Recommended path

Start with Essential. Use it for a week. When you need CE/GSD/gstack routing, local guardrails, hooks guidance, or stronger blast-radius rules, promote to Full.

<div align="right">

[![][back-to-top]][readme-top]

</div>

## Built With

Forge's methodology is extracted from and works alongside these projects:

| Project | Description | Role in Forge |
|---------|-------------|---------------|
| [Claude Code][claude-code] | Anthropic's AI coding CLI | Runtime -- CLAUDE.md is Claude Code's persistent instruction layer |
| [Compound Engineering][ce-plugin] | AI-powered development workflow plugin by Kieran Klaassen / Every | Methodology source -- Forge's task routing, quality gates, and review patterns are inspired by CE's workflow |
| [GSD][gsd-repo] | Spec-driven project workflow for many coding agents | Execution companion -- durable planning state, phase execution, verification, and shipping workflows |
| [gstack][gstack-repo] | Garry Tan's AI software factory workflow | Review companion -- product/engineering/design/DX gates, browser QA, and release discipline |
| [Revolve][revolve-repo] | Self-evolving AI research architecture | Recommended companion -- automates the "Evolve CLAUDE.md" step in the flywheel |
| [Best-README-Template][readme-template] | Popular README template by Othneil Drew | README structure and visual patterns |

<div align="right">

[![][back-to-top]][readme-top]

</div>

## Acknowledgments

- [Kieran Klaassen](https://github.com/kieranklaassen) and [Every](https://every.to) -- for [Compound Engineering][ce-plugin], the workflow methodology that Forge extracts and generalizes. CE's task routing, quality gates, review discipline, and knowledge compounding patterns are foundational references for Forge's templates
- [Anthropic](https://anthropic.com) -- for Claude Code and the CLAUDE.md instruction system that makes workflow-as-code possible
- [Othneil Drew](https://github.com/othneildrew) -- for [Best-README-Template][readme-template], the README layout inspiration
- [EverMind AI](https://github.com/EverMind-AI) -- for [EverMemOS](https://github.com/EverMind-AI/EverMemOS), README visual design reference

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
[usage-examples]: #usage-examples
[whats-inside]: #whats-inside
[works-with]: #works-with
[customization]: #customization
[built-with]: #built-with
[acknowledgments]: #acknowledgments
[contributing]: #contributing
[license-section]: #license

<!-- Images -->
[banner]: images/banner.jpg
[tier-diagram]: images/tiers.jpg
[back-to-top]: https://img.shields.io/badge/-Back_to_top-gray?style=flat-square

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
[revolve-repo]: https://github.com/eisen0419/revolve
[gsd-repo]: https://github.com/gsd-build/get-shit-done
[gstack-repo]: https://github.com/garrytan/gstack
[readme-template]: https://github.com/othneildrew/Best-README-Template
