<div align="center" id="readme-top">

![Forge Banner][banner]

[![License][license-badge]][license]
[![Claude Code][claude-badge]][claude-code]
[![Plugin][plugin-badge]][install-url]

**AI-Assisted Development Workflow Starter Kit for Claude Code**

Battle-tested CLAUDE.md templates -- task routing, error recovery, quality gates, and knowledge compounding.

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

That's one rule. Forge gives you 17 sections of these battle-tested patterns -- extracted from hundreds of real sessions, not invented in a vacuum.

CLAUDE.md is powerful, but building a good one from scratch takes months of trial and error. Most developers never discover patterns like circuit breakers (stop retrying the same failing approach), compact recovery (what to do when Claude's context gets compressed mid-session), or blast radius protocols (check impact before touching shared code). Forge gives you the skeleton. You grow the muscle through real use.

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

Then run `/forge-setup` in any project. The wizard walks you through everything:

```
> /forge-setup

? Which Forge tier would you like?
  - Essential — Core rules only: coding standards, task management, git, safety
  - Full — Complete methodology: circuit breaker, role system, knowledge compounding
> Essential

? What's your name?
> Alice

? What's your primary platform? (macOS / Linux / Windows+WSL)
> macOS

? Preferred output language for Claude responses?
> English

? Git commit style? (default: conventional commits)
> [Enter]

Detecting environment... zsh, npm, VS Code

Generating Essential CLAUDE.md...
Written to ./CLAUDE.md (142 lines, 10 sections)

Recommended plugins to enhance your workflow:
  claude plugin marketplace add https://github.com/EveryInc/compound-engineering-plugin
  claude plugin install compound-engineering
```

### Without Plugin

1. Copy `templates/essential.md` or `templates/full.md` to your project as `CLAUDE.md`
2. Replace all `{{VARIABLES}}` with your actual values
3. Done

<div align="right">

[![][back-to-top]][readme-top]

</div>

## Usage Examples

### Starting a new project

You just initialized a new repo and want Claude to follow consistent patterns from day one.

```
> /forge-setup
```

Pick Essential tier. In 2 minutes you have a CLAUDE.md with task routing, git conventions, and safety rules. Claude immediately starts routing tasks correctly -- small fixes go straight to implementation, multi-step features get a plan first.

### Junior developer with Essential tier

You're new to Claude Code and don't want to be overwhelmed. Essential gives you 10 sections that cover the fundamentals:

- **Task routing** prevents Claude from over-engineering a typo fix
- **Verification discipline** stops Claude from claiming "tests pass" without running them
- **Safety rules** block destructive commands like `rm -rf` or `git push --force`
- **Git conventions** enforce consistent commit messages across the team

No plugins required. Just a CLAUDE.md file in your repo.

### Power user with Full tier + plugins

You're running Claude Code with Compound Engineering and Revolve. Full tier adds:

- **Circuit breaker** -- when Claude tries the same failing approach twice, it stops and re-plans instead of burning your context window with retries
- **Role system** -- map abstract roles (designer, reviewer) to AI providers. Your reviewer might be Codex, your inspiration source might be Gemini
- **Blast radius protocol** -- before touching any exported function, Claude greps all callers and adds them to the verification list
- **Knowledge compounding** -- hard-won debugging lessons get saved to `docs/solutions/` so future sessions don't repeat the same mistakes

This tier works standalone but shines when paired with the CE + GSD combined workflow: `/ce:brainstorm` → `/ce:plan` → `/ce:run` → `/ce:review`.

<div align="right">

[![][back-to-top]][readme-top]

</div>

## What's Inside

| Section | Tier | What it does |
|---------|------|-------------|
| Decision Framework | Both | Three questions before any change -- cut scope creep early |
| Task Routing | Both | Route tasks to right workflow -- skip ceremony for trivial changes |
| CE+GSD Workflow | Full | brainstorm → plan → ce:run (automatic) → review pipeline |
| Error Recovery | Full | Circuit breaker: same approach fails twice, must re-plan |
| Compact Recovery | Full | What to do when Claude's context gets compressed mid-session |
| Quality Gates | Both | Testing strategy tied to blast radius, not dogma |
| Verification | Both | Delivery gate -- no claiming done without evidence |
| Blast Radius | Full | Assess impact before touching exported interfaces |
| Role System | Full | Map abstract roles (designer, reviewer) to AI providers |
| Peer Review | Full | Plan review + code review checkpoints |
| Subagent Strategy | Full | When to spawn subagents, model selection by complexity |
| Knowledge Compounding | Full | Extract lessons worth keeping into `docs/solutions/` |
| Git Conventions | Both | Branch naming, commit format, hard prohibitions |
| Safety Rules | Both | No destructive commands, no hardcoded secrets |
| Task Management | Both | `tasks/todo.md` discipline: plan before code, track as you go |

### Key Rules in Practice

**Task Routing** automatically matches effort to task size:

```
You: "fix the typo in the footer"
Claude: [routes as Lightweight -- direct fix, no planning overhead]

You: "add user authentication with OAuth"
Claude: [routes as Medium/Large -- starts with /ce:plan, identifies 6 subtasks,
         asks which OAuth provider before writing a line of code]
```

**Circuit Breaker** prevents wasted context on dead-end approaches:

```
Attempt 1: tries regex-based parsing -> fails on edge case
Attempt 2: tries regex-based parsing with fix -> same failure
Circuit breaker triggers: "Same approach failed 2x. Stopping to re-plan."
Re-plan: switches to proper AST parser -> succeeds
```

Without this rule, Claude will happily burn 10 attempts on the same broken approach while your context window shrinks.

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
| Standalone | Works | No plugins needed -- methodology lives in CLAUDE.md |
| [Compound Engineering][ce-plugin] | Enhanced | `/ce:brainstorm`, `/ce:plan`, `/ce:review`, `/ce:compound` |
| [GSD][gsd-repo] | Enhanced | `/ce:run` invokes GSD's wave-parallel execution engine for autonomous implementation |
| gstack | Enhanced | Browser QA, CEO/eng plan review |
| [Revolve][revolve-repo] | Enhanced | Research pipeline + CLAUDE.md auto-evolution |

<div align="right">

[![][back-to-top]][readme-top]

</div>

## Customization

Every section in the generated CLAUDE.md is independent. Remove what you don't need, adjust thresholds, add your own rules. The inline comments explain each section's purpose so you know what you're trading off.

### Remove a section

Just delete it. The other sections don't depend on it. If you never use subagents, remove the Subagent Strategy section entirely.

### Adjust thresholds

Task routing defaults to "3+ steps" as the trigger for full planning. If you want less ceremony, change it:

```markdown
| **Medium/Large** | 5+ steps, architecture decisions | Plan -> implement -> review |
```

The circuit breaker defaults to 2 consecutive failures before re-planning. Raise it to 3 if you want more tolerance:

```markdown
- Same approach fails 3 consecutive times: must re-plan
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

Start with Essential. Use it for a week. When you notice gaps -- Claude retrying failed approaches, making changes without checking impact, or losing context after compaction -- promote to Full. Those gaps tell you exactly which sections you need.

<div align="right">

[![][back-to-top]][readme-top]

</div>

## Built With

Forge's methodology is extracted from and works alongside these projects:

| Project | Description | Role in Forge |
|---------|-------------|---------------|
| [Claude Code][claude-code] | Anthropic's AI coding CLI | Runtime -- CLAUDE.md is Claude Code's persistent instruction layer |
| [Compound Engineering][ce-plugin] | AI-powered development workflow plugin by Kieran Klaassen / Every | Methodology source -- Forge's task routing, quality gates, and review patterns are inspired by CE's workflow |
| [Revolve][revolve-repo] | Self-evolving AI research architecture | Recommended companion -- automates the "Evolve CLAUDE.md" step in the flywheel |
| [Best-README-Template][readme-template] | Popular README template by Othneil Drew | README structure and visual patterns |

<div align="right">

[![][back-to-top]][readme-top]

</div>

## Acknowledgments

- [Kieran Klaassen](https://github.com/kieranklaassen) and [Every](https://every.to) -- for [Compound Engineering][ce-plugin], the workflow methodology that Forge extracts and generalizes. CE's task routing, error recovery circuit breaker, quality gates, subagent strategy, and knowledge compounding patterns are the foundation of Forge's templates
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
[readme-template]: https://github.com/othneildrew/Best-README-Template
