# crucible-preflight

> PreToolUse hook · intercepts high-risk Bash commands BEFORE they execute and denies them when a matching Crucible failed-direction prescribes a different `correct_action`. Closes the read-side gap that the existing `auto-evolve-collector` Stop hook cannot fill.
> PreToolUse hook · 在高风险 Bash 命令执行**前**拦截，当 Crucible failed-direction 命中且 correct_action 提供更安全路径时，**直接 deny** 让 agent 看到正确做法。补齐 `auto-evolve-collector` Stop hook 写得到但读不到的环节。

## Why this hook exists · 为什么有这个 hook

**EN.** The Crucible v0.3.0–v0.4.0 wave shipped a complete *writer* (Stop hook) and *storage* (`~/.claude/crucible/failed-directions/`), but the *reader* was honor-system prose in `~/CLAUDE.md` telling the agent "you should grep before L3 commands". Field data (status.sh) showed the honor system is unreliable — typical retrieval ratios stayed at 3/11 over multi-day runs.

This hook converts the reader from honor-system to enforced: when the agent attempts a high-risk `Bash` command, the hook synchronously checks the failed-directions store, and if the command matches a known prior failure, returns `permissionDecision: deny` with the matching `correct_action`. Claude Code shows the `permissionDecisionReason` to the agent (denials are the only PreToolUse path where that is true — `allow` and `ask` reasons go to the user instead, which is too late for `git push` / `rm -rf`).

**中文。** Crucible v0.3.0–v0.4.0 wave ship 了完整的**写入端**（Stop hook）和**存储**（`~/.claude/crucible/failed-directions/`），但**读取端**是 `~/CLAUDE.md` 里告诉 agent "L3 任务前你该 grep" 的 honor-system prose。实地数据（status.sh）显示 honor system 不可靠——多天运行后检索比例稳定在 3/11 左右。

这个 hook 把读取端从 honor-system 转成强制执行：agent 尝试任何高风险 `Bash` 命令时，hook 同步检查 failed-directions，命中则返回 `permissionDecision: deny` 加上对应的 `correct_action`。Claude Code 只在 deny 时把 `permissionDecisionReason` 给 agent 看（`allow` / `ask` 的 reason 给用户看，对 `git push` / `rm -rf` 这种破坏性命令已经太晚）。

## What it does · 它做了什么

On every Bash tool call, the hook runs five checks in order. Any check that "fails" short-circuits to **allow** (i.e. the hook does nothing). All must "pass" for a **deny** to fire.

```
1. tool_name == "Bash"
   └─ no:  allow
2. command matches high-risk regex
   (git push | git reset --hard | git rebase --force | rm -rf |
    chmod -R | chown -R | DROP TABLE | terraform destroy | kubectl delete)
   └─ no:  allow                              ← most commands stop here
2a. (NEW in v0.5.1) tag-push exemption — three detection cases:
    (a) --tags or --follow-tags flag anywhere on the line
    (b) explicit refs/tags/<name> path
    (c) last token is an EXISTING local git tag
         (verified via `git rev-parse --verify refs/tags/<token>`)
    └─ any case true:  allow                  ← branch-push yamls do not apply
3. some failed-direction yaml's trigger/sample_snippet/content/correct_action
   shares ≥ 2 keywords with the command
   └─ no:  allow                              ← anti-false-positive gate
4. the matched fingerprint is NOT in ~/.claude/crucible/.acks
   └─ in acks:  allow                         ← user/agent opt-out per fp
5. deny + emit fingerprint + correct_action + append surface_log.jsonl
```

The **≥ 2 keyword overlap** rule defends against fingerprint coarseness. `sha1(error_kind|tool_name)` collapses unrelated failures under buckets like `permission denied|Bash` — without secondary keyword matching, the hook would deny `git push` based on a `chmod` failure pattern. With ≥ 2 keywords (excluding 1–2 char tokens) the hook only fires when the command and the failure pattern share substantive vocabulary.

## What it does NOT do · 它不做什么

