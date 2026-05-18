# Forge Hooks · Runtime Behaviour Add-ons

> Optional runtime hooks that the **`forge-setup`** wizard can install on your behalf, or you can install/uninstall manually with `scripts/install-hook.sh` / `scripts/uninstall-hook.sh`.
> 可由 **`forge-setup`** 向导自动安装，也可通过 `scripts/install-hook.sh` / `scripts/uninstall-hook.sh` 手动安装/卸载的可选运行时 hook。

---

## What's the difference vs `templates/full.md`? · 与 `templates/full.md` 有什么区别？

**EN.** `templates/full.md` is **prose** — text that ends up *inside* the agent's `CLAUDE.md`/`AGENTS.md` as instructions. `templates/hooks/` is **shell scripts** — actual processes that Claude Code / Codex executes at lifecycle events (e.g. SessionStart, PreToolUse). The two are complementary:

- `full.md` tells the agent *how to think*.
- `hooks/` makes the runtime *act* at specific moments.

**中文。** `templates/full.md` 是 **散文（prose）** — 文本会进入 Agent 的 `CLAUDE.md` / `AGENTS.md` 作为指令。`templates/hooks/` 是 **shell 脚本** — Claude Code / Codex 在生命周期事件（SessionStart、PreToolUse 等）实际执行的进程。两者互补：

- `full.md` 告诉 Agent **怎么思考**。
- `hooks/` 让 runtime 在特定时机 **真做事**。

---

## Catalog · 目录

| Hook ID | Event | Language | Description |
|---------|-------|----------|-------------|
| [`project-context`](./project-context/) | `SessionStart` | adaptive | Forces the agent to emit "Project / Current stage" line before every first reply. 4-step fallback chain. |
| [`auto-evolve-collector`](./auto-evolve-collector/) | `Stop` | en | Scans the session jsonl on session end; persists tool errors and user corrections to a daily jsonl, the Crucible failed-directions store, and an optional Obsidian digest. Sibling to `templates/crucible/` and `scripts/crucible-bookkeep.sh`. |
| [`crucible-preflight`](./crucible-preflight/) | `PreToolUse` (matcher: `Bash`) | en | Read-side complement to `auto-evolve-collector`. Intercepts high-risk Bash commands BEFORE execution; if a `failed-directions/<fp>.yaml` matches (high-risk regex + ≥ 2 keyword overlap), denies the call and returns the matching `correct_action` to the agent. Anti-false-positive design; opt-out per fingerprint via `~/.claude/crucible/.acks`. Surface log at `~/.claude/crucible/surface_log.jsonl`. |

The `Language` column means:

