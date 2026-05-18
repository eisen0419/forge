# Forge Crucible · Evolution Asset System

> Forge shapes workflows outward. Crucible refines failures inward.
> Forge 把工作流塑形对外，Crucible 把错误与成功提纯对内。

Templates for a per-machine **failure-and-success memory** that lets the agent learn across sessions. Install once, populate either by hand or via the auto-evolve-collector hook, and `git init` the install location for cross-machine sync.

---

## What this is · 这是什么

**EN.** Two co-located stores that live at `~/.claude/crucible/` after install:

- `failed-directions/<fingerprint>.yaml` — every recurring error pattern the agent has seen, keyed by a stable 12-char sha1 of `(error_kind, tool_name)`.
- `golden-cases/<gc_id>.yaml` — manually curated success flows, each linked back to the failed direction it prevents.

The agent reads these before high-risk work (`git push`, migrations, auth, schema changes) and avoids re-stepping on rakes it already knows about.

**中文。** 装机后挂在 `~/.claude/crucible/` 的两个互相引用的目录：

- `failed-directions/<fingerprint>.yaml` — Agent 反复遇到的错误模式，按 `(error_kind, tool_name)` 的 12 位 sha1 去重。
- `golden-cases/<gc_id>.yaml` — 手工沉淀的成功流程，反向引用对应的 failed direction。

Agent 在 L2+ 高风险任务（`git push` / 迁移 / 认证 / 模式变更）前先读这两个目录，避免再踩同一个坑。

---

## Why · 为什么

Three problems Crucible exists to solve:

1. **Cross-session amnesia** — error lessons learned today are forgotten tomorrow because nothing persists between sessions.
2. **Recurring-failure tax** — the same `git push to main rejected by branch protection` happens every few weeks; each time costs the same diagnostic loop.
3. **Tribal knowledge loss** — successful flows (the right way to open a PR, the right way to do a migration) exist only in chat history and decay quickly.

Crucible turns each of those into a small, searchable, version-controlled artifact.

---

## How it slots in · 如何嵌入

```
                                          ┌─────────────────────────────────────┐
  Tool failure / user correction          │ ~/.claude/crucible/                 │
            │                             │                                     │
            ▼                             │  failed-directions/                 │
  auto-evolve-collector hook              │    <fingerprint>.yaml               │
  (optional, see templates/hooks/)        │    <fingerprint>.occurrences.jsonl  │
            │                             │                                     │
            ├──▶ append to occurrences ──▶│                                     │
            └──▶ create yaml if new       │  golden-cases/                      │
                                          │    <gc_id>.yaml ──linked──┐         │
  L2+ task starts                         │                            │        │
            │                             │      ┌─────────────────────┘        │
            ▼                             │      ▼                              │
  Agent greps failed-directions/ ◀────────┤  reverse link via                   │
            │                             │  linked_failed_direction field      │
            ▼                             └─────────────────────────────────────┘
  Hit → read correct_action → follow it
  Miss → proceed normally; success path may become a new golden case later
```

The system works **without** the auto-evolve-collector hook — you can populate it by hand. The hook is just the lazy default.

---

## Install · 安装

Currently a **copy-and-init** install (a wizard step will come in a follow-up release):

```bash
# 1. Stage the templates into your global Claude config
mkdir -p ~/.claude/crucible
cp -r templates/crucible/{README.md,schemas} ~/.claude/crucible/
mkdir -p ~/.claude/crucible/{failed-directions,golden-cases}

# 2. (Optional) seed with the example yamls to see the format
cp templates/crucible/seeds/failed-direction.example.yaml \
   ~/.claude/crucible/failed-directions/example.yaml
cp templates/crucible/seeds/golden-case.example.yaml \
   ~/.claude/crucible/golden-cases/gc_example.yaml

# 3. Put it under version control so lessons survive machine swaps
cd ~/.claude/crucible && git init && git add . && git commit -m "init crucible"
```

After that, point your agent's instructions (e.g. via Forge `templates/full.md`) at `~/.claude/crucible/` — see [`docs/workflows/crucible.md`](../../docs/workflows/crucible.md) for the prompt-side wiring.

---

## Schema overview · 模式概览

Full schemas live in [`schemas/`](./schemas/). Quick reference:

### `failed-directions/<fingerprint>.yaml`

