# Core Methodology

This directory contains Forge's agent-neutral workflow sections.

- `sections/` stores reusable methodology fragments.
- `templates/targets/*` adapts those ideas to concrete agent instruction files.
- Top-level `templates/essential.md` and `templates/full.md` remain the Claude Code compatibility templates.

When adding support for another agent, start with these core sections and translate only the platform-specific parts: output filename, command syntax, skill invocation style, and installation path.
