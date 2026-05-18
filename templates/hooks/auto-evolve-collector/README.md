# auto-evolve-collector

> Stop hook · scans each session's jsonl on session end, persists error and correction signals to a raw daily log, a Crucible failed-directions store, and (optionally) an Obsidian digest. No LLM in the path.
> Stop hook · 每次会话结束时扫描 session jsonl，把错误和用户纠正信号沉淀到原始日志 / Crucible failed-directions / 可选的 Obsidian 摘要。全程无 LLM。

## What it does · 它做了什么

**EN.** On every Claude Code `Stop` event the hook:

1. Reads the `session_id` from the stdin payload, locates the matching transcript jsonl under `~/.claude/projects/`.
2. Walks the transcript and extracts:
   - **Tool errors** — `tool_result` entries with `is_error: true`. Each error is classified into a canonical `error_kind` (e.g. `permission denied`, `read-before-edit`, `tls handshake timeout`) and stamped with a stable 12-char fingerprint of `(error_kind, tool_name)`.
   - **User corrections** — user messages containing any of `不对 / 错了 / 别 / 不要 / wrong / no, don't / stop` (bilingual, extensible).
   - **Session metadata** — first user message, tool-call count, cwd, started/ended timestamps.
3. Writes the results to up to three sinks. The first two are always on; the third is opt-in.

**中文。** 每次 Claude Code `Stop` 事件触发时，hook 会：

1. 从 stdin payload 读取 `session_id`，在 `~/.claude/projects/` 下找到对应的会话 jsonl。
2. 遍历 jsonl，提取：
   - **工具错误**——`tool_result` 中 `is_error: true` 的条目。每个错误规范化为 canonical `error_kind`（如 `permission denied` / `read-before-edit` / `tls handshake timeout`），并按 `(error_kind, tool_name)` 计算 12 位 fingerprint。
   - **用户纠正**——用户消息中包含 `不对 / 错了 / 别 / 不要 / wrong / no, don't / stop` 任意一条（双语，可扩展）。
   - **会话元数据**——首条用户消息、工具调用数、cwd、起止时间戳。
3. 写入最多三个出口，前两个总是开启，第三个 opt-in。

## Outputs · 输出

| Sink | Path | Always on? | Purpose |
|------|------|-----------|---------|
| Raw jsonl | `$EVOLVE_COLLECT_DIR/<date>.jsonl` (default `~/.claude/auto-lessons/<date>.jsonl`) | Yes | Append-only daily log; one JSON line per session. Source of truth for downstream analytics. |
| Crucible failed-direction | `$EVOLVE_CRUCIBLE_FD_DIR/<fingerprint>.yaml` + sidecar `.occurrences.jsonl` (default `~/.claude/crucible/failed-directions/`) | Yes | Per-fingerprint learning artifact. First sighting writes the yaml stub (`confidence: low`); every recurrence appends a line to the sidecar jsonl. User-editable fields are never overwritten. |
| Obsidian digest | `$EVOLVE_OBSIDIAN_DIR/<date>.md` | **No — opt in by setting the env var** | Human-readable daily digest for users who want to read their AI failure log in an Obsidian vault. Disabled by default because most users do not run an Obsidian vault. |

## Environment overrides · 环境变量

All paths are env-overridable. Common reasons to override:

- `EVOLVE_COLLECT_DIR` — point at an XDG-style location (e.g. `~/.local/share/claude/auto-lessons`).
- `EVOLVE_CRUCIBLE_FD_DIR` — when running Crucible in a non-default install location.
- `EVOLVE_OBSIDIAN_DIR` — set to **any** non-empty path to enable the Obsidian sink; leave unset to keep it off.

```bash
# Persist the Obsidian digest opt-in across sessions:
echo 'export EVOLVE_OBSIDIAN_DIR="$HOME/Documents/Obsidian/journal/ai-sessions"' >> ~/.zshrc
```

## Sibling artifacts · 联动产物

This hook is one of three Crucible-aligned artifacts; the fingerprint formula is identical across all three so the hook's output is directly consumable by the rest:

- **`templates/crucible/schemas/failed-direction.schema.yaml`** — defines the yaml shape this hook writes.
- **`scripts/crucible-bookkeep.sh gen-fingerprint <kind> <tool>`** — prints the exact same fingerprint the hook would compute for a given pair. Useful for testing.
- **`docs/workflows/crucible.md`** — explains how the agent should read these outputs back during pre-flight.

If you change the fingerprint formula in one, change it in all three. There is an end-to-end check in the Crucible PR notes that catches drift.

## Install · 安装

```bash
# From the forge repo root
scripts/install-hook.sh auto-evolve-collector
```

The installer copies `hook.sh` to `~/.claude/hooks/forge-auto-evolve-collector.sh`, registers it under the `Stop` event in `~/.claude/settings.json`, backs up the previous settings, and verifies by executing the hook with an empty payload (should exit 0 silently).

## Uninstall · 卸载

```bash
scripts/uninstall-hook.sh auto-evolve-collector
```

Removes only the registered `Stop` entry pointing at `forge-auto-evolve-collector.sh` and the script file itself. Other hooks, events, and `settings.json` fields are untouched.

## Cost / safety · 成本与安全

- **Budget**: < 5 s wall time per session. Pure machine work; no LLM call, no network.
- **Failure mode**: All exceptions are swallowed (`|| exit 0` after the inline Python). A broken hook never blocks session end.
- **Privacy**: Outputs are local-only. The Obsidian sink is opt-in precisely so users who do not run an Obsidian vault are not surprised by files appearing in unexpected places.

## Skip conditions · 跳过条件

The hook silently exits 0 when:

- The stdin payload has no `session_id`.
- The matching session jsonl cannot be found under `~/.claude/projects/`.
- Any inline Python error fires (`2>/dev/null || exit 0` at the bottom).

These short-circuits are intentional: a Stop hook that throws blocks session shutdown, which is far worse than missing one session's signals.

## What this does NOT do · 它不做什么

- It does **not** call any LLM. Classification is pure substring matching against `classify_error_kind()`.
- It does **not** modify the user-editable fields of an existing `<fp>.yaml`. Only the sidecar `.occurrences.jsonl` is appended.
- It does **not** create golden cases — those are a user-curated artifact (see `templates/crucible/seeds/golden-case.example.yaml`).
- It does **not** rotate or compact its output files. Periodic maintenance is the user's job (see `docs/workflows/crucible.md` for the recommended cadence).

## Source of truth · 来源

The behavior here mirrors the Crucible schema defined in `templates/crucible/schemas/`. If the schemas change, this hook must change too — they are sister artifacts.
