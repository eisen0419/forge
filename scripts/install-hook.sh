#!/bin/bash
# Forge · install-hook.sh
# Install a hook from templates/hooks/manifest.json into ~/.claude/hooks
# and register it in ~/.claude/settings.json under the declared event.
#
# Usage:
#   scripts/install-hook.sh <hook-id|all> [--home <path>]
#
# Examples:
#   scripts/install-hook.sh project-context
#   scripts/install-hook.sh all
#   scripts/install-hook.sh project-context --home /tmp/fakehome   # for tests
#
# Language for adaptive hooks (project-context, etc.) is decided at runtime
# by the hook itself — no install-time selection. To force a language for a
# session, export FORGE_HOOK_LANG=zh or =en before starting the agent.

set -euo pipefail

# ---------- args ----------
HOOK_ID=""
HOME_OVERRIDE=""

while (( $# > 0 )); do
  case "$1" in
    --home)  HOME_OVERRIDE="$2"; shift 2 ;;
    --lang)
      echo "⚠ --lang is deprecated and ignored — hooks pick language at runtime." >&2
      shift 2
      ;;
    -h|--help)
      sed -n '2,17p' "$0"
      exit 0
      ;;
    *)
      if [[ -z "$HOOK_ID" ]]; then HOOK_ID="$1"; shift
      else echo "❌ unexpected arg: $1" >&2; exit 2
      fi
      ;;
  esac
done

if [[ -z "$HOOK_ID" ]]; then
  echo "❌ missing hook id (or 'all')" >&2
  echo "Usage: $0 <hook-id|all> [--home <path>]" >&2
  exit 2
fi

# ---------- paths ----------
FORGE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MANIFEST="$FORGE_ROOT/templates/hooks/manifest.json"
TARGET_HOME="${HOME_OVERRIDE:-$HOME}"
HOOKS_DIR="$TARGET_HOME/.claude/hooks"
SETTINGS="$TARGET_HOME/.claude/settings.json"

# ---------- preflight ----------
command -v jq >/dev/null 2>&1 || { echo "❌ jq is required. Install via: brew install jq" >&2; exit 1; }
[[ -f "$MANIFEST" ]] || { echo "❌ manifest not found: $MANIFEST" >&2; exit 1; }

mkdir -p "$HOOKS_DIR"
if [[ ! -f "$SETTINGS" ]]; then
  mkdir -p "$(dirname "$SETTINGS")"
  echo '{}' > "$SETTINGS"
fi

# Backup settings.json before any mutation
BACKUP_SUFFIX=$(date +%Y%m%d-%H%M%S)
cp "$SETTINGS" "$SETTINGS.bak.$BACKUP_SUFFIX"

# ---------- core install ----------
install_one() {
  local id="$1"
  local entry
  entry=$(jq -c --arg id "$id" '.hooks[] | select(.id == $id)' "$MANIFEST")
  if [[ -z "$entry" || "$entry" == "null" ]]; then
    echo "❌ hook not found in manifest: $id" >&2
    return 1
  fi

  local event matcher marker script_rel src dst
  event=$(jq -r '.event' <<<"$entry")
  matcher=$(jq -r '.matcher // ""' <<<"$entry")
  marker=$(jq -r '.marker' <<<"$entry")
  script_rel=$(jq -r '.script' <<<"$entry")

  if [[ -z "$script_rel" || "$script_rel" == "null" ]]; then
    echo "❌ hook '$id' has no .script field in manifest" >&2
    return 1
  fi

  src="$FORGE_ROOT/templates/hooks/$script_rel"
  dst="$HOOKS_DIR/${marker}.sh"

  [[ -f "$src" ]] || { echo "❌ source script missing: $src" >&2; return 1; }

  cp "$src" "$dst"
  chmod +x "$dst"
  echo "✓ installed: $dst"

  # Register in settings.json (dedup by command string)
  local cmd="bash \"$dst\""
  local already
  already=$(jq --arg evt "$event" --arg cmd "$cmd" '
    (.hooks[$evt] // [])
    | map(.hooks[]?.command)
    | flatten
    | index($cmd) != null
  ' "$SETTINGS")

  if [[ "$already" == "true" ]]; then
    echo "  (already registered in settings.json under $event)"
  else
    local tmp
    tmp=$(mktemp)
    # Include "matcher" only when the manifest entry specifies one. The
    # PreToolUse / PostToolUse events require a matcher (which tool the hook
    # applies to, e.g. "Bash"); SessionStart / Stop / etc. ignore it.
    if [[ -n "$matcher" ]]; then
      jq --arg evt "$event" --arg cmd "$cmd" --arg mat "$matcher" '
        .hooks //= {}
        | .hooks[$evt] //= []
        | .hooks[$evt] += [{"matcher": $mat, "hooks": [{"command": $cmd, "type": "command"}]}]
      ' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
      echo "✓ registered: settings.json -> $event (matcher: $matcher)"
    else
      jq --arg evt "$event" --arg cmd "$cmd" '
        .hooks //= {}
        | .hooks[$evt] //= []
        | .hooks[$evt] += [{"hooks": [{"command": $cmd, "type": "command"}]}]
      ' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
      echo "✓ registered: settings.json -> $event"
    fi
  fi

  # Quick verification: run the hook once and show first line. PreToolUse /
  # PostToolUse hooks expect a JSON stdin payload — running them with no
  # stdin should hit the "allow" path (empty stdout, exit 0) by design, so
  # don't warn on empty output for those event types.
  if [[ "$event" == "PreToolUse" || "$event" == "PostToolUse" ]]; then
    if bash "$dst" </dev/null >/dev/null 2>&1; then
      echo "  verify: $event hook (empty-stdin smoke test → allow path, OK)"
    else
      echo "  ⚠ $event hook exited non-zero on empty stdin" >&2
    fi
  else
    local first_line
    first_line=$(bash "$dst" 2>&1 | head -1 || true)
    if [[ -n "$first_line" ]]; then
      echo "  verify: $first_line"
    else
      echo "  ⚠ verification produced empty output" >&2
    fi
  fi
}

# ---------- dispatch ----------
if [[ "$HOOK_ID" == "all" ]]; then
  jq -r '.hooks[].id' "$MANIFEST" | while read -r id; do install_one "$id"; done
else
  install_one "$HOOK_ID"
fi

echo
echo "Done. Settings backup: $SETTINGS.bak.$BACKUP_SUFFIX"
echo "Start a new agent session to pick up the hook."
