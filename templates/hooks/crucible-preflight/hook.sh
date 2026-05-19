#!/bin/bash
# crucible-preflight.sh — Forge runtime hook
#
# Event:    PreToolUse (matcher: Bash)
# Purpose:  Intercept high-risk Bash commands (git push, rm -rf, migrations,
#           force-push, etc.) BEFORE they execute and check the local Crucible
#           failed-directions store for a known prior failure pattern that
#           matches the command. If a match with both first-level (high-risk
#           keyword) and second-level (yaml trigger/sample_snippet keyword)
#           confirmation is found, the hook DENIES the command and returns
#           the matching fingerprint's correct_action so the agent sees it
#           and follows the proven recovery path instead of repeating the
#           prior failure.
#
# Why deny instead of echo: in the PreToolUse protocol, `additionalContext`
# from a non-blocking hook arrives ALONGSIDE the tool_result — too late for
# destructive commands. Only `permissionDecision: deny` with
# `permissionDecisionReason` is shown to the agent BEFORE the command runs.
#
# Anti-false-positive: fingerprint coarseness (sha1(error_kind|tool)) means
# a single fp may collapse unrelated failures under "permission denied|Bash".
# The hook therefore requires TWO independent matches:
#   1. The Bash command must match a high-risk regex (not every command).
#   2. The fp's trigger/sample_snippet must share at least one significant
#      keyword with the command (so e.g. a "git push to main" command does
#      not get denied by a "chmod permission denied" fingerprint).
#
# Bookkeeping: this hook does NOT mutate retrieval_count (which is an
# honor-system self-reported metric). It appends a single JSON line to
# $EVOLVE_CRUCIBLE_FD_DIR/../surface_log.jsonl per deny, capturing fp +
# command + timestamp so machine-observed surface activity can be audited
# independently of the model's self-reported reads.
#
# Environment overrides:
#   EVOLVE_CRUCIBLE_FD_DIR   default: $HOME/.claude/crucible/failed-directions

set -e

CRUCIBLE_FD_DIR="${EVOLVE_CRUCIBLE_FD_DIR:-$HOME/.claude/crucible/failed-directions}"
SURFACE_LOG="$(dirname "$CRUCIBLE_FD_DIR")/surface_log.jsonl"

# Allow-by-default — emit nothing on stdout, exit 0.
allow() { exit 0; }

# Deny — emit Claude Code hook JSON on stdout with fingerprint + correct_action.
deny_with_fingerprint() {
  local fp="$1" yaml="$2" cmd="$3"
  local correct_action
  # Extract correct_action's literal block (lines between `correct_action: |` and the next top-level key).
  correct_action=$(awk '
    /^correct_action: \|/ { in_block=1; next }
    in_block && /^[a-z_]+:/ { in_block=0 }
    in_block { print }
  ' "$yaml")

  # Fallback: if not a literal block, grab the inline value.
  if [ -z "$correct_action" ]; then
    correct_action=$(awk -F': ' '/^correct_action:/ {sub(/^correct_action: */,""); print; exit}' "$yaml")
  fi

  local trigger
  trigger=$(awk -F': ' '/^trigger:/ {sub(/^trigger: */,""); gsub(/^"|"$/, ""); print; exit}' "$yaml")

  # Append surface log line (machine-observed metric — does not mutate the yaml).
  mkdir -p "$(dirname "$SURFACE_LOG")"
  local ts
  ts=$(date -u +%Y-%m-%dT%H:%M:%SZ)
  printf '{"at":"%s","fp":"%s","action":"deny","command":%s}\n' \
    "$ts" "$fp" "$(printf '%s' "$cmd" | python3 -c 'import json,sys; print(json.dumps(sys.stdin.read()))')" \
    >> "$SURFACE_LOG" 2>/dev/null || true

  # Emit the Claude Code hook JSON. Note: permissionDecisionReason is shown
  # to the agent ONLY on deny (allow/ask shows it to the user, not the model).
  python3 - "$fp" "$trigger" "$correct_action" <<'PYEOF'
import json, sys
fp, trigger, correct_action = sys.argv[1], sys.argv[2], sys.argv[3]
reason = f"""[Crucible pre-flight] command intercepted by fingerprint {fp}

trigger: {trigger}

The local crucible store has a known failed-direction matching this
command. Before retrying, follow correct_action:

{correct_action}

If you have already done this analysis and want to proceed anyway, you
may re-issue the command after writing this fingerprint into
~/.claude/crucible/.acks (one fingerprint per line) — the hook will
then allow subsequent attempts at the same command pattern."""

print(json.dumps({
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": reason.strip(),
  }
}))
PYEOF
  exit 0
}

