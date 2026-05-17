<!-- SECTION: Knowledge Compounding (Full tier only)
  What: Rules for capturing and reusing solutions to hard problems
  Why: The first time you solve a problem takes hours. Document it, next time takes minutes
  Customize: Adjust the judgment criteria and storage path
  Optional: Install Revolve (https://github.com/eisen0419/revolve) to automate CLAUDE.md evolution -->

## Compound Discipline

When to document a solution:
- Fixed a non-trivial bug with a reusable pattern
- Discovered a new approach that future sessions should know
- Judgment: would this help a future session avoid repeating the same mistake?

Storage: `docs/solutions/` with category subdirectories and YAML frontmatter.

Minimum content: trigger signal, root cause, correct approach, verification method, applicable scope.

### Self-Improvement Loop

A lighter, faster channel than `docs/solutions/` — captures lessons during a single project's lifecycle, separate from cross-project pattern library:

1. **When the user corrects you** (says "no", "don't", "stop doing that", or otherwise rejects an approach), append the correction + the reason to `tasks/lessons.md`.
2. **At the start of every session**, re-read `tasks/lessons.md` if it exists — this is cheaper than re-learning the same mistake.
3. **When a lesson recurs** or proves broadly valuable, graduate it to `docs/solutions/` (or to `CLAUDE.md` via the Evolution loop below).

This makes the project's own correction history a first-class artifact, not a thing buried in chat logs.

### CLAUDE.md Evolution

**Manual** (default): Periodically review your sessions and update CLAUDE.md with new patterns and corrections.

**Automated**: Install [Revolve](https://github.com/eisen0419/revolve) and run `/evolve-claude-md` to scan conversations and suggest CLAUDE.md updates.