- **adaptive** — the hook decides at runtime by scanning `CLAUDE.md`, `AGENTS.md`, and `~/.claude/rules/*.md` for CJK density. Override with `FORGE_HOOK_LANG=zh|en`. See the hook's own README for details.
- **`zh` / `en` / etc.** — a fixed-language hook (not used yet; reserve for hooks where wording can't be made bilingual).

---

## Quick start · 快速上手

```bash
# Install one hook
scripts/install-hook.sh project-context

# Install everything in the manifest
scripts/install-hook.sh all

# Force language for an adaptive hook (env var, not install flag)
FORGE_HOOK_LANG=zh bash ~/.claude/hooks/forge-project-context.sh  # test/preview
# Or persist in your shell profile so Claude Code inherits it:
echo 'export FORGE_HOOK_LANG=zh' >> ~/.zshrc

# Uninstall
scripts/uninstall-hook.sh project-context
scripts/uninstall-hook.sh all
```

What the installer does:

1. Copies `templates/hooks/<id>/hook.sh` (or the script declared in manifest's `.script` field) to `~/.claude/hooks/<marker>.sh`.
2. Backs up `~/.claude/settings.json` with timestamp suffix.
3. Registers a `{"command": "bash <path>", "type": "command"}` entry under the declared event.
4. Deduplicates: re-running install on the same hook is a no-op.
5. Verifies by executing the hook and printing the first stdout line — useful sanity check on the language detection.

Uninstaller reverses both the script file and the `settings.json` registration, without touching other hooks or fields.

> **Scope:** All hooks here install into **`~/.claude/`** (global, affects every project). This matches Claude Code's hook semantics — a `SessionStart` hook is inherently per-machine, not per-project.
> **作用域：** 这里所有 hook 都装到 **`~/.claude/`**（全局，对所有项目生效）。这与 Claude Code hook 语义一致——`SessionStart` hook 本质上是按机器装，不是按项目装。

---

## Manifest schema · manifest 模式

`manifest.json` is the source of truth. Schema:

```jsonc
{
  "schema_version": "1.1",
  "hooks": [
    {
      "id": "project-context",            // unique, used in CLI: install-hook.sh <id>
      "name":        { "en": "...", "zh": "..." },
      "description": { "en": "...", "zh": "..." },
      "event": "SessionStart",            // any Claude Code hook event
      "matcher": "Bash",                  // OPTIONAL — required only for PreToolUse / PostToolUse (which tool to match)
      "marker": "forge-project-context",  // becomes ~/.claude/hooks/<marker>.sh and dedup key
      "script": "project-context/hook.sh",// path relative to templates/hooks/
      "language": "adaptive",             // "adaptive" | "en" | "zh" — informational only
      "scope": "global",                  // currently always "global"
      "version": "1.1.0"
    }
  ]
}
```

> **`matcher` field.** Optional. Required for `PreToolUse` and `PostToolUse` events (those events need to know which tool the hook applies to, e.g. `"Bash"`). Omitted for `SessionStart` / `Stop` / `SessionEnd` / etc.
> **Migration from 1.0 → 1.1.** Replaced `variants` / `default_variant` (install-time choice) with a single `script` field + adaptive runtime detection inside the hook itself. The `language` field is informational — used only by listings, not by the installer.

---

## Adding a new hook · 新增一个 hook

Three steps. No script changes needed.

1. **Create the hook directory** `templates/hooks/<id>/`:
   ```
   templates/hooks/<id>/
   ├── hook.sh           # the script — decide language at runtime if you want adaptive behavior
   └── README.md         # what it does, install/uninstall examples
   ```
   `chmod +x hook.sh`. The script's `stdout` becomes the system-reminder injected into the agent's context.

   For adaptive hooks, copy the `detect_lang()` function from `project-context/hook.sh` and branch on its output. Or use any other runtime signal (`$LANG`, project type detection, etc.).

2. **Add an entry to `manifest.json`** following the schema above. Pick a unique `marker` (used as both filename and dedup key).

3. **Test in a sandbox**:
   ```bash
   TMP=$(mktemp -d)
   ./scripts/install-hook.sh <id> --home "$TMP"
   bash "$TMP/.claude/hooks/<marker>.sh" | head      # sanity check stdout
   FORGE_HOOK_LANG=zh bash "$TMP/.claude/hooks/<marker>.sh" | head   # if adaptive
   ./scripts/uninstall-hook.sh <id> --home "$TMP"
   rm -rf "$TMP"
   ```

That's it — `forge-setup` will pick up the new hook on the next wizard run.

---

## Manual install without forge-setup · 不走向导的手动安装

```bash
git clone https://github.com/eisen0419/forge.git ~/forge   # or wherever
cd ~/forge
./scripts/install-hook.sh project-context --lang en
```

Start a new Claude Code or Codex session — the hook fires automatically.

---

## Troubleshooting · 故障排查

| Symptom · 现象 | Likely cause · 可能原因 | Fix · 处理 |
|----------------|------------------------|------------|
| `jq is required` | `jq` not installed | `brew install jq` (macOS) or your distro's package manager |
| Hook doesn't fire on session start | Old session still running | Open a **new** session — hooks only load at session start |
| `manifest not found` | Running script outside forge repo | `cd` into the forge repo root, or run with explicit absolute path |
| Want to peek what got injected | Just run the script directly: `bash ~/.claude/hooks/forge-project-context.sh` | Output is exactly what the agent sees |
