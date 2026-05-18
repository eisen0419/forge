<!-- SECTION: Pre-Flight Protocol (Crucible)
  What: Mandatory check for L3 high-risk tasks (git push, migration, auth, payment, schema, lockfile changes, rm -rf, force-push) before any tool call executes the operation.
  Why: Crucible's failed-directions store records error patterns the agent has hit before; consulting it before re-running a similar operation is what makes "learning across sessions" actually work. Without this section spliced into the agent's instructions, the agent never reads the directory and Crucible is effectively dead weight.
  Customize: Adjust the high-risk keyword list to your domain. The state-extract + retrieve + correct_action + bookkeep loop is the core mechanism — keep that intact.
  Depends on: templates/crucible/ being installed at ~/.claude/crucible/ (see docs/workflows/crucible.md). If Crucible is not installed, the section still works — step 2 simply finds nothing and the agent proceeds, while step 1 (state extract) still happens. -->

## Pre-Flight Protocol

Before running any of these — `git push`, `git reset --hard`, `rm -rf`, database migrations, auth-related code, payment-related code, schema or lockfile changes, force-push — do this **first**:

1. **State the plan** in one paragraph. Include `user_goal`, `constraints`, `known_facts`, `unknowns`, `risk_flags`, and `success_metric`. This forces an articulation of what "done" looks like before acting.
2. **Retrieve from Crucible.** `ls ~/.claude/crucible/failed-directions/` and grep the yamls for the relevant risk keyword.
3. **On a hit** — read the matched yaml's `correct_action` and follow it. Then run `scripts/crucible-bookkeep.sh hit <fingerprint>` to bump bookkeeping so the retrieval count reflects reality.
4. **On a miss** — proceed normally. If the success path is worth canonizing, write a new `~/.claude/crucible/golden-cases/gc_YYYY_MM_DD_NNN.yaml` and reverse-link it.

Never act on a high-risk command until step 2 has been done. If Crucible is not installed locally, step 2 finds nothing — that is OK; still do step 1.

See `templates/crucible/` and `docs/workflows/crucible.md` for the storage format and the full workflow.