- **It does not bump `retrieval_count`.** That field is documented as honor-system, model-reported. A hook-driven counter would silently change the field's meaning. Instead this hook appends a JSON line per surface to `~/.claude/crucible/surface_log.jsonl` — a separate, machine-observed signal.
- **It does not learn.** New failed-directions are still written by the `auto-evolve-collector` Stop hook. This hook only consumes.
- **It does not act on golden-cases.** Only `failed-directions/` is grepped — the deny logic needs an anti-pattern to point at, not a positive playbook.
- **It does not modify any yaml.** All Crucible yamls remain user-editable; the hook only reads them.
- **It does not block non-Bash tools** (Edit / Write / Read / etc.). Those are governed by Claude Code's own per-tool protocols; the hook is scoped to the destructive-bash use case the Crucible store models best.

## Outputs · 输出

| Sink | Path | Always on? | Purpose |
|------|------|-----------|---------|
| stdout JSON | `permissionDecisionReason` | On deny only | The agent reads this BEFORE the command runs and follows `correct_action` instead. |
| Surface log | `~/.claude/crucible/surface_log.jsonl` | On deny only | Append-only audit trail: `{"at":"ISO8601","fp":"<12-char>","action":"deny","command":"..."}`. Machine-observed read activity, independent of self-reported `retrieval_count`. |

## Acknowledgement bypass · 确认豁免

If the agent has already analyzed a fingerprint and wants to proceed anyway (e.g. the failed-direction's counterexamples explicitly cover the current case), append the fingerprint to `~/.claude/crucible/.acks` (one per line):

```bash
echo "df53a88d1096" >> ~/.claude/crucible/.acks
```

The hook then allows subsequent commands matching that fingerprint. To reset, truncate or delete the file.

This is a **per-fingerprint opt-out**, not a global kill switch. Pre-flight remains active for every other fp.

## Install · 安装

```bash
scripts/install-hook.sh crucible-preflight
```

This copies `hook.sh` to `~/.claude/hooks/forge-crucible-preflight.sh` and registers it under `PreToolUse` with `matcher: "Bash"` in `~/.claude/settings.json`.

## Uninstall · 卸载

```bash
scripts/uninstall-hook.sh crucible-preflight
```

## Cost / safety · 成本与安全

- **Budget**: typically < 50 ms per Bash call. Reads ≤ 30 yaml files, runs ~10 lines of awk + grep. No LLM, no network.
- **Failure mode**: `set -e` at the top, but every grep / yaml read is wrapped so a missing dir / malformed yaml exits 0 (allow). A broken hook never blocks a legitimate Bash call.
- **Privacy**: outputs stay local (`~/.claude/crucible/surface_log.jsonl`). No network calls. No data leaves the machine.

## Sibling artifacts · 联动产物

This hook is the **read-side** complement to the writer hook shipped in v0.3.0:

- `templates/hooks/auto-evolve-collector/hook.sh` — Stop hook, populates `failed-directions/` from each session's errors.
- `templates/crucible/schemas/failed-direction.schema.yaml` — the yaml shape this hook reads.
- `scripts/crucible-bookkeep.sh` — manual maintenance helper (`hit`, `list`, `validate`, `gen-fingerprint`).
- `~/.claude/crucible/surface_log.jsonl` — new in this PR. Audit trail of deny events.

Together they form the closed loop: error → fp → yaml (writer) → next L3 command → grep → deny + correct_action (reader).

## Tuning · 调整

Two knobs you'll likely want over time:

1. **High-risk regex** at `hook.sh` line ~110. Add tool prefixes specific to your workflow (e.g. `flyctl deploy`, `gh release delete`, `aws s3 rm`).
2. **Keyword threshold** at `hook.sh` line ~135 (`score >= 2`). Raise to 3 if you see false positives, lower to 1 if you see false negatives.

Both are intentionally exposed as plain numbers / regex strings rather than env vars — the contract is "edit your local copy if your domain needs different defaults".
