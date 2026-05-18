# Crucible Seeds · 示例文件

These are **worked examples** of the two yaml schemas, drawn from a real-world
pattern (pushing to a protected branch and using a PR instead).

## When to copy them

- **Copy as starter content** if you want a populated example to study or modify.
- **Don't copy verbatim into production** without editing `created_at`,
  `last_verified`, and `evidence_session` to reflect your own context. The
  placeholders are `<YYYY-MM-DD>` and `<your session id or PR number>`.

## What's in each file

| File | Purpose |
|------|---------|
| `failed-direction.example.yaml` | Schema-correct example of a failed direction, fingerprint `df53a88d1096`. |
| `golden-case.example.yaml` | Companion golden case `gc_example_001`, reverse-linked to the failed direction above. |

## Why exactly this example

The "push to main was rejected → open a PR" pattern is the canonical case for
Crucible because:

1. The failure is concrete and machine-detectable (the `permission denied` error
   from `Bash`).
2. The correct flow is concrete and grep-able (looks for `gh pr create` rather
   than `git push origin main`).
3. The two halves form a tight reverse-linked pair, which is the ideal shape
   for any new Crucible entry you add.

## See also

- [`../schemas/failed-direction.schema.yaml`](../schemas/failed-direction.schema.yaml)
- [`../schemas/golden-case.schema.yaml`](../schemas/golden-case.schema.yaml)
- [`../README.md`](../README.md) — overall design
- [`../../../docs/workflows/crucible.md`](../../../docs/workflows/crucible.md) — how the agent uses these at runtime
