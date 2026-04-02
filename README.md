# Forge

**AI-Assisted Development Workflow Starter Kit for Claude Code**

A verified structural starting point for CLAUDE.md — task routing, error recovery, quality gates, and knowledge compounding extracted from a battle-tested production workflow.

---

## Why Forge?

CLAUDE.md is powerful, but building one from scratch takes months of trial and error. Most users never discover patterns like circuit breakers, blast radius protocols, or compact recovery discipline. Forge gives you the skeleton; you grow the muscle through real use.

## Why Not Just Copy Someone's CLAUDE.md?

- **Structured methodology, not personal config** — Forge extracts universal patterns. Random CLAUDE.md files mix methodology with personal tool preferences, aliases, and team-specific context.
- **Tiered onboarding** — Essential for newcomers who want core discipline without overhead. Full for power users who want the complete system.
- **Interactive setup** — `/forge-setup` asks questions about your stack and generates a customized template rather than dropping a wall of text you have to decipher.
- **Documented rationale** — Every rule includes inline comments explaining why it exists, so you can make informed decisions about what to keep or remove.

## Two Tiers

| Tier | Contents |
|------|----------|
| Essential | Core rules: task routing, quality gates, verification discipline, git conventions, safety rules |
| Full | Everything in Essential + circuit breaker, compact recovery, role system, peer review, subagent strategy, blast radius, knowledge compounding |

## Quick Start

**With plugin (recommended):**

```bash
claude plugin marketplace add https://github.com/eisen0419/forge
claude plugin install forge
```

Then run `/forge-setup` in any project.

**Without plugin (manual):**

1. Copy `templates/essential.md` or `templates/full.md` to your project as `CLAUDE.md`
2. Replace all `{{VARIABLES}}` with your actual values
3. Done

## What's in the Template

| Section | Tier | Description |
|---------|------|-------------|
| Decision Framework | Both | Three questions to cut scope creep before it starts |
| Task Routing | Both | Maps task type to the right workflow — skip CE for trivial changes |
| Error Recovery | Full | Circuit breaker: same approach fails twice, you must re-plan |
| Quality Gates | Both | Testing strategy tied to blast radius, not dogma |
| Verification | Both | Delivery gate rules — no claiming done without evidence |
| Blast Radius | Full | Assess impact before touching exported interfaces |
| Role System | Full | Maps abstract roles (designer, reviewer) to concrete AI providers |
| Peer Review | Full | Plan review and code review checkpoints with pass/fail criteria |
| Subagent Strategy | Full | When to spawn subagents, model selection by task complexity |
| Knowledge Compounding | Full | When and how to extract lessons worth keeping |
| Git Conventions | Both | Branch naming, commit format, hard prohibitions |
| Safety Rules | Both | No destructive commands, no hardcoded secrets, no unparameterized queries |
| Task Management | Both | todo.md discipline: plan before code, track as you go |

## Works With

| Tool | Status | Description |
|------|--------|-------------|
| Standalone | Works | No plugins needed — methodology lives entirely in CLAUDE.md |
| Compound Engineering (CE) | Enhanced | Adds `/ce:plan`, `/ce:work`, `/ce:review`, `/ce:compound` |
| gstack | Enhanced | Adds browser QA, CEO/eng plan review |
| Revolve | Enhanced | Adds research pipeline and CLAUDE.md auto-evolution |

## Customization

Edit any section, remove what you don't need, add project-specific rules. The inline comments explain each section's purpose so you know what you're trading off when you cut something. Start with Essential and promote to Full when you feel the gaps.

## License

MIT
