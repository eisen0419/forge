#!/bin/bash
# Forge · uninstall-hook.sh
# Remove a hook from ~/.claude/hooks and unregister it from ~/.claude/settings.json
#
# Usage:
#   scripts/uninstall-hook.sh <hook-id|all> [--home <path>]
#
# Examples:
#   scripts/uninstall-hook.sh project-context
#   scripts/uninstall-hook.sh all
#   scripts/uninstall-hook.sh project-context --home /tmp/fakehome

set -euo pipefail

# ---------- args ----------
HOOK_ID=""
HOME_OVERRIDE=""

while (( $# > 0 )); do
  case "$1" in
    --home)  HOME_OVERRIDE="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,12p' "$0"
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
[[ -f "$SETTINGS" ]] || { echo "ℹ nothing to uninstall — $SETTINGS does not exist" >&2; exit 0; }

BACKUP_SUFFIX=$(date +%Y%m%d-%H%M%S)
cp "$SETTINGS" "$SETTINGS.bak.$BACKUP_SUFFIX"

uninstall_one() {
  local id="$1"
  local entry
  entry=$(jq -c --arg id "$id" '.hooks[] | select(.id == $id)' "$MANIFEST")
  if [[ -z "$entry" || "$entry" == "null" ]]; then
    echo "⚠ hook id not in manifest (skipping): $id" >&2
    return 0
  fi

  local event marker dst
  event=$(jq -r '.event' <<<"$entry")
  marker=$(jq -r '.marker' <<<"$entry")
  dst="$HOOKS_DIR/${marker}.sh"

  # Remove from settings.json: drop hook entries whose command contains the marker
  local tmp
  tmp=$(mktemp)
  jq --arg evt "$event" --arg marker "$marker" '
    if .hooks[$evt] then
      .hooks[$evt] = (.hooks[$evt]
        | map(
            .hooks = ((.hooks // []) | map(select((.command // "") | contains($marker) | not)))
            | select((.hooks | length) > 0)
          )
        | map(select(. != null))
      )
    else . end
    | if (.hooks[$evt] // []) | length == 0 then del(.hooks[$evt]) else . end
  ' "$SETTINGS" > "$tmp" && mv "$tmp" "$SETTINGS"
  echo "✓ unregistered from settings.json: $id ($event)"

  if [[ -f "$dst" ]]; then
    rm "$dst"
    echo "✓ removed script: $dst"
  else
    echo "  (script already absent: $dst)"
  fi
}

# ---------- dispatch ----------
if [[ "$HOOK_ID" == "all" ]]; then
  jq -r '.hooks[].id' "$MANIFEST" | while read -r id; do uninstall_one "$id"; done
else
  uninstall_one "$HOOK_ID"
fi

echo
echo "Done. Settings backup: $SETTINGS.bak.$BACKUP_SUFFIX"