| Field | Type | Who writes |
|-------|------|------------|
| `fingerprint` | 12-char sha1 | hook or `crucible-bookkeep.sh gen-fingerprint` |
| `error_kind` | string | hook (auto-classified) |
| `tool_name` | string | hook |
| `trigger` | string | hook (auto-generated summary) |
| `sample_snippet` | string | hook (first observation, truncated) |
| `created_at`, `status` | string | hook |
| `content`, `correct_action`, `counterexamples` | user-editable | you, once verified |
| `confidence` | `low` \| `medium` \| `high` | you |
| `last_retrieved`, `retrieval_count` | string, int | `scripts/crucible-bookkeep.sh hit` |
| `linked_golden_case` | gc_id | you |

Plus a sidecar `<fingerprint>.occurrences.jsonl` — one JSON line per recurrence, append-only. The split lets the hook stay fast (no yaml parse) and protects user-editable fields from machine overwrites.

### `golden-cases/<gc_id>.yaml`

| Field | Type |
|-------|------|
| `case_id` | `gc_YYYY_MM_DD_NNN` |
| `title`, `trigger` | string |
| `correct_flow` | list of strings |
| `verification` | list of strings (post-conditions you can grep for) |
| `linked_failed_direction` | fingerprint |
| `evidence_session` | placeholder for traceability |
| `created_at`, `last_verified`, `status` | string |

**Fingerprint formula** (must stay stable across the hook and any tooling):

```python
sha1(f"{error_kind[:30].lower()}|{tool_name or 'unknown'}").hexdigest()[:12]
```

---

## Maintenance commands · 维护命令

See [`scripts/crucible-bookkeep.sh`](../../scripts/crucible-bookkeep.sh):

```bash
scripts/crucible-bookkeep.sh hit <fingerprint>          # bump retrieval_count + last_retrieved
scripts/crucible-bookkeep.sh list                       # show all fingerprints + stats
scripts/crucible-bookkeep.sh validate                   # schema completeness check
scripts/crucible-bookkeep.sh gen-fingerprint <kind> <tool>
```

The agent is expected to run `hit` itself whenever pre-flight retrieval matches a fingerprint — this is the auto-bookkeeping protocol described in `docs/workflows/crucible.md`.

---

## Naming conventions · 命名约定

| Element | Style | Example |
|---------|-------|---------|
| Directory | kebab-case | `failed-directions/` |
| Field name | snake_case | `last_verified` |
| Fingerprint | 12-char sha1 | `df53a88d1096` |
| Golden case id | `gc_YYYY_MM_DD_NNN` | `gc_2026_05_18_001` |
| `status` enum | lowercase | `active` / `deprecated` / `archived` |

---

## Cost budget · 成本预算

- Per hook invocation: **< 5 s** (shared with `auto-evolve-collector`).
- Per yaml file: **< 5 KB** (occurrences > 100 → archive sidecar).
- Total directory: **< 50 MB**.
- **No LLM in the hook path** — pure machine writes, human-readable text.

---

## Relationship to other parts of Forge · 与 Forge 其它部分的关系

- **`templates/hooks/auto-evolve-collector/`** *(planned, separate PR)* auto-populates `failed-directions/`. Without it, you can still populate by hand or by other tooling — the schema is the contract.
- **`templates/full.md` / `templates/core/sections/`** — the agent-facing prose that tells the agent **when** to read Crucible (pre-flight at L2+, etc.). See `docs/workflows/crucible.md` for the section to splice in.
- **`templates/hooks/project-context/`** — already shipped; reminds the agent about project state at every session start. Crucible is the *outcome* memory; project-context is the *current-task* memory.

---

## Catchall fingerprint protocol · 兜底池

When the hook can't classify an error, it bins it to a catchall `kind=error` fingerprint per `tool_name`. **Do not chase every new error by editing the hook's classifier** — that race never ends. Instead:

| Action | Trigger |
|--------|---------|
| **Observe** | Catchall fingerprint's `occurrences.jsonl` keeps growing; yaml `status: catchall` |
| **Group manually** | Weekly scan: cluster snippets by visible pattern |
| **Promote to its own kind** | A cluster reaches 3+ occurrences → add a regex to `classify_error_kind()`, migrate the matching jsonl rows to a fresh fingerprint |
| **Leave alone** | One-offs stay in the catchall pool |

The catchall yaml's `catchall_observed_subtypes` field is a user-maintained list of "things I've already noticed living here," to speed up the next triage pass.
