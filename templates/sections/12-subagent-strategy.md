<!-- SECTION: Subagent Strategy (Full tier only)
  What: When and how to use subagents for parallel work
  Why: Keeps the main context window clean; enables parallel execution
  Customize: Adjust model selection based on your available models -->

## Subagent Strategy

- Use subagents to keep main context window clean
- Offload research, exploration, parallel analysis to subagents
- One subagent, one focused task
- Never let two subagents modify the same file

### Model Selection
| Scenario | Model | Rationale |
|----------|-------|-----------|
| Complex reasoning, architecture | opus | Deep thinking needed |
| Code implementation, testing | sonnet | Standard tasks |
| Quick search, formatting | haiku | Speed over depth |
