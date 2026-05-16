# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased] - v0.1.0

### Added

- Initial project scaffold with plugin metadata
- 17 section template fragments in `templates/core/sections/`
- Essential tier template (`templates/essential.md`)
- Full tier template (`templates/full.md`)
- Codex target templates for `AGENTS.md`
- Target-aware `/forge-setup` flow for Claude Code, Codex, or both

### Changed

- Updated Compound Engineering command references from legacy `/ce:*` style to current `/ce-*` style
- Renamed Forge's CE-to-GSD bridge from `ce:run` to `forge-run`
- Replaced stale `/gsd-session-report` reference with `/gsd-stats`
- Aligned marketplace metadata version with plugin version

### Fixed

- Fixed marketplace `source` path so `claude plugin validate .` passes
