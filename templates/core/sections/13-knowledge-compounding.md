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

### CLAUDE.md Evolution

**Manual** (default): Periodically review your sessions and update CLAUDE.md with new patterns and corrections.

**Automated**: Install [Revolve](https://github.com/eisen0419/revolve) and run `/evolve-claude-md` to scan conversations and suggest CLAUDE.md updates.
