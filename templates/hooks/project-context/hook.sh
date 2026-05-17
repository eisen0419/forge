#!/bin/bash
# Forge hook · Project Context Zero-Step (adaptive)
# Installed to: ~/.claude/hooks/forge-project-context.sh
# Registered in: ~/.claude/settings.json -> SessionStart
# stdout is injected as "SessionStart hook additional context" into the system prompt.
#
# Language is chosen at runtime so the user can change their agent's output
# language without reinstalling the hook.
#
# Detection order (first match wins):
#   1. $FORGE_HOOK_LANG env var: "zh" | "cn" | "chinese" | "中文" → zh
#                                 "en" | "english"               → en
#   2. CJK character density across common instruction files:
#        ./CLAUDE.md, ./AGENTS.md,
#        ~/.claude/CLAUDE.md, ~/.claude/rules/*.md
#      Total ≥ 50 CJK chars in the first 8 KB of any of them → zh
#   3. Fallback: en

detect_lang() {
  if [[ -n "${FORGE_HOOK_LANG:-}" ]]; then
    case "$(printf '%s' "$FORGE_HOOK_LANG" | tr '[:upper:]' '[:lower:]')" in
      zh|cn|chinese|中文|简体中文) echo zh; return ;;
      en|english) echo en; return ;;
    esac
  fi

  command -v python3 >/dev/null 2>&1 || { echo en; return; }

  local sources=(
    "$PWD/CLAUDE.md"
    "$PWD/AGENTS.md"
    "$HOME/.claude/CLAUDE.md"
  )
  if [[ -d "$HOME/.claude/rules" ]]; then
    while IFS= read -r f; do sources+=("$f"); done < <(ls "$HOME/.claude/rules"/*.md 2>/dev/null)
  fi

  local count=0 n
  for f in "${sources[@]}"; do
    [[ -f "$f" ]] || continue
    n=$(head -c 8192 "$f" 2>/dev/null | python3 -c "import sys,re; print(len(re.findall(r'[一-龥]', sys.stdin.buffer.read().decode('utf-8','replace'))))" 2>/dev/null || echo 0)
    count=$((count + n))
    if (( count >= 50 )); then
      echo zh
      return
    fi
  done

  echo en
}

case "$(detect_lang)" in
  zh)
    cat <<'EOF'
[项目认知第零步] 本轮第一个回答前，先在响应顶部输出一行：

> 项目定位: <一句话>。当前阶段: <一句话>。

判断顺序（前一步成功就停）：
1. 项目根 CLAUDE.md / AGENTS.md / README.md 第一段
2. package.json / pyproject.toml / Cargo.toml 的 description 字段
3. tasks/todo.md 顶部当前目标
4. 最近 5 条 commit message 趋势

四步都判断不出来 → 不要瞎猜，直接问用户："我没能从 README/CLAUDE.md/commits 看出项目定位和当前阶段，能用一两句告诉我吗？"

跳过条件：用户明确说"跳过项目认知" / 纯 shell 调试 / 单独问技术概念 / 闲聊 / 用户已在前一轮明示过项目定位。
EOF
    ;;
  *)
    cat <<'EOF'
[Project Context Zero-Step] Before your first reply this turn, emit ONE line at the top of your response:

> Project: <one sentence>. Current stage: <one sentence>.

Fallback chain (stop at the first hit):
1. The first paragraph of the project's CLAUDE.md / AGENTS.md / README.md
2. The `description` field in package.json / pyproject.toml / Cargo.toml
3. The current goal at the top of tasks/todo.md
4. The trend across the last 5 commit messages

If all four miss → do NOT guess. Ask the user: "I couldn't determine the project's positioning and current stage from README/CLAUDE.md/commits — can you tell me in one or two sentences?"

Skip when: the user says "skip project context" / pure shell debugging / standalone technical concept question / casual chat / the user already stated the project positioning in the previous turn.
EOF
    ;;
esac