# 1. Read PreToolUse stdin payload (JSON). Only Bash tool calls matter here;
# the manifest already scopes matcher=Bash, but defend against payload drift.
PAYLOAD=$(cat)
TOOL=$(printf '%s' "$PAYLOAD" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_name",""))' 2>/dev/null || echo "")
[ "$TOOL" = "Bash" ] || allow

CMD=$(printf '%s' "$PAYLOAD" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("tool_input",{}).get("command",""))' 2>/dev/null || echo "")
[ -z "$CMD" ] && allow

# 2. Acknowledgement bypass — if the user/agent has previously cited an fp
# in this session, do not re-deny the same fp. The model can include
# "acknowledged crucible fp:<id>" in any prior tool call's command/comment
# and that pattern surfaces in $HOME/.claude/crucible/.ack-current-session.
# (Best-effort: file is wiped on SessionStart by a sibling hook in future.)
ACK_FILE="$HOME/.claude/crucible/.acks"

# 3. First-level filter — high-risk Bash command regex.
#
# Match command prefixes only (not arbitrary substrings) so a script comment
# containing "git push" doesn't trip the hook. Use word-anchored extended
# regex on the first 200 chars of the command.
CMD_HEAD=$(printf '%s' "$CMD" | head -c 200)
HIGH_RISK_REGEX='(^|[ |&;()`$])(git[[:space:]]+push|git[[:space:]]+reset[[:space:]]+--hard|git[[:space:]]+rebase.*--force|rm[[:space:]]+-rf|chmod[[:space:]]+-R|chown[[:space:]]+-R|psql.*DROP[[:space:]]+TABLE|mysql.*DROP[[:space:]]+TABLE|terraform[[:space:]]+destroy|kubectl[[:space:]]+delete)'

if ! printf '%s' "$CMD_HEAD" | grep -qE "$HIGH_RISK_REGEX"; then
  allow
fi

# 3a. Tag-push early-allow.
#
# `git push origin v0.5.0` superficially looks like a branch push to the
# crucible store, because failed-directions yamls about protected-branch
# pushes share keywords with any `git push origin <ref>` command. But tag
# pushes do not actually risk the failures those yamls describe (you don't
# trip branch protection by pushing a tag; you don't fight the GitHub PR
# API by pushing a tag). So if this command is unambiguously a tag push,
# skip the rest of the hook and allow.
#
# Three detection cases:
#   (a) --tags or --follow-tags flag anywhere on the line
#   (b) explicit refs/tags/<name> path on the line
#   (c) the last whitespace-delimited token is an existing tag in the local
#       repo (queried via `git rev-parse --verify refs/tags/<token>`)
#
# Case (c) is the strict one — it requires the tag to actually exist before
# the push, which is the normal `git tag X && git push origin X` workflow.
# If somebody types `git push origin v0.5.0` while v0.5.0 doesn't exist
# locally yet, git itself will reject the push, and the hook will still
# have done its job (the branch-push yamls don't apply anyway).
if printf '%s' "$CMD_HEAD" | grep -qE '(^|[[:space:]])(--tags|--follow-tags)([[:space:]]|$)'; then
  allow
fi
if printf '%s' "$CMD_HEAD" | grep -qE 'refs/tags/[A-Za-z0-9._/-]+'; then
  allow
fi
# Last token of the command (after trimming trailing whitespace + comments).
# We only attempt this check if the command looks like `git push <remote> <ref>`
# — three or more tokens starting with `git push`.
LAST_TOK=$(printf '%s' "$CMD_HEAD" | awk '{print $NF}')
if [ -n "$LAST_TOK" ] \
   && printf '%s' "$CMD_HEAD" | grep -qE '^[[:space:]]*git[[:space:]]+push[[:space:]]+\S+[[:space:]]+\S+' \
   && command -v git >/dev/null 2>&1 \
   && git rev-parse --verify "refs/tags/$LAST_TOK" >/dev/null 2>&1; then
  allow
fi

# 4. Extract command keywords for the second-level match.
# Take alphanumeric tokens ≥ 3 chars from the first 200 chars, lowercase.
KEYWORDS=$(printf '%s' "$CMD_HEAD" | tr -c '[:alnum:]' '\n' | awk 'length($0) >= 3' | tr '[:upper:]' '[:lower:]' | sort -u)

# 5. For each failed-direction yaml, check if its trigger / sample_snippet /
# content / correct_action collectively share at least 2 keywords with the
# command. Two-match threshold avoids single-word coincidences (e.g. "git").
if [ ! -d "$CRUCIBLE_FD_DIR" ]; then
  allow
fi

BEST_MATCH=""
BEST_SCORE=0
for yaml in "$CRUCIBLE_FD_DIR"/*.yaml; do
  [ -f "$yaml" ] || continue
  # Acknowledged this fp already? Skip.
  fp=$(basename "$yaml" .yaml)
  if [ -f "$ACK_FILE" ] && grep -qx "$fp" "$ACK_FILE" 2>/dev/null; then
    continue
  fi

  # Pull the user-edited text fields (trigger / content / correct_action / sample_snippet)
  # and lowercase them for keyword comparison.
  text=$(awk '
    /^(trigger|content|correct_action|sample_snippet):/ { capture=1 }
    capture { print }
    /^[a-z_]+:/ && !/^(trigger|content|correct_action|sample_snippet):/ { capture=0 }
  ' "$yaml" 2>/dev/null | tr '[:upper:]' '[:lower:]')

  # Count keyword matches.
  score=0
  for kw in $KEYWORDS; do
    if printf '%s' "$text" | grep -qw "$kw"; then
      score=$((score + 1))
    fi
  done

  if [ "$score" -ge 2 ] && [ "$score" -gt "$BEST_SCORE" ]; then
    BEST_MATCH="$yaml"
    BEST_SCORE=$score
  fi
done

# 6. If we found a meaningfully-matching yaml, deny with its correct_action.
# If no yaml scored ≥ 2 keyword matches, the high-risk command is unfamiliar
# territory — let it through (this is intentional; the hook only blocks
# patterns the user has explicitly characterized in their crucible store).
if [ -n "$BEST_MATCH" ]; then
  fp=$(basename "$BEST_MATCH" .yaml)
  deny_with_fingerprint "$fp" "$BEST_MATCH" "$CMD"
fi

allow
