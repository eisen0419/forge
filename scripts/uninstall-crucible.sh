#!/usr/bin/env bash
# Forge · uninstall-crucible.sh
# Move ~/.claude/crucible/ aside (rename, not delete) so the user's
# accumulated failed-directions and golden-cases survive in case they
# change their mind. To actually delete, follow the printed instructions.
#
# Usage:
#   scripts/uninstall-crucible.sh                 # rename to .removed.<timestamp>
#   scripts/uninstall-crucible.sh --home <path>   # custom install root (for tests)

set -euo pipefail

HOME_OVERRIDE=""

while (( $# > 0 )); do
  case "$1" in
    --home)  HOME_OVERRIDE="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,11p' "$0"
      exit 0
      ;;
    *)
      echo "❌ unexpected arg: $1" >&2
      exit 2
      ;;
  esac
done

TARGET_HOME="${HOME_OVERRIDE:-$HOME}"
CRUCIBLE_DIR="$TARGET_HOME/.claude/crucible"

if [[ ! -d "$CRUCIBLE_DIR" ]]; then
  echo "  no install found at $CRUCIBLE_DIR — nothing to do"
  exit 0
fi

STAMP=$(date +%Y%m%d-%H%M%S)
BACKUP="${CRUCIBLE_DIR}.removed.${STAMP}"

mv "$CRUCIBLE_DIR" "$BACKUP"

echo "✓ Crucible moved aside (NOT deleted):"
echo "  $CRUCIBLE_DIR  →  $BACKUP"
echo ""
echo "To restore:    mv $BACKUP $CRUCIBLE_DIR"
echo "To actually delete (irreversible):"
echo "  rm -rf $BACKUP"
echo ""
echo "Reason this script renames instead of deleting: user-edited content_action / "
echo "confidence / linked_golden_case fields in your failed-directions/ yamls cannot"
echo "be recovered if deleted by accident. Renaming gives you a recovery path."
