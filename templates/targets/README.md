# Target Templates

Forge separates reusable workflow methodology from agent-specific instruction files.

- Core sections live in `templates/core/sections/`.
- Agent adapters live in `templates/targets/<agent>/`.

| Target | Output | Template |
|--------|--------|----------|
| Claude Code | `CLAUDE.md` | `templates/essential.md`, `templates/full.md` |
| Codex | `AGENTS.md` | `templates/targets/codex/essential.md`, `templates/targets/codex/full.md` |

The top-level Claude templates remain in place for backward compatibility with the initial Forge release. New agent targets should be added under `templates/targets/<agent>/`.
