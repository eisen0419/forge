<!-- SECTION: Role System (Full tier only)
  What: Abstract roles that map to AI providers for different tasks
  Why: Different AI tools have different strengths — leverage them
  Customize: Change the Provider column to your actual tools
  Note: This is a CLAUDE.md instruction convention, not a Claude Code API.
        Claude reads this table and follows it during inference. -->

## Role Assignments

| Role | Provider | Description |
|------|----------|-------------|
| designer | claude | Primary planner and architect — owns plans and designs |
| executor | claude | Code implementation — writes and modifies code |
<!-- Uncomment and customize to use multiple providers:
| inspiration | gemini | Creative brainstorming — provides ideas as reference |
| reviewer | codex | Scored quality gate — evaluates plans/code |
-->
