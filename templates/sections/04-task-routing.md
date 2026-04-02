<!-- SECTION: Task Routing
  What: Routes different types of work to appropriate workflows
  Why: Small tasks don't need full ceremony; large tasks need structure
  Customize: Adjust thresholds, add your project-specific skills/commands
  Note: Essential tier uses a simplified version; Full tier includes upgrade/downgrade signals -->

## Task Routing

| Type | Criteria | Workflow |
|------|----------|----------|
| **Read-only** | Analysis/questions/review | Direct answer |
| **Investigation** | Problem diagnosis, no code changes | Systematic debugging |
| **Lightweight** | Single file, small fix, clear scope | Implement → verify |
| **Medium/Large** | 3+ steps, architecture decisions, shared logic | Plan → implement → review |

**Lightweight rules**: Ask at most 1 clarifying question. Skip full workflow ceremony.

<!-- FULL_ONLY_START -->
**Upgrade signals**: Scope expands, touches public API/schema/persistence/concurrency, requirements unclear, verification insufficient.

**Downgrade signals**: Clear boundaries, no shared logic, problem converges to single fix.
<!-- FULL_ONLY_END -->
