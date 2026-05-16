# Forge Routing System Test

This document defines a repeatable test project for validating Forge's routing system, generated instruction artifacts, and add-on fit.

The test deliberately lets Forge make the wizard decisions. It uses the highest-coverage path:

- Target: Both Claude Code and Codex
- Tier: Full
- Language preference: Chinese output with product and command names unchanged
- Platform: macOS / zsh / npm + bun + pip + brew / VS Code
- Test level: 1, regression tests for local behavior changes
- Roles: designer gstack, reviewer Waza check, executor Codex, inspiration CE

## Add-On Roles

| Add-on | Best Fit | Do Not Use For |
|--------|----------|----------------|
| CE | Strategy, ideation, requirements, planning, implementation, review, product pulse, knowledge compounding | Every tiny edit |
| GSD | Durable `.planning/` state, codebase mapping, phase execution, verification, shipping | One-shot habit tasks |
| gstack | Product scope, UI/design/DX review, browser QA, release confidence | Routine text fetches or prose edits |
| Waza | Focused habits: `think`, `hunt`, `check`, `health`, `read`, `learn`, `write`, `design` | GSD-style project state or gstack-style release factory |
| Forge | Shared instruction layer, routing, safety, blast radius, verification, git hygiene | Replacing every specialized workflow |

## Scenario Matrix

| ID | User Task | Expected Route | Why |
|----|-----------|----------------|-----|
| S01 | Fix one typo in a footer | Standalone Forge, CE `/ce-work`, or GSD `/gsd-fast` | Low-risk local edit should skip ceremony |
| S02 | Add OAuth authentication | CE `/ce-strategy` if needed -> `/ce-brainstorm` -> `/ce-plan` -> implementation/review | Multi-step feature with security and product choices |
| S03 | Existing project already has `.planning/` | GSD map/new-project/discuss/plan/execute/verify/ship loop | GSD owns durable project state |
| S04 | A CE plan exists and should use GSD execution | `/forge-run <plan>` | Forge-run is only the CE-plan-to-GSD bridge |
| S05 | Browser UI looks wrong before release | gstack `/qa` / `/design-review` / `/ship` | Visual and release gates need browser/product judgment |
| S06 | A test failed and the old version worked | Waza `/hunt` | Root cause first, with bisect/regression posture |
| S07 | Review diff and push if green | Waza `/check` | Diff review, release gate, and follow-through fit Waza |
| S08 | Codex ignores `AGENTS.md` or hooks feel stale | Waza `/health` | Agent config and maintainability audit |
| S09 | Read a URL or PDF before research | Waza `/read`; chain to `/learn` only for multi-source synthesis | Fetching is not a planning workflow |
| S10 | Polish a release note or social post | Waza `/write` | Prose belongs to writing skill, not code review |
| S11 | Add a package or migration during a small task | Stop at `Do Not Introduce` and ask | Forbidden changes need explicit approval |
| S12 | Rename exported API | Forge blast-radius protocol, then targeted verification | Shared surface requires caller search |

## Recommended Combination Flow

The best default pairing from this test matrix is:

1. **Forge always on**: keep task routing, forbidden-change boundaries, blast-radius checks, git hygiene, and verification discipline in `CLAUDE.md` / `AGENTS.md`.
2. **Waza for focused habits**: use `think` for lean plans, `hunt` for root-cause debugging, `check` for diff/release follow-through, `health` for agent setup drift, and `read` / `learn` / `write` for content workflows.
3. **CE for feature shaping**: use CE when a feature needs strategy, brainstorming, requirements, implementation planning, or knowledge compounding.
4. **GSD for durable execution**: use GSD when the project benefits from `.planning/`, phase plans, workstreams, verification, and shipping state.
5. **gstack for product and release confidence**: use gstack when UI quality, browser QA, product scope, DX, or release gates are the risk center.
6. **`/forge-run` only as a bridge**: use it when a CE plan already exists and GSD should execute it. Do not make it the default for every medium or large task.

## Automated Checks

Run:

```bash
node scripts/test-forge-routing.mjs
```

The script validates:

1. JSON plugin manifests parse.
2. Full templates stay under 200 lines.
3. Essential templates stay compact.
4. Claude and Codex full templates include the same route coverage.
5. Waza is present as a focused habit layer, not as a project-state or release-factory replacement.
6. README and README_CN document the same add-ons.
7. `/forge-setup` prints install commands for CE, GSD, gstack, Waza, and Revolve.
8. `/forge-run` remains narrow and refuses focused Waza habit tasks.
9. Rendered test artifacts contain no `{{VARIABLES}}` placeholders.
10. Rendered Claude and Codex artifacts preserve their target-specific command style.

Generated artifacts are written to:

```text
.context/forge-routing-test-output/CLAUDE.md
.context/forge-routing-test-output/AGENTS.md
```

The `.context/` directory is ignored by git.

## Pass Criteria

A run is acceptable when the command exits 0 and prints:

```text
Forge routing system tests passed
```

Any failure should name the missing route, artifact issue, or stale wording that broke the contract.
