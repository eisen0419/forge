#!/usr/bin/env bash
# Forge · install-crucible.sh
# Stage Forge's Crucible evolution-asset templates into ~/.claude/crucible/
# and (by default) initialize the install dir as a git repo so lessons
# survive machine moves.
#
# Usage:
#   scripts/install-crucible.sh                  # standard install
#   scripts/install-crucible.sh --with-seeds     # also copy the worked-example yamls
#   scripts/install-crucible.sh --no-git         # skip the git init + first commit
#   scripts/install-crucible.sh --home <path>    # custom install root (for tests)
#
# Idempotent. README.md + schemas/ are refreshed on every run. User-editable
# data under failed-directions/ and golden-cases/ is never touched once written.

set -euo pipefail

WITH_SEEDS=0
NO_GIT=0
HOME_OVERRIDE=""

while (( $# > 0 )); do
  case "$1" in
    --with-seeds)  WITH_SEEDS=1; shift ;;
    --no-git)      NO_GIT=1; shift ;;
    --home)        HOME_OVERRIDE="$2"; shift 2 ;;
    -h|--help)
      sed -n '2,15p' "$0"
      exit 0
      ;;
    *)
      echo "❌ unexpected arg: $1" >&2
      echo "Run with -h for help." >&2
      exit 2
      ;;
  esac
done

FORGE_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TARGET_HOME="${HOME_OVERRIDE:-$HOME}"
CRUCIBLE_DIR="$TARGET_HOME/.claude/crucible"
SRC_DIR="$FORGE_ROOT/templates/crucible"

# Preflight
[[ -d "$SRC_DIR" ]] || { echo "❌ source not found: $SRC_DIR" >&2; exit 1; }

# Inform the user about idempotency before touching anything.
if [[ -d "$CRUCIBLE_DIR" ]]; then
  echo "✓ $CRUCIBLE_DIR exists — refreshing README + schemas, preserving user data."
fi

# 1. Skeleton directories.
mkdir -p "$CRUCIBLE_DIR/failed-directions" "$CRUCIBLE_DIR/golden-cases"

# 2. Refresh design doc and schemas (always overwrite — these are Forge's source of truth).
cp -f "$SRC_DIR/README.md" "$CRUCIBLE_DIR/"
mkdir -p "$CRUCIBLE_DIR/schemas"
cp -f "$SRC_DIR/schemas/"*.yaml "$CRUCIBLE_DIR/schemas/"
echo "✓ README.md + schemas/ refreshed"

# 3. (Optional) worked-example seeds — never overwrite if files already exist.
if (( WITH_SEEDS )); then
  if [[ ! -e "$CRUCIBLE_DIR/failed-directions/example.yaml" ]]; then
    cp "$SRC_DIR/seeds/failed-direction.example.yaml" \
       "$CRUCIBLE_DIR/failed-directions/example.yaml"
    echo "✓ failed-directions/example.yaml seeded"
  else
    echo "  failed-directions/example.yaml already exists — skipping"
  fi
  if [[ ! -e "$CRUCIBLE_DIR/golden-cases/gc_example.yaml" ]]; then
    cp "$SRC_DIR/seeds/golden-case.example.yaml" \
       "$CRUCIBLE_DIR/golden-cases/gc_example.yaml"
    echo "✓ golden-cases/gc_example.yaml seeded"
  else
    echo "  golden-cases/gc_example.yaml already exists — skipping"
  fi
fi

# 4. (Optional) initialize git in the install dir so lessons survive machine moves.
if ! (( NO_GIT )); then
  if [[ -d "$CRUCIBLE_DIR/.git" ]]; then
    echo "  $CRUCIBLE_DIR/.git exists — skipping init"
  else
    if ! command -v git >/dev/null 2>&1; then
      echo "⚠ git not on PATH — skipping git init (install is otherwise complete)"
    else
      (cd "$CRUCIBLE_DIR" && \
        git init -q && \
        git add . && \
        git commit -q -m "init crucible (forge install-crucible.sh)" 2>/dev/null) || \
        echo "⚠ git init failed (probably nothing to commit yet) — non-fatal"
      echo "✓ git initialized at $CRUCIBLE_DIR"
    fi
  fi
fi

echo ""
echo "✓ Crucible installed at $CRUCIBLE_DIR"
echo ""
echo "Next:"
echo "  - Splice the pre-flight prose into your CLAUDE.md / AGENTS.md (see docs/workflows/crucible.md)."
echo "  - Pair with the auto-evolve-collector hook for automatic population:"
echo "      scripts/install-hook.sh auto-evolve-collector"
