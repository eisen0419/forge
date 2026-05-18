# Crucible Workflow · How the Agent Uses It at Runtime

> Companion to [`templates/crucible/`](../../templates/crucible/). That directory
> defines the storage format; this doc defines the prompt-side behavior — when
> the agent reads Crucible, when it writes, and which prose to splice into
> `CLAUDE.md` / `AGENTS.md` so the agent actually does it.

---

## When Crucible activates

Crucible reads happen **before** the agent executes a task — not after. The
trigger is task risk, not task topic.

| Task level | Crucible behavior |
|------------|-------------------|
| L0 (read-only, Q&A, explanations) | Skip. |
| L1 (small edits, single-file bugfixes) | Skip; rely on regular tooling. |
| L2 (3+ steps, local refactors, no shared contracts) | Optional. Read only if the task touches a known high-risk keyword. |
| L3 (high-risk: `git push`, `migration`, `auth`, `payment`, `schema`, `force-push`, `rm -rf`) | **Mandatory** retrieval before any tool call that performs the risky operation. |

The exact keyword list lives wherever you put the pre-flight section (Forge
provides one in `templates/core/sections/` once the corresponding PR lands; for
now, add your own).

---

## The pre-flight protocol

For any L3 task, the agent should follow this sequence before running the risky
command:

1. **Extract state.** Write down (in the visible response, not just in
   reasoning): `user_goal`, `constraints`, `known_facts`, `unknowns`,
   `risk_flags`, `success_metric`. This forces the agent to articulate what
   "done" looks like before acting.

2. **Retrieve from Crucible.** List the failed-directions directory and grep for
   the risk keywords:
   ```bash
   ls ~/.claude/crucible/failed-directions/
   grep -l -i "push\|main\|migration\|<your-keywords>" \
        ~/.claude/crucible/failed-directions/*.yaml
   ```

3. **On a hit**, read the matched yaml's `correct_action` and follow it. Then
   bump the bookkeeping counters:
   ```bash
   scripts/crucible-bookkeep.sh hit <fingerprint>
   ```
   The `hit` subcommand is intentionally trivial so the agent can self-report
   its own retrieval rate. Over time the retrieval_count tells you which
   patterns are actually load-bearing vs. which are theatre.

4. **On a miss**, proceed normally. If the task succeeds in a way worth
   canonizing, follow "Writing back to Crucible" below.

5. **Linked golden cases.** When a failed-direction has a
   `linked_golden_case`, also read that file — it's the positive playbook
   against which the agent should run.

---

## Writing back to Crucible

Two writers, two cadences.

**Automatic (hook-driven).** If you install the future `auto-evolve-collector`
hook (planned, separate PR), every session's errors flow into
`failed-directions/<fp>.{yaml,occurrences.jsonl}` automatically — yaml first
sighting, jsonl per recurrence.

**Manual (agent-driven golden cases).** When the agent and user finish a flow
worth keeping, the agent should:

1. Pick a new id: `gc_$(date +%Y_%m_%d)_NNN` (NNN = the next ordinal that day).
2. Write `~/.claude/crucible/golden-cases/<id>.yaml` following
   `templates/crucible/schemas/golden-case.schema.yaml`.
3. If a matching failed-direction exists, fill `linked_failed_direction` with
   its fingerprint, and (on the failed-direction side) backfill
   `linked_golden_case` with the new id. Cycles like this are intentional —
   it's how the system stays bidirectional.

---

## Prose to splice into your CLAUDE.md / AGENTS.md

The agent will not retrieve from Crucible unless its instructions tell it to.
Add a section like the one below (adapt to your conventions):

```markdown
## Pre-flight (high-risk tasks)

Before running any of these — `git push`, `git reset --hard`, `rm -rf`,
database migrations, auth-related code, payment-related code, schema or
lockfile changes, force-push — do this *first*:

1. State the task plan in one paragraph.
2. List `~/.claude/crucible/failed-directions/` and grep the yamls for the
   relevant risk keyword.
3. If a fingerprint matches, follow its `correct_action`. Then run:
   `scripts/crucible-bookkeep.sh hit <fingerprint>` to bump bookkeeping.
4. If no fingerprint matches, proceed — and if the flow succeeds, propose
   writing a new golden case.

Never act on a high-risk command until step 2 has been done.
```

A version of this prose will ship as a Forge `templates/core/sections/` entry
in a follow-up PR; until then, paste it directly into your own config.

---

## Maintenance rhythm

The schemas and storage are designed to age gracefully without active
maintenance, but a light weekly pass keeps the signal clean.

| Cadence | Action |
|---------|--------|
| Weekly  | Scan `failed-directions/*.yaml` for entries with `confidence: low` and `occurrences ≥ 3` (`scripts/crucible-bookkeep.sh list` plus `wc -l <fp>.occurrences.jsonl`). Decide whether to promote `confidence` and fill in `correct_action`. |
| Monthly | Find entries with `last_retrieved` older than 90 days and `retrieval_count == 0`. Set `status: deprecated`. |
| Quarterly | Run a merge pass for near-duplicate fingerprints whose error_kind has drifted; consolidate to one. |
| Anytime | Re-run `scripts/crucible-bookkeep.sh validate` after manual edits to catch missing fields. |

---

## Catchall protocol

When the auto-collector can't classify an error, it bins it to a catchall
fingerprint per `tool_name`. **Do not chase every new error by editing the
classifier** — that race never ends. Instead:

| Action | Trigger |
|--------|---------|
| Observe | The catchall fingerprint's `occurrences.jsonl` keeps growing; yaml `status: catchall`. |
| Group manually | Weekly: cluster snippets by visible pattern. |
| Promote | Once a cluster reaches 3+, add a regex to the classifier, migrate the rows, remove from `catchall_observed_subtypes`. |
| Leave alone | One-offs stay in the pool forever. That's fine. |

---

## Failure modes (what won't work)

A few things to keep realistic expectations about.

- **The hook can't read your mind.** It records textual `error_kind` and
  `tool_name`. If your failures are semantic (right tool, wrong logic), the
  fingerprint won't distinguish them — that's what `golden-cases` are for.
- **Retrieval is opt-in.** The agent only consults Crucible if its instructions
  say so. Without the prose splice above, the directory just sits there.
- **Bookkeeping is honor-system.** `scripts/crucible-bookkeep.sh hit` requires
  the agent to *report* a retrieval. The signal is noisy at first; trend over
  weeks, not days.

---

## See also

- [`templates/crucible/README.md`](../../templates/crucible/README.md) — design and install
- [`templates/crucible/schemas/`](../../templates/crucible/schemas/) — exact field reference
- [`templates/crucible/seeds/`](../../templates/crucible/seeds/) — worked example
- [`scripts/crucible-bookkeep.sh`](../../scripts/crucible-bookkeep.sh) — maintenance commands
