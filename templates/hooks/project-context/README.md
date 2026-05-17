# project-context

> SessionStart hook · injects a fixed instruction so the agent emits one line of "project positioning + current stage" before its first reply. Language picked at runtime.
> SessionStart hook · 每次会话开始注入指令，让 Agent 在第一个回答顶部输出『项目定位 / 当前阶段』一行。语言运行时自适应。

## What it does · 它做了什么

**EN.** Before every first response in a Claude Code / Codex session, the agent is required to print a single line:

> Project: <one sentence>. Current stage: <one sentence>.

The agent derives the line using a four-step fallback chain (root CLAUDE.md/AGENTS.md/README.md → manifest description → tasks/todo.md → recent commits). If all four miss, the agent must ask the user instead of guessing.

**中文。** 每次 Claude Code / Codex 会话的第一个回答之前，Agent 必须在响应顶部输出一行：

> 项目定位: <一句话>。当前阶段: <一句话>。

判断顺序 4 步：项目根 CLAUDE.md/AGENTS.md/README.md → manifest 的 description → tasks/todo.md → 最近 5 条 commit。四步都失败时必须问用户，不能瞎猜。

## Language is adaptive · 语言运行时自适应

`hook.sh` decides the output language **at session-start time**, not at install time. So switching environments (move project, change global rules) automatically changes what the hook prints — no reinstall needed.

`hook.sh` 在**会话启动时**判断输出语言，**不是**安装时。换项目或改全局规则后，hook 自动切换语言，不用重装。

**Detection order** (first match wins):

1. `$FORGE_HOOK_LANG` env var: `zh` / `cn` / `chinese` / `中文` / `简体中文` → zh, `en` / `english` → en
2. CJK character density across `$PWD/CLAUDE.md`, `$PWD/AGENTS.md`, `~/.claude/CLAUDE.md`, `~/.claude/rules/*.md` — total ≥ 50 chars in the first 8 KB of any → zh
3. Fallback: en

**Requirements:** Detection step 2 needs `python3` on PATH (macOS ships it; most Linux distros do too). If `python3` is missing the hook silently falls back to English — set `FORGE_HOOK_LANG=zh` to override.

## Install · 安装

```bash
# From the forge repo root
scripts/install-hook.sh project-context
```

The installer copies a single `hook.sh` (no language variant choice). Run `bash ~/.claude/hooks/forge-project-context.sh | head -1` after install to verify which language the detector picked on your machine.

## Uninstall · 卸载

```bash
scripts/uninstall-hook.sh project-context
```

## Skip conditions · 跳过条件

The injected instruction itself tells the agent to skip when:

- The user explicitly says "skip project context" / "跳过项目认知".
- The session is pure shell debugging.
- A standalone technical concept is being asked.
- It's casual chat.
- The user already stated the project positioning in the previous turn.

## Source of truth · 来源

The Chinese branch is the canonical version that Eisen runs at `~/.claude/hooks/zero-step-project-context.sh`. The English branch is a 1:1 translation kept in sync intentionally — if you change one, change the other (both live inside the same `hook.sh`).
