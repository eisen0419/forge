<!-- SECTION: Role System (Full tier only)
  What: Abstract roles that map to AI providers for different tasks
  Why: Different AI tools have different strengths — leverage them
  Customize: Change the Provider column to your actual tools
  Note: This is a CLAUDE.md instruction convention, not a Claude Code API.
        Claude reads this table and follows it during inference. -->

## Role Assignments

| Role | Provider | Description |
|------|----------|-------------|
| designer | {{ROLE_DESIGNER}} | Primary planner and architect — owns plans and designs |
| executor | {{ROLE_EXECUTOR}} | Code implementation — writes and modifies code |
| inspiration | {{ROLE_INSPIRATION}} | Creative brainstorming — provides ideas as reference |
| reviewer | {{ROLE_REVIEWER}} | Scored quality gate — evaluates plans/code |
